import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database.dart';

class ProductosDao extends DatabaseAccessor<AppDatabase> {
  ProductosDao(AppDatabase db) : super(db);

  // ==================== CONFIGURACIÓN ====================
  static const Duration syncInterval = Duration(hours: 6);

  // ==================== OBTENER TODOS LOS PRODUCTOS ====================
  Future<List<Producto>> getAllProductos() async {
    return await select(db.productos).get();
  }

  // ==================== BUSCAR PRODUCTOS ====================
  Future<List<Producto>> searchProductos(String query) async {
    final queryLower = query.toLowerCase();
    return await (select(db.productos)..where(
      (p) =>
          p.nombre.lower().like('%$queryLower%') |
          p.codigo.lower().like('%$queryLower%') |
          p.referencia.lower().like('%$queryLower%'),
    )).get();
  }

  // ==================== FILTRAR POR CATEGORÍA ====================
  Future<List<Producto>> getProductosByCategoria(String categoria) async {
    return await (select(db.productos)
      ..where((p) => p.categoria.equals(categoria))).get();
  }

  // ==================== INSERTAR O ACTUALIZAR PRODUCTO ====================
  Future<void> insertOrUpdateProducto(ProductosCompanion producto) async {
    await into(db.productos).insertOnConflictUpdate(producto);
  }

  // ==================== ELIMINAR PRODUCTO ====================
  Future<void> deleteProducto(String id) async {
    await (delete(db.productos)..where((p) => p.id.equals(id))).go();
  }

  // ==================== LIMPIAR TODOS LOS PRODUCTOS ====================
  Future<void> clearAllProductos() async {
    await delete(db.productos).go();
  }

  // ==================== VERIFICAR SI NECESITA SINCRONIZACIÓN ====================
  Future<bool> needsSync() async {
    final syncRecord =
        await (select(db.syncControl)
          ..where((s) => s.tabla.equals('productos'))).getSingleOrNull();

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
          ..where((s) => s.tabla.equals('productos'))).getSingleOrNull();

    return syncRecord?.ultimaSync;
  }

  // ==================== ACTUALIZAR TIMESTAMP DE SINCRONIZACIÓN ====================
  Future<void> updateLastSync() async {
    await into(db.syncControl).insertOnConflictUpdate(
      SyncControlCompanion(
        tabla: Value('productos'),
        ultimaSync: Value(DateTime.now().toIso8601String()),
      ),
    );
  }

  // ==================== SINCRONIZACIÓN DESDE FIRESTORE ====================
  Future<void> syncProductos({bool forceSync = false}) async {
    try {
      // Verificar si necesita sincronización
      if (!forceSync && !await needsSync()) {
        print(
          '✅ Productos: No necesita sincronización (última sync hace menos de 6 horas)',
        );
        return;
      }

      final lastSync = await getLastSync();
      final firestoreInstance = FirebaseFirestore.instance;

      firestore.Query query = firestoreInstance.collection('productos');

      // Sincronización incremental si existe lastSync
      if (lastSync != null && !forceSync) {
        query = query.where(
          'updated_at',
          isGreaterThan: Timestamp.fromDate(DateTime.parse(lastSync)),
        );
        print('🔄 Sincronizando productos modificados desde $lastSync...');
      } else {
        print('🔄 Sincronización completa de productos...');
      }

      final snapshot = await query.get();

      if (snapshot.docs.isEmpty) {
        print('✅ No hay productos nuevos para sincronizar');
        await updateLastSync();
        return;
      }

      // Insertar o actualizar productos
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        await insertOrUpdateProducto(
          ProductosCompanion(
            id: Value(doc.id),
            nombre: Value(data['nombre'] ?? ''),
            categoria: Value(data['categoria'] ?? ''),
            codigo: Value(data['codigo'] ?? ''),
            referencia: Value(data['referencia'] ?? ''),
            precio20: Value((data['precio20'] ?? 0).toDouble()),
            pvp: Value((data['pvp'] ?? 0).toDouble()),
            fecha: Value(data['fecha']?.toDate().toIso8601String() ?? ''),
          ),
        );
      }

      await updateLastSync();
      print('✅ ${snapshot.docs.length} productos sincronizados correctamente');
    } catch (e) {
      print('❌ Error sincronizando productos: $e');
      rethrow;
    }
  }
}
