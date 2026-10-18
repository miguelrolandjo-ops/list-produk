import '../matching/normalize.dart';
import 'review_service.dart';

/// Below this, a field the model read is shown as "unclear" on Review.
const lowConfidence = 0.7;

/// How a line will be saved. A [suggestion] must be answered (✓ or ✗) before
/// saving; nothing is linked without the owner's say-so unless it was an exact
/// alias match ([auto]).
enum DraftKind { auto, suggestion, linked, isNew }

enum LineHint { none, priceMissing, priceUnclear, nameUnclear }

class DraftLine {
  const DraftLine({
    required this.poLineId,
    required this.rawName,
    required this.kind,
    required this.newName,
    this.productId,
    this.productName,
    this.qty,
    this.unit,
    this.unitPrice,
    this.nameConfidence = 0,
    this.unitPriceConfidence = 0,
    this.ignored = false,
    this.priceChecked = false,
    this.nameChecked = false,
  });

  final String poLineId;
  final String rawName;
  final DraftKind kind;

  /// Name used if this becomes a new product. Starts as the printed name.
  final String newName;
  final String? productId;
  final String? productName;
  final double? qty;
  final String? unit;
  final int? unitPrice;
  final double nameConfidence;
  final double unitPriceConfidence;
  final bool ignored;
  final bool priceChecked;
  final bool nameChecked;

  /// What to warn about, most important first. Editing the field clears it.
  LineHint get hint {
    if (ignored) return LineHint.none;
    if (unitPrice == null) return LineHint.priceMissing;
    if (!priceChecked && unitPriceConfidence < lowConfidence) {
      return LineHint.priceUnclear;
    }
    if (kind == DraftKind.isNew &&
        !nameChecked &&
        nameConfidence < lowConfidence) {
      return LineHint.nameUnclear;
    }
    return LineHint.none;
  }

  DraftLine copyWith({
    DraftKind? kind,
    String? newName,
    Object? productId = _keep,
    Object? productName = _keep,
    Object? unitPrice = _keep,
    bool? ignored,
    bool? priceChecked,
    bool? nameChecked,
  }) => DraftLine(
    poLineId: poLineId,
    rawName: rawName,
    kind: kind ?? this.kind,
    newName: newName ?? this.newName,
    productId: identical(productId, _keep)
        ? this.productId
        : productId as String?,
    productName: identical(productName, _keep)
        ? this.productName
        : productName as String?,
    qty: qty,
    unit: unit,
    unitPrice: identical(unitPrice, _keep)
        ? this.unitPrice
        : unitPrice as int?,
    nameConfidence: nameConfidence,
    unitPriceConfidence: unitPriceConfidence,
    ignored: ignored ?? this.ignored,
    priceChecked: priceChecked ?? this.priceChecked,
    nameChecked: nameChecked ?? this.nameChecked,
  );
}

const _keep = Object();

/// Everything the Review screen edits. Immutable: every change returns a new
/// draft, so the logic is testable without widgets.
class ReviewDraft {
  const ReviewDraft({
    required this.poId,
    required this.supplierName,
    required this.supplierMatched,
    required this.supplierConfidence,
    required this.knownSuppliers,
    required this.lines,
    this.poDate,
    String? originalSupplierName,
  }) : originalSupplierName = originalSupplierName ?? supplierName;

  final String poId;
  final String supplierName;
  final String originalSupplierName;

  /// The import linked this PO to an existing supplier.
  final bool supplierMatched;
  final double supplierConfidence;

  /// normalizeName of every supplier already in the catalog.
  final Set<String> knownSuppliers;
  final DateTime? poDate;
  final List<DraftLine> lines;

  bool get supplierIsKnown =>
      knownSuppliers.contains(normalizeName(supplierName));

  /// Show the match percentage only while the name is the one the PO printed
  /// and the import matched it.
  bool get showSupplierConfidence =>
      supplierMatched && supplierName == originalSupplierName;

  Iterable<DraftLine> get activeLines => lines.where((l) => !l.ignored);
  int get saveCount => activeLines.length;
  int get pendingSuggestions =>
      activeLines.where((l) => l.kind == DraftKind.suggestion).length;

  /// Why saving is not possible yet (Indonesian, shown under the button), or
  /// null when it is.
  String? get blocker {
    if (supplierName.trim().isEmpty) return 'Isi nama supplier';
    if (saveCount == 0) return 'Semua baris diabaikan';
    if (pendingSuggestions > 0) {
      return 'Jawab $pendingSuggestions saran produk dulu';
    }
    final noName = activeLines.where(
      (l) => l.kind == DraftKind.isNew && l.newName.trim().isEmpty,
    );
    if (noName.isNotEmpty) return 'Isi nama untuk produk baru';
    final noPrice = activeLines
        .where((l) => l.kind == DraftKind.isNew && l.unitPrice == null)
        .length;
    if (noPrice > 0) return 'Isi harga untuk $noPrice produk baru';
    return null;
  }

  bool get canSave => blocker == null;

  ReviewDraft setSupplierName(String name) => _copy(supplierName: name.trim());

  /// ✓ on a suggestion: link to the suggested product.
  ReviewDraft accept(int i) => _line(
    i,
    (l) => l.kind == DraftKind.suggestion && l.productId != null
        ? l.copyWith(kind: DraftKind.linked)
        : l,
  );

  /// ✗: not that product, so this line becomes a new product.
  ReviewDraft makeNew(int i) => _line(
    i,
    (l) => l.copyWith(
      kind: DraftKind.isNew,
      productId: null,
      productName: null,
    ),
  );

  ReviewDraft setPrice(int i, int? price) {
    if (price != null && price <= 0) {
      throw ArgumentError('Harga harus lebih dari 0');
    }
    return _line(i, (l) => l.copyWith(unitPrice: price, priceChecked: true));
  }

  ReviewDraft rename(int i, String name) =>
      _line(i, (l) => l.copyWith(newName: name.trim(), nameChecked: true));

  ReviewDraft toggleIgnore(int i) =>
      _line(i, (l) => l.copyWith(ignored: !l.ignored));

  /// Input for [ReviewService.save]. Throws [StateError] unless [canSave].
  ReviewedPo toReviewedPo() {
    final why = blocker;
    if (why != null) throw StateError(why);
    return ReviewedPo(
      poId: poId,
      supplierName: supplierName,
      poDate: poDate,
      lines: [
        for (final l in lines)
          if (l.ignored)
            ReviewedLine.ignore(poLineId: l.poLineId)
          else if (l.kind == DraftKind.isNew)
            ReviewedLine.createNew(
              poLineId: l.poLineId,
              rawName: l.rawName,
              newName: l.newName,
              newUnit: l.unit ?? 'pcs',
              unitPrice: l.unitPrice,
            )
          else
            ReviewedLine.link(
              poLineId: l.poLineId,
              rawName: l.rawName,
              productId: l.productId!,
              unitPrice: l.unitPrice,
            ),
      ],
    );
  }

  ReviewDraft _line(int i, DraftLine Function(DraftLine) f) {
    RangeError.checkValidIndex(i, lines);
    return _copy(lines: [...lines]..[i] = f(lines[i]));
  }

  ReviewDraft _copy({String? supplierName, List<DraftLine>? lines}) =>
      ReviewDraft(
        poId: poId,
        supplierName: supplierName ?? this.supplierName,
        originalSupplierName: originalSupplierName,
        supplierMatched: supplierMatched,
        supplierConfidence: supplierConfidence,
        knownSuppliers: knownSuppliers,
        poDate: poDate,
        lines: lines ?? this.lines,
      );
}
