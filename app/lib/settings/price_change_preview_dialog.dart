import 'package:flutter/material.dart';

import '../core/rupiah.dart';
import '../pricing/pricing_settings_service.dart';

/// "N produk akan berubah" with old -> new prices. Pops true when confirmed.
class PriceChangePreviewDialog extends StatelessWidget {
  const PriceChangePreviewDialog({super.key, required this.preview});
  final PricingPreview preview;

  @override
  Widget build(BuildContext context) {
    final n = preview.changes.length;
    return AlertDialog(
      title: Text(
        n == 0 ? 'Tidak ada produk berubah' : '$n produk akan berubah',
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (preview.overrideCount > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${preview.overrideCount} produk dengan harga manual '
                  'tidak ikut berubah.',
                ),
              ),
            if (n > 0)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in preview.changes)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(c.name),
                        subtitle: Text(
                          '${c.oldPrice == null ? '-' : formatRupiah(c.oldPrice!)}'
                          ' → ${formatRupiah(c.newPrice)}',
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Terapkan'),
        ),
      ],
    );
  }
}
