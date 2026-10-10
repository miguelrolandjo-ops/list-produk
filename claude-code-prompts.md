# Panduan Claude Code: Setup dan Urutan Prompt

## 1. Setup (sekali saja)

1. **Install Git for Windows** (git-scm.com). Dengan ini Claude Code bisa memakai Bash;
   tanpa ini Claude Code memakai PowerShell.
2. **Install Claude Code.** Buka PowerShell, lalu jalankan:
   ```
   irm https://claude.ai/install.ps1 | iex
   ```
   Atau pakai aplikasi desktop Claude kalau tidak ingin memakai terminal.
3. **Login.** Jalankan `claude` di folder proyek; browser akan terbuka untuk login.
4. **Susun repo** seperti ini, lalu `git init` dan commit pertama:

```
store-price-guide/
├── CLAUDE.md                    ← file dari percakapan ini
├── .claude/settings.json        ← file dari percakapan ini
├── .gitignore                   (isi minimal: .env, .env.*, build/, .dart_tool/)
├── docs/
│   ├── spec.md                  ← Product Spec v2 (yang sudah disetujui)
│   ├── build-guide.md
│   ├── local_schema.sql
│   ├── server_schema.sql
│   └── mockups/                 ← screenshot atau unduhan mockup (2 set layar)
└── shared/
    └── pricing_vectors.json     (isi dari build guide bagian 6)
```

5. **Opsional tapi disarankan: dokumentasi terkini.** Paket Flutter sering berubah.
   Tambahkan server MCP Context7 supaya Claude Code bisa membaca dokumentasi terbaru:
   ```
   claude mcp add --transport http context7 https://mcp.context7.com/mcp
   ```
   Cek dokumentasi Claude Code tentang MCP kalau perintahnya sudah berubah.

## 2. Cara kerja yang disarankan

- **Satu prompt = satu langkah kecil.** Jangan minta satu milestone sekaligus.
- **Mulai di plan mode** (tekan Shift+Tab sampai muncul "plan mode"). Claude membaca kode
  dan membuat rencana tanpa mengubah file. Baca rencananya, koreksi kalau perlu, baru
  izinkan.
- **`/clear` di antara langkah besar.** Konteks jadi bersih; `CLAUDE.md` tetap terbaca
  otomatis.
- **Commit setiap langkah yang berhasil.** Kalau langkah berikutnya kacau, Anda bisa
  kembali.
- **Uji di HP sungguhan** setelah setiap langkah, bukan hanya di emulator.
- **Perbarui baris "Current milestone"** di `CLAUDE.md` saat pindah milestone.

---

## 3. Prompt per milestone

Prompt boleh ditulis dalam Bahasa Indonesia. Salin, lalu sesuaikan.

### Milestone 0: Kerangka proyek

**0.1 Scaffold**
```
Baca CLAUDE.md dan docs/build-guide.md. Buat kerangka proyek sesuai bagian 4:
- flutter create di folder app/ untuk android dan ios, org com.<nama-anda>
- tambahkan paket untuk Milestone 1 saja: drift, drift_flutter, uuid, flutter_riverpod,
  go_router, intl; dev: drift_dev, build_runner
- pecah docs/local_schema.sql menjadi app/lib/data/owner.drift (bagian OWNER PHONE)
  dan app/lib/data/employee.drift (bagian EMPLOYEE PHONE), masing-masing dengan class
  database sendiri. Untuk sekarang hanya database owner yang dipakai.
- buat folder fitur kosong sesuai struktur di build guide
Jangan tambah fitur apa pun. Selesai kalau flutter analyze bersih dan aplikasi kosong
berjalan di HP saya.
```

### Milestone 1: Katalog lokal (tanpa server)

**1.1 Rumus harga + data awal**
```
Implementasikan calcRetail di app/lib/pricing/ sesuai build guide bagian 6, beserta
unit test yang membaca shared/pricing_vectors.json dan memeriksa semua pasangan.
Lalu buat seeding saat aplikasi pertama kali dibuka: settings (id = 1), 18 anchor
default, dan 3 margin threshold default (0–65.000: 30%, 65.000–400.000: 15%,
di atas 400.000: 20%). Seeding hanya sekali, tidak menimpa data yang sudah ada.
```

**1.2 Tambah produk manual**
```
Buat layar "Tambah manual": nama, model, kategori (pilih atau buat baru), unit,
supplier (pilih atau buat baru), harga supplier.
- Saat mengetik harga supplier, tampilkan pratinjau harga jual dan margin.
- Simpan dalam satu transaksi: product, supplier_prices, lalu hitung retail_price
  memakai basis dari settings (highest/lowest/latest) lewat current_supplier_prices.
- Pemilik boleh mengubah harga jual (wajib kelipatan 5.000); kalau diubah,
  retail_is_override = 1.
Taruh logika simpan dan hitung ulang di service yang bisa dites tanpa UI, dan buat
testnya, termasuk kasus 2 supplier dengan harga berbeda.
```

