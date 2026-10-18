import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers.dart';
import '../core/thousands_formatter.dart';
import '../products/name_field.dart';
import 'review_draft.dart';

/// Review PO (mockup "2. Owner: Review PO"): check the supplier and each line,
/// answer the suggestions, then save everything in one go.
///
/// The edits live in this widget's state (they are throwaway form state, and
/// the logic is in the plain-Dart [ReviewDraft]); Riverpod provides the
/// services.
class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.poId, super.key});

  final String poId;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  ReviewDraft? _draft;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    ref
        .read(reviewDraftLoaderProvider)
        .load(widget.poId)
        .then((d) {
          if (mounted) setState(() => _draft = d);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e);
        });
  }

  void _leave() => context.canPop() ? context.pop() : context.go('/');

  void _edit(ReviewDraft Function(ReviewDraft) f) =>
      setState(() => _draft = f(_draft!));

  Future<void> _save() async {
    final draft = _draft!;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(reviewServiceProvider).save(draft.toReviewedPo());
      messenger.showSnackBar(
        SnackBar(content: Text('${draft.saveCount} produk tersimpan')),
      );
      if (mounted) _leave();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    return Scaffold(
      appBar: AppBar(title: const Text('Review PO')),
      body: draft == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : const Text('PO ini tidak bisa dibuka'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SupplierBox(
                  draft: draft,
                  onEdit: () async {
                    final name = await _askText(
                      context,
                      title: 'Nama supplier',
                      initial: draft.supplierName,
                    );
                    if (name != null) _edit((d) => d.setSupplierName(name));
                  },
                ),
                const SizedBox(height: 8),
                for (var i = 0; i < draft.lines.length; i++)
                  _LineRow(
                    line: draft.lines[i],
                    onAccept: () => _edit((d) => d.accept(i)),
                    onReject: () => _edit((d) => d.makeNew(i)),
                    onTap: () => _lineActions(i),
                  ),
              ],
            ),
      bottomNavigationBar: draft == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (draft.blocker != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          draft.blocker!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _saving ? null : _leave,
                            child: const Text('Lewati'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: draft.canSave && !_saving ? _save : null,
                            child: Text('Simpan ${draft.saveCount} produk'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _lineActions(int i) async {
    final line = _draft!.lines[i];
    final action = await showModalBottomSheet<_Action>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(line.rawName), subtitle: const Text('PO')),
            if (!line.ignored) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Ubah harga'),
                onTap: () => Navigator.pop(context, _Action.price),
              ),
              if (line.kind == DraftKind.isNew) ...[
                ListTile(
                  leading: const Icon(Icons.drive_file_rename_outline),
                  title: const Text('Ubah nama produk baru'),
                  onTap: () => Navigator.pop(context, _Action.rename),
                ),
                ListTile(
                  leading: const Icon(Icons.label_outline),
                  title: const Text('Ubah kategori'),
                  onTap: () => Navigator.pop(context, _Action.category),
                ),
              ] else
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: const Text('Bukan produk ini, buat produk baru'),
                  onTap: () => Navigator.pop(context, _Action.makeNew),
                ),
            ],
            ListTile(
              leading: Icon(
                line.ignored ? Icons.undo : Icons.visibility_off_outlined,
              ),
              title: Text(line.ignored ? 'Pakai baris ini lagi' : 'Abaikan baris'),
              onTap: () => Navigator.pop(context, _Action.toggleIgnore),
            ),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case _Action.price:
        final price = await _askPrice(context, line.unitPrice);
        if (price != null) _edit((d) => d.setPrice(i, price));
      case _Action.rename:
        final name = await _askText(
          context,
          title: 'Nama produk baru',
          initial: line.newName,
        );
        if (name != null) _edit((d) => d.rename(i, name));
      case _Action.category:
        final category = await _askCategory(
          context,
          options: _draft!.categoryOptions,
          initial: line.newCategory ?? '',
        );
        if (category != null) _edit((d) => d.setCategory(i, category));
      case _Action.makeNew:
        _edit((d) => d.makeNew(i));
      case _Action.toggleIgnore:
        _edit((d) => d.toggleIgnore(i));
    }
  }
}

enum _Action { price, rename, category, makeNew, toggleIgnore }

class _SupplierBox extends StatelessWidget {
  const _SupplierBox({required this.draft, required this.onEdit});

