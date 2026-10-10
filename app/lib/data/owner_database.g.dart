// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'owner_database.dart';

// ignore_for_file: type=lint
class Settings extends Table with TableInfo<Settings, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY CHECK (id = 1)',
  );
  static const VerificationMeta _storeIdMeta = const VerificationMeta(
    'storeId',
  );
  late final GeneratedColumn<String> storeId = GeneratedColumn<String>(
    'store_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _minRetailMeta = const VerificationMeta(
    'minRetail',
  );
  late final GeneratedColumn<int> minRetail = GeneratedColumn<int>(
    'min_retail',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 5000',
    defaultValue: const CustomExpression('5000'),
  );
  static const VerificationMeta _roundToMeta = const VerificationMeta(
    'roundTo',
  );
  late final GeneratedColumn<int> roundTo = GeneratedColumn<int>(
    'round_to',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 5000 CHECK (round_to > 0)',
    defaultValue: const CustomExpression('5000'),
  );
  static const VerificationMeta _aboveMarkupPctMeta = const VerificationMeta(
    'aboveMarkupPct',
  );
  late final GeneratedColumn<double> aboveMarkupPct = GeneratedColumn<double>(
    'above_markup_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 30',
    defaultValue: const CustomExpression('30'),
  );
  static const VerificationMeta _basisMeta = const VerificationMeta('basis');
  late final GeneratedColumn<String> basis = GeneratedColumn<String>(
    'basis',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'highest\' CHECK (basis IN (\'highest\', \'lowest\', \'latest\'))',
    defaultValue: const CustomExpression('\'highest\''),
  );
  static const VerificationMeta _lastBackupAtMeta = const VerificationMeta(
    'lastBackupAt',
  );
  late final GeneratedColumn<String> lastBackupAt = GeneratedColumn<String>(
    'last_backup_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    storeId,
    minRetail,
    roundTo,
    aboveMarkupPct,
    basis,
    lastBackupAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('store_id')) {
      context.handle(
        _storeIdMeta,
        storeId.isAcceptableOrUnknown(data['store_id']!, _storeIdMeta),
      );
    }
    if (data.containsKey('min_retail')) {
      context.handle(
        _minRetailMeta,
        minRetail.isAcceptableOrUnknown(data['min_retail']!, _minRetailMeta),
      );
    }
    if (data.containsKey('round_to')) {
      context.handle(
        _roundToMeta,
        roundTo.isAcceptableOrUnknown(data['round_to']!, _roundToMeta),
      );
    }
    if (data.containsKey('above_markup_pct')) {
      context.handle(
        _aboveMarkupPctMeta,
        aboveMarkupPct.isAcceptableOrUnknown(
          data['above_markup_pct']!,
          _aboveMarkupPctMeta,
        ),
      );
    }
    if (data.containsKey('basis')) {
      context.handle(
        _basisMeta,
        basis.isAcceptableOrUnknown(data['basis']!, _basisMeta),
      );
    }
    if (data.containsKey('last_backup_at')) {
      context.handle(
        _lastBackupAtMeta,
        lastBackupAt.isAcceptableOrUnknown(
          data['last_backup_at']!,
          _lastBackupAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      storeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}store_id'],
      ),
      minRetail: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_retail'],
      )!,
      roundTo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}round_to'],
      )!,
      aboveMarkupPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}above_markup_pct'],
      )!,
      basis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}basis'],
      )!,
      lastBackupAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_backup_at'],
      ),
    );
  }

  @override
  Settings createAlias(String alias) {
    return Settings(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Setting extends DataClass implements Insertable<Setting> {
  final int id;
  final String? storeId;

  /// from server create_store()
  final int minRetail;
  final int roundTo;
  final double aboveMarkupPct;
  final String basis;
  final String? lastBackupAt;
  const Setting({
    required this.id,
    this.storeId,
    required this.minRetail,
    required this.roundTo,
    required this.aboveMarkupPct,
    required this.basis,
    this.lastBackupAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || storeId != null) {
      map['store_id'] = Variable<String>(storeId);
    }
    map['min_retail'] = Variable<int>(minRetail);
    map['round_to'] = Variable<int>(roundTo);
    map['above_markup_pct'] = Variable<double>(aboveMarkupPct);
    map['basis'] = Variable<String>(basis);
    if (!nullToAbsent || lastBackupAt != null) {
      map['last_backup_at'] = Variable<String>(lastBackupAt);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      storeId: storeId == null && nullToAbsent
          ? const Value.absent()
          : Value(storeId),
      minRetail: Value(minRetail),
      roundTo: Value(roundTo),
      aboveMarkupPct: Value(aboveMarkupPct),
      basis: Value(basis),
      lastBackupAt: lastBackupAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastBackupAt),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      storeId: serializer.fromJson<String?>(json['store_id']),
      minRetail: serializer.fromJson<int>(json['min_retail']),
      roundTo: serializer.fromJson<int>(json['round_to']),
      aboveMarkupPct: serializer.fromJson<double>(json['above_markup_pct']),
      basis: serializer.fromJson<String>(json['basis']),
      lastBackupAt: serializer.fromJson<String?>(json['last_backup_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'store_id': serializer.toJson<String?>(storeId),
      'min_retail': serializer.toJson<int>(minRetail),
      'round_to': serializer.toJson<int>(roundTo),
      'above_markup_pct': serializer.toJson<double>(aboveMarkupPct),
      'basis': serializer.toJson<String>(basis),
      'last_backup_at': serializer.toJson<String?>(lastBackupAt),
    };
  }

  Setting copyWith({
    int? id,
    Value<String?> storeId = const Value.absent(),
    int? minRetail,
    int? roundTo,
    double? aboveMarkupPct,
    String? basis,
    Value<String?> lastBackupAt = const Value.absent(),
  }) => Setting(
    id: id ?? this.id,
    storeId: storeId.present ? storeId.value : this.storeId,
    minRetail: minRetail ?? this.minRetail,
    roundTo: roundTo ?? this.roundTo,
    aboveMarkupPct: aboveMarkupPct ?? this.aboveMarkupPct,
    basis: basis ?? this.basis,
    lastBackupAt: lastBackupAt.present ? lastBackupAt.value : this.lastBackupAt,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      storeId: data.storeId.present ? data.storeId.value : this.storeId,
      minRetail: data.minRetail.present ? data.minRetail.value : this.minRetail,
      roundTo: data.roundTo.present ? data.roundTo.value : this.roundTo,
      aboveMarkupPct: data.aboveMarkupPct.present
          ? data.aboveMarkupPct.value
          : this.aboveMarkupPct,
      basis: data.basis.present ? data.basis.value : this.basis,
      lastBackupAt: data.lastBackupAt.present
          ? data.lastBackupAt.value
          : this.lastBackupAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('minRetail: $minRetail, ')
          ..write('roundTo: $roundTo, ')
          ..write('aboveMarkupPct: $aboveMarkupPct, ')
          ..write('basis: $basis, ')
          ..write('lastBackupAt: $lastBackupAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    storeId,
    minRetail,
    roundTo,
    aboveMarkupPct,
    basis,
    lastBackupAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.storeId == this.storeId &&
          other.minRetail == this.minRetail &&
          other.roundTo == this.roundTo &&
          other.aboveMarkupPct == this.aboveMarkupPct &&
          other.basis == this.basis &&
          other.lastBackupAt == this.lastBackupAt);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<String?> storeId;
  final Value<int> minRetail;
  final Value<int> roundTo;
  final Value<double> aboveMarkupPct;
  final Value<String> basis;
  final Value<String?> lastBackupAt;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.minRetail = const Value.absent(),
    this.roundTo = const Value.absent(),
    this.aboveMarkupPct = const Value.absent(),
    this.basis = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.storeId = const Value.absent(),
    this.minRetail = const Value.absent(),
    this.roundTo = const Value.absent(),
    this.aboveMarkupPct = const Value.absent(),
    this.basis = const Value.absent(),
    this.lastBackupAt = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<String>? storeId,
    Expression<int>? minRetail,
    Expression<int>? roundTo,
    Expression<double>? aboveMarkupPct,
    Expression<String>? basis,
    Expression<String>? lastBackupAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (storeId != null) 'store_id': storeId,
      if (minRetail != null) 'min_retail': minRetail,
      if (roundTo != null) 'round_to': roundTo,
      if (aboveMarkupPct != null) 'above_markup_pct': aboveMarkupPct,
      if (basis != null) 'basis': basis,
      if (lastBackupAt != null) 'last_backup_at': lastBackupAt,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<String?>? storeId,
    Value<int>? minRetail,
    Value<int>? roundTo,
    Value<double>? aboveMarkupPct,
    Value<String>? basis,
    Value<String?>? lastBackupAt,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      minRetail: minRetail ?? this.minRetail,
      roundTo: roundTo ?? this.roundTo,
      aboveMarkupPct: aboveMarkupPct ?? this.aboveMarkupPct,
      basis: basis ?? this.basis,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (storeId.present) {
      map['store_id'] = Variable<String>(storeId.value);
    }
    if (minRetail.present) {
      map['min_retail'] = Variable<int>(minRetail.value);
    }
    if (roundTo.present) {
      map['round_to'] = Variable<int>(roundTo.value);
    }
    if (aboveMarkupPct.present) {
      map['above_markup_pct'] = Variable<double>(aboveMarkupPct.value);
    }
    if (basis.present) {
      map['basis'] = Variable<String>(basis.value);
    }
    if (lastBackupAt.present) {
      map['last_backup_at'] = Variable<String>(lastBackupAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('storeId: $storeId, ')
          ..write('minRetail: $minRetail, ')
          ..write('roundTo: $roundTo, ')
          ..write('aboveMarkupPct: $aboveMarkupPct, ')
          ..write('basis: $basis, ')
          ..write('lastBackupAt: $lastBackupAt')
          ..write(')'))
        .toString();
  }
}

class PricingAnchors extends Table
    with TableInfo<PricingAnchors, PricingAnchor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PricingAnchors(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _supplyPriceMeta = const VerificationMeta(
    'supplyPrice',
  );
  late final GeneratedColumn<int> supplyPrice = GeneratedColumn<int>(
    'supply_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY CHECK (supply_price > 0)',
  );
  static const VerificationMeta _retailPriceMeta = const VerificationMeta(
    'retailPrice',
  );
  late final GeneratedColumn<int> retailPrice = GeneratedColumn<int>(
    'retail_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (retail_price > 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [supplyPrice, retailPrice];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pricing_anchors';
  @override
  VerificationContext validateIntegrity(
    Insertable<PricingAnchor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('supply_price')) {
      context.handle(
        _supplyPriceMeta,
        supplyPrice.isAcceptableOrUnknown(
          data['supply_price']!,
          _supplyPriceMeta,
        ),
      );
    }
    if (data.containsKey('retail_price')) {
      context.handle(
        _retailPriceMeta,
        retailPrice.isAcceptableOrUnknown(
          data['retail_price']!,
          _retailPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_retailPriceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {supplyPrice};
  @override
  PricingAnchor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PricingAnchor(
      supplyPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}supply_price'],
      )!,
      retailPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retail_price'],
      )!,
    );
  }

  @override
  PricingAnchors createAlias(String alias) {
    return PricingAnchors(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PricingAnchor extends DataClass implements Insertable<PricingAnchor> {
  final int supplyPrice;
  final int retailPrice;
  const PricingAnchor({required this.supplyPrice, required this.retailPrice});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['supply_price'] = Variable<int>(supplyPrice);
    map['retail_price'] = Variable<int>(retailPrice);
    return map;
  }

  PricingAnchorsCompanion toCompanion(bool nullToAbsent) {
    return PricingAnchorsCompanion(
      supplyPrice: Value(supplyPrice),
      retailPrice: Value(retailPrice),
    );
  }

  factory PricingAnchor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PricingAnchor(
      supplyPrice: serializer.fromJson<int>(json['supply_price']),
      retailPrice: serializer.fromJson<int>(json['retail_price']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'supply_price': serializer.toJson<int>(supplyPrice),
      'retail_price': serializer.toJson<int>(retailPrice),
    };
  }

  PricingAnchor copyWith({int? supplyPrice, int? retailPrice}) => PricingAnchor(
    supplyPrice: supplyPrice ?? this.supplyPrice,
    retailPrice: retailPrice ?? this.retailPrice,
  );
  PricingAnchor copyWithCompanion(PricingAnchorsCompanion data) {
    return PricingAnchor(
      supplyPrice: data.supplyPrice.present
          ? data.supplyPrice.value
          : this.supplyPrice,
      retailPrice: data.retailPrice.present
          ? data.retailPrice.value
          : this.retailPrice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PricingAnchor(')
          ..write('supplyPrice: $supplyPrice, ')
          ..write('retailPrice: $retailPrice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(supplyPrice, retailPrice);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PricingAnchor &&
          other.supplyPrice == this.supplyPrice &&
          other.retailPrice == this.retailPrice);
}

class PricingAnchorsCompanion extends UpdateCompanion<PricingAnchor> {
  final Value<int> supplyPrice;
  final Value<int> retailPrice;
  const PricingAnchorsCompanion({
    this.supplyPrice = const Value.absent(),
    this.retailPrice = const Value.absent(),
  });
  PricingAnchorsCompanion.insert({
    this.supplyPrice = const Value.absent(),
    required int retailPrice,
  }) : retailPrice = Value(retailPrice);
  static Insertable<PricingAnchor> custom({
    Expression<int>? supplyPrice,
    Expression<int>? retailPrice,
  }) {
    return RawValuesInsertable({
      if (supplyPrice != null) 'supply_price': supplyPrice,
      if (retailPrice != null) 'retail_price': retailPrice,
    });
  }

  PricingAnchorsCompanion copyWith({
    Value<int>? supplyPrice,
    Value<int>? retailPrice,
  }) {
    return PricingAnchorsCompanion(
      supplyPrice: supplyPrice ?? this.supplyPrice,
      retailPrice: retailPrice ?? this.retailPrice,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (supplyPrice.present) {
      map['supply_price'] = Variable<int>(supplyPrice.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<int>(retailPrice.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PricingAnchorsCompanion(')
          ..write('supplyPrice: $supplyPrice, ')
          ..write('retailPrice: $retailPrice')
          ..write(')'))
        .toString();
  }
}

class MarginThresholds extends Table
    with TableInfo<MarginThresholds, MarginThreshold> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MarginThresholds(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _minSupplyMeta = const VerificationMeta(
    'minSupply',
  );
  late final GeneratedColumn<int> minSupply = GeneratedColumn<int>(
    'min_supply',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _maxSupplyMeta = const VerificationMeta(
    'maxSupply',
  );
  late final GeneratedColumn<int> maxSupply = GeneratedColumn<int>(
    'max_supply',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _minMarginPctMeta = const VerificationMeta(
    'minMarginPct',
  );
  late final GeneratedColumn<double> minMarginPct = GeneratedColumn<double>(
    'min_margin_pct',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    minSupply,
    maxSupply,
    minMarginPct,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'margin_thresholds';
  @override
  VerificationContext validateIntegrity(
    Insertable<MarginThreshold> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('min_supply')) {
      context.handle(
        _minSupplyMeta,
        minSupply.isAcceptableOrUnknown(data['min_supply']!, _minSupplyMeta),
      );
    }
    if (data.containsKey('max_supply')) {
      context.handle(
        _maxSupplyMeta,
        maxSupply.isAcceptableOrUnknown(data['max_supply']!, _maxSupplyMeta),
      );
    }
    if (data.containsKey('min_margin_pct')) {
      context.handle(
        _minMarginPctMeta,
        minMarginPct.isAcceptableOrUnknown(
          data['min_margin_pct']!,
          _minMarginPctMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minMarginPctMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MarginThreshold map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MarginThreshold(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      minSupply: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}min_supply'],
      )!,
      maxSupply: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_supply'],
      ),
      minMarginPct: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}min_margin_pct'],
      )!,
    );
  }

  @override
  MarginThresholds createAlias(String alias) {
    return MarginThresholds(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MarginThreshold extends DataClass implements Insertable<MarginThreshold> {
  final int id;
  final int minSupply;
  final int? maxSupply;

  /// NULL = no upper limit
  final double minMarginPct;
  const MarginThreshold({
    required this.id,
    required this.minSupply,
    this.maxSupply,
    required this.minMarginPct,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['min_supply'] = Variable<int>(minSupply);
    if (!nullToAbsent || maxSupply != null) {
      map['max_supply'] = Variable<int>(maxSupply);
    }
    map['min_margin_pct'] = Variable<double>(minMarginPct);
    return map;
  }

  MarginThresholdsCompanion toCompanion(bool nullToAbsent) {
    return MarginThresholdsCompanion(
      id: Value(id),
      minSupply: Value(minSupply),
      maxSupply: maxSupply == null && nullToAbsent
          ? const Value.absent()
          : Value(maxSupply),
      minMarginPct: Value(minMarginPct),
    );
  }

  factory MarginThreshold.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MarginThreshold(
      id: serializer.fromJson<int>(json['id']),
      minSupply: serializer.fromJson<int>(json['min_supply']),
      maxSupply: serializer.fromJson<int?>(json['max_supply']),
      minMarginPct: serializer.fromJson<double>(json['min_margin_pct']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'min_supply': serializer.toJson<int>(minSupply),
      'max_supply': serializer.toJson<int?>(maxSupply),
      'min_margin_pct': serializer.toJson<double>(minMarginPct),
    };
  }

  MarginThreshold copyWith({
    int? id,
    int? minSupply,
    Value<int?> maxSupply = const Value.absent(),
    double? minMarginPct,
  }) => MarginThreshold(
    id: id ?? this.id,
    minSupply: minSupply ?? this.minSupply,
    maxSupply: maxSupply.present ? maxSupply.value : this.maxSupply,
    minMarginPct: minMarginPct ?? this.minMarginPct,
  );
  MarginThreshold copyWithCompanion(MarginThresholdsCompanion data) {
    return MarginThreshold(
      id: data.id.present ? data.id.value : this.id,
      minSupply: data.minSupply.present ? data.minSupply.value : this.minSupply,
      maxSupply: data.maxSupply.present ? data.maxSupply.value : this.maxSupply,
      minMarginPct: data.minMarginPct.present
          ? data.minMarginPct.value
          : this.minMarginPct,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MarginThreshold(')
          ..write('id: $id, ')
          ..write('minSupply: $minSupply, ')
          ..write('maxSupply: $maxSupply, ')
          ..write('minMarginPct: $minMarginPct')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, minSupply, maxSupply, minMarginPct);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MarginThreshold &&
          other.id == this.id &&
          other.minSupply == this.minSupply &&
          other.maxSupply == this.maxSupply &&
          other.minMarginPct == this.minMarginPct);
}

class MarginThresholdsCompanion extends UpdateCompanion<MarginThreshold> {
  final Value<int> id;
  final Value<int> minSupply;
  final Value<int?> maxSupply;
  final Value<double> minMarginPct;
  const MarginThresholdsCompanion({
    this.id = const Value.absent(),
    this.minSupply = const Value.absent(),
    this.maxSupply = const Value.absent(),
    this.minMarginPct = const Value.absent(),
  });
  MarginThresholdsCompanion.insert({
    this.id = const Value.absent(),
    this.minSupply = const Value.absent(),
    this.maxSupply = const Value.absent(),
    required double minMarginPct,
  }) : minMarginPct = Value(minMarginPct);
  static Insertable<MarginThreshold> custom({
    Expression<int>? id,
    Expression<int>? minSupply,
    Expression<int>? maxSupply,
    Expression<double>? minMarginPct,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (minSupply != null) 'min_supply': minSupply,
      if (maxSupply != null) 'max_supply': maxSupply,
      if (minMarginPct != null) 'min_margin_pct': minMarginPct,
    });
  }

  MarginThresholdsCompanion copyWith({
    Value<int>? id,
    Value<int>? minSupply,
    Value<int?>? maxSupply,
    Value<double>? minMarginPct,
  }) {
    return MarginThresholdsCompanion(
      id: id ?? this.id,
      minSupply: minSupply ?? this.minSupply,
      maxSupply: maxSupply ?? this.maxSupply,
      minMarginPct: minMarginPct ?? this.minMarginPct,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (minSupply.present) {
      map['min_supply'] = Variable<int>(minSupply.value);
    }
    if (maxSupply.present) {
      map['max_supply'] = Variable<int>(maxSupply.value);
    }
    if (minMarginPct.present) {
      map['min_margin_pct'] = Variable<double>(minMarginPct.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MarginThresholdsCompanion(')
          ..write('id: $id, ')
          ..write('minSupply: $minSupply, ')
          ..write('maxSupply: $maxSupply, ')
          ..write('minMarginPct: $minMarginPct')
          ..write(')'))
        .toString();
  }
}

class Categories extends Table with TableInfo<Categories, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Categories(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  @override
  List<GeneratedColumn> get $columns => [id, name];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
    );
  }

  @override
  Categories createAlias(String alias) {
    return Categories(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Category extends DataClass implements Insertable<Category> {
  final String? id;
  final String name;
  const Category({this.id, required this.name});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['name'] = Variable<String>(name);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String>(name),
    };
  }

  Category copyWith({Value<String?> id = const Value.absent(), String? name}) =>
      Category(id: id.present ? id.value : this.id, name: name ?? this.name);
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category && other.id == this.id && other.name == this.name);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String?> id;
  final Value<String> name;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String?>? id,
    Value<String>? name,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Suppliers extends Table with TableInfo<Suppliers, Supplier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Suppliers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, phone, address, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suppliers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Supplier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Supplier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Supplier(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  Suppliers createAlias(String alias) {
    return Suppliers(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Supplier extends DataClass implements Insertable<Supplier> {
  final String? id;
  final String name;
  final String? phone;
  final String? address;
  final String createdAt;
  const Supplier({
    this.id,
    required this.name,
    this.phone,
    this.address,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  SuppliersCompanion toCompanion(bool nullToAbsent) {
    return SuppliersCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      createdAt: Value(createdAt),
    );
  }

  factory Supplier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Supplier(
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phone: serializer.fromJson<String?>(json['phone']),
      address: serializer.fromJson<String?>(json['address']),
      createdAt: serializer.fromJson<String>(json['created_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String>(name),
      'phone': serializer.toJson<String?>(phone),
      'address': serializer.toJson<String?>(address),
      'created_at': serializer.toJson<String>(createdAt),
    };
  }

  Supplier copyWith({
    Value<String?> id = const Value.absent(),
    String? name,
    Value<String?> phone = const Value.absent(),
    Value<String?> address = const Value.absent(),
    String? createdAt,
  }) => Supplier(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    phone: phone.present ? phone.value : this.phone,
    address: address.present ? address.value : this.address,
    createdAt: createdAt ?? this.createdAt,
  );
  Supplier copyWithCompanion(SuppliersCompanion data) {
    return Supplier(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phone: data.phone.present ? data.phone.value : this.phone,
      address: data.address.present ? data.address.value : this.address,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Supplier(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, phone, address, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Supplier &&
          other.id == this.id &&
          other.name == this.name &&
          other.phone == this.phone &&
          other.address == this.address &&
          other.createdAt == this.createdAt);
}

class SuppliersCompanion extends UpdateCompanion<Supplier> {
  final Value<String?> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String?> address;
  final Value<String> createdAt;
  final Value<int> rowid;
  const SuppliersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuppliersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    this.address = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Supplier> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? phone,
    Expression<String>? address,
    Expression<String>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (address != null) 'address': address,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuppliersCompanion copyWith({
    Value<String?>? id,
    Value<String>? name,
    Value<String?>? phone,
    Value<String?>? address,
    Value<String>? createdAt,
    Value<int>? rowid,
  }) {
    return SuppliersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuppliersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phone: $phone, ')
          ..write('address: $address, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Products extends Table with TableInfo<Products, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Products(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES categories(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pcs\'',
    defaultValue: const CustomExpression('\'pcs\''),
  );
  static const VerificationMeta _photoLocalPathMeta = const VerificationMeta(
    'photoLocalPath',
  );
  late final GeneratedColumn<String> photoLocalPath = GeneratedColumn<String>(
    'photo_local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _photoRemotePathMeta = const VerificationMeta(
    'photoRemotePath',
  );
  late final GeneratedColumn<String> photoRemotePath = GeneratedColumn<String>(
    'photo_remote_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _retailPriceMeta = const VerificationMeta(
    'retailPrice',
  );
  late final GeneratedColumn<int> retailPrice = GeneratedColumn<int>(
    'retail_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _retailIsOverrideMeta = const VerificationMeta(
    'retailIsOverride',
  );
  late final GeneratedColumn<int> retailIsOverride = GeneratedColumn<int>(
    'retail_is_override',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (retail_is_override IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<String> deletedAt = GeneratedColumn<String>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _publishedAtMeta = const VerificationMeta(
    'publishedAt',
  );
  late final GeneratedColumn<String> publishedAt = GeneratedColumn<String>(
    'published_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    model,
    categoryId,
    unit,
    photoLocalPath,
    photoRemotePath,
    retailPrice,
    retailIsOverride,
    createdAt,
    updatedAt,
    deletedAt,
    publishedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('photo_local_path')) {
      context.handle(
        _photoLocalPathMeta,
        photoLocalPath.isAcceptableOrUnknown(
          data['photo_local_path']!,
          _photoLocalPathMeta,
        ),
      );
    }
    if (data.containsKey('photo_remote_path')) {
      context.handle(
        _photoRemotePathMeta,
        photoRemotePath.isAcceptableOrUnknown(
          data['photo_remote_path']!,
          _photoRemotePathMeta,
        ),
      );
    }
    if (data.containsKey('retail_price')) {
      context.handle(
        _retailPriceMeta,
        retailPrice.isAcceptableOrUnknown(
          data['retail_price']!,
          _retailPriceMeta,
        ),
      );
    }
    if (data.containsKey('retail_is_override')) {
      context.handle(
        _retailIsOverrideMeta,
        retailIsOverride.isAcceptableOrUnknown(
          data['retail_is_override']!,
          _retailIsOverrideMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('published_at')) {
      context.handle(
        _publishedAtMeta,
        publishedAt.isAcceptableOrUnknown(
          data['published_at']!,
          _publishedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      photoLocalPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_local_path'],
      ),
      photoRemotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_remote_path'],
      ),
      retailPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retail_price'],
      ),
      retailIsOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retail_is_override'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_at'],
      ),
      publishedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}published_at'],
      ),
    );
  }

  @override
  Products createAlias(String alias) {
    return Products(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Product extends DataClass implements Insertable<Product> {
  final String? id;
  final String name;
  final String? model;
  final String? categoryId;
  final String unit;
  final String? photoLocalPath;

  /// file on this phone
  final String? photoRemotePath;

  /// path in 'product-photos' after upload
  final int? retailPrice;
  final int retailIsOverride;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  /// soft delete, so employees learn about removals
  final String? publishedAt;
  const Product({
    this.id,
    required this.name,
    this.model,
    this.categoryId,
    required this.unit,
    this.photoLocalPath,
    this.photoRemotePath,
    this.retailPrice,
    required this.retailIsOverride,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.publishedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || photoLocalPath != null) {
      map['photo_local_path'] = Variable<String>(photoLocalPath);
    }
    if (!nullToAbsent || photoRemotePath != null) {
      map['photo_remote_path'] = Variable<String>(photoRemotePath);
    }
    if (!nullToAbsent || retailPrice != null) {
      map['retail_price'] = Variable<int>(retailPrice);
    }
    map['retail_is_override'] = Variable<int>(retailIsOverride);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<String>(deletedAt);
    }
    if (!nullToAbsent || publishedAt != null) {
      map['published_at'] = Variable<String>(publishedAt);
    }
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      unit: Value(unit),
      photoLocalPath: photoLocalPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoLocalPath),
      photoRemotePath: photoRemotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoRemotePath),
      retailPrice: retailPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(retailPrice),
      retailIsOverride: Value(retailIsOverride),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      publishedAt: publishedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(publishedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      model: serializer.fromJson<String?>(json['model']),
      categoryId: serializer.fromJson<String?>(json['category_id']),
      unit: serializer.fromJson<String>(json['unit']),
      photoLocalPath: serializer.fromJson<String?>(json['photo_local_path']),
      photoRemotePath: serializer.fromJson<String?>(json['photo_remote_path']),
      retailPrice: serializer.fromJson<int?>(json['retail_price']),
      retailIsOverride: serializer.fromJson<int>(json['retail_is_override']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
      deletedAt: serializer.fromJson<String?>(json['deleted_at']),
      publishedAt: serializer.fromJson<String?>(json['published_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String>(name),
      'model': serializer.toJson<String?>(model),
      'category_id': serializer.toJson<String?>(categoryId),
      'unit': serializer.toJson<String>(unit),
      'photo_local_path': serializer.toJson<String?>(photoLocalPath),
      'photo_remote_path': serializer.toJson<String?>(photoRemotePath),
      'retail_price': serializer.toJson<int?>(retailPrice),
      'retail_is_override': serializer.toJson<int>(retailIsOverride),
      'created_at': serializer.toJson<String>(createdAt),
      'updated_at': serializer.toJson<String>(updatedAt),
      'deleted_at': serializer.toJson<String?>(deletedAt),
      'published_at': serializer.toJson<String?>(publishedAt),
    };
  }

  Product copyWith({
    Value<String?> id = const Value.absent(),
    String? name,
    Value<String?> model = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    String? unit,
    Value<String?> photoLocalPath = const Value.absent(),
    Value<String?> photoRemotePath = const Value.absent(),
    Value<int?> retailPrice = const Value.absent(),
    int? retailIsOverride,
    String? createdAt,
    String? updatedAt,
    Value<String?> deletedAt = const Value.absent(),
    Value<String?> publishedAt = const Value.absent(),
  }) => Product(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    model: model.present ? model.value : this.model,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    unit: unit ?? this.unit,
    photoLocalPath: photoLocalPath.present
        ? photoLocalPath.value
        : this.photoLocalPath,
    photoRemotePath: photoRemotePath.present
        ? photoRemotePath.value
        : this.photoRemotePath,
    retailPrice: retailPrice.present ? retailPrice.value : this.retailPrice,
    retailIsOverride: retailIsOverride ?? this.retailIsOverride,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    publishedAt: publishedAt.present ? publishedAt.value : this.publishedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      model: data.model.present ? data.model.value : this.model,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      unit: data.unit.present ? data.unit.value : this.unit,
      photoLocalPath: data.photoLocalPath.present
          ? data.photoLocalPath.value
          : this.photoLocalPath,
      photoRemotePath: data.photoRemotePath.present
          ? data.photoRemotePath.value
          : this.photoRemotePath,
      retailPrice: data.retailPrice.present
          ? data.retailPrice.value
          : this.retailPrice,
      retailIsOverride: data.retailIsOverride.present
          ? data.retailIsOverride.value
          : this.retailIsOverride,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      publishedAt: data.publishedAt.present
          ? data.publishedAt.value
          : this.publishedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('categoryId: $categoryId, ')
          ..write('unit: $unit, ')
          ..write('photoLocalPath: $photoLocalPath, ')
          ..write('photoRemotePath: $photoRemotePath, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('retailIsOverride: $retailIsOverride, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('publishedAt: $publishedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    model,
    categoryId,
    unit,
    photoLocalPath,
    photoRemotePath,
    retailPrice,
    retailIsOverride,
    createdAt,
    updatedAt,
    deletedAt,
    publishedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.model == this.model &&
          other.categoryId == this.categoryId &&
          other.unit == this.unit &&
          other.photoLocalPath == this.photoLocalPath &&
          other.photoRemotePath == this.photoRemotePath &&
          other.retailPrice == this.retailPrice &&
          other.retailIsOverride == this.retailIsOverride &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.publishedAt == this.publishedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String?> id;
  final Value<String> name;
  final Value<String?> model;
  final Value<String?> categoryId;
  final Value<String> unit;
  final Value<String?> photoLocalPath;
  final Value<String?> photoRemotePath;
  final Value<int?> retailPrice;
  final Value<int> retailIsOverride;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<String?> deletedAt;
  final Value<String?> publishedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.model = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.unit = const Value.absent(),
    this.photoLocalPath = const Value.absent(),
    this.photoRemotePath = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.retailIsOverride = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.model = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.unit = const Value.absent(),
    this.photoLocalPath = const Value.absent(),
    this.photoRemotePath = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.retailIsOverride = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.publishedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? model,
    Expression<String>? categoryId,
    Expression<String>? unit,
    Expression<String>? photoLocalPath,
    Expression<String>? photoRemotePath,
    Expression<int>? retailPrice,
    Expression<int>? retailIsOverride,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<String>? deletedAt,
    Expression<String>? publishedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (model != null) 'model': model,
      if (categoryId != null) 'category_id': categoryId,
      if (unit != null) 'unit': unit,
      if (photoLocalPath != null) 'photo_local_path': photoLocalPath,
      if (photoRemotePath != null) 'photo_remote_path': photoRemotePath,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (retailIsOverride != null) 'retail_is_override': retailIsOverride,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (publishedAt != null) 'published_at': publishedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String?>? id,
    Value<String>? name,
    Value<String?>? model,
    Value<String?>? categoryId,
    Value<String>? unit,
    Value<String?>? photoLocalPath,
    Value<String?>? photoRemotePath,
    Value<int?>? retailPrice,
    Value<int>? retailIsOverride,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<String?>? deletedAt,
    Value<String?>? publishedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      categoryId: categoryId ?? this.categoryId,
      unit: unit ?? this.unit,
      photoLocalPath: photoLocalPath ?? this.photoLocalPath,
      photoRemotePath: photoRemotePath ?? this.photoRemotePath,
      retailPrice: retailPrice ?? this.retailPrice,
      retailIsOverride: retailIsOverride ?? this.retailIsOverride,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      publishedAt: publishedAt ?? this.publishedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (photoLocalPath.present) {
      map['photo_local_path'] = Variable<String>(photoLocalPath.value);
    }
    if (photoRemotePath.present) {
      map['photo_remote_path'] = Variable<String>(photoRemotePath.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<int>(retailPrice.value);
    }
    if (retailIsOverride.present) {
      map['retail_is_override'] = Variable<int>(retailIsOverride.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<String>(deletedAt.value);
    }
    if (publishedAt.present) {
      map['published_at'] = Variable<String>(publishedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('categoryId: $categoryId, ')
          ..write('unit: $unit, ')
          ..write('photoLocalPath: $photoLocalPath, ')
          ..write('photoRemotePath: $photoRemotePath, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('retailIsOverride: $retailIsOverride, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('publishedAt: $publishedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ProductAliases extends Table
    with TableInfo<ProductAliases, ProductAliase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ProductAliases(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES products(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES suppliers(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _aliasMeta = const VerificationMeta('alias');
  late final GeneratedColumn<String> alias = GeneratedColumn<String>(
    'alias',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _aliasNormMeta = const VerificationMeta(
    'aliasNorm',
  );
  late final GeneratedColumn<String> aliasNorm = GeneratedColumn<String>(
    'alias_norm',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    supplierId,
    alias,
    aliasNorm,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_aliases';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductAliase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_supplierIdMeta);
    }
    if (data.containsKey('alias')) {
      context.handle(
        _aliasMeta,
        alias.isAcceptableOrUnknown(data['alias']!, _aliasMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasMeta);
    }
    if (data.containsKey('alias_norm')) {
      context.handle(
        _aliasNormMeta,
        aliasNorm.isAcceptableOrUnknown(data['alias_norm']!, _aliasNormMeta),
      );
    } else if (isInserting) {
      context.missing(_aliasNormMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {supplierId, aliasNorm},
  ];
  @override
  ProductAliase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductAliase(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      )!,
      alias: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias'],
      )!,
      aliasNorm: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alias_norm'],
      )!,
    );
  }

  @override
  ProductAliases createAlias(String alias) {
    return ProductAliases(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(supplier_id, alias_norm)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ProductAliase extends DataClass implements Insertable<ProductAliase> {
  final String? id;
  final String productId;
  final String supplierId;
  final String alias;
  final String aliasNorm;
  const ProductAliase({
    this.id,
    required this.productId,
    required this.supplierId,
    required this.alias,
    required this.aliasNorm,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['product_id'] = Variable<String>(productId);
    map['supplier_id'] = Variable<String>(supplierId);
    map['alias'] = Variable<String>(alias);
    map['alias_norm'] = Variable<String>(aliasNorm);
    return map;
  }

  ProductAliasesCompanion toCompanion(bool nullToAbsent) {
    return ProductAliasesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      productId: Value(productId),
      supplierId: Value(supplierId),
      alias: Value(alias),
      aliasNorm: Value(aliasNorm),
    );
  }

  factory ProductAliase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductAliase(
      id: serializer.fromJson<String?>(json['id']),
      productId: serializer.fromJson<String>(json['product_id']),
      supplierId: serializer.fromJson<String>(json['supplier_id']),
      alias: serializer.fromJson<String>(json['alias']),
      aliasNorm: serializer.fromJson<String>(json['alias_norm']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'product_id': serializer.toJson<String>(productId),
      'supplier_id': serializer.toJson<String>(supplierId),
      'alias': serializer.toJson<String>(alias),
      'alias_norm': serializer.toJson<String>(aliasNorm),
    };
  }

  ProductAliase copyWith({
    Value<String?> id = const Value.absent(),
    String? productId,
    String? supplierId,
    String? alias,
    String? aliasNorm,
  }) => ProductAliase(
    id: id.present ? id.value : this.id,
    productId: productId ?? this.productId,
    supplierId: supplierId ?? this.supplierId,
    alias: alias ?? this.alias,
    aliasNorm: aliasNorm ?? this.aliasNorm,
  );
  ProductAliase copyWithCompanion(ProductAliasesCompanion data) {
    return ProductAliase(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      alias: data.alias.present ? data.alias.value : this.alias,
      aliasNorm: data.aliasNorm.present ? data.aliasNorm.value : this.aliasNorm,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductAliase(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('supplierId: $supplierId, ')
          ..write('alias: $alias, ')
          ..write('aliasNorm: $aliasNorm')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, productId, supplierId, alias, aliasNorm);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductAliase &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.supplierId == this.supplierId &&
          other.alias == this.alias &&
          other.aliasNorm == this.aliasNorm);
}

class ProductAliasesCompanion extends UpdateCompanion<ProductAliase> {
  final Value<String?> id;
  final Value<String> productId;
  final Value<String> supplierId;
  final Value<String> alias;
  final Value<String> aliasNorm;
  final Value<int> rowid;
  const ProductAliasesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.alias = const Value.absent(),
    this.aliasNorm = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductAliasesCompanion.insert({
    this.id = const Value.absent(),
    required String productId,
    required String supplierId,
    required String alias,
    required String aliasNorm,
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       supplierId = Value(supplierId),
       alias = Value(alias),
       aliasNorm = Value(aliasNorm);
  static Insertable<ProductAliase> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? supplierId,
    Expression<String>? alias,
    Expression<String>? aliasNorm,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (alias != null) 'alias': alias,
      if (aliasNorm != null) 'alias_norm': aliasNorm,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductAliasesCompanion copyWith({
    Value<String?>? id,
    Value<String>? productId,
    Value<String>? supplierId,
    Value<String>? alias,
    Value<String>? aliasNorm,
    Value<int>? rowid,
  }) {
    return ProductAliasesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      alias: alias ?? this.alias,
      aliasNorm: aliasNorm ?? this.aliasNorm,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (alias.present) {
      map['alias'] = Variable<String>(alias.value);
    }
    if (aliasNorm.present) {
      map['alias_norm'] = Variable<String>(aliasNorm.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductAliasesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('supplierId: $supplierId, ')
          ..write('alias: $alias, ')
          ..write('aliasNorm: $aliasNorm, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PurchaseOrders extends Table
    with TableInfo<PurchaseOrders, PurchaseOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PurchaseOrders(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES suppliers(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'queued\' CHECK (status IN (\'queued\', \'uploading\', \'processing\', \'needs_review\', \'saved\', \'failed\'))',
    defaultValue: const CustomExpression('\'queued\''),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (source IN (\'camera\', \'gallery\', \'share\', \'whatsapp\'))',
  );
  static const VerificationMeta _poDateMeta = const VerificationMeta('poDate');
  late final GeneratedColumn<String> poDate = GeneratedColumn<String>(
    'po_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _serverJobIdMeta = const VerificationMeta(
    'serverJobId',
  );
  late final GeneratedColumn<String> serverJobId = GeneratedColumn<String>(
    'server_job_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _rawResultMeta = const VerificationMeta(
    'rawResult',
  );
  late final GeneratedColumn<String> rawResult = GeneratedColumn<String>(
    'raw_result',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  late final GeneratedColumn<String> reviewedAt = GeneratedColumn<String>(
    'reviewed_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    supplierId,
    status,
    source,
    poDate,
    serverJobId,
    rawResult,
    createdAt,
    reviewedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'purchase_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<PurchaseOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('po_date')) {
      context.handle(
        _poDateMeta,
        poDate.isAcceptableOrUnknown(data['po_date']!, _poDateMeta),
      );
    }
    if (data.containsKey('server_job_id')) {
      context.handle(
        _serverJobIdMeta,
        serverJobId.isAcceptableOrUnknown(
          data['server_job_id']!,
          _serverJobIdMeta,
        ),
      );
    }
    if (data.containsKey('raw_result')) {
      context.handle(
        _rawResultMeta,
        rawResult.isAcceptableOrUnknown(data['raw_result']!, _rawResultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PurchaseOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PurchaseOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      poDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}po_date'],
      ),
      serverJobId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_job_id'],
      ),
      rawResult: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_result'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reviewed_at'],
      ),
    );
  }

  @override
  PurchaseOrders createAlias(String alias) {
    return PurchaseOrders(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PurchaseOrder extends DataClass implements Insertable<PurchaseOrder> {
  final String? id;
  final String? supplierId;
  final String status;
  final String source;
  final String? poDate;
  final String? serverJobId;

  /// extraction_jobs.id on the server
  final String? rawResult;

  /// extraction JSON, kept for debugging
  final String createdAt;
  final String? reviewedAt;
  const PurchaseOrder({
    this.id,
    this.supplierId,
    required this.status,
    required this.source,
    this.poDate,
    this.serverJobId,
    this.rawResult,
    required this.createdAt,
    this.reviewedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    if (!nullToAbsent || supplierId != null) {
      map['supplier_id'] = Variable<String>(supplierId);
    }
    map['status'] = Variable<String>(status);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || poDate != null) {
      map['po_date'] = Variable<String>(poDate);
    }
    if (!nullToAbsent || serverJobId != null) {
      map['server_job_id'] = Variable<String>(serverJobId);
    }
    if (!nullToAbsent || rawResult != null) {
      map['raw_result'] = Variable<String>(rawResult);
    }
    map['created_at'] = Variable<String>(createdAt);
    if (!nullToAbsent || reviewedAt != null) {
      map['reviewed_at'] = Variable<String>(reviewedAt);
    }
    return map;
  }

  PurchaseOrdersCompanion toCompanion(bool nullToAbsent) {
    return PurchaseOrdersCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      supplierId: supplierId == null && nullToAbsent
          ? const Value.absent()
          : Value(supplierId),
      status: Value(status),
      source: Value(source),
      poDate: poDate == null && nullToAbsent
          ? const Value.absent()
          : Value(poDate),
      serverJobId: serverJobId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverJobId),
      rawResult: rawResult == null && nullToAbsent
          ? const Value.absent()
          : Value(rawResult),
      createdAt: Value(createdAt),
      reviewedAt: reviewedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewedAt),
    );
  }

  factory PurchaseOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PurchaseOrder(
      id: serializer.fromJson<String?>(json['id']),
      supplierId: serializer.fromJson<String?>(json['supplier_id']),
      status: serializer.fromJson<String>(json['status']),
      source: serializer.fromJson<String>(json['source']),
      poDate: serializer.fromJson<String?>(json['po_date']),
      serverJobId: serializer.fromJson<String?>(json['server_job_id']),
      rawResult: serializer.fromJson<String?>(json['raw_result']),
      createdAt: serializer.fromJson<String>(json['created_at']),
      reviewedAt: serializer.fromJson<String?>(json['reviewed_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'supplier_id': serializer.toJson<String?>(supplierId),
      'status': serializer.toJson<String>(status),
      'source': serializer.toJson<String>(source),
      'po_date': serializer.toJson<String?>(poDate),
      'server_job_id': serializer.toJson<String?>(serverJobId),
      'raw_result': serializer.toJson<String?>(rawResult),
      'created_at': serializer.toJson<String>(createdAt),
      'reviewed_at': serializer.toJson<String?>(reviewedAt),
    };
  }

  PurchaseOrder copyWith({
    Value<String?> id = const Value.absent(),
    Value<String?> supplierId = const Value.absent(),
    String? status,
    String? source,
    Value<String?> poDate = const Value.absent(),
    Value<String?> serverJobId = const Value.absent(),
    Value<String?> rawResult = const Value.absent(),
    String? createdAt,
    Value<String?> reviewedAt = const Value.absent(),
  }) => PurchaseOrder(
    id: id.present ? id.value : this.id,
    supplierId: supplierId.present ? supplierId.value : this.supplierId,
    status: status ?? this.status,
    source: source ?? this.source,
    poDate: poDate.present ? poDate.value : this.poDate,
    serverJobId: serverJobId.present ? serverJobId.value : this.serverJobId,
    rawResult: rawResult.present ? rawResult.value : this.rawResult,
    createdAt: createdAt ?? this.createdAt,
    reviewedAt: reviewedAt.present ? reviewedAt.value : this.reviewedAt,
  );
  PurchaseOrder copyWithCompanion(PurchaseOrdersCompanion data) {
    return PurchaseOrder(
      id: data.id.present ? data.id.value : this.id,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      status: data.status.present ? data.status.value : this.status,
      source: data.source.present ? data.source.value : this.source,
      poDate: data.poDate.present ? data.poDate.value : this.poDate,
      serverJobId: data.serverJobId.present
          ? data.serverJobId.value
          : this.serverJobId,
      rawResult: data.rawResult.present ? data.rawResult.value : this.rawResult,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrder(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('poDate: $poDate, ')
          ..write('serverJobId: $serverJobId, ')
          ..write('rawResult: $rawResult, ')
          ..write('createdAt: $createdAt, ')
          ..write('reviewedAt: $reviewedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    supplierId,
    status,
    source,
    poDate,
    serverJobId,
    rawResult,
    createdAt,
    reviewedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PurchaseOrder &&
          other.id == this.id &&
          other.supplierId == this.supplierId &&
          other.status == this.status &&
          other.source == this.source &&
          other.poDate == this.poDate &&
          other.serverJobId == this.serverJobId &&
          other.rawResult == this.rawResult &&
          other.createdAt == this.createdAt &&
          other.reviewedAt == this.reviewedAt);
}

class PurchaseOrdersCompanion extends UpdateCompanion<PurchaseOrder> {
  final Value<String?> id;
  final Value<String?> supplierId;
  final Value<String> status;
  final Value<String> source;
  final Value<String?> poDate;
  final Value<String?> serverJobId;
  final Value<String?> rawResult;
  final Value<String> createdAt;
  final Value<String?> reviewedAt;
  final Value<int> rowid;
  const PurchaseOrdersCompanion({
    this.id = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.status = const Value.absent(),
    this.source = const Value.absent(),
    this.poDate = const Value.absent(),
    this.serverJobId = const Value.absent(),
    this.rawResult = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PurchaseOrdersCompanion.insert({
    this.id = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.status = const Value.absent(),
    required String source,
    this.poDate = const Value.absent(),
    this.serverJobId = const Value.absent(),
    this.rawResult = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : source = Value(source);
  static Insertable<PurchaseOrder> custom({
    Expression<String>? id,
    Expression<String>? supplierId,
    Expression<String>? status,
    Expression<String>? source,
    Expression<String>? poDate,
    Expression<String>? serverJobId,
    Expression<String>? rawResult,
    Expression<String>? createdAt,
    Expression<String>? reviewedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (supplierId != null) 'supplier_id': supplierId,
      if (status != null) 'status': status,
      if (source != null) 'source': source,
      if (poDate != null) 'po_date': poDate,
      if (serverJobId != null) 'server_job_id': serverJobId,
      if (rawResult != null) 'raw_result': rawResult,
      if (createdAt != null) 'created_at': createdAt,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PurchaseOrdersCompanion copyWith({
    Value<String?>? id,
    Value<String?>? supplierId,
    Value<String>? status,
    Value<String>? source,
    Value<String?>? poDate,
    Value<String?>? serverJobId,
    Value<String?>? rawResult,
    Value<String>? createdAt,
    Value<String?>? reviewedAt,
    Value<int>? rowid,
  }) {
    return PurchaseOrdersCompanion(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      status: status ?? this.status,
      source: source ?? this.source,
      poDate: poDate ?? this.poDate,
      serverJobId: serverJobId ?? this.serverJobId,
      rawResult: rawResult ?? this.rawResult,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (poDate.present) {
      map['po_date'] = Variable<String>(poDate.value);
    }
    if (serverJobId.present) {
      map['server_job_id'] = Variable<String>(serverJobId.value);
    }
    if (rawResult.present) {
      map['raw_result'] = Variable<String>(rawResult.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<String>(reviewedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PurchaseOrdersCompanion(')
          ..write('id: $id, ')
          ..write('supplierId: $supplierId, ')
          ..write('status: $status, ')
          ..write('source: $source, ')
          ..write('poDate: $poDate, ')
          ..write('serverJobId: $serverJobId, ')
          ..write('rawResult: $rawResult, ')
          ..write('createdAt: $createdAt, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PoLines extends Table with TableInfo<PoLines, PoLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PoLines(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _poIdMeta = const VerificationMeta('poId');
  late final GeneratedColumn<String> poId = GeneratedColumn<String>(
    'po_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES purchase_orders(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _lineNoMeta = const VerificationMeta('lineNo');
  late final GeneratedColumn<int> lineNo = GeneratedColumn<int>(
    'line_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _rawNameMeta = const VerificationMeta(
    'rawName',
  );
  late final GeneratedColumn<String> rawName = GeneratedColumn<String>(
    'raw_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _qtyMeta = const VerificationMeta('qty');
  late final GeneratedColumn<double> qty = GeneratedColumn<double>(
    'qty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  late final GeneratedColumn<String> confidence = GeneratedColumn<String>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _matchedProductIdMeta = const VerificationMeta(
    'matchedProductId',
  );
  late final GeneratedColumn<String> matchedProductId = GeneratedColumn<String>(
    'matched_product_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES products(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _matchStatusMeta = const VerificationMeta(
    'matchStatus',
  );
  late final GeneratedColumn<String> matchStatus = GeneratedColumn<String>(
    'match_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'new\' CHECK (match_status IN (\'auto\', \'suggested\', \'confirmed\', \'new\', \'ignored\'))',
    defaultValue: const CustomExpression('\'new\''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    poId,
    lineNo,
    rawName,
    qty,
    unit,
    unitPrice,
    confidence,
    matchedProductId,
    matchStatus,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'po_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<PoLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('po_id')) {
      context.handle(
        _poIdMeta,
        poId.isAcceptableOrUnknown(data['po_id']!, _poIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poIdMeta);
    }
    if (data.containsKey('line_no')) {
      context.handle(
        _lineNoMeta,
        lineNo.isAcceptableOrUnknown(data['line_no']!, _lineNoMeta),
      );
    } else if (isInserting) {
      context.missing(_lineNoMeta);
    }
    if (data.containsKey('raw_name')) {
      context.handle(
        _rawNameMeta,
        rawName.isAcceptableOrUnknown(data['raw_name']!, _rawNameMeta),
      );
    } else if (isInserting) {
      context.missing(_rawNameMeta);
    }
    if (data.containsKey('qty')) {
      context.handle(
        _qtyMeta,
        qty.isAcceptableOrUnknown(data['qty']!, _qtyMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('matched_product_id')) {
      context.handle(
        _matchedProductIdMeta,
        matchedProductId.isAcceptableOrUnknown(
          data['matched_product_id']!,
          _matchedProductIdMeta,
        ),
      );
    }
    if (data.containsKey('match_status')) {
      context.handle(
        _matchStatusMeta,
        matchStatus.isAcceptableOrUnknown(
          data['match_status']!,
          _matchStatusMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PoLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PoLine(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      poId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}po_id'],
      )!,
      lineNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}line_no'],
      )!,
      rawName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_name'],
      )!,
      qty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}qty'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      ),
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}confidence'],
      ),
      matchedProductId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}matched_product_id'],
      ),
      matchStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}match_status'],
      )!,
    );
  }

  @override
  PoLines createAlias(String alias) {
    return PoLines(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class PoLine extends DataClass implements Insertable<PoLine> {
  final String? id;
  final String poId;
  final int lineNo;
  final String rawName;
  final double? qty;
  final String? unit;
  final int? unitPrice;
  final String? confidence;

  /// JSON, e.g. {"unit_price":0.62}
  final String? matchedProductId;
  final String matchStatus;
  const PoLine({
    this.id,
    required this.poId,
    required this.lineNo,
    required this.rawName,
    this.qty,
    this.unit,
    this.unitPrice,
    this.confidence,
    this.matchedProductId,
    required this.matchStatus,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['po_id'] = Variable<String>(poId);
    map['line_no'] = Variable<int>(lineNo);
    map['raw_name'] = Variable<String>(rawName);
    if (!nullToAbsent || qty != null) {
      map['qty'] = Variable<double>(qty);
    }
    if (!nullToAbsent || unit != null) {
      map['unit'] = Variable<String>(unit);
    }
    if (!nullToAbsent || unitPrice != null) {
      map['unit_price'] = Variable<int>(unitPrice);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<String>(confidence);
    }
    if (!nullToAbsent || matchedProductId != null) {
      map['matched_product_id'] = Variable<String>(matchedProductId);
    }
    map['match_status'] = Variable<String>(matchStatus);
    return map;
  }

  PoLinesCompanion toCompanion(bool nullToAbsent) {
    return PoLinesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      poId: Value(poId),
      lineNo: Value(lineNo),
      rawName: Value(rawName),
      qty: qty == null && nullToAbsent ? const Value.absent() : Value(qty),
      unit: unit == null && nullToAbsent ? const Value.absent() : Value(unit),
      unitPrice: unitPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(unitPrice),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      matchedProductId: matchedProductId == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedProductId),
      matchStatus: Value(matchStatus),
    );
  }

  factory PoLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PoLine(
      id: serializer.fromJson<String?>(json['id']),
      poId: serializer.fromJson<String>(json['po_id']),
      lineNo: serializer.fromJson<int>(json['line_no']),
      rawName: serializer.fromJson<String>(json['raw_name']),
      qty: serializer.fromJson<double?>(json['qty']),
      unit: serializer.fromJson<String?>(json['unit']),
      unitPrice: serializer.fromJson<int?>(json['unit_price']),
      confidence: serializer.fromJson<String?>(json['confidence']),
      matchedProductId: serializer.fromJson<String?>(
        json['matched_product_id'],
      ),
      matchStatus: serializer.fromJson<String>(json['match_status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'po_id': serializer.toJson<String>(poId),
      'line_no': serializer.toJson<int>(lineNo),
      'raw_name': serializer.toJson<String>(rawName),
      'qty': serializer.toJson<double?>(qty),
      'unit': serializer.toJson<String?>(unit),
      'unit_price': serializer.toJson<int?>(unitPrice),
      'confidence': serializer.toJson<String?>(confidence),
      'matched_product_id': serializer.toJson<String?>(matchedProductId),
      'match_status': serializer.toJson<String>(matchStatus),
    };
  }

  PoLine copyWith({
    Value<String?> id = const Value.absent(),
    String? poId,
    int? lineNo,
    String? rawName,
    Value<double?> qty = const Value.absent(),
    Value<String?> unit = const Value.absent(),
    Value<int?> unitPrice = const Value.absent(),
    Value<String?> confidence = const Value.absent(),
    Value<String?> matchedProductId = const Value.absent(),
    String? matchStatus,
  }) => PoLine(
    id: id.present ? id.value : this.id,
    poId: poId ?? this.poId,
    lineNo: lineNo ?? this.lineNo,
    rawName: rawName ?? this.rawName,
    qty: qty.present ? qty.value : this.qty,
    unit: unit.present ? unit.value : this.unit,
    unitPrice: unitPrice.present ? unitPrice.value : this.unitPrice,
    confidence: confidence.present ? confidence.value : this.confidence,
    matchedProductId: matchedProductId.present
        ? matchedProductId.value
        : this.matchedProductId,
    matchStatus: matchStatus ?? this.matchStatus,
  );
  PoLine copyWithCompanion(PoLinesCompanion data) {
    return PoLine(
      id: data.id.present ? data.id.value : this.id,
      poId: data.poId.present ? data.poId.value : this.poId,
      lineNo: data.lineNo.present ? data.lineNo.value : this.lineNo,
      rawName: data.rawName.present ? data.rawName.value : this.rawName,
      qty: data.qty.present ? data.qty.value : this.qty,
      unit: data.unit.present ? data.unit.value : this.unit,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      matchedProductId: data.matchedProductId.present
          ? data.matchedProductId.value
          : this.matchedProductId,
      matchStatus: data.matchStatus.present
          ? data.matchStatus.value
          : this.matchStatus,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PoLine(')
          ..write('id: $id, ')
          ..write('poId: $poId, ')
          ..write('lineNo: $lineNo, ')
          ..write('rawName: $rawName, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('confidence: $confidence, ')
          ..write('matchedProductId: $matchedProductId, ')
          ..write('matchStatus: $matchStatus')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    poId,
    lineNo,
    rawName,
    qty,
    unit,
    unitPrice,
    confidence,
    matchedProductId,
    matchStatus,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PoLine &&
          other.id == this.id &&
          other.poId == this.poId &&
          other.lineNo == this.lineNo &&
          other.rawName == this.rawName &&
          other.qty == this.qty &&
          other.unit == this.unit &&
          other.unitPrice == this.unitPrice &&
          other.confidence == this.confidence &&
          other.matchedProductId == this.matchedProductId &&
          other.matchStatus == this.matchStatus);
}

class PoLinesCompanion extends UpdateCompanion<PoLine> {
  final Value<String?> id;
  final Value<String> poId;
  final Value<int> lineNo;
  final Value<String> rawName;
  final Value<double?> qty;
  final Value<String?> unit;
  final Value<int?> unitPrice;
  final Value<String?> confidence;
  final Value<String?> matchedProductId;
  final Value<String> matchStatus;
  final Value<int> rowid;
  const PoLinesCompanion({
    this.id = const Value.absent(),
    this.poId = const Value.absent(),
    this.lineNo = const Value.absent(),
    this.rawName = const Value.absent(),
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.confidence = const Value.absent(),
    this.matchedProductId = const Value.absent(),
    this.matchStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoLinesCompanion.insert({
    this.id = const Value.absent(),
    required String poId,
    required int lineNo,
    required String rawName,
    this.qty = const Value.absent(),
    this.unit = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.confidence = const Value.absent(),
    this.matchedProductId = const Value.absent(),
    this.matchStatus = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : poId = Value(poId),
       lineNo = Value(lineNo),
       rawName = Value(rawName);
  static Insertable<PoLine> custom({
    Expression<String>? id,
    Expression<String>? poId,
    Expression<int>? lineNo,
    Expression<String>? rawName,
    Expression<double>? qty,
    Expression<String>? unit,
    Expression<int>? unitPrice,
    Expression<String>? confidence,
    Expression<String>? matchedProductId,
    Expression<String>? matchStatus,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (poId != null) 'po_id': poId,
      if (lineNo != null) 'line_no': lineNo,
      if (rawName != null) 'raw_name': rawName,
      if (qty != null) 'qty': qty,
      if (unit != null) 'unit': unit,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (confidence != null) 'confidence': confidence,
      if (matchedProductId != null) 'matched_product_id': matchedProductId,
      if (matchStatus != null) 'match_status': matchStatus,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoLinesCompanion copyWith({
    Value<String?>? id,
    Value<String>? poId,
    Value<int>? lineNo,
    Value<String>? rawName,
    Value<double?>? qty,
    Value<String?>? unit,
    Value<int?>? unitPrice,
    Value<String?>? confidence,
    Value<String?>? matchedProductId,
    Value<String>? matchStatus,
    Value<int>? rowid,
  }) {
    return PoLinesCompanion(
      id: id ?? this.id,
      poId: poId ?? this.poId,
      lineNo: lineNo ?? this.lineNo,
      rawName: rawName ?? this.rawName,
      qty: qty ?? this.qty,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      confidence: confidence ?? this.confidence,
      matchedProductId: matchedProductId ?? this.matchedProductId,
      matchStatus: matchStatus ?? this.matchStatus,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (poId.present) {
      map['po_id'] = Variable<String>(poId.value);
    }
    if (lineNo.present) {
      map['line_no'] = Variable<int>(lineNo.value);
    }
    if (rawName.present) {
      map['raw_name'] = Variable<String>(rawName.value);
    }
    if (qty.present) {
      map['qty'] = Variable<double>(qty.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<String>(confidence.value);
    }
    if (matchedProductId.present) {
      map['matched_product_id'] = Variable<String>(matchedProductId.value);
    }
    if (matchStatus.present) {
      map['match_status'] = Variable<String>(matchStatus.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoLinesCompanion(')
          ..write('id: $id, ')
          ..write('poId: $poId, ')
          ..write('lineNo: $lineNo, ')
          ..write('rawName: $rawName, ')
          ..write('qty: $qty, ')
          ..write('unit: $unit, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('confidence: $confidence, ')
          ..write('matchedProductId: $matchedProductId, ')
          ..write('matchStatus: $matchStatus, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SupplierPrices extends Table
    with TableInfo<SupplierPrices, SupplierPrice> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SupplierPrices(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES products(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _supplierIdMeta = const VerificationMeta(
    'supplierId',
  );
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES suppliers(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (unit_price > 0)',
  );
  static const VerificationMeta _poLineIdMeta = const VerificationMeta(
    'poLineId',
  );
  late final GeneratedColumn<String> poLineId = GeneratedColumn<String>(
    'po_line_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES po_lines(id)ON DELETE SET NULL',
  );
  static const VerificationMeta _observedAtMeta = const VerificationMeta(
    'observedAt',
  );
  late final GeneratedColumn<String> observedAt = GeneratedColumn<String>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT (strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\'))',
    defaultValue: const CustomExpression(
      'strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\')',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    productId,
    supplierId,
    unitPrice,
    poLineId,
    observedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'supplier_prices';
  @override
  VerificationContext validateIntegrity(
    Insertable<SupplierPrice> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('supplier_id')) {
      context.handle(
        _supplierIdMeta,
        supplierId.isAcceptableOrUnknown(data['supplier_id']!, _supplierIdMeta),
      );
    } else if (isInserting) {
      context.missing(_supplierIdMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('po_line_id')) {
      context.handle(
        _poLineIdMeta,
        poLineId.isAcceptableOrUnknown(data['po_line_id']!, _poLineIdMeta),
      );
    }
    if (data.containsKey('observed_at')) {
      context.handle(
        _observedAtMeta,
        observedAt.isAcceptableOrUnknown(data['observed_at']!, _observedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SupplierPrice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SupplierPrice(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      )!,
      poLineId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}po_line_id'],
      ),
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_at'],
      )!,
    );
  }

  @override
  SupplierPrices createAlias(String alias) {
    return SupplierPrices(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SupplierPrice extends DataClass implements Insertable<SupplierPrice> {
  final String? id;
  final String productId;
  final String supplierId;
  final int unitPrice;
  final String? poLineId;
  final String observedAt;
  const SupplierPrice({
    this.id,
    required this.productId,
    required this.supplierId,
    required this.unitPrice,
    this.poLineId,
    required this.observedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['product_id'] = Variable<String>(productId);
    map['supplier_id'] = Variable<String>(supplierId);
    map['unit_price'] = Variable<int>(unitPrice);
    if (!nullToAbsent || poLineId != null) {
      map['po_line_id'] = Variable<String>(poLineId);
    }
    map['observed_at'] = Variable<String>(observedAt);
    return map;
  }

  SupplierPricesCompanion toCompanion(bool nullToAbsent) {
    return SupplierPricesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      productId: Value(productId),
      supplierId: Value(supplierId),
      unitPrice: Value(unitPrice),
      poLineId: poLineId == null && nullToAbsent
          ? const Value.absent()
          : Value(poLineId),
      observedAt: Value(observedAt),
    );
  }

  factory SupplierPrice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SupplierPrice(
      id: serializer.fromJson<String?>(json['id']),
      productId: serializer.fromJson<String>(json['product_id']),
      supplierId: serializer.fromJson<String>(json['supplier_id']),
      unitPrice: serializer.fromJson<int>(json['unit_price']),
      poLineId: serializer.fromJson<String?>(json['po_line_id']),
      observedAt: serializer.fromJson<String>(json['observed_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'product_id': serializer.toJson<String>(productId),
      'supplier_id': serializer.toJson<String>(supplierId),
      'unit_price': serializer.toJson<int>(unitPrice),
      'po_line_id': serializer.toJson<String?>(poLineId),
      'observed_at': serializer.toJson<String>(observedAt),
    };
  }

  SupplierPrice copyWith({
    Value<String?> id = const Value.absent(),
    String? productId,
    String? supplierId,
    int? unitPrice,
    Value<String?> poLineId = const Value.absent(),
    String? observedAt,
  }) => SupplierPrice(
    id: id.present ? id.value : this.id,
    productId: productId ?? this.productId,
    supplierId: supplierId ?? this.supplierId,
    unitPrice: unitPrice ?? this.unitPrice,
    poLineId: poLineId.present ? poLineId.value : this.poLineId,
    observedAt: observedAt ?? this.observedAt,
  );
  SupplierPrice copyWithCompanion(SupplierPricesCompanion data) {
    return SupplierPrice(
      id: data.id.present ? data.id.value : this.id,
      productId: data.productId.present ? data.productId.value : this.productId,
      supplierId: data.supplierId.present
          ? data.supplierId.value
          : this.supplierId,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      poLineId: data.poLineId.present ? data.poLineId.value : this.poLineId,
      observedAt: data.observedAt.present
          ? data.observedAt.value
          : this.observedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SupplierPrice(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('supplierId: $supplierId, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('poLineId: $poLineId, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, productId, supplierId, unitPrice, poLineId, observedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SupplierPrice &&
          other.id == this.id &&
          other.productId == this.productId &&
          other.supplierId == this.supplierId &&
          other.unitPrice == this.unitPrice &&
          other.poLineId == this.poLineId &&
          other.observedAt == this.observedAt);
}

class SupplierPricesCompanion extends UpdateCompanion<SupplierPrice> {
  final Value<String?> id;
  final Value<String> productId;
  final Value<String> supplierId;
  final Value<int> unitPrice;
  final Value<String?> poLineId;
  final Value<String> observedAt;
  final Value<int> rowid;
  const SupplierPricesCompanion({
    this.id = const Value.absent(),
    this.productId = const Value.absent(),
    this.supplierId = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.poLineId = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SupplierPricesCompanion.insert({
    this.id = const Value.absent(),
    required String productId,
    required String supplierId,
    required int unitPrice,
    this.poLineId = const Value.absent(),
    this.observedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : productId = Value(productId),
       supplierId = Value(supplierId),
       unitPrice = Value(unitPrice);
  static Insertable<SupplierPrice> custom({
    Expression<String>? id,
    Expression<String>? productId,
    Expression<String>? supplierId,
    Expression<int>? unitPrice,
    Expression<String>? poLineId,
    Expression<String>? observedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (supplierId != null) 'supplier_id': supplierId,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (poLineId != null) 'po_line_id': poLineId,
      if (observedAt != null) 'observed_at': observedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SupplierPricesCompanion copyWith({
    Value<String?>? id,
    Value<String>? productId,
    Value<String>? supplierId,
    Value<int>? unitPrice,
    Value<String?>? poLineId,
    Value<String>? observedAt,
    Value<int>? rowid,
  }) {
    return SupplierPricesCompanion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      supplierId: supplierId ?? this.supplierId,
      unitPrice: unitPrice ?? this.unitPrice,
      poLineId: poLineId ?? this.poLineId,
      observedAt: observedAt ?? this.observedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (supplierId.present) {
      map['supplier_id'] = Variable<String>(supplierId.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<int>(unitPrice.value);
    }
    if (poLineId.present) {
      map['po_line_id'] = Variable<String>(poLineId.value);
    }
    if (observedAt.present) {
      map['observed_at'] = Variable<String>(observedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SupplierPricesCompanion(')
          ..write('id: $id, ')
          ..write('productId: $productId, ')
          ..write('supplierId: $supplierId, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('poLineId: $poLineId, ')
          ..write('observedAt: $observedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class PoPages extends Table with TableInfo<PoPages, PoPage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PoPages(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _poIdMeta = const VerificationMeta('poId');
  late final GeneratedColumn<String> poId = GeneratedColumn<String>(
    'po_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES purchase_orders(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _pageNoMeta = const VerificationMeta('pageNo');
  late final GeneratedColumn<int> pageNo = GeneratedColumn<int>(
    'page_no',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [id, poId, pageNo, localPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'po_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<PoPage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('po_id')) {
      context.handle(
        _poIdMeta,
        poId.isAcceptableOrUnknown(data['po_id']!, _poIdMeta),
      );
    } else if (isInserting) {
      context.missing(_poIdMeta);
    }
    if (data.containsKey('page_no')) {
      context.handle(
        _pageNoMeta,
        pageNo.isAcceptableOrUnknown(data['page_no']!, _pageNoMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNoMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {poId, pageNo},
  ];
  @override
  PoPage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PoPage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      poId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}po_id'],
      )!,
      pageNo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_no'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
    );
  }

  @override
  PoPages createAlias(String alias) {
    return PoPages(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const ['UNIQUE(po_id, page_no)'];
  @override
  bool get dontWriteConstraints => true;
}

class PoPage extends DataClass implements Insertable<PoPage> {
  final String? id;
  final String poId;
  final int pageNo;
  final String localPath;
  const PoPage({
    this.id,
    required this.poId,
    required this.pageNo,
    required this.localPath,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['po_id'] = Variable<String>(poId);
    map['page_no'] = Variable<int>(pageNo);
    map['local_path'] = Variable<String>(localPath);
    return map;
  }

  PoPagesCompanion toCompanion(bool nullToAbsent) {
    return PoPagesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      poId: Value(poId),
      pageNo: Value(pageNo),
      localPath: Value(localPath),
    );
  }

  factory PoPage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PoPage(
      id: serializer.fromJson<String?>(json['id']),
      poId: serializer.fromJson<String>(json['po_id']),
      pageNo: serializer.fromJson<int>(json['page_no']),
      localPath: serializer.fromJson<String>(json['local_path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'po_id': serializer.toJson<String>(poId),
      'page_no': serializer.toJson<int>(pageNo),
      'local_path': serializer.toJson<String>(localPath),
    };
  }

  PoPage copyWith({
    Value<String?> id = const Value.absent(),
    String? poId,
    int? pageNo,
    String? localPath,
  }) => PoPage(
    id: id.present ? id.value : this.id,
    poId: poId ?? this.poId,
    pageNo: pageNo ?? this.pageNo,
    localPath: localPath ?? this.localPath,
  );
  PoPage copyWithCompanion(PoPagesCompanion data) {
    return PoPage(
      id: data.id.present ? data.id.value : this.id,
      poId: data.poId.present ? data.poId.value : this.poId,
      pageNo: data.pageNo.present ? data.pageNo.value : this.pageNo,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PoPage(')
          ..write('id: $id, ')
          ..write('poId: $poId, ')
          ..write('pageNo: $pageNo, ')
          ..write('localPath: $localPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, poId, pageNo, localPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PoPage &&
          other.id == this.id &&
          other.poId == this.poId &&
          other.pageNo == this.pageNo &&
          other.localPath == this.localPath);
}

class PoPagesCompanion extends UpdateCompanion<PoPage> {
  final Value<String?> id;
  final Value<String> poId;
  final Value<int> pageNo;
  final Value<String> localPath;
  final Value<int> rowid;
  const PoPagesCompanion({
    this.id = const Value.absent(),
    this.poId = const Value.absent(),
    this.pageNo = const Value.absent(),
    this.localPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PoPagesCompanion.insert({
    this.id = const Value.absent(),
    required String poId,
    required int pageNo,
    required String localPath,
    this.rowid = const Value.absent(),
  }) : poId = Value(poId),
       pageNo = Value(pageNo),
       localPath = Value(localPath);
  static Insertable<PoPage> custom({
    Expression<String>? id,
    Expression<String>? poId,
    Expression<int>? pageNo,
    Expression<String>? localPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (poId != null) 'po_id': poId,
      if (pageNo != null) 'page_no': pageNo,
      if (localPath != null) 'local_path': localPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PoPagesCompanion copyWith({
    Value<String?>? id,
    Value<String>? poId,
    Value<int>? pageNo,
    Value<String>? localPath,
    Value<int>? rowid,
  }) {
    return PoPagesCompanion(
      id: id ?? this.id,
      poId: poId ?? this.poId,
      pageNo: pageNo ?? this.pageNo,
      localPath: localPath ?? this.localPath,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (poId.present) {
      map['po_id'] = Variable<String>(poId.value);
    }
    if (pageNo.present) {
      map['page_no'] = Variable<int>(pageNo.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PoPagesCompanion(')
          ..write('id: $id, ')
          ..write('poId: $poId, ')
          ..write('pageNo: $pageNo, ')
          ..write('localPath: $localPath, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CurrentSupplierPrice extends DataClass {
  final String productId;
  final String supplierId;
  final int unitPrice;
  final String observedAt;
  const CurrentSupplierPrice({
    required this.productId,
    required this.supplierId,
    required this.unitPrice,
    required this.observedAt,
  });
  factory CurrentSupplierPrice.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrentSupplierPrice(
      productId: serializer.fromJson<String>(json['product_id']),
      supplierId: serializer.fromJson<String>(json['supplier_id']),
      unitPrice: serializer.fromJson<int>(json['unit_price']),
      observedAt: serializer.fromJson<String>(json['observed_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'product_id': serializer.toJson<String>(productId),
      'supplier_id': serializer.toJson<String>(supplierId),
      'unit_price': serializer.toJson<int>(unitPrice),
      'observed_at': serializer.toJson<String>(observedAt),
    };
  }

  CurrentSupplierPrice copyWith({
    String? productId,
    String? supplierId,
    int? unitPrice,
    String? observedAt,
  }) => CurrentSupplierPrice(
    productId: productId ?? this.productId,
    supplierId: supplierId ?? this.supplierId,
    unitPrice: unitPrice ?? this.unitPrice,
    observedAt: observedAt ?? this.observedAt,
  );
  @override
  String toString() {
    return (StringBuffer('CurrentSupplierPrice(')
          ..write('productId: $productId, ')
          ..write('supplierId: $supplierId, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('observedAt: $observedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(productId, supplierId, unitPrice, observedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrentSupplierPrice &&
          other.productId == this.productId &&
          other.supplierId == this.supplierId &&
          other.unitPrice == this.unitPrice &&
          other.observedAt == this.observedAt);
}

class CurrentSupplierPrices
    extends ViewInfo<CurrentSupplierPrices, CurrentSupplierPrice>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$OwnerDatabase attachedDatabase;
  CurrentSupplierPrices(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [
    productId,
    supplierId,
    unitPrice,
    observedAt,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'current_supplier_prices';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite: 'CREATE VIEW current_supplier_prices AS SELECT product_id, supplier_id, unit_price, observed_at FROM (SELECT product_id, supplier_id, unit_price, observed_at, ROW_NUMBER()OVER (PARTITION BY product_id, supplier_id ORDER BY observed_at DESC RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW EXCLUDE NO OTHERS) AS rn FROM supplier_prices) WHERE rn = 1',
  };
  @override
  CurrentSupplierPrices get asDslTable => this;
  @override
  CurrentSupplierPrice map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrentSupplierPrice(
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      supplierId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}supplier_id'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price'],
      )!,
      observedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observed_at'],
      )!,
    );
  }

  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> supplierId = GeneratedColumn<String>(
    'supplier_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> unitPrice = GeneratedColumn<int>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<String> observedAt = GeneratedColumn<String>(
    'observed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  @override
  CurrentSupplierPrices createAlias(String alias) {
    return CurrentSupplierPrices(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {
    'supplier_prices',
    'products',
    'suppliers',
    'po_lines',
    'purchase_orders',
    'categories',
  };
}

class ProductsToPublishData extends DataClass {
  final String? id;
  final String name;
  final String? model;
  final String? category;
  final String unit;
  final String? photoPath;
  final int? retailPrice;
  final bool isDeleted;
  const ProductsToPublishData({
    this.id,
    required this.name,
    this.model,
    this.category,
    required this.unit,
    this.photoPath,
    this.retailPrice,
    required this.isDeleted,
  });
  factory ProductsToPublishData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductsToPublishData(
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      model: serializer.fromJson<String?>(json['model']),
      category: serializer.fromJson<String?>(json['category']),
      unit: serializer.fromJson<String>(json['unit']),
      photoPath: serializer.fromJson<String?>(json['photo_path']),
      retailPrice: serializer.fromJson<int?>(json['retail_price']),
      isDeleted: serializer.fromJson<bool>(json['is_deleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String>(name),
      'model': serializer.toJson<String?>(model),
      'category': serializer.toJson<String?>(category),
      'unit': serializer.toJson<String>(unit),
      'photo_path': serializer.toJson<String?>(photoPath),
      'retail_price': serializer.toJson<int?>(retailPrice),
      'is_deleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ProductsToPublishData copyWith({
    Value<String?> id = const Value.absent(),
    String? name,
    Value<String?> model = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? unit,
    Value<String?> photoPath = const Value.absent(),
    Value<int?> retailPrice = const Value.absent(),
    bool? isDeleted,
  }) => ProductsToPublishData(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    model: model.present ? model.value : this.model,
    category: category.present ? category.value : this.category,
    unit: unit ?? this.unit,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    retailPrice: retailPrice.present ? retailPrice.value : this.retailPrice,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  @override
  String toString() {
    return (StringBuffer('ProductsToPublishData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('photoPath: $photoPath, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    model,
    category,
    unit,
    photoPath,
    retailPrice,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductsToPublishData &&
          other.id == this.id &&
          other.name == this.name &&
          other.model == this.model &&
          other.category == this.category &&
          other.unit == this.unit &&
          other.photoPath == this.photoPath &&
          other.retailPrice == this.retailPrice &&
          other.isDeleted == this.isDeleted);
}

class ProductsToPublish
    extends ViewInfo<ProductsToPublish, ProductsToPublishData>
    implements HasResultSet {
  final String? _alias;
  @override
  final _$OwnerDatabase attachedDatabase;
  ProductsToPublish(this.attachedDatabase, [this._alias]);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    model,
    category,
    unit,
    photoPath,
    retailPrice,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? entityName;
  @override
  String get entityName => 'products_to_publish';
  @override
  Map<SqlDialect, String> get createViewStatements => {
    SqlDialect.sqlite: 'CREATE VIEW products_to_publish AS SELECT p.id, p.name, p.model, c.name AS category, p.unit, p.photo_remote_path AS photo_path, p.retail_price,(p.deleted_at IS NOT NULL)AS is_deleted FROM products AS p LEFT JOIN categories AS c ON c.id = p.category_id WHERE p.published_at IS NULL OR p.updated_at > p.published_at',
  };
  @override
  ProductsToPublish get asDslTable => this;
  @override
  ProductsToPublishData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductsToPublishData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      photoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_path'],
      ),
      retailPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retail_price'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
  );
  late final GeneratedColumn<int> retailPrice = GeneratedColumn<int>(
    'retail_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
  );
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
  );
  @override
  ProductsToPublish createAlias(String alias) {
    return ProductsToPublish(attachedDatabase, alias);
  }

  @override
  Query? get query => null;
  @override
  Set<String> get readTables => const {'products', 'categories'};
}

abstract class _$OwnerDatabase extends GeneratedDatabase {
  _$OwnerDatabase(QueryExecutor e) : super(e);
  $OwnerDatabaseManager get managers => $OwnerDatabaseManager(this);
  late final Settings settings = Settings(this);
  late final PricingAnchors pricingAnchors = PricingAnchors(this);
  late final MarginThresholds marginThresholds = MarginThresholds(this);
  late final Categories categories = Categories(this);
  late final Suppliers suppliers = Suppliers(this);
  late final Products products = Products(this);
  late final Index productsName = Index(
    'products_name',
    'CREATE INDEX products_name ON products (name)',
  );
  late final ProductAliases productAliases = ProductAliases(this);
  late final PurchaseOrders purchaseOrders = PurchaseOrders(this);
  late final PoLines poLines = PoLines(this);
  late final SupplierPrices supplierPrices = SupplierPrices(this);
  late final Index supplierPricesLatest = Index(
    'supplier_prices_latest',
    'CREATE INDEX supplier_prices_latest ON supplier_prices (product_id, supplier_id, observed_at DESC)',
  );
  late final PoPages poPages = PoPages(this);
  late final CurrentSupplierPrices currentSupplierPrices =
      CurrentSupplierPrices(this);
  late final ProductsToPublish productsToPublish = ProductsToPublish(this);
  late final Trigger productsTouch = Trigger(
    'CREATE TRIGGER products_touch AFTER UPDATE OF name, model, category_id, unit, photo_remote_path, retail_price, deleted_at ON products BEGIN UPDATE products SET updated_at = strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\') WHERE id = NEW.id;END',
    'products_touch',
  );
  late final Trigger categoriesTouch = Trigger(
    'CREATE TRIGGER categories_touch AFTER UPDATE OF name ON categories BEGIN UPDATE products SET updated_at = strftime(\'%Y-%m-%dT%H:%M:%fZ\', \'now\') WHERE category_id = NEW.id;END',
    'categories_touch',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    settings,
    pricingAnchors,
    marginThresholds,
    categories,
    suppliers,
    products,
    productsName,
    productAliases,
    purchaseOrders,
    poLines,
    supplierPrices,
    supplierPricesLatest,
    poPages,
    currentSupplierPrices,
    productsToPublish,
    productsTouch,
    categoriesTouch,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('products', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_aliases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'suppliers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('product_aliases', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'suppliers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('purchase_orders', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'purchase_orders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('po_lines', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('po_lines', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('supplier_prices', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'suppliers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('supplier_prices', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'po_lines',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('supplier_prices', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'purchase_orders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('po_pages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'products',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('products', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'categories',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('products', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $SettingsCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> storeId,
  Value<int> minRetail,
  Value<int> roundTo,
  Value<double> aboveMarkupPct,
  Value<String> basis,
  Value<String?> lastBackupAt,
});
typedef $SettingsUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<String?> storeId,
  Value<int> minRetail,
  Value<int> roundTo,
  Value<double> aboveMarkupPct,
  Value<String> basis,
  Value<String?> lastBackupAt,
});

class $SettingsFilterComposer extends Composer<_$OwnerDatabase, Settings> {
  $SettingsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minRetail => $composableBuilder(
    column: $table.minRetail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get roundTo => $composableBuilder(
    column: $table.roundTo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get aboveMarkupPct => $composableBuilder(
    column: $table.aboveMarkupPct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SettingsOrderingComposer extends Composer<_$OwnerDatabase, Settings> {
  $SettingsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get storeId => $composableBuilder(
    column: $table.storeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minRetail => $composableBuilder(
    column: $table.minRetail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get roundTo => $composableBuilder(
    column: $table.roundTo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get aboveMarkupPct => $composableBuilder(
    column: $table.aboveMarkupPct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get basis => $composableBuilder(
    column: $table.basis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SettingsAnnotationComposer extends Composer<_$OwnerDatabase, Settings> {
  $SettingsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get storeId =>
      $composableBuilder(column: $table.storeId, builder: (column) => column);

  GeneratedColumn<int> get minRetail =>
      $composableBuilder(column: $table.minRetail, builder: (column) => column);

  GeneratedColumn<int> get roundTo =>
      $composableBuilder(column: $table.roundTo, builder: (column) => column);

  GeneratedColumn<double> get aboveMarkupPct => $composableBuilder(
    column: $table.aboveMarkupPct,
    builder: (column) => column,
  );

  GeneratedColumn<String> get basis =>
      $composableBuilder(column: $table.basis, builder: (column) => column);

  GeneratedColumn<String> get lastBackupAt => $composableBuilder(
    column: $table.lastBackupAt,
    builder: (column) => column,
  );
}

class $SettingsTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          Settings,
          Setting,
          $SettingsFilterComposer,
          $SettingsOrderingComposer,
          $SettingsAnnotationComposer,
          $SettingsCreateCompanionBuilder,
          $SettingsUpdateCompanionBuilder,
          (Setting, BaseReferences<_$OwnerDatabase, Settings, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $SettingsTableManager(_$OwnerDatabase db, Settings table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SettingsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SettingsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SettingsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<int> minRetail = const Value.absent(),
                Value<int> roundTo = const Value.absent(),
                Value<double> aboveMarkupPct = const Value.absent(),
                Value<String> basis = const Value.absent(),
                Value<String?> lastBackupAt = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                storeId: storeId,
                minRetail: minRetail,
                roundTo: roundTo,
                aboveMarkupPct: aboveMarkupPct,
                basis: basis,
                lastBackupAt: lastBackupAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> storeId = const Value.absent(),
                Value<int> minRetail = const Value.absent(),
                Value<int> roundTo = const Value.absent(),
                Value<double> aboveMarkupPct = const Value.absent(),
                Value<String> basis = const Value.absent(),
                Value<String?> lastBackupAt = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                storeId: storeId,
                minRetail: minRetail,
                roundTo: roundTo,
                aboveMarkupPct: aboveMarkupPct,
                basis: basis,
                lastBackupAt: lastBackupAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Settings, Setting>(table),
                  BaseReferences<_$OwnerDatabase, Settings, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SettingsProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      Settings,
      Setting,
      $SettingsFilterComposer,
      $SettingsOrderingComposer,
      $SettingsAnnotationComposer,
      $SettingsCreateCompanionBuilder,
      $SettingsUpdateCompanionBuilder,
      (Setting, BaseReferences<_$OwnerDatabase, Settings, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $PricingAnchorsCreateCompanionBuilder =
    PricingAnchorsCompanion Function({
      Value<int> supplyPrice,
      required int retailPrice,
    });
typedef $PricingAnchorsUpdateCompanionBuilder =
    PricingAnchorsCompanion Function({
      Value<int> supplyPrice,
      Value<int> retailPrice,
    });

class $PricingAnchorsFilterComposer
    extends Composer<_$OwnerDatabase, PricingAnchors> {
  $PricingAnchorsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get supplyPrice => $composableBuilder(
    column: $table.supplyPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnFilters(column),
  );
}

class $PricingAnchorsOrderingComposer
    extends Composer<_$OwnerDatabase, PricingAnchors> {
  $PricingAnchorsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get supplyPrice => $composableBuilder(
    column: $table.supplyPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $PricingAnchorsAnnotationComposer
    extends Composer<_$OwnerDatabase, PricingAnchors> {
  $PricingAnchorsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get supplyPrice => $composableBuilder(
    column: $table.supplyPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => column,
  );
}

class $PricingAnchorsTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          PricingAnchors,
          PricingAnchor,
          $PricingAnchorsFilterComposer,
          $PricingAnchorsOrderingComposer,
          $PricingAnchorsAnnotationComposer,
          $PricingAnchorsCreateCompanionBuilder,
          $PricingAnchorsUpdateCompanionBuilder,
          (
            PricingAnchor,
            BaseReferences<_$OwnerDatabase, PricingAnchors, PricingAnchor>,
          ),
          PricingAnchor,
          PrefetchHooks Function()
        > {
  $PricingAnchorsTableManager(_$OwnerDatabase db, PricingAnchors table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PricingAnchorsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PricingAnchorsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PricingAnchorsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> supplyPrice = const Value.absent(),
                Value<int> retailPrice = const Value.absent(),
              }) => PricingAnchorsCompanion(
                supplyPrice: supplyPrice,
                retailPrice: retailPrice,
              ),
          createCompanionCallback:
              ({
                Value<int> supplyPrice = const Value.absent(),
                required int retailPrice,
              }) => PricingAnchorsCompanion.insert(
                supplyPrice: supplyPrice,
                retailPrice: retailPrice,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PricingAnchors, PricingAnchor>(table),
                  BaseReferences<
                    _$OwnerDatabase,
                    PricingAnchors,
                    PricingAnchor
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $PricingAnchorsProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      PricingAnchors,
      PricingAnchor,
      $PricingAnchorsFilterComposer,
      $PricingAnchorsOrderingComposer,
      $PricingAnchorsAnnotationComposer,
      $PricingAnchorsCreateCompanionBuilder,
      $PricingAnchorsUpdateCompanionBuilder,
      (
        PricingAnchor,
        BaseReferences<_$OwnerDatabase, PricingAnchors, PricingAnchor>,
      ),
      PricingAnchor,
      PrefetchHooks Function()
    >;
typedef $MarginThresholdsCreateCompanionBuilder =
    MarginThresholdsCompanion Function({
      Value<int> id,
      Value<int> minSupply,
      Value<int?> maxSupply,
      required double minMarginPct,
    });
typedef $MarginThresholdsUpdateCompanionBuilder =
    MarginThresholdsCompanion Function({
      Value<int> id,
      Value<int> minSupply,
      Value<int?> maxSupply,
      Value<double> minMarginPct,
    });

class $MarginThresholdsFilterComposer
    extends Composer<_$OwnerDatabase, MarginThresholds> {
  $MarginThresholdsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minSupply => $composableBuilder(
    column: $table.minSupply,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxSupply => $composableBuilder(
    column: $table.maxSupply,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get minMarginPct => $composableBuilder(
    column: $table.minMarginPct,
    builder: (column) => ColumnFilters(column),
  );
}

class $MarginThresholdsOrderingComposer
    extends Composer<_$OwnerDatabase, MarginThresholds> {
  $MarginThresholdsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minSupply => $composableBuilder(
    column: $table.minSupply,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxSupply => $composableBuilder(
    column: $table.maxSupply,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get minMarginPct => $composableBuilder(
    column: $table.minMarginPct,
    builder: (column) => ColumnOrderings(column),
  );
}

class $MarginThresholdsAnnotationComposer
    extends Composer<_$OwnerDatabase, MarginThresholds> {
  $MarginThresholdsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get minSupply =>
      $composableBuilder(column: $table.minSupply, builder: (column) => column);

  GeneratedColumn<int> get maxSupply =>
      $composableBuilder(column: $table.maxSupply, builder: (column) => column);

  GeneratedColumn<double> get minMarginPct => $composableBuilder(
    column: $table.minMarginPct,
    builder: (column) => column,
  );
}

class $MarginThresholdsTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          MarginThresholds,
          MarginThreshold,
          $MarginThresholdsFilterComposer,
          $MarginThresholdsOrderingComposer,
          $MarginThresholdsAnnotationComposer,
          $MarginThresholdsCreateCompanionBuilder,
          $MarginThresholdsUpdateCompanionBuilder,
          (
            MarginThreshold,
            BaseReferences<_$OwnerDatabase, MarginThresholds, MarginThreshold>,
          ),
          MarginThreshold,
          PrefetchHooks Function()
        > {
  $MarginThresholdsTableManager(_$OwnerDatabase db, MarginThresholds table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $MarginThresholdsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $MarginThresholdsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $MarginThresholdsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> minSupply = const Value.absent(),
                Value<int?> maxSupply = const Value.absent(),
                Value<double> minMarginPct = const Value.absent(),
              }) => MarginThresholdsCompanion(
                id: id,
                minSupply: minSupply,
                maxSupply: maxSupply,
                minMarginPct: minMarginPct,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> minSupply = const Value.absent(),
                Value<int?> maxSupply = const Value.absent(),
                required double minMarginPct,
              }) => MarginThresholdsCompanion.insert(
                id: id,
                minSupply: minSupply,
                maxSupply: maxSupply,
                minMarginPct: minMarginPct,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<MarginThresholds, MarginThreshold>(table),
                  BaseReferences<
                    _$OwnerDatabase,
                    MarginThresholds,
                    MarginThreshold
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $MarginThresholdsProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      MarginThresholds,
      MarginThreshold,
      $MarginThresholdsFilterComposer,
      $MarginThresholdsOrderingComposer,
      $MarginThresholdsAnnotationComposer,
      $MarginThresholdsCreateCompanionBuilder,
      $MarginThresholdsUpdateCompanionBuilder,
      (
        MarginThreshold,
        BaseReferences<_$OwnerDatabase, MarginThresholds, MarginThreshold>,
      ),
      MarginThreshold,
      PrefetchHooks Function()
    >;
typedef $CategoriesCreateCompanionBuilder = CategoriesCompanion Function({
  Value<String?> id,
  required String name,
  Value<int> rowid,
});
typedef $CategoriesUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String?> id,
  Value<String> name,
  Value<int> rowid,
});

final class $CategoriesReferences
    extends BaseReferences<_$OwnerDatabase, Categories, Category> {
  $CategoriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Products, List<Product>> _productsRefsTable(
    _$OwnerDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.products,
    aliasName: 'categories__id__products__category_id',
  );

  $ProductsProcessedTableManager get productsRefs {
    final manager = $ProductsTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_productsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CategoriesFilterComposer extends Composer<_$OwnerDatabase, Categories> {
  $CategoriesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productsRefs(
    Expression<bool> Function($ProductsFilterComposer f) f,
  ) {
    final $ProductsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CategoriesOrderingComposer
    extends Composer<_$OwnerDatabase, Categories> {
  $CategoriesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CategoriesAnnotationComposer
    extends Composer<_$OwnerDatabase, Categories> {
  $CategoriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  Expression<T> productsRefs<T extends Object>(
    Expression<T> Function($ProductsAnnotationComposer a) f,
  ) {
    final $ProductsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CategoriesTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          Categories,
          Category,
          $CategoriesFilterComposer,
          $CategoriesOrderingComposer,
          $CategoriesAnnotationComposer,
          $CategoriesCreateCompanionBuilder,
          $CategoriesUpdateCompanionBuilder,
          (Category, $CategoriesReferences),
          Category,
          PrefetchHooks Function({bool productsRefs})
        > {
  $CategoriesTableManager(_$OwnerDatabase db, Categories table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CategoriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CategoriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CategoriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String?> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CategoriesCompanion(id: id, name: name, rowid: rowid),
          createCompanionCallback: ({
            Value<String?> id = const Value.absent(),
            required String name,
            Value<int> rowid = const Value.absent(),
          }) => CategoriesCompanion.insert(id: id, name: name, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Categories, Category>(table),
                  $CategoriesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (productsRefs) db.products],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (productsRefs)
                    await $_getPrefetchedData<Category, Categories, Product>(
                      currentTable: table,
                      referencedTable: $CategoriesReferences._productsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $CategoriesReferences(db, table, p0).productsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $CategoriesProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      Categories,
      Category,
      $CategoriesFilterComposer,
      $CategoriesOrderingComposer,
      $CategoriesAnnotationComposer,
      $CategoriesCreateCompanionBuilder,
      $CategoriesUpdateCompanionBuilder,
      (Category, $CategoriesReferences),
      Category,
      PrefetchHooks Function({bool productsRefs})
    >;
typedef $SuppliersCreateCompanionBuilder = SuppliersCompanion Function({
  Value<String?> id,
  required String name,
  Value<String?> phone,
  Value<String?> address,
  Value<String> createdAt,
  Value<int> rowid,
});
typedef $SuppliersUpdateCompanionBuilder = SuppliersCompanion Function({
  Value<String?> id,
  Value<String> name,
  Value<String?> phone,
  Value<String?> address,
  Value<String> createdAt,
  Value<int> rowid,
});

final class $SuppliersReferences
    extends BaseReferences<_$OwnerDatabase, Suppliers, Supplier> {
  $SuppliersReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<ProductAliases, List<ProductAliase>>
  _productAliasesRefsTable(_$OwnerDatabase db) => MultiTypedResultKey.fromTable(
    db.productAliases,
    aliasName: 'suppliers__id__product_aliases__supplier_id',
  );

  $ProductAliasesProcessedTableManager get productAliasesRefs {
    final manager = $ProductAliasesTableManager(
      $_db,
      $_db.productAliases,
    ).filter((f) => f.supplierId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_productAliasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<PurchaseOrders, List<PurchaseOrder>>
  _purchaseOrdersRefsTable(_$OwnerDatabase db) => MultiTypedResultKey.fromTable(
    db.purchaseOrders,
    aliasName: 'suppliers__id__purchase_orders__supplier_id',
  );

  $PurchaseOrdersProcessedTableManager get purchaseOrdersRefs {
    final manager = $PurchaseOrdersTableManager(
      $_db,
      $_db.purchaseOrders,
    ).filter((f) => f.supplierId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_purchaseOrdersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<SupplierPrices, List<SupplierPrice>>
  _supplierPricesRefsTable(_$OwnerDatabase db) => MultiTypedResultKey.fromTable(
    db.supplierPrices,
    aliasName: 'suppliers__id__supplier_prices__supplier_id',
  );

  $SupplierPricesProcessedTableManager get supplierPricesRefs {
    final manager = $SupplierPricesTableManager(
      $_db,
      $_db.supplierPrices,
    ).filter((f) => f.supplierId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_supplierPricesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $SuppliersFilterComposer extends Composer<_$OwnerDatabase, Suppliers> {
  $SuppliersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> productAliasesRefs(
    Expression<bool> Function($ProductAliasesFilterComposer f) f,
  ) {
    final $ProductAliasesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productAliases,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductAliasesFilterComposer(
            $db: $db,
            $table: $db.productAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> purchaseOrdersRefs(
    Expression<bool> Function($PurchaseOrdersFilterComposer f) f,
  ) {
    final $PurchaseOrdersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersFilterComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> supplierPricesRefs(
    Expression<bool> Function($SupplierPricesFilterComposer f) f,
  ) {
    final $SupplierPricesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.supplierPrices,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SupplierPricesFilterComposer(
            $db: $db,
            $table: $db.supplierPrices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SuppliersOrderingComposer extends Composer<_$OwnerDatabase, Suppliers> {
  $SuppliersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SuppliersAnnotationComposer
    extends Composer<_$OwnerDatabase, Suppliers> {
  $SuppliersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> productAliasesRefs<T extends Object>(
    Expression<T> Function($ProductAliasesAnnotationComposer a) f,
  ) {
    final $ProductAliasesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productAliases,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductAliasesAnnotationComposer(
            $db: $db,
            $table: $db.productAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> purchaseOrdersRefs<T extends Object>(
    Expression<T> Function($PurchaseOrdersAnnotationComposer a) f,
  ) {
    final $PurchaseOrdersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersAnnotationComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> supplierPricesRefs<T extends Object>(
    Expression<T> Function($SupplierPricesAnnotationComposer a) f,
  ) {
    final $SupplierPricesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.supplierPrices,
      getReferencedColumn: (t) => t.supplierId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SupplierPricesAnnotationComposer(
            $db: $db,
            $table: $db.supplierPrices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SuppliersTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          Suppliers,
          Supplier,
          $SuppliersFilterComposer,
          $SuppliersOrderingComposer,
          $SuppliersAnnotationComposer,
          $SuppliersCreateCompanionBuilder,
          $SuppliersUpdateCompanionBuilder,
          (Supplier, $SuppliersReferences),
          Supplier,
          PrefetchHooks Function({
            bool productAliasesRefs,
            bool purchaseOrdersRefs,
            bool supplierPricesRefs,
          })
        > {
  $SuppliersTableManager(_$OwnerDatabase db, Suppliers table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SuppliersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SuppliersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SuppliersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersCompanion(
                id: id,
                name: name,
                phone: phone,
                address: address,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String name,
                Value<String?> phone = const Value.absent(),
                Value<String?> address = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuppliersCompanion.insert(
                id: id,
                name: name,
                phone: phone,
                address: address,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Suppliers, Supplier>(table),
                  $SuppliersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                productAliasesRefs = false,
                purchaseOrdersRefs = false,
                supplierPricesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productAliasesRefs) db.productAliases,
                    if (purchaseOrdersRefs) db.purchaseOrders,
                    if (supplierPricesRefs) db.supplierPrices,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productAliasesRefs)
                        await $_getPrefetchedData<
                          Supplier,
                          Suppliers,
                          ProductAliase
                        >(
                          currentTable: table,
                          referencedTable: $SuppliersReferences
                              ._productAliasesRefsTable(db),
                          managerFromTypedResult: (p0) => $SuppliersReferences(
                            db,
                            table,
                            p0,
                          ).productAliasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.supplierId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (purchaseOrdersRefs)
                        await $_getPrefetchedData<
                          Supplier,
                          Suppliers,
                          PurchaseOrder
                        >(
                          currentTable: table,
                          referencedTable: $SuppliersReferences
                              ._purchaseOrdersRefsTable(db),
                          managerFromTypedResult: (p0) => $SuppliersReferences(
                            db,
                            table,
                            p0,
                          ).purchaseOrdersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.supplierId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (supplierPricesRefs)
                        await $_getPrefetchedData<
                          Supplier,
                          Suppliers,
                          SupplierPrice
                        >(
                          currentTable: table,
                          referencedTable: $SuppliersReferences
                              ._supplierPricesRefsTable(db),
                          managerFromTypedResult: (p0) => $SuppliersReferences(
                            db,
                            table,
                            p0,
                          ).supplierPricesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.supplierId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $SuppliersProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      Suppliers,
      Supplier,
      $SuppliersFilterComposer,
      $SuppliersOrderingComposer,
      $SuppliersAnnotationComposer,
      $SuppliersCreateCompanionBuilder,
      $SuppliersUpdateCompanionBuilder,
      (Supplier, $SuppliersReferences),
      Supplier,
      PrefetchHooks Function({
        bool productAliasesRefs,
        bool purchaseOrdersRefs,
        bool supplierPricesRefs,
      })
    >;
typedef $ProductsCreateCompanionBuilder = ProductsCompanion Function({
  Value<String?> id,
  required String name,
  Value<String?> model,
  Value<String?> categoryId,
  Value<String> unit,
  Value<String?> photoLocalPath,
  Value<String?> photoRemotePath,
  Value<int?> retailPrice,
  Value<int> retailIsOverride,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<String?> publishedAt,
  Value<int> rowid,
});
typedef $ProductsUpdateCompanionBuilder = ProductsCompanion Function({
  Value<String?> id,
  Value<String> name,
  Value<String?> model,
  Value<String?> categoryId,
  Value<String> unit,
  Value<String?> photoLocalPath,
  Value<String?> photoRemotePath,
  Value<int?> retailPrice,
  Value<int> retailIsOverride,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<String?> deletedAt,
  Value<String?> publishedAt,
  Value<int> rowid,
});

final class $ProductsReferences
    extends BaseReferences<_$OwnerDatabase, Products, Product> {
  $ProductsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Categories _categoryIdTable(_$OwnerDatabase db) =>
      db.categories.createAlias('products__category_id__categories__id');

  $CategoriesProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $CategoriesTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<ProductAliases, List<ProductAliase>>
  _productAliasesRefsTable(_$OwnerDatabase db) => MultiTypedResultKey.fromTable(
    db.productAliases,
    aliasName: 'products__id__product_aliases__product_id',
  );

  $ProductAliasesProcessedTableManager get productAliasesRefs {
    final manager = $ProductAliasesTableManager(
      $_db,
      $_db.productAliases,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_productAliasesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<PoLines, List<PoLine>> _poLinesRefsTable(
    _$OwnerDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.poLines,
    aliasName: 'products__id__po_lines__matched_product_id',
  );

  $PoLinesProcessedTableManager get poLinesRefs {
    final manager = $PoLinesTableManager($_db, $_db.poLines).filter(
      (f) => f.matchedProductId.id.sqlEquals($_itemColumn<String>('id')),
    );

    final cache = $_typedResult.readTableOrNull(_poLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<SupplierPrices, List<SupplierPrice>>
  _supplierPricesRefsTable(_$OwnerDatabase db) => MultiTypedResultKey.fromTable(
    db.supplierPrices,
    aliasName: 'products__id__supplier_prices__product_id',
  );

  $SupplierPricesProcessedTableManager get supplierPricesRefs {
    final manager = $SupplierPricesTableManager(
      $_db,
      $_db.supplierPrices,
    ).filter((f) => f.productId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_supplierPricesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ProductsFilterComposer extends Composer<_$OwnerDatabase, Products> {
  $ProductsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoLocalPath => $composableBuilder(
    column: $table.photoLocalPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoRemotePath => $composableBuilder(
    column: $table.photoRemotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retailIsOverride => $composableBuilder(
    column: $table.retailIsOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CategoriesFilterComposer get categoryId {
    final $CategoriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoriesFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> productAliasesRefs(
    Expression<bool> Function($ProductAliasesFilterComposer f) f,
  ) {
    final $ProductAliasesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productAliases,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductAliasesFilterComposer(
            $db: $db,
            $table: $db.productAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> poLinesRefs(
    Expression<bool> Function($PoLinesFilterComposer f) f,
  ) {
    final $PoLinesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poLines,
      getReferencedColumn: (t) => t.matchedProductId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoLinesFilterComposer(
            $db: $db,
            $table: $db.poLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> supplierPricesRefs(
    Expression<bool> Function($SupplierPricesFilterComposer f) f,
  ) {
    final $SupplierPricesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.supplierPrices,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SupplierPricesFilterComposer(
            $db: $db,
            $table: $db.supplierPrices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProductsOrderingComposer extends Composer<_$OwnerDatabase, Products> {
  $ProductsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoLocalPath => $composableBuilder(
    column: $table.photoLocalPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoRemotePath => $composableBuilder(
    column: $table.photoRemotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retailIsOverride => $composableBuilder(
    column: $table.retailIsOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CategoriesOrderingComposer get categoryId {
    final $CategoriesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoriesOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ProductsAnnotationComposer extends Composer<_$OwnerDatabase, Products> {
  $ProductsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get photoLocalPath => $composableBuilder(
    column: $table.photoLocalPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get photoRemotePath => $composableBuilder(
    column: $table.photoRemotePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retailIsOverride => $composableBuilder(
    column: $table.retailIsOverride,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get publishedAt => $composableBuilder(
    column: $table.publishedAt,
    builder: (column) => column,
  );

  $CategoriesAnnotationComposer get categoryId {
    final $CategoriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CategoriesAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> productAliasesRefs<T extends Object>(
    Expression<T> Function($ProductAliasesAnnotationComposer a) f,
  ) {
    final $ProductAliasesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.productAliases,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductAliasesAnnotationComposer(
            $db: $db,
            $table: $db.productAliases,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> poLinesRefs<T extends Object>(
    Expression<T> Function($PoLinesAnnotationComposer a) f,
  ) {
    final $PoLinesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poLines,
      getReferencedColumn: (t) => t.matchedProductId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoLinesAnnotationComposer(
            $db: $db,
            $table: $db.poLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> supplierPricesRefs<T extends Object>(
    Expression<T> Function($SupplierPricesAnnotationComposer a) f,
  ) {
    final $SupplierPricesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.supplierPrices,
      getReferencedColumn: (t) => t.productId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SupplierPricesAnnotationComposer(
            $db: $db,
            $table: $db.supplierPrices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ProductsTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          Products,
          Product,
          $ProductsFilterComposer,
          $ProductsOrderingComposer,
          $ProductsAnnotationComposer,
          $ProductsCreateCompanionBuilder,
          $ProductsUpdateCompanionBuilder,
          (Product, $ProductsReferences),
          Product,
          PrefetchHooks Function({
            bool categoryId,
            bool productAliasesRefs,
            bool poLinesRefs,
            bool supplierPricesRefs,
          })
        > {
  $ProductsTableManager(_$OwnerDatabase db, Products table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProductsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProductsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProductsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> photoLocalPath = const Value.absent(),
                Value<String?> photoRemotePath = const Value.absent(),
                Value<int?> retailPrice = const Value.absent(),
                Value<int> retailIsOverride = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                model: model,
                categoryId: categoryId,
                unit: unit,
                photoLocalPath: photoLocalPath,
                photoRemotePath: photoRemotePath,
                retailPrice: retailPrice,
                retailIsOverride: retailIsOverride,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String name,
                Value<String?> model = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> photoLocalPath = const Value.absent(),
                Value<String?> photoRemotePath = const Value.absent(),
                Value<int?> retailPrice = const Value.absent(),
                Value<int> retailIsOverride = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<String?> deletedAt = const Value.absent(),
                Value<String?> publishedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                model: model,
                categoryId: categoryId,
                unit: unit,
                photoLocalPath: photoLocalPath,
                photoRemotePath: photoRemotePath,
                retailPrice: retailPrice,
                retailIsOverride: retailIsOverride,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                publishedAt: publishedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Products, Product>(table),
                  $ProductsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                categoryId = false,
                productAliasesRefs = false,
                poLinesRefs = false,
                supplierPricesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (productAliasesRefs) db.productAliases,
                    if (poLinesRefs) db.poLines,
                    if (supplierPricesRefs) db.supplierPrices,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (categoryId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.categoryId,
                            referencedTable: $ProductsReferences
                                ._categoryIdTable(db),
                            referencedColumn: $ProductsReferences
                                ._categoryIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (productAliasesRefs)
                        await $_getPrefetchedData<
                          Product,
                          Products,
                          ProductAliase
                        >(
                          currentTable: table,
                          referencedTable: $ProductsReferences
                              ._productAliasesRefsTable(db),
                          managerFromTypedResult: (p0) => $ProductsReferences(
                            db,
                            table,
                            p0,
                          ).productAliasesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (poLinesRefs)
                        await $_getPrefetchedData<Product, Products, PoLine>(
                          currentTable: table,
                          referencedTable: $ProductsReferences
                              ._poLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $ProductsReferences(db, table, p0).poLinesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.matchedProductId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (supplierPricesRefs)
                        await $_getPrefetchedData<
                          Product,
                          Products,
                          SupplierPrice
                        >(
                          currentTable: table,
                          referencedTable: $ProductsReferences
                              ._supplierPricesRefsTable(db),
                          managerFromTypedResult: (p0) => $ProductsReferences(
                            db,
                            table,
                            p0,
                          ).supplierPricesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.productId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ProductsProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      Products,
      Product,
      $ProductsFilterComposer,
      $ProductsOrderingComposer,
      $ProductsAnnotationComposer,
      $ProductsCreateCompanionBuilder,
      $ProductsUpdateCompanionBuilder,
      (Product, $ProductsReferences),
      Product,
      PrefetchHooks Function({
        bool categoryId,
        bool productAliasesRefs,
        bool poLinesRefs,
        bool supplierPricesRefs,
      })
    >;
typedef $ProductAliasesCreateCompanionBuilder =
    ProductAliasesCompanion Function({
      Value<String?> id,
      required String productId,
      required String supplierId,
      required String alias,
      required String aliasNorm,
      Value<int> rowid,
    });
typedef $ProductAliasesUpdateCompanionBuilder =
    ProductAliasesCompanion Function({
      Value<String?> id,
      Value<String> productId,
      Value<String> supplierId,
      Value<String> alias,
      Value<String> aliasNorm,
      Value<int> rowid,
    });

final class $ProductAliasesReferences
    extends BaseReferences<_$OwnerDatabase, ProductAliases, ProductAliase> {
  $ProductAliasesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Products _productIdTable(_$OwnerDatabase db) =>
      db.products.createAlias('product_aliases__product_id__products__id');

  $ProductsProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $ProductsTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Suppliers _supplierIdTable(_$OwnerDatabase db) =>
      db.suppliers.createAlias('product_aliases__supplier_id__suppliers__id');

  $SuppliersProcessedTableManager get supplierId {
    final $_column = $_itemColumn<String>('supplier_id')!;

    final manager = $SuppliersTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ProductAliasesFilterComposer
    extends Composer<_$OwnerDatabase, ProductAliases> {
  $ProductAliasesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get aliasNorm => $composableBuilder(
    column: $table.aliasNorm,
    builder: (column) => ColumnFilters(column),
  );

  $ProductsFilterComposer get productId {
    final $ProductsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SuppliersFilterComposer get supplierId {
    final $SuppliersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ProductAliasesOrderingComposer
    extends Composer<_$OwnerDatabase, ProductAliases> {
  $ProductAliasesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alias => $composableBuilder(
    column: $table.alias,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get aliasNorm => $composableBuilder(
    column: $table.aliasNorm,
    builder: (column) => ColumnOrderings(column),
  );

  $ProductsOrderingComposer get productId {
    final $ProductsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SuppliersOrderingComposer get supplierId {
    final $SuppliersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ProductAliasesAnnotationComposer
    extends Composer<_$OwnerDatabase, ProductAliases> {
  $ProductAliasesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get alias =>
      $composableBuilder(column: $table.alias, builder: (column) => column);

  GeneratedColumn<String> get aliasNorm =>
      $composableBuilder(column: $table.aliasNorm, builder: (column) => column);

  $ProductsAnnotationComposer get productId {
    final $ProductsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SuppliersAnnotationComposer get supplierId {
    final $SuppliersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ProductAliasesTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          ProductAliases,
          ProductAliase,
          $ProductAliasesFilterComposer,
          $ProductAliasesOrderingComposer,
          $ProductAliasesAnnotationComposer,
          $ProductAliasesCreateCompanionBuilder,
          $ProductAliasesUpdateCompanionBuilder,
          (ProductAliase, $ProductAliasesReferences),
          ProductAliase,
          PrefetchHooks Function({bool productId, bool supplierId})
        > {
  $ProductAliasesTableManager(_$OwnerDatabase db, ProductAliases table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ProductAliasesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ProductAliasesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ProductAliasesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> supplierId = const Value.absent(),
                Value<String> alias = const Value.absent(),
                Value<String> aliasNorm = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductAliasesCompanion(
                id: id,
                productId: productId,
                supplierId: supplierId,
                alias: alias,
                aliasNorm: aliasNorm,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String productId,
                required String supplierId,
                required String alias,
                required String aliasNorm,
                Value<int> rowid = const Value.absent(),
              }) => ProductAliasesCompanion.insert(
                id: id,
                productId: productId,
                supplierId: supplierId,
                alias: alias,
                aliasNorm: aliasNorm,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<ProductAliases, ProductAliase>(table),
                  $ProductAliasesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({productId = false, supplierId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (productId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.productId,
                        referencedTable: $ProductAliasesReferences
                            ._productIdTable(db),
                        referencedColumn: $ProductAliasesReferences
                            ._productIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (supplierId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.supplierId,
                        referencedTable: $ProductAliasesReferences
                            ._supplierIdTable(db),
                        referencedColumn: $ProductAliasesReferences
                            ._supplierIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ProductAliasesProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      ProductAliases,
      ProductAliase,
      $ProductAliasesFilterComposer,
      $ProductAliasesOrderingComposer,
      $ProductAliasesAnnotationComposer,
      $ProductAliasesCreateCompanionBuilder,
      $ProductAliasesUpdateCompanionBuilder,
      (ProductAliase, $ProductAliasesReferences),
      ProductAliase,
      PrefetchHooks Function({bool productId, bool supplierId})
    >;
typedef $PurchaseOrdersCreateCompanionBuilder =
    PurchaseOrdersCompanion Function({
      Value<String?> id,
      Value<String?> supplierId,
      Value<String> status,
      required String source,
      Value<String?> poDate,
      Value<String?> serverJobId,
      Value<String?> rawResult,
      Value<String> createdAt,
      Value<String?> reviewedAt,
      Value<int> rowid,
    });
typedef $PurchaseOrdersUpdateCompanionBuilder =
    PurchaseOrdersCompanion Function({
      Value<String?> id,
      Value<String?> supplierId,
      Value<String> status,
      Value<String> source,
      Value<String?> poDate,
      Value<String?> serverJobId,
      Value<String?> rawResult,
      Value<String> createdAt,
      Value<String?> reviewedAt,
      Value<int> rowid,
    });

final class $PurchaseOrdersReferences
    extends BaseReferences<_$OwnerDatabase, PurchaseOrders, PurchaseOrder> {
  $PurchaseOrdersReferences(super.$_db, super.$_table, super.$_typedResult);

  static Suppliers _supplierIdTable(_$OwnerDatabase db) =>
      db.suppliers.createAlias('purchase_orders__supplier_id__suppliers__id');

  $SuppliersProcessedTableManager? get supplierId {
    final $_column = $_itemColumn<String>('supplier_id');
    if ($_column == null) return null;
    final manager = $SuppliersTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<PoLines, List<PoLine>> _poLinesRefsTable(
    _$OwnerDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.poLines,
    aliasName: 'purchase_orders__id__po_lines__po_id',
  );

  $PoLinesProcessedTableManager get poLinesRefs {
    final manager = $PoLinesTableManager(
      $_db,
      $_db.poLines,
    ).filter((f) => f.poId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_poLinesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<PoPages, List<PoPage>> _poPagesRefsTable(
    _$OwnerDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.poPages,
    aliasName: 'purchase_orders__id__po_pages__po_id',
  );

  $PoPagesProcessedTableManager get poPagesRefs {
    final manager = $PoPagesTableManager(
      $_db,
      $_db.poPages,
    ).filter((f) => f.poId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_poPagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $PurchaseOrdersFilterComposer
    extends Composer<_$OwnerDatabase, PurchaseOrders> {
  $PurchaseOrdersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get poDate => $composableBuilder(
    column: $table.poDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverJobId => $composableBuilder(
    column: $table.serverJobId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawResult => $composableBuilder(
    column: $table.rawResult,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  $SuppliersFilterComposer get supplierId {
    final $SuppliersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> poLinesRefs(
    Expression<bool> Function($PoLinesFilterComposer f) f,
  ) {
    final $PoLinesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poLines,
      getReferencedColumn: (t) => t.poId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoLinesFilterComposer(
            $db: $db,
            $table: $db.poLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> poPagesRefs(
    Expression<bool> Function($PoPagesFilterComposer f) f,
  ) {
    final $PoPagesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poPages,
      getReferencedColumn: (t) => t.poId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoPagesFilterComposer(
            $db: $db,
            $table: $db.poPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PurchaseOrdersOrderingComposer
    extends Composer<_$OwnerDatabase, PurchaseOrders> {
  $PurchaseOrdersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get poDate => $composableBuilder(
    column: $table.poDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverJobId => $composableBuilder(
    column: $table.serverJobId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawResult => $composableBuilder(
    column: $table.rawResult,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $SuppliersOrderingComposer get supplierId {
    final $SuppliersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PurchaseOrdersAnnotationComposer
    extends Composer<_$OwnerDatabase, PurchaseOrders> {
  $PurchaseOrdersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get poDate =>
      $composableBuilder(column: $table.poDate, builder: (column) => column);

  GeneratedColumn<String> get serverJobId => $composableBuilder(
    column: $table.serverJobId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawResult =>
      $composableBuilder(column: $table.rawResult, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  $SuppliersAnnotationComposer get supplierId {
    final $SuppliersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> poLinesRefs<T extends Object>(
    Expression<T> Function($PoLinesAnnotationComposer a) f,
  ) {
    final $PoLinesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poLines,
      getReferencedColumn: (t) => t.poId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoLinesAnnotationComposer(
            $db: $db,
            $table: $db.poLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> poPagesRefs<T extends Object>(
    Expression<T> Function($PoPagesAnnotationComposer a) f,
  ) {
    final $PoPagesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.poPages,
      getReferencedColumn: (t) => t.poId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoPagesAnnotationComposer(
            $db: $db,
            $table: $db.poPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PurchaseOrdersTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          PurchaseOrders,
          PurchaseOrder,
          $PurchaseOrdersFilterComposer,
          $PurchaseOrdersOrderingComposer,
          $PurchaseOrdersAnnotationComposer,
          $PurchaseOrdersCreateCompanionBuilder,
          $PurchaseOrdersUpdateCompanionBuilder,
          (PurchaseOrder, $PurchaseOrdersReferences),
          PurchaseOrder,
          PrefetchHooks Function({
            bool supplierId,
            bool poLinesRefs,
            bool poPagesRefs,
          })
        > {
  $PurchaseOrdersTableManager(_$OwnerDatabase db, PurchaseOrders table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PurchaseOrdersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PurchaseOrdersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PurchaseOrdersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> poDate = const Value.absent(),
                Value<String?> serverJobId = const Value.absent(),
                Value<String?> rawResult = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> reviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersCompanion(
                id: id,
                supplierId: supplierId,
                status: status,
                source: source,
                poDate: poDate,
                serverJobId: serverJobId,
                rawResult: rawResult,
                createdAt: createdAt,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String?> supplierId = const Value.absent(),
                Value<String> status = const Value.absent(),
                required String source,
                Value<String?> poDate = const Value.absent(),
                Value<String?> serverJobId = const Value.absent(),
                Value<String?> rawResult = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String?> reviewedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PurchaseOrdersCompanion.insert(
                id: id,
                supplierId: supplierId,
                status: status,
                source: source,
                poDate: poDate,
                serverJobId: serverJobId,
                rawResult: rawResult,
                createdAt: createdAt,
                reviewedAt: reviewedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PurchaseOrders, PurchaseOrder>(table),
                  $PurchaseOrdersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({supplierId = false, poLinesRefs = false, poPagesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (poLinesRefs) db.poLines,
                    if (poPagesRefs) db.poPages,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (supplierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.supplierId,
                            referencedTable: $PurchaseOrdersReferences
                                ._supplierIdTable(db),
                            referencedColumn: $PurchaseOrdersReferences
                                ._supplierIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (poLinesRefs)
                        await $_getPrefetchedData<
                          PurchaseOrder,
                          PurchaseOrders,
                          PoLine
                        >(
                          currentTable: table,
                          referencedTable: $PurchaseOrdersReferences
                              ._poLinesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $PurchaseOrdersReferences(
                                db,
                                table,
                                p0,
                              ).poLinesRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.poId == item.id),
                          typedResults: items,
                        ),
                      if (poPagesRefs)
                        await $_getPrefetchedData<
                          PurchaseOrder,
                          PurchaseOrders,
                          PoPage
                        >(
                          currentTable: table,
                          referencedTable: $PurchaseOrdersReferences
                              ._poPagesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $PurchaseOrdersReferences(
                                db,
                                table,
                                p0,
                              ).poPagesRefs,
                          referencedItemsForCurrentItem: (
                            item,
                            referencedItems,
                          ) => referencedItems.where((e) => e.poId == item.id),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $PurchaseOrdersProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      PurchaseOrders,
      PurchaseOrder,
      $PurchaseOrdersFilterComposer,
      $PurchaseOrdersOrderingComposer,
      $PurchaseOrdersAnnotationComposer,
      $PurchaseOrdersCreateCompanionBuilder,
      $PurchaseOrdersUpdateCompanionBuilder,
      (PurchaseOrder, $PurchaseOrdersReferences),
      PurchaseOrder,
      PrefetchHooks Function({
        bool supplierId,
        bool poLinesRefs,
        bool poPagesRefs,
      })
    >;
typedef $PoLinesCreateCompanionBuilder = PoLinesCompanion Function({
  Value<String?> id,
  required String poId,
  required int lineNo,
  required String rawName,
  Value<double?> qty,
  Value<String?> unit,
  Value<int?> unitPrice,
  Value<String?> confidence,
  Value<String?> matchedProductId,
  Value<String> matchStatus,
  Value<int> rowid,
});
typedef $PoLinesUpdateCompanionBuilder = PoLinesCompanion Function({
  Value<String?> id,
  Value<String> poId,
  Value<int> lineNo,
  Value<String> rawName,
  Value<double?> qty,
  Value<String?> unit,
  Value<int?> unitPrice,
  Value<String?> confidence,
  Value<String?> matchedProductId,
  Value<String> matchStatus,
  Value<int> rowid,
});

final class $PoLinesReferences
    extends BaseReferences<_$OwnerDatabase, PoLines, PoLine> {
  $PoLinesReferences(super.$_db, super.$_table, super.$_typedResult);

  static PurchaseOrders _poIdTable(_$OwnerDatabase db) =>
      db.purchaseOrders.createAlias('po_lines__po_id__purchase_orders__id');

  $PurchaseOrdersProcessedTableManager get poId {
    final $_column = $_itemColumn<String>('po_id')!;

    final manager = $PurchaseOrdersTableManager(
      $_db,
      $_db.purchaseOrders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_poIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Products _matchedProductIdTable(_$OwnerDatabase db) =>
      db.products.createAlias('po_lines__matched_product_id__products__id');

  $ProductsProcessedTableManager? get matchedProductId {
    final $_column = $_itemColumn<String>('matched_product_id');
    if ($_column == null) return null;
    final manager = $ProductsTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_matchedProductIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<SupplierPrices, List<SupplierPrice>>
  _supplierPricesRefsTable(_$OwnerDatabase db) => MultiTypedResultKey.fromTable(
    db.supplierPrices,
    aliasName: 'po_lines__id__supplier_prices__po_line_id',
  );

  $SupplierPricesProcessedTableManager get supplierPricesRefs {
    final manager = $SupplierPricesTableManager(
      $_db,
      $_db.supplierPrices,
    ).filter((f) => f.poLineId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_supplierPricesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $PoLinesFilterComposer extends Composer<_$OwnerDatabase, PoLines> {
  $PoLinesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get matchStatus => $composableBuilder(
    column: $table.matchStatus,
    builder: (column) => ColumnFilters(column),
  );

  $PurchaseOrdersFilterComposer get poId {
    final $PurchaseOrdersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersFilterComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ProductsFilterComposer get matchedProductId {
    final $ProductsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedProductId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> supplierPricesRefs(
    Expression<bool> Function($SupplierPricesFilterComposer f) f,
  ) {
    final $SupplierPricesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.supplierPrices,
      getReferencedColumn: (t) => t.poLineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SupplierPricesFilterComposer(
            $db: $db,
            $table: $db.supplierPrices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PoLinesOrderingComposer extends Composer<_$OwnerDatabase, PoLines> {
  $PoLinesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lineNo => $composableBuilder(
    column: $table.lineNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawName => $composableBuilder(
    column: $table.rawName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get qty => $composableBuilder(
    column: $table.qty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get matchStatus => $composableBuilder(
    column: $table.matchStatus,
    builder: (column) => ColumnOrderings(column),
  );

  $PurchaseOrdersOrderingComposer get poId {
    final $PurchaseOrdersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersOrderingComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ProductsOrderingComposer get matchedProductId {
    final $ProductsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedProductId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PoLinesAnnotationComposer extends Composer<_$OwnerDatabase, PoLines> {
  $PoLinesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get lineNo =>
      $composableBuilder(column: $table.lineNo, builder: (column) => column);

  GeneratedColumn<String> get rawName =>
      $composableBuilder(column: $table.rawName, builder: (column) => column);

  GeneratedColumn<double> get qty =>
      $composableBuilder(column: $table.qty, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get matchStatus => $composableBuilder(
    column: $table.matchStatus,
    builder: (column) => column,
  );

  $PurchaseOrdersAnnotationComposer get poId {
    final $PurchaseOrdersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersAnnotationComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $ProductsAnnotationComposer get matchedProductId {
    final $ProductsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.matchedProductId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> supplierPricesRefs<T extends Object>(
    Expression<T> Function($SupplierPricesAnnotationComposer a) f,
  ) {
    final $SupplierPricesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.supplierPrices,
      getReferencedColumn: (t) => t.poLineId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SupplierPricesAnnotationComposer(
            $db: $db,
            $table: $db.supplierPrices,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $PoLinesTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          PoLines,
          PoLine,
          $PoLinesFilterComposer,
          $PoLinesOrderingComposer,
          $PoLinesAnnotationComposer,
          $PoLinesCreateCompanionBuilder,
          $PoLinesUpdateCompanionBuilder,
          (PoLine, $PoLinesReferences),
          PoLine,
          PrefetchHooks Function({
            bool poId,
            bool matchedProductId,
            bool supplierPricesRefs,
          })
        > {
  $PoLinesTableManager(_$OwnerDatabase db, PoLines table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PoLinesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PoLinesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PoLinesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> poId = const Value.absent(),
                Value<int> lineNo = const Value.absent(),
                Value<String> rawName = const Value.absent(),
                Value<double?> qty = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> unitPrice = const Value.absent(),
                Value<String?> confidence = const Value.absent(),
                Value<String?> matchedProductId = const Value.absent(),
                Value<String> matchStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoLinesCompanion(
                id: id,
                poId: poId,
                lineNo: lineNo,
                rawName: rawName,
                qty: qty,
                unit: unit,
                unitPrice: unitPrice,
                confidence: confidence,
                matchedProductId: matchedProductId,
                matchStatus: matchStatus,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String poId,
                required int lineNo,
                required String rawName,
                Value<double?> qty = const Value.absent(),
                Value<String?> unit = const Value.absent(),
                Value<int?> unitPrice = const Value.absent(),
                Value<String?> confidence = const Value.absent(),
                Value<String?> matchedProductId = const Value.absent(),
                Value<String> matchStatus = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoLinesCompanion.insert(
                id: id,
                poId: poId,
                lineNo: lineNo,
                rawName: rawName,
                qty: qty,
                unit: unit,
                unitPrice: unitPrice,
                confidence: confidence,
                matchedProductId: matchedProductId,
                matchStatus: matchStatus,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PoLines, PoLine>(table),
                  $PoLinesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                poId = false,
                matchedProductId = false,
                supplierPricesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (supplierPricesRefs) db.supplierPrices,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (poId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.poId,
                            referencedTable: $PoLinesReferences._poIdTable(db),
                            referencedColumn: $PoLinesReferences
                                ._poIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (matchedProductId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.matchedProductId,
                            referencedTable: $PoLinesReferences
                                ._matchedProductIdTable(db),
                            referencedColumn: $PoLinesReferences
                                ._matchedProductIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (supplierPricesRefs)
                        await $_getPrefetchedData<
                          PoLine,
                          PoLines,
                          SupplierPrice
                        >(
                          currentTable: table,
                          referencedTable: $PoLinesReferences
                              ._supplierPricesRefsTable(db),
                          managerFromTypedResult: (p0) => $PoLinesReferences(
                            db,
                            table,
                            p0,
                          ).supplierPricesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.poLineId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $PoLinesProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      PoLines,
      PoLine,
      $PoLinesFilterComposer,
      $PoLinesOrderingComposer,
      $PoLinesAnnotationComposer,
      $PoLinesCreateCompanionBuilder,
      $PoLinesUpdateCompanionBuilder,
      (PoLine, $PoLinesReferences),
      PoLine,
      PrefetchHooks Function({
        bool poId,
        bool matchedProductId,
        bool supplierPricesRefs,
      })
    >;
typedef $SupplierPricesCreateCompanionBuilder =
    SupplierPricesCompanion Function({
      Value<String?> id,
      required String productId,
      required String supplierId,
      required int unitPrice,
      Value<String?> poLineId,
      Value<String> observedAt,
      Value<int> rowid,
    });
typedef $SupplierPricesUpdateCompanionBuilder =
    SupplierPricesCompanion Function({
      Value<String?> id,
      Value<String> productId,
      Value<String> supplierId,
      Value<int> unitPrice,
      Value<String?> poLineId,
      Value<String> observedAt,
      Value<int> rowid,
    });

final class $SupplierPricesReferences
    extends BaseReferences<_$OwnerDatabase, SupplierPrices, SupplierPrice> {
  $SupplierPricesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Products _productIdTable(_$OwnerDatabase db) =>
      db.products.createAlias('supplier_prices__product_id__products__id');

  $ProductsProcessedTableManager get productId {
    final $_column = $_itemColumn<String>('product_id')!;

    final manager = $ProductsTableManager(
      $_db,
      $_db.products,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_productIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Suppliers _supplierIdTable(_$OwnerDatabase db) =>
      db.suppliers.createAlias('supplier_prices__supplier_id__suppliers__id');

  $SuppliersProcessedTableManager get supplierId {
    final $_column = $_itemColumn<String>('supplier_id')!;

    final manager = $SuppliersTableManager(
      $_db,
      $_db.suppliers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_supplierIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static PoLines _poLineIdTable(_$OwnerDatabase db) =>
      db.poLines.createAlias('supplier_prices__po_line_id__po_lines__id');

  $PoLinesProcessedTableManager? get poLineId {
    final $_column = $_itemColumn<String>('po_line_id');
    if ($_column == null) return null;
    final manager = $PoLinesTableManager(
      $_db,
      $_db.poLines,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_poLineIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $SupplierPricesFilterComposer
    extends Composer<_$OwnerDatabase, SupplierPrices> {
  $SupplierPricesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnFilters(column),
  );

  $ProductsFilterComposer get productId {
    final $ProductsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsFilterComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SuppliersFilterComposer get supplierId {
    final $SuppliersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersFilterComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $PoLinesFilterComposer get poLineId {
    final $PoLinesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poLineId,
      referencedTable: $db.poLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoLinesFilterComposer(
            $db: $db,
            $table: $db.poLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SupplierPricesOrderingComposer
    extends Composer<_$OwnerDatabase, SupplierPrices> {
  $SupplierPricesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $ProductsOrderingComposer get productId {
    final $ProductsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsOrderingComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SuppliersOrderingComposer get supplierId {
    final $SuppliersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersOrderingComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $PoLinesOrderingComposer get poLineId {
    final $PoLinesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poLineId,
      referencedTable: $db.poLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoLinesOrderingComposer(
            $db: $db,
            $table: $db.poLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SupplierPricesAnnotationComposer
    extends Composer<_$OwnerDatabase, SupplierPrices> {
  $SupplierPricesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<String> get observedAt => $composableBuilder(
    column: $table.observedAt,
    builder: (column) => column,
  );

  $ProductsAnnotationComposer get productId {
    final $ProductsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.productId,
      referencedTable: $db.products,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ProductsAnnotationComposer(
            $db: $db,
            $table: $db.products,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SuppliersAnnotationComposer get supplierId {
    final $SuppliersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.supplierId,
      referencedTable: $db.suppliers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SuppliersAnnotationComposer(
            $db: $db,
            $table: $db.suppliers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $PoLinesAnnotationComposer get poLineId {
    final $PoLinesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poLineId,
      referencedTable: $db.poLines,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PoLinesAnnotationComposer(
            $db: $db,
            $table: $db.poLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SupplierPricesTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          SupplierPrices,
          SupplierPrice,
          $SupplierPricesFilterComposer,
          $SupplierPricesOrderingComposer,
          $SupplierPricesAnnotationComposer,
          $SupplierPricesCreateCompanionBuilder,
          $SupplierPricesUpdateCompanionBuilder,
          (SupplierPrice, $SupplierPricesReferences),
          SupplierPrice,
          PrefetchHooks Function({
            bool productId,
            bool supplierId,
            bool poLineId,
          })
        > {
  $SupplierPricesTableManager(_$OwnerDatabase db, SupplierPrices table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SupplierPricesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SupplierPricesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SupplierPricesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> supplierId = const Value.absent(),
                Value<int> unitPrice = const Value.absent(),
                Value<String?> poLineId = const Value.absent(),
                Value<String> observedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SupplierPricesCompanion(
                id: id,
                productId: productId,
                supplierId: supplierId,
                unitPrice: unitPrice,
                poLineId: poLineId,
                observedAt: observedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String productId,
                required String supplierId,
                required int unitPrice,
                Value<String?> poLineId = const Value.absent(),
                Value<String> observedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SupplierPricesCompanion.insert(
                id: id,
                productId: productId,
                supplierId: supplierId,
                unitPrice: unitPrice,
                poLineId: poLineId,
                observedAt: observedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<SupplierPrices, SupplierPrice>(table),
                  $SupplierPricesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({productId = false, supplierId = false, poLineId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (productId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.productId,
                            referencedTable: $SupplierPricesReferences
                                ._productIdTable(db),
                            referencedColumn: $SupplierPricesReferences
                                ._productIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (supplierId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.supplierId,
                            referencedTable: $SupplierPricesReferences
                                ._supplierIdTable(db),
                            referencedColumn: $SupplierPricesReferences
                                ._supplierIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (poLineId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.poLineId,
                            referencedTable: $SupplierPricesReferences
                                ._poLineIdTable(db),
                            referencedColumn: $SupplierPricesReferences
                                ._poLineIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $SupplierPricesProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      SupplierPrices,
      SupplierPrice,
      $SupplierPricesFilterComposer,
      $SupplierPricesOrderingComposer,
      $SupplierPricesAnnotationComposer,
      $SupplierPricesCreateCompanionBuilder,
      $SupplierPricesUpdateCompanionBuilder,
      (SupplierPrice, $SupplierPricesReferences),
      SupplierPrice,
      PrefetchHooks Function({bool productId, bool supplierId, bool poLineId})
    >;
typedef $PoPagesCreateCompanionBuilder = PoPagesCompanion Function({
  Value<String?> id,
  required String poId,
  required int pageNo,
  required String localPath,
  Value<int> rowid,
});
typedef $PoPagesUpdateCompanionBuilder = PoPagesCompanion Function({
  Value<String?> id,
  Value<String> poId,
  Value<int> pageNo,
  Value<String> localPath,
  Value<int> rowid,
});

final class $PoPagesReferences
    extends BaseReferences<_$OwnerDatabase, PoPages, PoPage> {
  $PoPagesReferences(super.$_db, super.$_table, super.$_typedResult);

  static PurchaseOrders _poIdTable(_$OwnerDatabase db) =>
      db.purchaseOrders.createAlias('po_pages__po_id__purchase_orders__id');

  $PurchaseOrdersProcessedTableManager get poId {
    final $_column = $_itemColumn<String>('po_id')!;

    final manager = $PurchaseOrdersTableManager(
      $_db,
      $_db.purchaseOrders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_poIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $PoPagesFilterComposer extends Composer<_$OwnerDatabase, PoPages> {
  $PoPagesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  $PurchaseOrdersFilterComposer get poId {
    final $PurchaseOrdersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersFilterComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PoPagesOrderingComposer extends Composer<_$OwnerDatabase, PoPages> {
  $PoPagesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNo => $composableBuilder(
    column: $table.pageNo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  $PurchaseOrdersOrderingComposer get poId {
    final $PurchaseOrdersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersOrderingComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PoPagesAnnotationComposer extends Composer<_$OwnerDatabase, PoPages> {
  $PoPagesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageNo =>
      $composableBuilder(column: $table.pageNo, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  $PurchaseOrdersAnnotationComposer get poId {
    final $PurchaseOrdersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.poId,
      referencedTable: $db.purchaseOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $PurchaseOrdersAnnotationComposer(
            $db: $db,
            $table: $db.purchaseOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $PoPagesTableManager
    extends
        RootTableManager<
          _$OwnerDatabase,
          PoPages,
          PoPage,
          $PoPagesFilterComposer,
          $PoPagesOrderingComposer,
          $PoPagesAnnotationComposer,
          $PoPagesCreateCompanionBuilder,
          $PoPagesUpdateCompanionBuilder,
          (PoPage, $PoPagesReferences),
          PoPage,
          PrefetchHooks Function({bool poId})
        > {
  $PoPagesTableManager(_$OwnerDatabase db, PoPages table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $PoPagesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $PoPagesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $PoPagesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> poId = const Value.absent(),
                Value<int> pageNo = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PoPagesCompanion(
                id: id,
                poId: poId,
                pageNo: pageNo,
                localPath: localPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String poId,
                required int pageNo,
                required String localPath,
                Value<int> rowid = const Value.absent(),
              }) => PoPagesCompanion.insert(
                id: id,
                poId: poId,
                pageNo: pageNo,
                localPath: localPath,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<PoPages, PoPage>(table),
                  $PoPagesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({poId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (poId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.poId,
                        referencedTable: $PoPagesReferences._poIdTable(db),
                        referencedColumn: $PoPagesReferences._poIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $PoPagesProcessedTableManager =
    ProcessedTableManager<
      _$OwnerDatabase,
      PoPages,
      PoPage,
      $PoPagesFilterComposer,
      $PoPagesOrderingComposer,
      $PoPagesAnnotationComposer,
      $PoPagesCreateCompanionBuilder,
      $PoPagesUpdateCompanionBuilder,
      (PoPage, $PoPagesReferences),
      PoPage,
      PrefetchHooks Function({bool poId})
    >;

class $OwnerDatabaseManager {
  final _$OwnerDatabase _db;
  $OwnerDatabaseManager(this._db);
  $SettingsTableManager get settings =>
      $SettingsTableManager(_db, _db.settings);
  $PricingAnchorsTableManager get pricingAnchors =>
      $PricingAnchorsTableManager(_db, _db.pricingAnchors);
  $MarginThresholdsTableManager get marginThresholds =>
      $MarginThresholdsTableManager(_db, _db.marginThresholds);
  $CategoriesTableManager get categories =>
      $CategoriesTableManager(_db, _db.categories);
  $SuppliersTableManager get suppliers =>
      $SuppliersTableManager(_db, _db.suppliers);
  $ProductsTableManager get products =>
      $ProductsTableManager(_db, _db.products);
  $ProductAliasesTableManager get productAliases =>
      $ProductAliasesTableManager(_db, _db.productAliases);
  $PurchaseOrdersTableManager get purchaseOrders =>
      $PurchaseOrdersTableManager(_db, _db.purchaseOrders);
  $PoLinesTableManager get poLines => $PoLinesTableManager(_db, _db.poLines);
  $SupplierPricesTableManager get supplierPrices =>
      $SupplierPricesTableManager(_db, _db.supplierPrices);
  $PoPagesTableManager get poPages => $PoPagesTableManager(_db, _db.poPages);
}