**1.3 Daftar, detail, dan pencarian produk**
```
Buat daftar produk dengan pencarian (nama atau model, kata sebagian), dan layar
detail produk sesuai mockup layar 3 di docs/mockups: harga jual dengan margin,
daftar harga supplier terbaru per supplier, tombol riwayat harga dan ubah harga.
Tambahkan juga hapus produk (soft delete lewat deleted_at).
```
*Selesai kalau:* 10 produk asli yang Anda masukkan menunjukkan harga jual yang benar
dalam mode pesawat.

### Milestone 2: Pengaturan harga dan cadangan

**2.1 Layar aturan harga**
```
Buat menu Pengaturan sesuai mockup layar C, lalu layar Aturan harga sesuai mockup
layar 4: daftar anchor yang bisa ditambah/ubah/hapus dengan margin per baris,
validasi (kelipatan 5.000, harga jual naik seiring harga supplier), kotak
"Coba harga", dan pengaturan markup di atas anchor terakhir.
Setiap perubahan anchor menampilkan pratinjau "N produk akan berubah" (lama → baru)
sebelum diterapkan dalam satu transaksi. Produk override tidak ikut berubah.
```

**2.2 Batas margin dan ubah massal**
```
Tambahkan layar Batas margin (rentang + persen minimum) dan tanda peringatan di
daftar/detail produk jika margin di bawah batas rentangnya.
Lalu buat "Ubah massal per rentang": pilih rentang harga supplier, +/- persen atau
+/- Rupiah, dibulatkan ke atas ke 5.000, dengan pratinjau sebelum diterapkan.
Hasilnya disimpan sebagai override.
```

**2.3 Cadangan dan pemulihan**
```
Buat fitur cadangan sesuai build guide bagian 8 dan mockup layar D:
- "Cadangkan sekarang": salinan database dengan VACUUM INTO, dizip bersama foto
  produk (opsional lewat toggle), lalu dibuka lewat share sheet. Simpan
  last_backup_at.
- "Pulihkan dari file": pilih file, minta konfirmasi bahwa semua data di HP ini akan
  diganti, validasi bahwa file memang cadangan aplikasi ini, lalu ganti database.
- Banner pengingat jika cadangan terakhir lebih dari 7 hari (mockup layar B).
- Pastikan android:allowBackup aktif.
Jelaskan cara saya menguji pemulihan di emulator atau HP kedua.
```
*Selesai kalau:* semua test harga lolos, override bertahan setelah anchor diubah, dan
cadangan berhasil dipulihkan di perangkat lain.

### Milestone 3: Server dan karyawan

**3.1 Supabase dan akun pemilik**
```
Siapkan Supabase lokal: supabase init, salin docs/server_schema.sql menjadi
supabase/migrations/0001_init.sql, jalankan supabase db reset. Lalu tambahkan
supabase_flutter: daftar/masuk pemilik dengan email, panggil create_store sekali,
simpan store_id ke settings. URL dan anon key dibaca dari konfigurasi, bukan
ditulis langsung di kode. Jelaskan cara saya membuat project Supabase sungguhan nanti.
```

**3.2 Publikasi katalog**
```
Buat publish service sesuai build guide bagian 7: baca products_to_publish, unggah
foto produk baru ke product-photos, panggil publish_catalog per 200 item, lalu set
published_at ke updated_at yang dikirim. Jalankan otomatis setelah simpan dan saat
aplikasi kembali aktif; kalau offline, coba lagi nanti. Tampilkan penanda
"N belum terkirim" sesuai mockup layar B.
Buat test yang memastikan payload hanya berisi field yang diizinkan, dan produk yang
diubah selama proses kirim tetap tercatat belum terkirim.
```

**3.3 Undangan dan layar pembuka**
```
Buat layar pertama kali dibuka sesuai mockup layar A (buat toko, pulihkan, gabung
sebagai karyawan dengan kode). Lalu fitur undangan sesuai mockup layar 5 dan build
guide bagian 10: create_invite, kirim lewat share sheet, daftar karyawan, tombol
cabut. Tambahkan app_links untuk membuka /j/:code, dan buat file assetlinks.json
serta halaman landing statis sederhana di folder web-landing/.
Karyawan masuk dengan anonymous sign-in lalu accept_invite.
```

