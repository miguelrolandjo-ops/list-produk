// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_database.dart';

// ignore_for_file: type=lint
class Catalog extends Table with TableInfo<Catalog, CatalogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Catalog(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
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
  static const VerificationMeta _photoPathMeta = const VerificationMeta(
    'photoPath',
  );
  late final GeneratedColumn<String> photoPath = GeneratedColumn<String>(
    'photo_path',
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
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    model,
    category,
    unit,
    photoPath,
    retailPrice,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogData> instance, {
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
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    }
    if (data.containsKey('photo_path')) {
      context.handle(
        _photoPathMeta,
        photoPath.isAcceptableOrUnknown(data['photo_path']!, _photoPathMeta),
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
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogData(
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
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  Catalog createAlias(String alias) {
    return Catalog(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatalogData extends DataClass implements Insertable<CatalogData> {
  final String? id;
  final String name;
  final String? model;
  final String? category;
  final String unit;
  final String? photoPath;
  final int? retailPrice;
  final String updatedAt;
  const CatalogData({
    this.id,
    required this.name,
    this.model,
    this.category,
    required this.unit,
    this.photoPath,
    this.retailPrice,
    required this.updatedAt,
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
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['unit'] = Variable<String>(unit);
    if (!nullToAbsent || photoPath != null) {
      map['photo_path'] = Variable<String>(photoPath);
    }
    if (!nullToAbsent || retailPrice != null) {
      map['retail_price'] = Variable<int>(retailPrice);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  CatalogCompanion toCompanion(bool nullToAbsent) {
    return CatalogCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      unit: Value(unit),
      photoPath: photoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(photoPath),
      retailPrice: retailPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(retailPrice),
      updatedAt: Value(updatedAt),
    );
  }

  factory CatalogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogData(
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      model: serializer.fromJson<String?>(json['model']),
      category: serializer.fromJson<String?>(json['category']),
      unit: serializer.fromJson<String>(json['unit']),
      photoPath: serializer.fromJson<String?>(json['photo_path']),
      retailPrice: serializer.fromJson<int?>(json['retail_price']),
      updatedAt: serializer.fromJson<String>(json['updated_at']),
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
      'updated_at': serializer.toJson<String>(updatedAt),
    };
  }

  CatalogData copyWith({
    Value<String?> id = const Value.absent(),
    String? name,
    Value<String?> model = const Value.absent(),
    Value<String?> category = const Value.absent(),
    String? unit,
    Value<String?> photoPath = const Value.absent(),
    Value<int?> retailPrice = const Value.absent(),
    String? updatedAt,
  }) => CatalogData(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    model: model.present ? model.value : this.model,
    category: category.present ? category.value : this.category,
    unit: unit ?? this.unit,
    photoPath: photoPath.present ? photoPath.value : this.photoPath,
    retailPrice: retailPrice.present ? retailPrice.value : this.retailPrice,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CatalogData copyWithCompanion(CatalogCompanion data) {
    return CatalogData(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      model: data.model.present ? data.model.value : this.model,
      category: data.category.present ? data.category.value : this.category,
      unit: data.unit.present ? data.unit.value : this.unit,
      photoPath: data.photoPath.present ? data.photoPath.value : this.photoPath,
      retailPrice: data.retailPrice.present
          ? data.retailPrice.value
          : this.retailPrice,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogData(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('photoPath: $photoPath, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('updatedAt: $updatedAt')
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
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogData &&
          other.id == this.id &&
          other.name == this.name &&
          other.model == this.model &&
          other.category == this.category &&
          other.unit == this.unit &&
          other.photoPath == this.photoPath &&
          other.retailPrice == this.retailPrice &&
          other.updatedAt == this.updatedAt);
}

class CatalogCompanion extends UpdateCompanion<CatalogData> {
  final Value<String?> id;
  final Value<String> name;
  final Value<String?> model;
  final Value<String?> category;
  final Value<String> unit;
  final Value<String?> photoPath;
  final Value<int?> retailPrice;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const CatalogCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.model = const Value.absent(),
    this.category = const Value.absent(),
    this.unit = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.retailPrice = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.model = const Value.absent(),
    this.category = const Value.absent(),
    this.unit = const Value.absent(),
    this.photoPath = const Value.absent(),
    this.retailPrice = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       updatedAt = Value(updatedAt);
  static Insertable<CatalogData> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? model,
    Expression<String>? category,
    Expression<String>? unit,
    Expression<String>? photoPath,
    Expression<int>? retailPrice,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (model != null) 'model': model,
      if (category != null) 'category': category,
      if (unit != null) 'unit': unit,
      if (photoPath != null) 'photo_path': photoPath,
      if (retailPrice != null) 'retail_price': retailPrice,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogCompanion copyWith({
    Value<String?>? id,
    Value<String>? name,
    Value<String?>? model,
    Value<String?>? category,
    Value<String>? unit,
    Value<String?>? photoPath,
    Value<int?>? retailPrice,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return CatalogCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      model: model ?? this.model,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      photoPath: photoPath ?? this.photoPath,
      retailPrice: retailPrice ?? this.retailPrice,
      updatedAt: updatedAt ?? this.updatedAt,
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
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (photoPath.present) {
      map['photo_path'] = Variable<String>(photoPath.value);
    }
    if (retailPrice.present) {
      map['retail_price'] = Variable<int>(retailPrice.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('category: $category, ')
          ..write('unit: $unit, ')
          ..write('photoPath: $photoPath, ')
          ..write('retailPrice: $retailPrice, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatalogSearch extends Table
    with
        TableInfo<CatalogSearch, CatalogSearchData>,
        VirtualTableInfo<CatalogSearch, CatalogSearchData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatalogSearch(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [name, model, category];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_search';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogSearchData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
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
    } else if (isInserting) {
      context.missing(_modelMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  CatalogSearchData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogSearchData(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
    );
  }

  @override
  CatalogSearch createAlias(String alias) {
    return CatalogSearch(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(name, model, category, content=\'catalog\', content_rowid=\'rowid\', tokenize = \'unicode61 remove_diacritics 2\')';
}

class CatalogSearchData extends DataClass
    implements Insertable<CatalogSearchData> {
  final String name;
  final String model;
  final String category;
  const CatalogSearchData({
    required this.name,
    required this.model,
    required this.category,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['model'] = Variable<String>(model);
    map['category'] = Variable<String>(category);
    return map;
  }

  CatalogSearchCompanion toCompanion(bool nullToAbsent) {
    return CatalogSearchCompanion(
      name: Value(name),
      model: Value(model),
      category: Value(category),
    );
  }

  factory CatalogSearchData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogSearchData(
      name: serializer.fromJson<String>(json['name']),
      model: serializer.fromJson<String>(json['model']),
      category: serializer.fromJson<String>(json['category']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'model': serializer.toJson<String>(model),
      'category': serializer.toJson<String>(category),
    };
  }

  CatalogSearchData copyWith({String? name, String? model, String? category}) =>
      CatalogSearchData(
        name: name ?? this.name,
        model: model ?? this.model,
        category: category ?? this.category,
      );
  CatalogSearchData copyWithCompanion(CatalogSearchCompanion data) {
    return CatalogSearchData(
      name: data.name.present ? data.name.value : this.name,
      model: data.model.present ? data.model.value : this.model,
      category: data.category.present ? data.category.value : this.category,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogSearchData(')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('category: $category')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, model, category);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogSearchData &&
          other.name == this.name &&
          other.model == this.model &&
          other.category == this.category);
}

class CatalogSearchCompanion extends UpdateCompanion<CatalogSearchData> {
  final Value<String> name;
  final Value<String> model;
  final Value<String> category;
  final Value<int> rowid;
  const CatalogSearchCompanion({
    this.name = const Value.absent(),
    this.model = const Value.absent(),
    this.category = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogSearchCompanion.insert({
    required String name,
    required String model,
    required String category,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       model = Value(model),
       category = Value(category);
  static Insertable<CatalogSearchData> custom({
    Expression<String>? name,
    Expression<String>? model,
    Expression<String>? category,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (model != null) 'model': model,
      if (category != null) 'category': category,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogSearchCompanion copyWith({
    Value<String>? name,
    Value<String>? model,
    Value<String>? category,
    Value<int>? rowid,
  }) {
    return CatalogSearchCompanion(
      name: name ?? this.name,
      model: model ?? this.model,
      category: category ?? this.category,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogSearchCompanion(')
          ..write('name: $name, ')
          ..write('model: $model, ')
          ..write('category: $category, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$EmployeeDatabase extends GeneratedDatabase {
  _$EmployeeDatabase(QueryExecutor e) : super(e);
  $EmployeeDatabaseManager get managers => $EmployeeDatabaseManager(this);
  late final Catalog catalog = Catalog(this);
  late final CatalogSearch catalogSearch = CatalogSearch(this);
  late final Trigger catalogAi = Trigger(
    'CREATE TRIGGER catalog_ai AFTER INSERT ON catalog BEGIN INSERT INTO catalog_search ("rowid", name, model, category) VALUES (NEW."rowid", NEW.name, NEW.model, NEW.category);END',
    'catalog_ai',
  );
  late final Trigger catalogAd = Trigger(
    'CREATE TRIGGER catalog_ad AFTER DELETE ON catalog BEGIN INSERT INTO catalog_search (catalog_search, "rowid", name, model, category) VALUES (\'delete\', OLD."rowid", OLD.name, OLD.model, OLD.category);END',
    'catalog_ad',
  );
  late final Trigger catalogAu = Trigger(
    'CREATE TRIGGER catalog_au AFTER UPDATE ON catalog BEGIN INSERT INTO catalog_search (catalog_search, "rowid", name, model, category) VALUES (\'delete\', OLD."rowid", OLD.name, OLD.model, OLD.category);INSERT INTO catalog_search ("rowid", name, model, category) VALUES (NEW."rowid", NEW.name, NEW.model, NEW.category);END',
    'catalog_au',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    catalog,
    catalogSearch,
    catalogAi,
    catalogAd,
    catalogAu,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'catalog',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('catalog_search', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'catalog',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('catalog_search', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'catalog',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('catalog_search', kind: UpdateKind.insert)],
    ),
  ]);
}

typedef $CatalogCreateCompanionBuilder = CatalogCompanion Function({
  Value<String?> id,
  required String name,
  Value<String?> model,
  Value<String?> category,
  Value<String> unit,
  Value<String?> photoPath,
  Value<int?> retailPrice,
  required String updatedAt,
  Value<int> rowid,
});
typedef $CatalogUpdateCompanionBuilder = CatalogCompanion Function({
  Value<String?> id,
  Value<String> name,
  Value<String?> model,
  Value<String?> category,
  Value<String> unit,
  Value<String?> photoPath,
  Value<int?> retailPrice,
  Value<String> updatedAt,
  Value<int> rowid,
});

class $CatalogFilterComposer extends Composer<_$EmployeeDatabase, Catalog> {
  $CatalogFilterComposer({
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

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $CatalogOrderingComposer extends Composer<_$EmployeeDatabase, Catalog> {
  $CatalogOrderingComposer({
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

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoPath => $composableBuilder(
    column: $table.photoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatalogAnnotationComposer extends Composer<_$EmployeeDatabase, Catalog> {
  $CatalogAnnotationComposer({
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

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<String> get photoPath =>
      $composableBuilder(column: $table.photoPath, builder: (column) => column);

  GeneratedColumn<int> get retailPrice => $composableBuilder(
    column: $table.retailPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $CatalogTableManager
    extends
        RootTableManager<
          _$EmployeeDatabase,
          Catalog,
          CatalogData,
          $CatalogFilterComposer,
          $CatalogOrderingComposer,
          $CatalogAnnotationComposer,
          $CatalogCreateCompanionBuilder,
          $CatalogUpdateCompanionBuilder,
          (
            CatalogData,
            BaseReferences<_$EmployeeDatabase, Catalog, CatalogData>,
          ),
          CatalogData,
          PrefetchHooks Function()
        > {
  $CatalogTableManager(_$EmployeeDatabase db, Catalog table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatalogFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatalogOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatalogAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> model = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int?> retailPrice = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogCompanion(
                id: id,
                name: name,
                model: model,
                category: category,
                unit: unit,
                photoPath: photoPath,
                retailPrice: retailPrice,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String name,
                Value<String?> model = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<String?> photoPath = const Value.absent(),
                Value<int?> retailPrice = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CatalogCompanion.insert(
                id: id,
                name: name,
                model: model,
                category: category,
                unit: unit,
                photoPath: photoPath,
                retailPrice: retailPrice,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<Catalog, CatalogData>(table),
                  BaseReferences<_$EmployeeDatabase, Catalog, CatalogData>(
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

typedef $CatalogProcessedTableManager =
    ProcessedTableManager<
      _$EmployeeDatabase,
      Catalog,
      CatalogData,
      $CatalogFilterComposer,
      $CatalogOrderingComposer,
      $CatalogAnnotationComposer,
      $CatalogCreateCompanionBuilder,
      $CatalogUpdateCompanionBuilder,
      (CatalogData, BaseReferences<_$EmployeeDatabase, Catalog, CatalogData>),
      CatalogData,
      PrefetchHooks Function()
    >;
typedef $CatalogSearchCreateCompanionBuilder = CatalogSearchCompanion Function({
  required String name,
  required String model,
  required String category,
  Value<int> rowid,
});
typedef $CatalogSearchUpdateCompanionBuilder = CatalogSearchCompanion Function({
  Value<String> name,
  Value<String> model,
  Value<String> category,
  Value<int> rowid,
});

class $CatalogSearchFilterComposer
    extends Composer<_$EmployeeDatabase, CatalogSearch> {
  $CatalogSearchFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );
}

class $CatalogSearchOrderingComposer
    extends Composer<_$EmployeeDatabase, CatalogSearch> {
  $CatalogSearchOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatalogSearchAnnotationComposer
    extends Composer<_$EmployeeDatabase, CatalogSearch> {
  $CatalogSearchAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);
}

class $CatalogSearchTableManager
    extends
        RootTableManager<
          _$EmployeeDatabase,
          CatalogSearch,
          CatalogSearchData,
          $CatalogSearchFilterComposer,
          $CatalogSearchOrderingComposer,
          $CatalogSearchAnnotationComposer,
          $CatalogSearchCreateCompanionBuilder,
          $CatalogSearchUpdateCompanionBuilder,
          (
            CatalogSearchData,
            BaseReferences<
              _$EmployeeDatabase,
              CatalogSearch,
              CatalogSearchData
            >,
          ),
          CatalogSearchData,
          PrefetchHooks Function()
        > {
  $CatalogSearchTableManager(_$EmployeeDatabase db, CatalogSearch table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatalogSearchFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatalogSearchOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatalogSearchAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> model = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogSearchCompanion(
                name: name,
                model: model,
                category: category,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String model,
                required String category,
                Value<int> rowid = const Value.absent(),
              }) => CatalogSearchCompanion.insert(
                name: name,
                model: model,
                category: category,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<CatalogSearch, CatalogSearchData>(table),
                  BaseReferences<
                    _$EmployeeDatabase,
                    CatalogSearch,
                    CatalogSearchData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CatalogSearchProcessedTableManager =
    ProcessedTableManager<
      _$EmployeeDatabase,
      CatalogSearch,
      CatalogSearchData,
      $CatalogSearchFilterComposer,
      $CatalogSearchOrderingComposer,
      $CatalogSearchAnnotationComposer,
      $CatalogSearchCreateCompanionBuilder,
      $CatalogSearchUpdateCompanionBuilder,
      (
        CatalogSearchData,
        BaseReferences<_$EmployeeDatabase, CatalogSearch, CatalogSearchData>,
      ),
      CatalogSearchData,
      PrefetchHooks Function()
    >;

class $EmployeeDatabaseManager {
  final _$EmployeeDatabase _db;
  $EmployeeDatabaseManager(this._db);
  $CatalogTableManager get catalog => $CatalogTableManager(_db, _db.catalog);
  $CatalogSearchTableManager get catalogSearch =>
      $CatalogSearchTableManager(_db, _db.catalogSearch);
}
