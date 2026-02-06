// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ProductosTable extends Productos
    with TableInfo<$ProductosTable, Producto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoriaMeta = const VerificationMeta(
    'categoria',
  );
  @override
  late final GeneratedColumn<String> categoria = GeneratedColumn<String>(
    'categoria',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _referenciaMeta = const VerificationMeta(
    'referencia',
  );
  @override
  late final GeneratedColumn<String> referencia = GeneratedColumn<String>(
    'referencia',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precio20Meta = const VerificationMeta(
    'precio20',
  );
  @override
  late final GeneratedColumn<double> precio20 = GeneratedColumn<double>(
    'precio20',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pvpMeta = const VerificationMeta('pvp');
  @override
  late final GeneratedColumn<double> pvp = GeneratedColumn<double>(
    'pvp',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nombre,
    categoria,
    codigo,
    referencia,
    precio20,
    pvp,
    fecha,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Producto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('categoria')) {
      context.handle(
        _categoriaMeta,
        categoria.isAcceptableOrUnknown(data['categoria']!, _categoriaMeta),
      );
    } else if (isInserting) {
      context.missing(_categoriaMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('referencia')) {
      context.handle(
        _referenciaMeta,
        referencia.isAcceptableOrUnknown(data['referencia']!, _referenciaMeta),
      );
    } else if (isInserting) {
      context.missing(_referenciaMeta);
    }
    if (data.containsKey('precio20')) {
      context.handle(
        _precio20Meta,
        precio20.isAcceptableOrUnknown(data['precio20']!, _precio20Meta),
      );
    } else if (isInserting) {
      context.missing(_precio20Meta);
    }
    if (data.containsKey('pvp')) {
      context.handle(
        _pvpMeta,
        pvp.isAcceptableOrUnknown(data['pvp']!, _pvpMeta),
      );
    } else if (isInserting) {
      context.missing(_pvpMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Producto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Producto(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      nombre:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nombre'],
          )!,
      categoria:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}categoria'],
          )!,
      codigo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}codigo'],
          )!,
      referencia:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}referencia'],
          )!,
      precio20:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}precio20'],
          )!,
      pvp:
          attachedDatabase.typeMapping.read(
            DriftSqlType.double,
            data['${effectivePrefix}pvp'],
          )!,
      fecha:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}fecha'],
          )!,
    );
  }

  @override
  $ProductosTable createAlias(String alias) {
    return $ProductosTable(attachedDatabase, alias);
  }
}

class Producto extends DataClass implements Insertable<Producto> {
  final String id;
  final String nombre;
  final String categoria;
  final String codigo;
  final String referencia;
  final double precio20;
  final double pvp;
  final String fecha;
  const Producto({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.codigo,
    required this.referencia,
    required this.precio20,
    required this.pvp,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['categoria'] = Variable<String>(categoria);
    map['codigo'] = Variable<String>(codigo);
    map['referencia'] = Variable<String>(referencia);
    map['precio20'] = Variable<double>(precio20);
    map['pvp'] = Variable<double>(pvp);
    map['fecha'] = Variable<String>(fecha);
    return map;
  }

  ProductosCompanion toCompanion(bool nullToAbsent) {
    return ProductosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      categoria: Value(categoria),
      codigo: Value(codigo),
      referencia: Value(referencia),
      precio20: Value(precio20),
      pvp: Value(pvp),
      fecha: Value(fecha),
    );
  }

