/// The extraction contract (docs/build-guide.md section 9), as the phone reads
/// it. Mirrors worker/extractor.Result; shared/extraction_sample.json is
/// parsed by tests on both sides.
///
/// Parsing is strict: a malformed result throws [FormatException] so the
/// caller can mark the PO as failed instead of storing half-understood data.
class ExtractionResult {
  const ExtractionResult({
    required this.supplier,
    required this.poDate,
    required this.lines,
  });

  factory ExtractionResult.fromJson(Object? json) {
    final m = _map(json, 'result');
    final lines = m['lines'];
    if (lines is! List) throw const FormatException('lines must be a list');
    return ExtractionResult(
      supplier: ExtractedSupplier._fromJson(_map(m['supplier'], 'supplier')),
      poDate: _date(m['po_date']),
      lines: [
        for (var i = 0; i < lines.length; i++)
          ExtractedLine._fromJson(_map(lines[i], 'lines[$i]'), i),
      ],
    );
  }

  final ExtractedSupplier supplier;
  final DateTime? poDate;
  final List<ExtractedLine> lines;
}

class ExtractedSupplier {
  const ExtractedSupplier({
    this.name,
    this.phone,
    this.address,
    this.confidence = 0,
  });

  factory ExtractedSupplier._fromJson(Map<String, Object?> m) =>
      ExtractedSupplier(
        name: _blankToNull(_string(m['name'], 'supplier.name')),
        phone: _blankToNull(_string(m['phone'], 'supplier.phone')),
        address: _blankToNull(_string(m['address'], 'supplier.address')),
        confidence: _confidence(m['confidence'], 'supplier.confidence'),
      );

  final String? name;
  final String? phone;
  final String? address;
  final double confidence;
}

class ExtractedLine {
  const ExtractedLine({
    required this.name,
    this.qty,
    this.unit,
    this.unitPrice,
    this.nameConfidence = 0,
    this.qtyConfidence = 0,
    this.unitPriceConfidence = 0,
  });

  factory ExtractedLine._fromJson(Map<String, Object?> m, int i) {
    final at = 'lines[$i]';
    final name = _string(m['name'], '$at.name')?.trim() ?? '';
    if (name.isEmpty) throw FormatException('$at.name is empty');
    final conf = m['confidence'] == null
        ? const <String, Object?>{}
        : _map(m['confidence'], '$at.confidence');
    return ExtractedLine(
      name: name,
      qty: _positiveNum(m['qty'], '$at.qty')?.toDouble(),
      unit: _blankToNull(_string(m['unit'], '$at.unit')),
      unitPrice: _price(m['unit_price'], '$at.unit_price'),
      nameConfidence: _confidence(conf['name'], '$at.confidence.name'),
      qtyConfidence: _confidence(conf['qty'], '$at.confidence.qty'),
      unitPriceConfidence: _confidence(
        conf['unit_price'],
        '$at.confidence.unit_price',
      ),
    );
  }

  final String name;
  final double? qty;
  final String? unit;

  /// Whole Rupiah, or null when the price could not be read.
  final int? unitPrice;
  final double nameConfidence;
  final double qtyConfidence;
  final double unitPriceConfidence;

  /// Stored in po_lines.confidence.
  Map<String, double> get confidenceJson => {
    'name': nameConfidence,
    'qty': qtyConfidence,
    'unit_price': unitPriceConfidence,
  };
}

Map<String, Object?> _map(Object? v, String at) {
  if (v is Map<String, Object?>) return v;
  if (v is Map) return v.cast<String, Object?>();
  throw FormatException('$at must be an object');
}

String? _string(Object? v, String at) {
  if (v == null) return null;
  if (v is String) return v;
  throw FormatException('$at must be a string or null');
}

String? _blankToNull(String? s) {
  final t = s?.trim();
  return t == null || t.isEmpty ? null : t;
}

num? _positiveNum(Object? v, String at) {
  if (v == null) return null;
  if (v is num && v > 0) return v;
  throw FormatException('$at must be a positive number or null');
}

/// Money is whole Rupiah. 9500 and 9500.0 are fine; 9500.5 is not.
int? _price(Object? v, String at) {
  final n = _positiveNum(v, at);
  if (n == null) return null;
  if (n != n.truncate()) throw FormatException('$at must be a whole number');
  return n.toInt();
}

double _confidence(Object? v, String at) {
  if (v == null) return 0;
  if (v is num && v >= 0 && v <= 1) return v.toDouble();
  throw FormatException('$at must be between 0 and 1');
}

DateTime? _date(Object? v) {
  if (v == null) return null;
  if (v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v)) {
    final d = DateTime.tryParse(v);
    if (d != null && d.toIso8601String().startsWith(v)) {
      return DateTime.utc(d.year, d.month, d.day);
    }
  }
  throw FormatException('po_date must be YYYY-MM-DD or null');
}