**3.4 Mode karyawan**
```
Buat mode karyawan sesuai mockup layar 6 memakai database employee.drift:
sinkron lewat employee_catalog dengan kursor updated_at dari server, hapus item
is_deleted, pencarian FTS5 (kata sebagian, misalnya "kab" menemukan "Kabel"),
filter kategori, status offline dan waktu pembaruan terakhir.
Kalau akses dicabut (panggilan ditolak), tampilkan pesan dan kembali ke layar pembuka.
Mode karyawan tidak boleh bisa membuka layar pemilik mana pun.
```
*Selesai kalau:* HP kedua bisa bergabung, mencari dalam mode pesawat, melihat perubahan
harga setelah refresh, dan kehilangan akses setelah dicabut.

### Milestone 4: Impor PO dengan data palsu

**4.1 Worker Go**
```
Buat worker Go di folder worker/ sesuai build guide bagian 9: interface Extractor,
FakeExtractor yang mengembalikan contoh JSON dari kontrak, loop job dengan
FOR UPDATE SKIP LOCKED memakai pgx, coba ulang maksimal 3 kali, hapus gambar setelah
selesai atau gagal, dan pembersihan harian. Konfigurasi lewat environment variable.
Buat test untuk loop job memakai database Supabase lokal.
```

**4.2 Unggah PO dan Inbox**
```
Buat Inbox sesuai mockup layar B: kamera dan galeri (beberapa foto = beberapa halaman),
kompres ke sisi panjang sekitar 1600px, simpan lokal, unggah ke po-images saat online,
submit_extraction, lalu polling status. Tambahkan receive_sharing_intent supaya
aplikasi muncul saat berbagi foto dari WhatsApp. Status: Antre, Mengunggah, Diproses,
Perlu dicek, Tersimpan, Gagal. Jelaskan cara menguji share dari WhatsApp di HP saya.
```

**4.3 Pencocokan dan layar Review**
```
Implementasikan pencocokan sesuai build guide bagian 9 (normalize, similarity, alias
persis = auto, mirip > 0.5 = suggested, lainnya = new) dengan unit test. Lalu buat
layar Review sesuai mockup layar 2: supplier terdeteksi, baris dengan nilai
kepercayaan rendah ditandai, tombol ✓/✗ untuk saran, edit nama/harga. "Simpan"
dalam satu transaksi: produk baru, alias yang dikonfirmasi, supplier_prices, hitung
ulang harga, lalu publish. Panggil mark_extraction_fetched setelah hasil tersimpan
di HP.
```
*Selesai kalau:* berbagi foto dari WhatsApp berakhir dengan produk tersimpan dan katalog
karyawan ikut diperbarui (dengan data palsu).

### Milestone 5: Pembacaan PO sungguhan

**5.1 Alat uji akurasi**
```
Buat perintah Go terpisah (worker/cmd/evaluate) yang menjalankan sebuah Extractor
pada folder foto PO dan membandingkan hasilnya dengan file jawaban yang saya isi
manual (format JSON sama dengan kontrak). Hasilkan ringkasan: supplier benar/salah,
jumlah baris terbaca, dan berapa harga yang salah, per foto dan total.
```

**5.2 Extractor sungguhan**
```
Implementasikan <OllamaExtractor / CloudExtractor> sesuai build guide bagian 9,
dengan prompt yang mengikuti aturan kontrak (harga bilangan bulat, titik sebagai
pemisah ribuan, null jika tidak terbaca). Kunci API dan alamat model dari environment
variable. Jalankan alat uji akurasi pada folder testdata/ dan tunjukkan hasilnya.
```

---

## 4. Prompt yang berguna kapan saja

**Saat ada bug**
```
Di HP saya: <apa yang saya lakukan>, <apa yang terjadi>, <apa yang seharusnya>.
Error lengkap:
<tempel error>
Cari penyebabnya dulu dan jelaskan sebelum mengubah kode.
```

**Saat bingung dengan kode**
```
Jelaskan bagaimana <fitur> bekerja dari tombol ditekan sampai data tersimpan.
Sebutkan file-file yang terlibat. Jangan ubah apa pun.
```

**Pemeriksaan keamanan sebelum rilis**
```
Periksa seluruh repo terhadap aturan arsitektur di CLAUDE.md:
- apakah ada service role key atau rahasia lain di app/ atau di git history
- apakah ada jalur kode yang mengirim data supplier ke server
- apakah mode karyawan bisa mengakses data atau layar pemilik
- apakah ada harga yang memakai double
Laporkan temuan dengan lokasi file; jangan ubah apa pun dulu.
```