  factory Producto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Producto(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      categoria: serializer.fromJson<String>(json['categoria']),
      codigo: serializer.fromJson<String>(json['codigo']),
      referencia: serializer.fromJson<String>(json['referencia']),
      precio20: serializer.fromJson<double>(json['precio20']),
      pvp: serializer.fromJson<double>(json['pvp']),
      fecha: serializer.fromJson<String>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'categoria': serializer.toJson<String>(categoria),
      'codigo': serializer.toJson<String>(codigo),
      'referencia': serializer.toJson<String>(referencia),
      'precio20': serializer.toJson<double>(precio20),
      'pvp': serializer.toJson<double>(pvp),
      'fecha': serializer.toJson<String>(fecha),
    };
  }

  Producto copyWith({
    String? id,
    String? nombre,
    String? categoria,
    String? codigo,
    String? referencia,
    double? precio20,
    double? pvp,
    String? fecha,
  }) => Producto(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    categoria: categoria ?? this.categoria,
    codigo: codigo ?? this.codigo,
    referencia: referencia ?? this.referencia,
    precio20: precio20 ?? this.precio20,
    pvp: pvp ?? this.pvp,
    fecha: fecha ?? this.fecha,
  );
  Producto copyWithCompanion(ProductosCompanion data) {
    return Producto(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      categoria: data.categoria.present ? data.categoria.value : this.categoria,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      referencia:
          data.referencia.present ? data.referencia.value : this.referencia,
      precio20: data.precio20.present ? data.precio20.value : this.precio20,
      pvp: data.pvp.present ? data.pvp.value : this.pvp,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Producto(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('codigo: $codigo, ')
          ..write('referencia: $referencia, ')
          ..write('precio20: $precio20, ')
          ..write('pvp: $pvp, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nombre,
    categoria,
    codigo,
    referencia,
    precio20,
    pvp,
    fecha,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Producto &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.categoria == this.categoria &&
          other.codigo == this.codigo &&
          other.referencia == this.referencia &&
          other.precio20 == this.precio20 &&
          other.pvp == this.pvp &&
          other.fecha == this.fecha);
}

class ProductosCompanion extends UpdateCompanion<Producto> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> categoria;
  final Value<String> codigo;
  final Value<String> referencia;
  final Value<double> precio20;
  final Value<double> pvp;
  final Value<String> fecha;
  final Value<int> rowid;
  const ProductosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.categoria = const Value.absent(),
    this.codigo = const Value.absent(),
    this.referencia = const Value.absent(),
    this.precio20 = const Value.absent(),
    this.pvp = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductosCompanion.insert({
    required String id,
    required String nombre,
    required String categoria,
    required String codigo,
    required String referencia,
    required double precio20,
    required double pvp,
    required String fecha,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       categoria = Value(categoria),
       codigo = Value(codigo),
       referencia = Value(referencia),
       precio20 = Value(precio20),
       pvp = Value(pvp),
       fecha = Value(fecha);
  static Insertable<Producto> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? categoria,
    Expression<String>? codigo,
    Expression<String>? referencia,
    Expression<double>? precio20,
    Expression<double>? pvp,
    Expression<String>? fecha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (categoria != null) 'categoria': categoria,
      if (codigo != null) 'codigo': codigo,
      if (referencia != null) 'referencia': referencia,
      if (precio20 != null) 'precio20': precio20,
      if (pvp != null) 'pvp': pvp,
      if (fecha != null) 'fecha': fecha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductosCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? categoria,
    Value<String>? codigo,
    Value<String>? referencia,
    Value<double>? precio20,
    Value<double>? pvp,
    Value<String>? fecha,
    Value<int>? rowid,
  }) {
    return ProductosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      codigo: codigo ?? this.codigo,
      referencia: referencia ?? this.referencia,
      precio20: precio20 ?? this.precio20,
      pvp: pvp ?? this.pvp,
      fecha: fecha ?? this.fecha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (categoria.present) {
      map['categoria'] = Variable<String>(categoria.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (referencia.present) {
      map['referencia'] = Variable<String>(referencia.value);
    }
    if (precio20.present) {
      map['precio20'] = Variable<double>(precio20.value);
    }
    if (pvp.present) {
      map['pvp'] = Variable<double>(pvp.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('categoria: $categoria, ')
          ..write('codigo: $codigo, ')
          ..write('referencia: $referencia, ')
          ..write('precio20: $precio20, ')
          ..write('pvp: $pvp, ')
          ..write('fecha: $fecha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriasTable extends Categorias
    with TableInfo<$CategoriasTable, Categoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaCreacionMeta = const VerificationMeta(
    'fechaCreacion',
  );
  @override
  late final GeneratedColumn<String> fechaCreacion = GeneratedColumn<String>(
    'fecha_creacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, fechaCreacion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categorias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Categoria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('fecha_creacion')) {
      context.handle(
        _fechaCreacionMeta,
        fechaCreacion.isAcceptableOrUnknown(
          data['fecha_creacion']!,
          _fechaCreacionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaCreacionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Categoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Categoria(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      nombre:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nombre'],
          )!,
      fechaCreacion:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}fecha_creacion'],
          )!,
    );
  }

  @override
  $CategoriasTable createAlias(String alias) {
    return $CategoriasTable(attachedDatabase, alias);
  }
}

class Categoria extends DataClass implements Insertable<Categoria> {
  final String id;
  final String nombre;
  final String fechaCreacion;
  const Categoria({
    required this.id,
    required this.nombre,
    required this.fechaCreacion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['fecha_creacion'] = Variable<String>(fechaCreacion);
    return map;
  }

  CategoriasCompanion toCompanion(bool nullToAbsent) {
    return CategoriasCompanion(
      id: Value(id),
      nombre: Value(nombre),
      fechaCreacion: Value(fechaCreacion),
    );
  }

  factory Categoria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Categoria(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      fechaCreacion: serializer.fromJson<String>(json['fechaCreacion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'fechaCreacion': serializer.toJson<String>(fechaCreacion),
    };
  }

  Categoria copyWith({String? id, String? nombre, String? fechaCreacion}) =>
      Categoria(
        id: id ?? this.id,
        nombre: nombre ?? this.nombre,
        fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      );
  Categoria copyWithCompanion(CategoriasCompanion data) {
    return Categoria(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      fechaCreacion:
          data.fechaCreacion.present
              ? data.fechaCreacion.value
              : this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Categoria(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fechaCreacion: $fechaCreacion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, fechaCreacion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Categoria &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.fechaCreacion == this.fechaCreacion);
}

class CategoriasCompanion extends UpdateCompanion<Categoria> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<String> fechaCreacion;
  final Value<int> rowid;
  const CategoriasCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriasCompanion.insert({
    required String id,
    required String nombre,
    required String fechaCreacion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       fechaCreacion = Value(fechaCreacion);
  static Insertable<Categoria> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<String>? fechaCreacion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriasCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<String>? fechaCreacion,
    Value<int>? rowid,
  }) {
    return CategoriasCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (fechaCreacion.present) {
      map['fecha_creacion'] = Variable<String>(fechaCreacion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriasCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CatalogoInsumosTable extends CatalogoInsumos
    with TableInfo<$CatalogoInsumosTable, CatalogoInsumo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CatalogoInsumosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<int> activo = GeneratedColumn<int>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaCreacionMeta = const VerificationMeta(
    'fechaCreacion',
  );
  @override
  late final GeneratedColumn<String> fechaCreacion = GeneratedColumn<String>(
    'fecha_creacion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nombre, activo, fechaCreacion];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalogo_insumos';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogoInsumo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    } else if (isInserting) {
      context.missing(_activoMeta);
    }
    if (data.containsKey('fecha_creacion')) {
      context.handle(
        _fechaCreacionMeta,
        fechaCreacion.isAcceptableOrUnknown(
          data['fecha_creacion']!,
          _fechaCreacionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fechaCreacionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogoInsumo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogoInsumo(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      nombre:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nombre'],
          )!,
      activo:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}activo'],
          )!,
      fechaCreacion:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}fecha_creacion'],
          )!,
    );
  }

  @override
  $CatalogoInsumosTable createAlias(String alias) {
    return $CatalogoInsumosTable(attachedDatabase, alias);
  }
}

class CatalogoInsumo extends DataClass implements Insertable<CatalogoInsumo> {
  final String id;
  final String nombre;
  final int activo;
  final String fechaCreacion;
  const CatalogoInsumo({
    required this.id,
    required this.nombre,
    required this.activo,
    required this.fechaCreacion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nombre'] = Variable<String>(nombre);
    map['activo'] = Variable<int>(activo);
    map['fecha_creacion'] = Variable<String>(fechaCreacion);
    return map;
  }

  CatalogoInsumosCompanion toCompanion(bool nullToAbsent) {
    return CatalogoInsumosCompanion(
      id: Value(id),
      nombre: Value(nombre),
      activo: Value(activo),
      fechaCreacion: Value(fechaCreacion),
    );
  }

  factory CatalogoInsumo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogoInsumo(
      id: serializer.fromJson<String>(json['id']),
      nombre: serializer.fromJson<String>(json['nombre']),
      activo: serializer.fromJson<int>(json['activo']),
      fechaCreacion: serializer.fromJson<String>(json['fechaCreacion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nombre': serializer.toJson<String>(nombre),
      'activo': serializer.toJson<int>(activo),
      'fechaCreacion': serializer.toJson<String>(fechaCreacion),
    };
  }

  CatalogoInsumo copyWith({
    String? id,
    String? nombre,
    int? activo,
    String? fechaCreacion,
  }) => CatalogoInsumo(
    id: id ?? this.id,
    nombre: nombre ?? this.nombre,
    activo: activo ?? this.activo,
    fechaCreacion: fechaCreacion ?? this.fechaCreacion,
  );
  CatalogoInsumo copyWithCompanion(CatalogoInsumosCompanion data) {
    return CatalogoInsumo(
      id: data.id.present ? data.id.value : this.id,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      activo: data.activo.present ? data.activo.value : this.activo,
      fechaCreacion:
          data.fechaCreacion.present
              ? data.fechaCreacion.value
              : this.fechaCreacion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogoInsumo(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('activo: $activo, ')
          ..write('fechaCreacion: $fechaCreacion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, nombre, activo, fechaCreacion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogoInsumo &&
          other.id == this.id &&
          other.nombre == this.nombre &&
          other.activo == this.activo &&
          other.fechaCreacion == this.fechaCreacion);
}

class CatalogoInsumosCompanion extends UpdateCompanion<CatalogoInsumo> {
  final Value<String> id;
  final Value<String> nombre;
  final Value<int> activo;
  final Value<String> fechaCreacion;
  final Value<int> rowid;
  const CatalogoInsumosCompanion({
    this.id = const Value.absent(),
    this.nombre = const Value.absent(),
    this.activo = const Value.absent(),
    this.fechaCreacion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CatalogoInsumosCompanion.insert({
    required String id,
    required String nombre,
    required int activo,
    required String fechaCreacion,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nombre = Value(nombre),
       activo = Value(activo),
       fechaCreacion = Value(fechaCreacion);
  static Insertable<CatalogoInsumo> custom({
    Expression<String>? id,
    Expression<String>? nombre,
    Expression<int>? activo,
    Expression<String>? fechaCreacion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nombre != null) 'nombre': nombre,
      if (activo != null) 'activo': activo,
      if (fechaCreacion != null) 'fecha_creacion': fechaCreacion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CatalogoInsumosCompanion copyWith({
    Value<String>? id,
    Value<String>? nombre,
    Value<int>? activo,
    Value<String>? fechaCreacion,
    Value<int>? rowid,
  }) {
    return CatalogoInsumosCompanion(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (activo.present) {
      map['activo'] = Variable<int>(activo.value);
    }
    if (fechaCreacion.present) {
      map['fecha_creacion'] = Variable<String>(fechaCreacion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogoInsumosCompanion(')
          ..write('id: $id, ')
          ..write('nombre: $nombre, ')
          ..write('activo: $activo, ')
          ..write('fechaCreacion: $fechaCreacion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InventarioInsumosTable extends InventarioInsumos
    with TableInfo<$InventarioInsumosTable, InventarioInsumo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InventarioInsumosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _catalogoIdMeta = const VerificationMeta(
    'catalogoId',
  );
  @override
  late final GeneratedColumn<String> catalogoId = GeneratedColumn<String>(
    'catalogo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
    'cantidad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    catalogoId,
    nombre,
    cantidad,
    fecha,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inventario_insumos';
  @override
  VerificationContext validateIntegrity(
    Insertable<InventarioInsumo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('catalogo_id')) {
      context.handle(
        _catalogoIdMeta,
        catalogoId.isAcceptableOrUnknown(data['catalogo_id']!, _catalogoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_catalogoIdMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InventarioInsumo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InventarioInsumo(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      catalogoId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}catalogo_id'],
          )!,
      nombre:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}nombre'],
          )!,
      cantidad:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}cantidad'],
          )!,
      fecha:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}fecha'],
          )!,
    );
  }

  @override
  $InventarioInsumosTable createAlias(String alias) {
    return $InventarioInsumosTable(attachedDatabase, alias);
  }
}

class InventarioInsumo extends DataClass
    implements Insertable<InventarioInsumo> {
  final String id;
  final String catalogoId;
  final String nombre;
  final int cantidad;
  final String fecha;
  const InventarioInsumo({
    required this.id,
    required this.catalogoId,
    required this.nombre,
    required this.cantidad,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['catalogo_id'] = Variable<String>(catalogoId);
    map['nombre'] = Variable<String>(nombre);
    map['cantidad'] = Variable<int>(cantidad);
    map['fecha'] = Variable<String>(fecha);
    return map;
  }

  InventarioInsumosCompanion toCompanion(bool nullToAbsent) {
    return InventarioInsumosCompanion(
      id: Value(id),
      catalogoId: Value(catalogoId),
      nombre: Value(nombre),
      cantidad: Value(cantidad),
      fecha: Value(fecha),
    );
  }

  factory InventarioInsumo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InventarioInsumo(
      id: serializer.fromJson<String>(json['id']),
      catalogoId: serializer.fromJson<String>(json['catalogoId']),
      nombre: serializer.fromJson<String>(json['nombre']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
      fecha: serializer.fromJson<String>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'catalogoId': serializer.toJson<String>(catalogoId),
      'nombre': serializer.toJson<String>(nombre),
      'cantidad': serializer.toJson<int>(cantidad),
      'fecha': serializer.toJson<String>(fecha),
    };
  }

  InventarioInsumo copyWith({
    String? id,
    String? catalogoId,
    String? nombre,
    int? cantidad,
    String? fecha,
  }) => InventarioInsumo(
    id: id ?? this.id,
    catalogoId: catalogoId ?? this.catalogoId,
    nombre: nombre ?? this.nombre,
    cantidad: cantidad ?? this.cantidad,
    fecha: fecha ?? this.fecha,
  );
  InventarioInsumo copyWithCompanion(InventarioInsumosCompanion data) {
    return InventarioInsumo(
      id: data.id.present ? data.id.value : this.id,
      catalogoId:
          data.catalogoId.present ? data.catalogoId.value : this.catalogoId,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InventarioInsumo(')
          ..write('id: $id, ')
          ..write('catalogoId: $catalogoId, ')
          ..write('nombre: $nombre, ')
          ..write('cantidad: $cantidad, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, catalogoId, nombre, cantidad, fecha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InventarioInsumo &&
          other.id == this.id &&
          other.catalogoId == this.catalogoId &&
          other.nombre == this.nombre &&
          other.cantidad == this.cantidad &&
          other.fecha == this.fecha);
}

class InventarioInsumosCompanion extends UpdateCompanion<InventarioInsumo> {
  final Value<String> id;
  final Value<String> catalogoId;
  final Value<String> nombre;
  final Value<int> cantidad;
  final Value<String> fecha;
  final Value<int> rowid;
  const InventarioInsumosCompanion({
    this.id = const Value.absent(),
    this.catalogoId = const Value.absent(),
    this.nombre = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InventarioInsumosCompanion.insert({
    required String id,
    required String catalogoId,
    required String nombre,
    required int cantidad,
    required String fecha,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       catalogoId = Value(catalogoId),
       nombre = Value(nombre),
       cantidad = Value(cantidad),
       fecha = Value(fecha);
  static Insertable<InventarioInsumo> custom({
    Expression<String>? id,
    Expression<String>? catalogoId,
    Expression<String>? nombre,
    Expression<int>? cantidad,
    Expression<String>? fecha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (catalogoId != null) 'catalogo_id': catalogoId,
      if (nombre != null) 'nombre': nombre,
      if (cantidad != null) 'cantidad': cantidad,
      if (fecha != null) 'fecha': fecha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InventarioInsumosCompanion copyWith({
    Value<String>? id,
    Value<String>? catalogoId,
    Value<String>? nombre,
    Value<int>? cantidad,
    Value<String>? fecha,
    Value<int>? rowid,
  }) {
    return InventarioInsumosCompanion(
      id: id ?? this.id,
      catalogoId: catalogoId ?? this.catalogoId,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      fecha: fecha ?? this.fecha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (catalogoId.present) {
      map['catalogo_id'] = Variable<String>(catalogoId.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<int>(cantidad.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InventarioInsumosCompanion(')
          ..write('id: $id, ')
          ..write('catalogoId: $catalogoId, ')
          ..write('nombre: $nombre, ')
          ..write('cantidad: $cantidad, ')
          ..write('fecha: $fecha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SolicitudesInsumosTable extends SolicitudesInsumos
    with TableInfo<$SolicitudesInsumosTable, SolicitudesInsumo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SolicitudesInsumosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empleadoIdMeta = const VerificationMeta(
    'empleadoId',
  );
  @override
  late final GeneratedColumn<String> empleadoId = GeneratedColumn<String>(
    'empleado_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empleadoNombreMeta = const VerificationMeta(
    'empleadoNombre',
  );
  @override
  late final GeneratedColumn<String> empleadoNombre = GeneratedColumn<String>(
    'empleado_nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _insumoIdMeta = const VerificationMeta(
    'insumoId',
  );
  @override
  late final GeneratedColumn<String> insumoId = GeneratedColumn<String>(
    'insumo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
    'cantidad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<String> fecha = GeneratedColumn<String>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    empleadoId,
    empleadoNombre,
    insumoId,
    cantidad,
    fecha,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'solicitudes_insumos';
  @override
  VerificationContext validateIntegrity(
    Insertable<SolicitudesInsumo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('empleado_id')) {
      context.handle(
        _empleadoIdMeta,
        empleadoId.isAcceptableOrUnknown(data['empleado_id']!, _empleadoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_empleadoIdMeta);
    }
    if (data.containsKey('empleado_nombre')) {
      context.handle(
        _empleadoNombreMeta,
        empleadoNombre.isAcceptableOrUnknown(
          data['empleado_nombre']!,
          _empleadoNombreMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_empleadoNombreMeta);
    }
    if (data.containsKey('insumo_id')) {
      context.handle(
        _insumoIdMeta,
        insumoId.isAcceptableOrUnknown(data['insumo_id']!, _insumoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_insumoIdMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SolicitudesInsumo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SolicitudesInsumo(
      id:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}id'],
          )!,
      empleadoId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}empleado_id'],
          )!,
      empleadoNombre:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}empleado_nombre'],
          )!,
      insumoId:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}insumo_id'],
          )!,
      cantidad:
          attachedDatabase.typeMapping.read(
            DriftSqlType.int,
            data['${effectivePrefix}cantidad'],
          )!,
      fecha:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}fecha'],
          )!,
    );
  }

  @override
  $SolicitudesInsumosTable createAlias(String alias) {
    return $SolicitudesInsumosTable(attachedDatabase, alias);
  }
}

class SolicitudesInsumo extends DataClass
    implements Insertable<SolicitudesInsumo> {
  final String id;
  final String empleadoId;
  final String empleadoNombre;
  final String insumoId;
  final int cantidad;
  final String fecha;
  const SolicitudesInsumo({
    required this.id,
    required this.empleadoId,
    required this.empleadoNombre,
    required this.insumoId,
    required this.cantidad,
    required this.fecha,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['empleado_id'] = Variable<String>(empleadoId);
    map['empleado_nombre'] = Variable<String>(empleadoNombre);
    map['insumo_id'] = Variable<String>(insumoId);
    map['cantidad'] = Variable<int>(cantidad);
    map['fecha'] = Variable<String>(fecha);
    return map;
  }

  SolicitudesInsumosCompanion toCompanion(bool nullToAbsent) {
    return SolicitudesInsumosCompanion(
      id: Value(id),
      empleadoId: Value(empleadoId),
      empleadoNombre: Value(empleadoNombre),
      insumoId: Value(insumoId),
      cantidad: Value(cantidad),
      fecha: Value(fecha),
    );
  }

  factory SolicitudesInsumo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SolicitudesInsumo(
      id: serializer.fromJson<String>(json['id']),
      empleadoId: serializer.fromJson<String>(json['empleadoId']),
      empleadoNombre: serializer.fromJson<String>(json['empleadoNombre']),
      insumoId: serializer.fromJson<String>(json['insumoId']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
      fecha: serializer.fromJson<String>(json['fecha']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'empleadoId': serializer.toJson<String>(empleadoId),
      'empleadoNombre': serializer.toJson<String>(empleadoNombre),
      'insumoId': serializer.toJson<String>(insumoId),
      'cantidad': serializer.toJson<int>(cantidad),
      'fecha': serializer.toJson<String>(fecha),
    };
  }

  SolicitudesInsumo copyWith({
    String? id,
    String? empleadoId,
    String? empleadoNombre,
    String? insumoId,
    int? cantidad,
    String? fecha,
  }) => SolicitudesInsumo(
    id: id ?? this.id,
    empleadoId: empleadoId ?? this.empleadoId,
    empleadoNombre: empleadoNombre ?? this.empleadoNombre,
    insumoId: insumoId ?? this.insumoId,
    cantidad: cantidad ?? this.cantidad,
    fecha: fecha ?? this.fecha,
  );
  SolicitudesInsumo copyWithCompanion(SolicitudesInsumosCompanion data) {
    return SolicitudesInsumo(
      id: data.id.present ? data.id.value : this.id,
      empleadoId:
          data.empleadoId.present ? data.empleadoId.value : this.empleadoId,
      empleadoNombre:
          data.empleadoNombre.present
              ? data.empleadoNombre.value
              : this.empleadoNombre,
      insumoId: data.insumoId.present ? data.insumoId.value : this.insumoId,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SolicitudesInsumo(')
          ..write('id: $id, ')
          ..write('empleadoId: $empleadoId, ')
          ..write('empleadoNombre: $empleadoNombre, ')
          ..write('insumoId: $insumoId, ')
          ..write('cantidad: $cantidad, ')
          ..write('fecha: $fecha')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, empleadoId, empleadoNombre, insumoId, cantidad, fecha);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SolicitudesInsumo &&
          other.id == this.id &&
          other.empleadoId == this.empleadoId &&
          other.empleadoNombre == this.empleadoNombre &&
          other.insumoId == this.insumoId &&
          other.cantidad == this.cantidad &&
          other.fecha == this.fecha);
}

class SolicitudesInsumosCompanion extends UpdateCompanion<SolicitudesInsumo> {
  final Value<String> id;
  final Value<String> empleadoId;
  final Value<String> empleadoNombre;
  final Value<String> insumoId;
  final Value<int> cantidad;
  final Value<String> fecha;
  final Value<int> rowid;
  const SolicitudesInsumosCompanion({
    this.id = const Value.absent(),
    this.empleadoId = const Value.absent(),
    this.empleadoNombre = const Value.absent(),
    this.insumoId = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.fecha = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SolicitudesInsumosCompanion.insert({
    required String id,
    required String empleadoId,
    required String empleadoNombre,
    required String insumoId,
    required int cantidad,
    required String fecha,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       empleadoId = Value(empleadoId),
       empleadoNombre = Value(empleadoNombre),
       insumoId = Value(insumoId),
       cantidad = Value(cantidad),
       fecha = Value(fecha);
  static Insertable<SolicitudesInsumo> custom({
    Expression<String>? id,
    Expression<String>? empleadoId,
    Expression<String>? empleadoNombre,
    Expression<String>? insumoId,
    Expression<int>? cantidad,
    Expression<String>? fecha,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (empleadoId != null) 'empleado_id': empleadoId,
      if (empleadoNombre != null) 'empleado_nombre': empleadoNombre,
      if (insumoId != null) 'insumo_id': insumoId,
      if (cantidad != null) 'cantidad': cantidad,
      if (fecha != null) 'fecha': fecha,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SolicitudesInsumosCompanion copyWith({
    Value<String>? id,
    Value<String>? empleadoId,
    Value<String>? empleadoNombre,
    Value<String>? insumoId,
    Value<int>? cantidad,
    Value<String>? fecha,
    Value<int>? rowid,
  }) {
    return SolicitudesInsumosCompanion(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      empleadoNombre: empleadoNombre ?? this.empleadoNombre,
      insumoId: insumoId ?? this.insumoId,
      cantidad: cantidad ?? this.cantidad,
      fecha: fecha ?? this.fecha,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (empleadoId.present) {
      map['empleado_id'] = Variable<String>(empleadoId.value);
    }
    if (empleadoNombre.present) {
      map['empleado_nombre'] = Variable<String>(empleadoNombre.value);
    }
    if (insumoId.present) {
      map['insumo_id'] = Variable<String>(insumoId.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<int>(cantidad.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<String>(fecha.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SolicitudesInsumosCompanion(')
          ..write('id: $id, ')
          ..write('empleadoId: $empleadoId, ')
          ..write('empleadoNombre: $empleadoNombre, ')
          ..write('insumoId: $insumoId, ')
          ..write('cantidad: $cantidad, ')
          ..write('fecha: $fecha, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncControlTable extends SyncControl
    with TableInfo<$SyncControlTable, SyncControlData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncControlTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tablaMeta = const VerificationMeta('tabla');
  @override
  late final GeneratedColumn<String> tabla = GeneratedColumn<String>(
    'tabla',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ultimaSyncMeta = const VerificationMeta(
    'ultimaSync',
  );
  @override
  late final GeneratedColumn<String> ultimaSync = GeneratedColumn<String>(
    'ultima_sync',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tabla, ultimaSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_control';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncControlData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('tabla')) {
      context.handle(
        _tablaMeta,
        tabla.isAcceptableOrUnknown(data['tabla']!, _tablaMeta),
      );
    } else if (isInserting) {
      context.missing(_tablaMeta);
    }
    if (data.containsKey('ultima_sync')) {
      context.handle(
        _ultimaSyncMeta,
        ultimaSync.isAcceptableOrUnknown(data['ultima_sync']!, _ultimaSyncMeta),
      );
    } else if (isInserting) {
      context.missing(_ultimaSyncMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tabla};
  @override
  SyncControlData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncControlData(
      tabla:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}tabla'],
          )!,
      ultimaSync:
          attachedDatabase.typeMapping.read(
            DriftSqlType.string,
            data['${effectivePrefix}ultima_sync'],
          )!,
    );
  }

  @override
  $SyncControlTable createAlias(String alias) {
    return $SyncControlTable(attachedDatabase, alias);
  }
}

class SyncControlData extends DataClass implements Insertable<SyncControlData> {
  final String tabla;
  final String ultimaSync;
  const SyncControlData({required this.tabla, required this.ultimaSync});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['tabla'] = Variable<String>(tabla);
    map['ultima_sync'] = Variable<String>(ultimaSync);
    return map;
  }

  SyncControlCompanion toCompanion(bool nullToAbsent) {
    return SyncControlCompanion(
      tabla: Value(tabla),
      ultimaSync: Value(ultimaSync),
    );
  }

  factory SyncControlData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncControlData(
      tabla: serializer.fromJson<String>(json['tabla']),
      ultimaSync: serializer.fromJson<String>(json['ultimaSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tabla': serializer.toJson<String>(tabla),
      'ultimaSync': serializer.toJson<String>(ultimaSync),
    };
  }

  SyncControlData copyWith({String? tabla, String? ultimaSync}) =>
      SyncControlData(
        tabla: tabla ?? this.tabla,
        ultimaSync: ultimaSync ?? this.ultimaSync,
      );
  SyncControlData copyWithCompanion(SyncControlCompanion data) {
    return SyncControlData(
      tabla: data.tabla.present ? data.tabla.value : this.tabla,
      ultimaSync:
          data.ultimaSync.present ? data.ultimaSync.value : this.ultimaSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncControlData(')
          ..write('tabla: $tabla, ')
          ..write('ultimaSync: $ultimaSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tabla, ultimaSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncControlData &&
          other.tabla == this.tabla &&
          other.ultimaSync == this.ultimaSync);
}

class SyncControlCompanion extends UpdateCompanion<SyncControlData> {
  final Value<String> tabla;
  final Value<String> ultimaSync;
  final Value<int> rowid;
  const SyncControlCompanion({
    this.tabla = const Value.absent(),
    this.ultimaSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncControlCompanion.insert({
    required String tabla,
    required String ultimaSync,
    this.rowid = const Value.absent(),
  }) : tabla = Value(tabla),
       ultimaSync = Value(ultimaSync);
  static Insertable<SyncControlData> custom({
    Expression<String>? tabla,
    Expression<String>? ultimaSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tabla != null) 'tabla': tabla,
      if (ultimaSync != null) 'ultima_sync': ultimaSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncControlCompanion copyWith({
    Value<String>? tabla,
    Value<String>? ultimaSync,
    Value<int>? rowid,
  }) {
    return SyncControlCompanion(
      tabla: tabla ?? this.tabla,
      ultimaSync: ultimaSync ?? this.ultimaSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tabla.present) {
      map['tabla'] = Variable<String>(tabla.value);
    }
    if (ultimaSync.present) {
      map['ultima_sync'] = Variable<String>(ultimaSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncControlCompanion(')
          ..write('tabla: $tabla, ')
          ..write('ultimaSync: $ultimaSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductosTable productos = $ProductosTable(this);
  late final $CategoriasTable categorias = $CategoriasTable(this);
  late final $CatalogoInsumosTable catalogoInsumos = $CatalogoInsumosTable(
    this,
  );
  late final $InventarioInsumosTable inventarioInsumos =
      $InventarioInsumosTable(this);
  late final $SolicitudesInsumosTable solicitudesInsumos =
      $SolicitudesInsumosTable(this);
  late final $SyncControlTable syncControl = $SyncControlTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    productos,
    categorias,
    catalogoInsumos,
    inventarioInsumos,
    solicitudesInsumos,
    syncControl,
  ];
}

typedef $$ProductosTableCreateCompanionBuilder =
    ProductosCompanion Function({
      required String id,
      required String nombre,
      required String categoria,
      required String codigo,
      required String referencia,
      required double precio20,
      required double pvp,
      required String fecha,
      Value<int> rowid,
    });
typedef $$ProductosTableUpdateCompanionBuilder =
    ProductosCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> categoria,
      Value<String> codigo,
      Value<String> referencia,
      Value<double> precio20,
      Value<double> pvp,
      Value<String> fecha,
      Value<int> rowid,
    });

class $$ProductosTableFilterComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableFilterComposer({
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

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get referencia => $composableBuilder(
    column: $table.referencia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get precio20 => $composableBuilder(
    column: $table.precio20,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pvp => $composableBuilder(
    column: $table.pvp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableOrderingComposer({
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

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoria => $composableBuilder(
    column: $table.categoria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get referencia => $composableBuilder(
    column: $table.referencia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get precio20 => $composableBuilder(
    column: $table.precio20,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pvp => $composableBuilder(
    column: $table.pvp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get categoria =>
      $composableBuilder(column: $table.categoria, builder: (column) => column);

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get referencia => $composableBuilder(
    column: $table.referencia,
    builder: (column) => column,
  );

  GeneratedColumn<double> get precio20 =>
      $composableBuilder(column: $table.precio20, builder: (column) => column);

  GeneratedColumn<double> get pvp =>
      $composableBuilder(column: $table.pvp, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);
}

class $$ProductosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductosTable,
          Producto,
          $$ProductosTableFilterComposer,
          $$ProductosTableOrderingComposer,
          $$ProductosTableAnnotationComposer,
          $$ProductosTableCreateCompanionBuilder,
          $$ProductosTableUpdateCompanionBuilder,
          (Producto, BaseReferences<_$AppDatabase, $ProductosTable, Producto>),
          Producto,
          PrefetchHooks Function()
        > {
  $$ProductosTableTableManager(_$AppDatabase db, $ProductosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$ProductosTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$ProductosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$ProductosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> categoria = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> referencia = const Value.absent(),
                Value<double> precio20 = const Value.absent(),
                Value<double> pvp = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion(
                id: id,
                nombre: nombre,
                categoria: categoria,
                codigo: codigo,
                referencia: referencia,
                precio20: precio20,
                pvp: pvp,
                fecha: fecha,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String categoria,
                required String codigo,
                required String referencia,
                required double precio20,
                required double pvp,
                required String fecha,
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion.insert(
                id: id,
                nombre: nombre,
                categoria: categoria,
                codigo: codigo,
                referencia: referencia,
                precio20: precio20,
                pvp: pvp,
                fecha: fecha,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductosTable,
      Producto,
      $$ProductosTableFilterComposer,
      $$ProductosTableOrderingComposer,
      $$ProductosTableAnnotationComposer,
      $$ProductosTableCreateCompanionBuilder,
      $$ProductosTableUpdateCompanionBuilder,
      (Producto, BaseReferences<_$AppDatabase, $ProductosTable, Producto>),
      Producto,
      PrefetchHooks Function()
    >;
typedef $$CategoriasTableCreateCompanionBuilder =
    CategoriasCompanion Function({
      required String id,
      required String nombre,
      required String fechaCreacion,
      Value<int> rowid,
    });
typedef $$CategoriasTableUpdateCompanionBuilder =
    CategoriasCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<String> fechaCreacion,
      Value<int> rowid,
    });

class $$CategoriasTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableFilterComposer({
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

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriasTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableOrderingComposer({
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

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => column,
  );
}

class $$CategoriasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriasTable,
          Categoria,
          $$CategoriasTableFilterComposer,
          $$CategoriasTableOrderingComposer,
          $$CategoriasTableAnnotationComposer,
          $$CategoriasTableCreateCompanionBuilder,
          $$CategoriasTableUpdateCompanionBuilder,
          (
            Categoria,
            BaseReferences<_$AppDatabase, $CategoriasTable, Categoria>,
          ),
          Categoria,
          PrefetchHooks Function()
        > {
  $$CategoriasTableTableManager(_$AppDatabase db, $CategoriasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$CategoriasTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CategoriasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () => $$CategoriasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> fechaCreacion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion(
                id: id,
                nombre: nombre,
                fechaCreacion: fechaCreacion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required String fechaCreacion,
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion.insert(
                id: id,
                nombre: nombre,
                fechaCreacion: fechaCreacion,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriasTable,
      Categoria,
      $$CategoriasTableFilterComposer,
      $$CategoriasTableOrderingComposer,
      $$CategoriasTableAnnotationComposer,
      $$CategoriasTableCreateCompanionBuilder,
      $$CategoriasTableUpdateCompanionBuilder,
      (Categoria, BaseReferences<_$AppDatabase, $CategoriasTable, Categoria>),
      Categoria,
      PrefetchHooks Function()
    >;
typedef $$CatalogoInsumosTableCreateCompanionBuilder =
    CatalogoInsumosCompanion Function({
      required String id,
      required String nombre,
      required int activo,
      required String fechaCreacion,
      Value<int> rowid,
    });
typedef $$CatalogoInsumosTableUpdateCompanionBuilder =
    CatalogoInsumosCompanion Function({
      Value<String> id,
      Value<String> nombre,
      Value<int> activo,
      Value<String> fechaCreacion,
      Value<int> rowid,
    });

class $$CatalogoInsumosTableFilterComposer
    extends Composer<_$AppDatabase, $CatalogoInsumosTable> {
  $$CatalogoInsumosTableFilterComposer({
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

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CatalogoInsumosTableOrderingComposer
    extends Composer<_$AppDatabase, $CatalogoInsumosTable> {
  $$CatalogoInsumosTableOrderingComposer({
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

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CatalogoInsumosTableAnnotationComposer
    extends Composer<_$AppDatabase, $CatalogoInsumosTable> {
  $$CatalogoInsumosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<String> get fechaCreacion => $composableBuilder(
    column: $table.fechaCreacion,
    builder: (column) => column,
  );
}

class $$CatalogoInsumosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CatalogoInsumosTable,
          CatalogoInsumo,
          $$CatalogoInsumosTableFilterComposer,
          $$CatalogoInsumosTableOrderingComposer,
          $$CatalogoInsumosTableAnnotationComposer,
          $$CatalogoInsumosTableCreateCompanionBuilder,
          $$CatalogoInsumosTableUpdateCompanionBuilder,
          (
            CatalogoInsumo,
            BaseReferences<
              _$AppDatabase,
              $CatalogoInsumosTable,
              CatalogoInsumo
            >,
          ),
          CatalogoInsumo,
          PrefetchHooks Function()
        > {
  $$CatalogoInsumosTableTableManager(
    _$AppDatabase db,
    $CatalogoInsumosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () =>
                  $$CatalogoInsumosTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$CatalogoInsumosTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$CatalogoInsumosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<int> activo = const Value.absent(),
                Value<String> fechaCreacion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CatalogoInsumosCompanion(
                id: id,
                nombre: nombre,
                activo: activo,
                fechaCreacion: fechaCreacion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nombre,
                required int activo,
                required String fechaCreacion,
                Value<int> rowid = const Value.absent(),
              }) => CatalogoInsumosCompanion.insert(
                id: id,
                nombre: nombre,
                activo: activo,
                fechaCreacion: fechaCreacion,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CatalogoInsumosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CatalogoInsumosTable,
      CatalogoInsumo,
      $$CatalogoInsumosTableFilterComposer,
      $$CatalogoInsumosTableOrderingComposer,
      $$CatalogoInsumosTableAnnotationComposer,
      $$CatalogoInsumosTableCreateCompanionBuilder,
      $$CatalogoInsumosTableUpdateCompanionBuilder,
      (
        CatalogoInsumo,
        BaseReferences<_$AppDatabase, $CatalogoInsumosTable, CatalogoInsumo>,
      ),
      CatalogoInsumo,
      PrefetchHooks Function()
    >;
typedef $$InventarioInsumosTableCreateCompanionBuilder =
    InventarioInsumosCompanion Function({
      required String id,
      required String catalogoId,
      required String nombre,
      required int cantidad,
      required String fecha,
      Value<int> rowid,
    });
typedef $$InventarioInsumosTableUpdateCompanionBuilder =
    InventarioInsumosCompanion Function({
      Value<String> id,
      Value<String> catalogoId,
      Value<String> nombre,
      Value<int> cantidad,
      Value<String> fecha,
      Value<int> rowid,
    });

class $$InventarioInsumosTableFilterComposer
    extends Composer<_$AppDatabase, $InventarioInsumosTable> {
  $$InventarioInsumosTableFilterComposer({
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

  ColumnFilters<String> get catalogoId => $composableBuilder(
    column: $table.catalogoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InventarioInsumosTableOrderingComposer
    extends Composer<_$AppDatabase, $InventarioInsumosTable> {
  $$InventarioInsumosTableOrderingComposer({
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

  ColumnOrderings<String> get catalogoId => $composableBuilder(
    column: $table.catalogoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InventarioInsumosTableAnnotationComposer
    extends Composer<_$AppDatabase, $InventarioInsumosTable> {
  $$InventarioInsumosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get catalogoId => $composableBuilder(
    column: $table.catalogoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<int> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);
}

class $$InventarioInsumosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InventarioInsumosTable,
          InventarioInsumo,
          $$InventarioInsumosTableFilterComposer,
          $$InventarioInsumosTableOrderingComposer,
          $$InventarioInsumosTableAnnotationComposer,
          $$InventarioInsumosTableCreateCompanionBuilder,
          $$InventarioInsumosTableUpdateCompanionBuilder,
          (
            InventarioInsumo,
            BaseReferences<
              _$AppDatabase,
              $InventarioInsumosTable,
              InventarioInsumo
            >,
          ),
          InventarioInsumo,
          PrefetchHooks Function()
        > {
  $$InventarioInsumosTableTableManager(
    _$AppDatabase db,
    $InventarioInsumosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$InventarioInsumosTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$InventarioInsumosTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$InventarioInsumosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> catalogoId = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<int> cantidad = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InventarioInsumosCompanion(
                id: id,
                catalogoId: catalogoId,
                nombre: nombre,
                cantidad: cantidad,
                fecha: fecha,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String catalogoId,
                required String nombre,
                required int cantidad,
                required String fecha,
                Value<int> rowid = const Value.absent(),
              }) => InventarioInsumosCompanion.insert(
                id: id,
                catalogoId: catalogoId,
                nombre: nombre,
                cantidad: cantidad,
                fecha: fecha,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InventarioInsumosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InventarioInsumosTable,
      InventarioInsumo,
      $$InventarioInsumosTableFilterComposer,
      $$InventarioInsumosTableOrderingComposer,
      $$InventarioInsumosTableAnnotationComposer,
      $$InventarioInsumosTableCreateCompanionBuilder,
      $$InventarioInsumosTableUpdateCompanionBuilder,
      (
        InventarioInsumo,
        BaseReferences<
          _$AppDatabase,
          $InventarioInsumosTable,
          InventarioInsumo
        >,
      ),
      InventarioInsumo,
      PrefetchHooks Function()
    >;
typedef $$SolicitudesInsumosTableCreateCompanionBuilder =
    SolicitudesInsumosCompanion Function({
      required String id,
      required String empleadoId,
      required String empleadoNombre,
      required String insumoId,
      required int cantidad,
      required String fecha,
      Value<int> rowid,
    });
typedef $$SolicitudesInsumosTableUpdateCompanionBuilder =
    SolicitudesInsumosCompanion Function({
      Value<String> id,
      Value<String> empleadoId,
      Value<String> empleadoNombre,
      Value<String> insumoId,
      Value<int> cantidad,
      Value<String> fecha,
      Value<int> rowid,
    });

class $$SolicitudesInsumosTableFilterComposer
    extends Composer<_$AppDatabase, $SolicitudesInsumosTable> {
  $$SolicitudesInsumosTableFilterComposer({
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

  ColumnFilters<String> get empleadoId => $composableBuilder(
    column: $table.empleadoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get empleadoNombre => $composableBuilder(
    column: $table.empleadoNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get insumoId => $composableBuilder(
    column: $table.insumoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SolicitudesInsumosTableOrderingComposer
    extends Composer<_$AppDatabase, $SolicitudesInsumosTable> {
  $$SolicitudesInsumosTableOrderingComposer({
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

  ColumnOrderings<String> get empleadoId => $composableBuilder(
    column: $table.empleadoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get empleadoNombre => $composableBuilder(
    column: $table.empleadoNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get insumoId => $composableBuilder(
    column: $table.insumoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SolicitudesInsumosTableAnnotationComposer
    extends Composer<_$AppDatabase, $SolicitudesInsumosTable> {
  $$SolicitudesInsumosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get empleadoId => $composableBuilder(
    column: $table.empleadoId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get empleadoNombre => $composableBuilder(
    column: $table.empleadoNombre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get insumoId =>
      $composableBuilder(column: $table.insumoId, builder: (column) => column);

  GeneratedColumn<int> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<String> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);
}

class $$SolicitudesInsumosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SolicitudesInsumosTable,
          SolicitudesInsumo,
          $$SolicitudesInsumosTableFilterComposer,
          $$SolicitudesInsumosTableOrderingComposer,
          $$SolicitudesInsumosTableAnnotationComposer,
          $$SolicitudesInsumosTableCreateCompanionBuilder,
          $$SolicitudesInsumosTableUpdateCompanionBuilder,
          (
            SolicitudesInsumo,
            BaseReferences<
              _$AppDatabase,
              $SolicitudesInsumosTable,
              SolicitudesInsumo
            >,
          ),
          SolicitudesInsumo,
          PrefetchHooks Function()
        > {
  $$SolicitudesInsumosTableTableManager(
    _$AppDatabase db,
    $SolicitudesInsumosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SolicitudesInsumosTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer:
              () => $$SolicitudesInsumosTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer:
              () => $$SolicitudesInsumosTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> empleadoId = const Value.absent(),
                Value<String> empleadoNombre = const Value.absent(),
                Value<String> insumoId = const Value.absent(),
                Value<int> cantidad = const Value.absent(),
                Value<String> fecha = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SolicitudesInsumosCompanion(
                id: id,
                empleadoId: empleadoId,
                empleadoNombre: empleadoNombre,
                insumoId: insumoId,
                cantidad: cantidad,
                fecha: fecha,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String empleadoId,
                required String empleadoNombre,
                required String insumoId,
                required int cantidad,
                required String fecha,
                Value<int> rowid = const Value.absent(),
              }) => SolicitudesInsumosCompanion.insert(
                id: id,
                empleadoId: empleadoId,
                empleadoNombre: empleadoNombre,
                insumoId: insumoId,
                cantidad: cantidad,
                fecha: fecha,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SolicitudesInsumosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SolicitudesInsumosTable,
      SolicitudesInsumo,
      $$SolicitudesInsumosTableFilterComposer,
      $$SolicitudesInsumosTableOrderingComposer,
      $$SolicitudesInsumosTableAnnotationComposer,
      $$SolicitudesInsumosTableCreateCompanionBuilder,
      $$SolicitudesInsumosTableUpdateCompanionBuilder,
      (
        SolicitudesInsumo,
        BaseReferences<
          _$AppDatabase,
          $SolicitudesInsumosTable,
          SolicitudesInsumo
        >,
      ),
      SolicitudesInsumo,
      PrefetchHooks Function()
    >;
typedef $$SyncControlTableCreateCompanionBuilder =
    SyncControlCompanion Function({
      required String tabla,
      required String ultimaSync,
      Value<int> rowid,
    });
typedef $$SyncControlTableUpdateCompanionBuilder =
    SyncControlCompanion Function({
      Value<String> tabla,
      Value<String> ultimaSync,
      Value<int> rowid,
    });

class $$SyncControlTableFilterComposer
    extends Composer<_$AppDatabase, $SyncControlTable> {
  $$SyncControlTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimaSync => $composableBuilder(
    column: $table.ultimaSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncControlTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncControlTable> {
  $$SyncControlTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tabla => $composableBuilder(
    column: $table.tabla,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimaSync => $composableBuilder(
    column: $table.ultimaSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncControlTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncControlTable> {
  $$SyncControlTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tabla =>
      $composableBuilder(column: $table.tabla, builder: (column) => column);

  GeneratedColumn<String> get ultimaSync => $composableBuilder(
    column: $table.ultimaSync,
    builder: (column) => column,
  );
}

class $$SyncControlTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncControlTable,
          SyncControlData,
          $$SyncControlTableFilterComposer,
          $$SyncControlTableOrderingComposer,
          $$SyncControlTableAnnotationComposer,
          $$SyncControlTableCreateCompanionBuilder,
          $$SyncControlTableUpdateCompanionBuilder,
          (
            SyncControlData,
            BaseReferences<_$AppDatabase, $SyncControlTable, SyncControlData>,
          ),
          SyncControlData,
          PrefetchHooks Function()
        > {
  $$SyncControlTableTableManager(_$AppDatabase db, $SyncControlTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer:
              () => $$SyncControlTableFilterComposer($db: db, $table: table),
          createOrderingComposer:
              () => $$SyncControlTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer:
              () =>
                  $$SyncControlTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tabla = const Value.absent(),
                Value<String> ultimaSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncControlCompanion(
                tabla: tabla,
                ultimaSync: ultimaSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tabla,
                required String ultimaSync,
                Value<int> rowid = const Value.absent(),
              }) => SyncControlCompanion.insert(
                tabla: tabla,
                ultimaSync: ultimaSync,
                rowid: rowid,
              ),
          withReferenceMapper:
              (p0) =>
                  p0
                      .map(
                        (e) => (
                          e.readTable(table),
                          BaseReferences(db, table, e),
                        ),
                      )
                      .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncControlTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncControlTable,
      SyncControlData,
      $$SyncControlTableFilterComposer,
      $$SyncControlTableOrderingComposer,
      $$SyncControlTableAnnotationComposer,
      $$SyncControlTableCreateCompanionBuilder,
      $$SyncControlTableUpdateCompanionBuilder,
      (
        SyncControlData,
        BaseReferences<_$AppDatabase, $SyncControlTable, SyncControlData>,
      ),
      SyncControlData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductosTableTableManager get productos =>
      $$ProductosTableTableManager(_db, _db.productos);
  $$CategoriasTableTableManager get categorias =>
      $$CategoriasTableTableManager(_db, _db.categorias);
  $$CatalogoInsumosTableTableManager get catalogoInsumos =>
      $$CatalogoInsumosTableTableManager(_db, _db.catalogoInsumos);
  $$InventarioInsumosTableTableManager get inventarioInsumos =>
      $$InventarioInsumosTableTableManager(_db, _db.inventarioInsumos);
  $$SolicitudesInsumosTableTableManager get solicitudesInsumos =>
      $$SolicitudesInsumosTableTableManager(_db, _db.solicitudesInsumos);
  $$SyncControlTableTableManager get syncControl =>
      $$SyncControlTableTableManager(_db, _db.syncControl);
}
