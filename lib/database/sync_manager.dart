import 'dart:async';
import 'productos_dao.dart';
import 'categorias_dao.dart';
import 'database.dart';
import 'catalogo_insumos_dao.dart';
import 'inventario_insumos_dao.dart';
import 'solicitudes_insumos_dao.dart';

class SyncManager {
  final AppDatabase database;
  final ProductosDao productosDao;
  final CategoriasDao categoriasDao;
  final CatalogoInsumosDao catalogoInsumosDao;
  final InventarioInsumosDao inventarioInsumosDao;
  final SolicitudesInsumosDao solicitudesInsumosDao;
  Timer? _syncTimer;

  SyncManager(this.database)
    : productosDao = ProductosDao(database),
      categoriasDao = CategoriasDao(database),
      catalogoInsumosDao = CatalogoInsumosDao(database),
      inventarioInsumosDao = InventarioInsumosDao(database),
      solicitudesInsumosDao = SolicitudesInsumosDao(database);

  // ==================== INICIAR SINCRONIZACIÓN AUTOMÁTICA ====================
  void startAutoSync() {
    // Sincronizar inmediatamente al iniciar
    syncAll();

    // Timer que verifica cada 30 minutos si necesita sincronizar
    _syncTimer = Timer.periodic(Duration(minutes: 30), (_) {
      syncAll();
    });

    print('🔄 Sincronización automática iniciada (verifica cada 30 min)');
  }

  // ==================== DETENER SINCRONIZACIÓN AUTOMÁTICA ====================
  void stopAutoSync() {
    _syncTimer?.cancel();
    print('⏸️ Sincronización automática detenida');
  }

  // ==================== SINCRONIZAR TODO ====================
  Future<void> syncAll({bool forceSync = false}) async {
    print('🔄 Iniciando sincronización...');

    try {
      await productosDao.syncProductos(forceSync: forceSync);
      await categoriasDao.syncCategorias(forceSync: forceSync);
      await catalogoInsumosDao.syncCatalogoInsumos(forceSync: forceSync);
      await inventarioInsumosDao.syncInventarioInsumos(forceSync: forceSync);
      await solicitudesInsumosDao.syncSolicitudesInsumos(forceSync: forceSync);

      print('✅ Sincronización completada');
    } catch (e) {
      print('❌ Error en sincronización: $e');
    }
  }

  // ==================== LIMPIAR BASE DE DATOS ====================
  Future<void> clearAllData() async {
    await productosDao.clearAllProductos();
    await categoriasDao.clearAllCategorias();
    print('🗑️ Base de datos limpiada');
  }

  // ==================== CERRAR ====================
  void dispose() {
    stopAutoSync();
  }
}