  final ReviewDraft draft;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final known = draft.supplierIsKnown;
    final pill = !known
        ? 'Baru'
        : draft.showSupplierConfidence
        ? 'Cocok ${(draft.supplierConfidence * 100).round()}%'
        : 'Cocok';
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Supplier terdeteksi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      draft.supplierName.isEmpty
                          ? 'Isi nama supplier'
                          : draft.supplierName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              Chip(
                label: Text(pill),
                visualDensity: VisualDensity.compact,
                backgroundColor: known
                    ? scheme.secondaryContainer
                    : scheme.tertiaryContainer,
              ),
              const Icon(Icons.edit_outlined, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.line,
    required this.onAccept,
    required this.onReject,
    required this.onTap,
  });

  final DraftLine line;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall;
    final hint = line.hint;
    final warn = hint != LineHint.none;
    final warnColor = scheme.onTertiaryContainer;

    final (IconData icon, String text) = switch (line.kind) {
      _ when line.ignored => (Icons.visibility_off_outlined, 'Diabaikan'),
      DraftKind.auto => (
        Icons.link,
        'Otomatis terhubung${_to(line.productName)}',
      ),
      DraftKind.suggestion => (
        Icons.help_outline,
        'Sama dengan "${line.productName ?? '?'}"?',
      ),
      DraftKind.linked => (Icons.link, 'Terhubung${_to(line.productName)}'),
      DraftKind.isNew => (
        Icons.auto_awesome,
        [
          line.newName == line.rawName
              ? 'Produk baru'
              : 'Produk baru: ${line.newName}',
          if (line.newCategory != null)
            line.categoryChecked
                ? line.newCategory!
                : '${line.newCategory} (saran)',
        ].join(' · '),
      ),
    };
    final caption = switch (hint) {
      LineHint.priceMissing => 'Harga tidak terbaca, isi harga',
      LineHint.priceFromCatalog => 'Harga tidak terbaca, pakai harga lama',
      LineHint.priceUnclear =>
        line.previousPrice == null
            ? 'Teks kurang jelas, cek harga'
            : 'Teks kurang jelas, cek harga '
                  '(sebelumnya ${groupThousands(line.previousPrice!)})',
      LineHint.nameUnclear => 'Teks kurang jelas, cek nama',
      LineHint.none => text,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: warn ? scheme.tertiaryContainer : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      line.rawName,
                      style: TextStyle(
                        color: warn ? warnColor : null,
                        decoration: line.ignored
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Row(
                      children: [
                        if (!warn) ...[
                          Icon(icon, size: 14, color: _captionColor(context)),
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            caption,
                            style: muted?.copyWith(
                              color: warn ? warnColor : _captionColor(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (line.kind == DraftKind.suggestion && !line.ignored) ...[
                IconButton.outlined(
                  tooltip: 'Ya',
                  icon: const Icon(Icons.check, size: 18),
                  onPressed: onAccept,
                ),
                const SizedBox(width: 4),
                IconButton.outlined(
                  tooltip: 'Tidak',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onReject,
                ),
              ] else
                Text(
                  line.unitPrice == null ? '-' : groupThousands(line.unitPrice!),
                  style: TextStyle(color: warn ? warnColor : null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _captionColor(BuildContext context) =>
      line.kind == DraftKind.suggestion && !line.ignored
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).textTheme.bodySmall?.color;

  static String _to(String? name) => name == null ? '' : ': $name';
}

Future<String?> _askText(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

Future<int?> _askPrice(BuildContext context, int? initial) {
  final controller = TextEditingController(
    text: initial == null ? '' : groupThousands(initial),
  );
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Harga supplier'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: const [ThousandsFormatter()],
        decoration: const InputDecoration(prefixText: 'Rp '),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            final price = parseGrouped(controller.text);
            if (price != null && price > 0) Navigator.pop(context, price);
          },
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}

/// Pick or type a category. Returns the name, an empty string for "no
/// category", or null if cancelled.
Future<String?> _askCategory(
  BuildContext context, {
  required List<String> options,
  required String initial,
}) {
  var name = initial;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Kategori produk baru'),
      content: NameField(
        label: 'Kategori',
        options: options,
        initialText: initial,
        onChanged: (v) => name = v,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ''),
          child: const Text('Tanpa kategori'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, name),
          child: const Text('Simpan'),
        ),
      ],
    ),
  );
}
