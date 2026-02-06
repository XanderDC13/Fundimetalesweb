import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';

class InventarioInsumosDao extends DatabaseAccessor<AppDatabase> {
  InventarioInsumosDao(AppDatabase db) : super(db);

  static const Duration syncInterval = Duration(hours: 2);

  Future<List<InventarioInsumo>> getAllInventarioInsumos() async {
    return await select(db.inventarioInsumos).get();
  }

  Future<void> insertOrUpdateInventarioInsumo(InventarioInsumosCompanion insumo) async {
    await into(db.inventarioInsumos).insertOnConflictUpdate(insumo);
  }

  Future<bool> needsSync() async {
    final syncRecord = await (select(db.syncControl)
          ..where((s) => s.tabla.equals('inventario_insumos'))).getSingleOrNull();
    if (syncRecord == null) return true;
    return DateTime.now().difference(DateTime.parse(syncRecord.ultimaSync)) > syncInterval;
  }

  Future<void> updateLastSync() async {
    await into(db.syncControl).insertOnConflictUpdate(
      SyncControlCompanion(
        tabla: Value('inventario_insumos'),
        ultimaSync: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> syncInventarioInsumos({bool forceSync = false}) async {
    try {
      if (!forceSync && !await needsSync()) {
        print('✅ Inventario insumos: No necesita sincronización');
        return;
      }

      final snapshot = await FirebaseFirestore.instance.collection('inventario_insumos').get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        await insertOrUpdateInventarioInsumo(
          InventarioInsumosCompanion(
            id: Value(doc.id),
            catalogoId: Value(data['catalogo_id'] ?? ''),
            nombre: Value(data['nombre'] ?? ''),
            cantidad: Value(data['cantidad'] ?? 0),
            fecha: Value(data['fecha']?.toDate().toIso8601String() ?? ''),
          ),
        );
      }

      await updateLastSync();
      print('✅ ${snapshot.docs.length} inventario insumos sincronizados');
    } catch (e) {
      print('❌ Error sincronizando inventario insumos: $e');
    }
  }
}