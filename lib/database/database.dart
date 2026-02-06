import 'package:drift/drift.dart';
import 'package:drift/web.dart';

part 'database.g.dart';

// ==================== TABLA PRODUCTOS ====================
class Productos extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get categoria => text()();
  TextColumn get codigo => text()();
  TextColumn get referencia => text()();
  RealColumn get precio20 => real()();
  RealColumn get pvp => real()();
  TextColumn get fecha => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== TABLA CATEGORIAS ====================
class Categorias extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  TextColumn get fechaCreacion => text().named('fecha_creacion')();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== TABLA CATALOGO INSUMOS ====================
class CatalogoInsumos extends Table {
  TextColumn get id => text()();
  TextColumn get nombre => text()();
  IntColumn get activo => integer()();
  TextColumn get fechaCreacion => text().named('fecha_creacion')();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== TABLA INVENTARIO INSUMOS ====================
class InventarioInsumos extends Table {
  TextColumn get id => text()();
  TextColumn get catalogoId => text().named('catalogo_id')();
  TextColumn get nombre => text()();
  IntColumn get cantidad => integer()();
  TextColumn get fecha => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== TABLA SOLICITUDES INSUMOS ====================
class SolicitudesInsumos extends Table {
  TextColumn get id => text()();
  TextColumn get empleadoId => text().named('empleado_id')();
  TextColumn get empleadoNombre => text().named('empleado_nombre')();
  TextColumn get insumoId => text().named('insumo_id')();
  IntColumn get cantidad => integer()();
  TextColumn get fecha => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ==================== TABLA CONTROL DE SINCRONIZACIÓN ====================
class SyncControl extends Table {
  TextColumn get tabla => text()();
  TextColumn get ultimaSync => text().named('ultima_sync')();

  @override
  Set<Column> get primaryKey => {tabla};
}

// ==================== BASE DE DATOS ====================
@DriftDatabase(
  tables: [
    Productos,
    Categorias,
    CatalogoInsumos,
    InventarioInsumos,
    SolicitudesInsumos,
    SyncControl,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ==================== CONEXIÓN WEB ====================
  static QueryExecutor _openConnection() {
    return WebDatabase.withStorage(
      DriftWebStorage.indexedDb(
        'fundimetales_db',
        migrateFromLocalStorage: false,
      ),
    );
  }
}
