import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';

class CategoriasDao extends DatabaseAccessor<AppDatabase> {
  CategoriasDao(AppDatabase db) : super(db);

  // ==================== CONFIGURACIÓN ====================
  static const Duration syncInterval = Duration(days: 30);

  // ==================== OBTENER TODAS LAS CATEGORÍAS ====================
  Future<List<Categoria>> getAllCategorias() async {
    return await select(db.categorias).get();
  }

  // ==================== OBTENER CATEGORÍAS ORDENADAS ====================
  Future<List<Categoria>> getCategoriasOrdenadas() async {
    return await (select(db.categorias)
      ..orderBy([(c) => OrderingTerm(expression: c.nombre)])).get();
  }

  // ==================== INSERTAR O ACTUALIZAR CATEGORÍA ====================
  Future<void> insertOrUpdateCategoria(CategoriasCompanion categoria) async {
    await into(db.categorias).insertOnConflictUpdate(categoria);
  }

  // ==================== ELIMINAR CATEGORÍA ====================
  Future<void> deleteCategoria(String id) async {
    await (delete(db.categorias)..where((c) => c.id.equals(id))).go();
  }

  // ==================== LIMPIAR TODAS LAS CATEGORÍAS ====================
  Future<void> clearAllCategorias() async {
    await delete(db.categorias).go();
  }

  // ==================== VERIFICAR SI NECESITA SINCRONIZACIÓN ====================
  Future<bool> needsSync() async {
    final syncRecord =
        await (select(db.syncControl)
          ..where((s) => s.tabla.equals('categorias'))).getSingleOrNull();

    if (syncRecord == null) return true;

    final lastSync = DateTime.parse(syncRecord.ultimaSync);
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    return difference > syncInterval;
  }

  // ==================== OBTENER ÚLTIMA SINCRONIZACIÓN ====================
  Future<String?> getLastSync() async {
    final syncRecord =
        await (select(db.syncControl)
          ..where((s) => s.tabla.equals('categorias'))).getSingleOrNull();

    return syncRecord?.ultimaSync;
  }

  // ==================== ACTUALIZAR TIMESTAMP DE SINCRONIZACIÓN ====================
  Future<void> updateLastSync() async {
    await into(db.syncControl).insertOnConflictUpdate(
      SyncControlCompanion(
        tabla: Value('categorias'),
        ultimaSync: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  // ==================== SINCRONIZACIÓN DESDE FIRESTORE ====================
  Future<void> syncCategorias({bool forceSync = false}) async {
    try {
      // Verificar si necesita sincronización
      if (!forceSync && !await needsSync()) {
        print(
          '✅ Categorías: No necesita sincronización (última sync hace menos de 30 días)',
        );
        return;
      }

      final lastSync = await getLastSync();
      final firestoreInstance = FirebaseFirestore.instance;

      firestore.Query query = firestoreInstance.collection('categorias');

      // Sincronización incremental si existe lastSync
      if (lastSync != null && !forceSync) {
        query = query.where(
          'fecha_creacion',
          isGreaterThan: Timestamp.fromDate(DateTime.parse(lastSync)),
        );
        print('🔄 Sincronizando categorías modificadas desde $lastSync...');
      } else {
        print('🔄 Sincronización completa de categorías...');
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print('✅ No hay categorías nuevas para sincronizar');
        await updateLastSync();
        return;
      }

      // Insertar o actualizar categorías
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        await insertOrUpdateCategoria(
          CategoriasCompanion(
            id: Value(doc.id),
            nombre: Value(data['nombre'] ?? ''),
            fechaCreacion: Value(
              data['fecha_creacion']?.toDate().toIso8601String() ?? '',
            ),
          ),
        );
      }

      await updateLastSync();
      print('✅ ${snapshot.docs.length} categorías sincronizadas correctamente');
    } catch (e) {
      print('❌ Error sincronizando categorías: $e');
      rethrow;
    }
  }
}
