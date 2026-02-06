import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';

class SolicitudesInsumosDao extends DatabaseAccessor<AppDatabase> {
  SolicitudesInsumosDao(AppDatabase db) : super(db);

  static const Duration syncInterval = Duration(hours: 1);

  Future<List<SolicitudesInsumo>> getAllSolicitudes() async {
    return await (select(db.solicitudesInsumos)..orderBy([
      (s) => OrderingTerm(expression: s.fecha, mode: OrderingMode.desc),
    ])).get();
  }

  Future<void> insertOrUpdateSolicitud(
    SolicitudesInsumosCompanion solicitud,
  ) async {
    await into(db.solicitudesInsumos).insertOnConflictUpdate(solicitud);
  }

  Future<bool> needsSync() async {
    final syncRecord =
        await (select(db.syncControl)..where(
          (s) => s.tabla.equals('solicitudes_insumos'),
        )).getSingleOrNull();
    if (syncRecord == null) return true;
    return DateTime.now().difference(DateTime.parse(syncRecord.ultimaSync)) >
        syncInterval;
  }

  Future<void> updateLastSync() async {
    await into(db.syncControl).insertOnConflictUpdate(
      SyncControlCompanion(
        tabla: Value('solicitudes_insumos'),
        ultimaSync: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  Future<void> syncSolicitudesInsumos({bool forceSync = false}) async {
    try {
      if (!forceSync && !await needsSync()) {
        print('✅ Solicitudes insumos: No necesita sincronización');
        return;
      }

      final snapshot =
          await FirebaseFirestore.instance
              .collection('solicitudes_insumos')
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        await insertOrUpdateSolicitud(
          SolicitudesInsumosCompanion(
            id: Value(doc.id),
            empleadoId: Value(data['empleado_id'] ?? ''),
            empleadoNombre: Value(data['empleado_nombre'] ?? ''),
            insumoId: Value(data['insumo_id'] ?? ''),
            cantidad: Value(data['cantidad'] ?? 0),
            fecha: Value(data['fecha']?.toDate().toIso8601String() ?? ''),
          ),
        );
      }

      await updateLastSync();
      print('✅ ${snapshot.docs.length} solicitudes insumos sincronizadas');
    } catch (e) {
      print('❌ Error sincronizando solicitudes: $e');
    }
  }
}
