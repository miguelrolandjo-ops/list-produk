-- =====================================================================
-- Store Price Guide App: SERVER schema (Supabase / PostgreSQL)
-- Local-first design: the owner's phone holds all real data.
-- The server only stores:
--   1. the employee catalog (safe fields only)
--   2. store access (owner, employees, invites)
--   3. the PO extraction queue (images in, JSON out, then deleted)
-- Put this file in: supabase/migrations/0001_init.sql
-- =====================================================================

create type member_role as enum ('owner', 'employee');
create type job_status  as enum ('pending', 'running', 'done', 'failed');

-- ---------------------------------------------------------------------
-- Access
-- ---------------------------------------------------------------------
create table stores (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_at timestamptz not null default now()
);

create table store_members (
  store_id     uuid not null references stores on delete cascade,
  user_id      uuid not null references auth.users on delete cascade,
  role         member_role not null,
  display_name text,
  device_label text,
  joined_at    timestamptz not null default now(),
  last_seen_at timestamptz,
  revoked_at   timestamptz,
  primary key (store_id, user_id)
);

create table invites (
  id         uuid primary key default gen_random_uuid(),
  store_id   uuid not null references stores on delete cascade,
  code       text not null unique,
  created_by uuid not null references auth.users,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default now() + interval '7 days',
  revoked_at timestamptz
);

-- ---------------------------------------------------------------------
-- Employee catalog: ONLY these columns exist on the server.
-- There is nowhere to store supplier names or supply prices.
-- ---------------------------------------------------------------------
create table catalog_items (
  store_id     uuid not null references stores on delete cascade,
  id           uuid not null,               -- same id as the product on the owner phone
  name         text not null,
  model        text,
  category     text,
  unit         text not null default 'pcs',
  photo_path   text,                        -- path in 'product-photos' bucket
  retail_price bigint,
  is_deleted   boolean not null default false,
  updated_at   timestamptz not null default now(),  -- SERVER clock, used as sync cursor
  primary key (store_id, id)
);
create index catalog_items_sync on catalog_items (store_id, updated_at);

-- ---------------------------------------------------------------------
-- Extraction queue. Images are deleted after processing; results are
-- deleted after the owner phone has fetched them (or after 14 days).
-- ---------------------------------------------------------------------
create table extraction_jobs (
  id          uuid primary key default gen_random_uuid(),
  store_id    uuid not null references stores on delete cascade,
  page_paths  text[] not null,              -- paths in 'po-images' bucket
  status      job_status not null default 'pending',
  attempts    int not null default 0,
  locked_by   text,
  locked_at   timestamptz,
  result      jsonb,                        -- extraction JSON (see build guide)
  last_error  text,
  created_at  timestamptz not null default now(),
  finished_at timestamptz,
  fetched_at  timestamptz                   -- set when the owner phone downloads the result
);
create index extraction_jobs_pending on extraction_jobs (created_at) where status = 'pending';

-- ---------------------------------------------------------------------
-- Access helpers
-- ---------------------------------------------------------------------
create or replace function is_owner(p_store uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from store_members
                  where store_id = p_store and user_id = auth.uid()
                    and role = 'owner' and revoked_at is null)
$$;

