import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';

class CatalogoInsumosDao extends DatabaseAccessor<AppDatabase> {
  CatalogoInsumosDao(AppDatabase db) : super(db);

  static const Duration syncInterval = Duration(days: 30);

  Future<List<CatalogoInsumo>> getAllCatalogoInsumos() async {
    return await select(db.catalogoInsumos).get();
  }

  Future<void> insertOrUpdateCatalogoInsumo(CatalogoInsumosCompanion insumo) async {
    await into(db.catalogoInsumos).insertOnConflictUpdate(insumo);
  }

  Future<bool> needsSync() async {
    final syncRecord = await (select(db.syncControl)
          ..where((s) => s.tabla.equals('catalogo_insumos'))).getSingleOrNull();
    if (syncRecord == null) return true;
    return DateTime.now().difference(DateTime.parse(syncRecord.ultimaSync)) > syncInterval;
  }

  Future<void> updateLastSync() async {
    await into(db.syncControl).insertOnConflictUpdate(
      SyncControlCompanion(
        tabla: Value('catalogo_insumos'),
        ultimaSync: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> syncCatalogoInsumos({bool forceSync = false}) async {
    try {
      if (!forceSync && !await needsSync()) {
        print('✅ Catálogo insumos: No necesita sincronización');
        return;
      }

      final snapshot = await FirebaseFirestore.instance.collection('catalogo_insumos').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        await insertOrUpdateCatalogoInsumo(
          CatalogoInsumosCompanion(
            id: Value(doc.id),
            nombre: Value(data['nombre'] ?? ''),
            activo: Value((data['activo'] ?? true) ? 1 : 0),
            fechaCreacion: Value(data['fecha_creacion']?.toDate().toIso8601String() ?? ''),
          ),
        );
      }

      await updateLastSync();
      print('✅ ${snapshot.docs.length} catálogo insumos sincronizados');
    } catch (e) {
      print('❌ Error sincronizando catálogo insumos: $e');
    }
  }
}