create or replace function is_member(p_store uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (select 1 from store_members
                  where store_id = p_store and user_id = auth.uid()
                    and revoked_at is null)
$$;

-- ---------------------------------------------------------------------
-- Row level security. Apps use the RPCs below; direct table access is
-- limited to what each role needs. The worker uses the service role.
-- ---------------------------------------------------------------------
alter table stores          enable row level security;
alter table store_members   enable row level security;
alter table invites         enable row level security;
alter table catalog_items   enable row level security;
alter table extraction_jobs enable row level security;

create policy member_read  on stores for select using (is_member(id));
create policy owner_update on stores for update using (is_owner(id));

create policy self_read    on store_members for select using (user_id = auth.uid());
create policy owner_read   on store_members for select using (is_owner(store_id));
create policy owner_update on store_members for update using (is_owner(store_id));

create policy owner_all on invites for all
  using (is_owner(store_id)) with check (is_owner(store_id));

create policy owner_read on extraction_jobs for select using (is_owner(store_id));
-- catalog_items: no direct policies; read via employee_catalog(), write via publish_catalog()

-- ---------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------

-- Owner signup: create store + owner membership. Returns store id
-- (save it in the owner phone's local settings table).
create or replace function create_store(p_name text)
returns uuid language plpgsql security definer set search_path = public as $$
declare sid uuid;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  insert into stores (name) values (p_name) returning id into sid;
  insert into store_members (store_id, user_id, role) values (sid, auth.uid(), 'owner');
  return sid;
end $$;

-- Owner: push changed products to the employee catalog.
-- p_items is a JSON array. ONLY the whitelisted fields below are read;
-- anything else in the payload (e.g. a supply price sent by mistake) is ignored.
-- Returns the number of items written.
create or replace function publish_catalog(p_store uuid, p_items jsonb)
returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if not is_owner(p_store) then raise exception 'not allowed'; end if;
  insert into catalog_items as c
         (store_id, id, name, model, category, unit, photo_path, retail_price, is_deleted, updated_at)
  select p_store,
         (i->>'id')::uuid,
         i->>'name',
         i->>'model',
         i->>'category',
         coalesce(i->>'unit', 'pcs'),
         i->>'photo_path',
         (i->>'retail_price')::bigint,
         coalesce((i->>'is_deleted')::boolean, false),
         now()
    from jsonb_array_elements(p_items) i
  on conflict (store_id, id) do update
     set name = excluded.name, model = excluded.model, category = excluded.category,
         unit = excluded.unit, photo_path = excluded.photo_path,
         retail_price = excluded.retail_price, is_deleted = excluded.is_deleted,
         updated_at = now();
  get diagnostics n = row_count;
  return n;
end $$;

-- Everyone in the store: read the catalog, incrementally with p_since.
-- Use the max updated_at you received as the next p_since.
create or replace function employee_catalog(p_store uuid, p_since timestamptz default null)
returns table (id uuid, name text, model text, category text, unit text,
               photo_path text, retail_price bigint, is_deleted boolean, updated_at timestamptz)
language plpgsql volatile security definer set search_path = public as $$
begin
  if not is_member(p_store) then raise exception 'not allowed'; end if;
  update store_members set last_seen_at = now()
   where store_id = p_store and user_id = auth.uid();
  return query
    select c.id, c.name, c.model, c.category, c.unit, c.photo_path, c.retail_price,
           c.is_deleted, c.updated_at
      from catalog_items c
     where c.store_id = p_store
       and (p_since is null or c.updated_at > p_since)
     order by c.updated_at;
end $$;

-- Owner: create a 7-day invite code.
create or replace function create_invite(p_store uuid)
returns text language plpgsql security definer set search_path = public as $$
declare c text;
begin
  if not is_owner(p_store) then raise exception 'not allowed'; end if;
  c := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  insert into invites (store_id, code, created_by) values (p_store, c, auth.uid());
  return c;
end $$;

-- Employee (signed in anonymously): join with an invite code.
create or replace function accept_invite(p_code text, p_name text, p_device text)
returns uuid language plpgsql security definer set search_path = public as $$
declare inv invites;
begin
  if auth.uid() is null then raise exception 'not signed in'; end if;
  select * into inv from invites
   where code = upper(p_code) and revoked_at is null and expires_at > now();
  if not found then raise exception 'invite invalid or expired'; end if;
  insert into store_members (store_id, user_id, role, display_name, device_label)
  values (inv.store_id, auth.uid(), 'employee', p_name, p_device)
  on conflict (store_id, user_id) do update
    set revoked_at = null, display_name = excluded.display_name,
        device_label = excluded.device_label, joined_at = now();
  return inv.store_id;
end $$;

-- Owner: queue uploaded PO pages for extraction. Upload images first.
create or replace function submit_extraction(p_store uuid, p_paths text[])
returns uuid language plpgsql security definer set search_path = public as $$
declare jid uuid;
begin
  if not is_owner(p_store) then raise exception 'not allowed'; end if;
  if coalesce(array_length(p_paths, 1), 0) = 0 then raise exception 'no pages'; end if;
  insert into extraction_jobs (store_id, page_paths) values (p_store, p_paths)
  returning id into jid;
  return jid;
end $$;

-- Owner: mark a result as downloaded so the server can delete it.
create or replace function mark_extraction_fetched(p_job uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  update extraction_jobs set fetched_at = now(), result = null
   where id = p_job and is_owner(store_id) and status in ('done', 'failed');
end $$;

-- ---------------------------------------------------------------------
-- Storage buckets (create in Supabase dashboard, both PRIVATE):
--   po-images       path: {store_id}/{job_or_po_id}/{page_no}.jpg   owner only; worker deletes after use
--   product-photos  path: {store_id}/{product_id}.jpg                members read, owner write
-- ---------------------------------------------------------------------
create policy po_images_owner on storage.objects for all
  using (bucket_id = 'po-images' and is_owner(((storage.foldername(name))[1])::uuid))
  with check (bucket_id = 'po-images' and is_owner(((storage.foldername(name))[1])::uuid));

create policy product_photos_read on storage.objects for select
  using (bucket_id = 'product-photos' and is_member(((storage.foldername(name))[1])::uuid));

create policy product_photos_write on storage.objects for insert
  with check (bucket_id = 'product-photos' and is_owner(((storage.foldername(name))[1])::uuid));

create policy product_photos_update on storage.objects for update
  using (bucket_id = 'product-photos' and is_owner(((storage.foldername(name))[1])::uuid));
