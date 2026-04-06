import 'package:basefundi/services/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnviosTulcanDeskScreen extends StatefulWidget {
  const EnviosTulcanDeskScreen({super.key});

  @override
  State<EnviosTulcanDeskScreen> createState() => _EnviosTulcanDeskScreenState();
}

class _EnviosTulcanDeskScreenState extends State<EnviosTulcanDeskScreen> {
  String sucursalUsuario = '';
  String ciRucSucursal = '';
  bool _cargando = true;

  // Map ordenId -> Set de índices aceptados
  final Map<String, Set<int>> _itemsAceptados = {};
  // Map ordenId -> Set de índices eliminados (solo visualmente)
  final Map<String, Set<int>> _itemsEliminados = {};
  // Map ordenId -> Set de índices procesando (aceptando)
  final Map<String, Set<int>> _itemsProcesando = {};

  @override
  void initState() {
    super.initState();
    _cargarSucursal();
  }

  Future<void> _cargarSucursal() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();
        if (doc.exists) {
          final sede = doc['sede'] ?? '';
          setState(() {
            sucursalUsuario = sede;
            if (sede == 'Quito') {
              ciRucSucursal = '1710253228';
            } else if (sede == 'Guayaquil') {
              ciRucSucursal = '0930138672';
            }
            _cargando = false;
          });
        }
      }
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  /// Acepta UN ítem individual: actualiza inventario + kardex
  Future<void> _aceptarItem(
    String ordenId,
    List<dynamic> items,
    int idx,
  ) async {
    final item = items[idx] as Map<String, dynamic>;

    // ✅ Conversión segura para ref y cantidad
    final referencia = (item['ref'] ?? '').toString().trim();
    final cantidadRaw = item['cantidad'];
    final cantidad =
        cantidadRaw is int
            ? cantidadRaw
            : int.tryParse(cantidadRaw.toString()) ?? 0;

    if (referencia.isEmpty || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ítem sin referencia o cantidad válida'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _itemsProcesando.putIfAbsent(ordenId, () => {}).add(idx);
    });

    try {
      final timestamp = Timestamp.now();
      final user = FirebaseAuth.instance.currentUser;

      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user?.uid)
              .get();
      final usuarioNombre =
          usuarioDoc.exists
              ? (usuarioDoc['nombre'] ?? 'Desconocido')
              : 'Desconocido';

      final docInventario = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(sucursalUsuario)
          .collection('procesos')
          .doc('bodega')
          .collection('productos')
          .doc(referencia);

      final snapshot = await docInventario.get();

      if (snapshot.exists) {
        // ✅ Manejo seguro del tipo numérico
        final cantidadActual = (snapshot['cantidad'] ?? 0);
        final cantidadInt =
            cantidadActual is int
                ? cantidadActual
                : (cantidadActual as num).toInt();

        await docInventario.update({
          'cantidad': cantidadInt + cantidad,
          'ultima_actualizacion': timestamp,
        });
      } else {
        // No existe: crear con la cantidad recibida
        await docInventario.set({
          'cantidad': cantidad,
          'ultima_actualizacion': timestamp,
        });
      }

      await FirebaseFirestore.instance.collection('kardex_movimientos').add({
        'referencia': referencia,
        'tipo': 'entrada',
        'cantidad': cantidad,
        'fecha': timestamp,
        'usuario_uid': user?.uid ?? 'desconocido',
        'usuario_nombre': usuarioNombre,
        'sucursal': sucursalUsuario,
        'motivo': 'Recepción envío desde Tulcán - Orden ID: $ordenId',
      });

      // Marcar ítem como 'aceptado' en Firestore sin tocar los demás campos
      await _marcarEstadoItem(ordenId, items, idx, 'aceptado');

      setState(() {
        _itemsProcesando[ordenId]?.remove(idx);
        _itemsAceptados.putIfAbsent(ordenId, () => {}).add(idx);
      });
    } catch (e) {
      setState(() => _itemsProcesando[ordenId]?.remove(idx));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al aceptar ítem: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  /// Elimina un ítem visualmente (no toca Firestore)
  void _eliminarItem(String ordenId, List<dynamic> items, int idx) async {
    setState(() {
      _itemsEliminados.putIfAbsent(ordenId, () => {}).add(idx);
    });
    await _marcarEstadoItem(ordenId, items, idx, 'eliminado');
  }

  Future<void> _marcarEstadoItem(
    String ordenId,
    List<dynamic> items,
    int idx,
    String estado, // 'aceptado' o 'eliminado'
  ) async {
    try {
      final ordenRef = FirebaseFirestore.instance
          .collection('ordenes_despacho')
          .doc(ordenId);

      // Copiar el array completo y solo modificar el ítem en idx
      final itemsActualizados = List<dynamic>.from(items);
      final itemActualizado = Map<String, dynamic>.from(
        itemsActualizados[idx] as Map<String, dynamic>,
      );
      itemActualizado['estado_item'] = estado;
      itemsActualizados[idx] = itemActualizado;

      await ordenRef.update({'items': itemsActualizados});

      // Verificar si todos los ítems ya tienen estado
      final todosProcessados = itemsActualizados.every((item) {
        final e = (item as Map<String, dynamic>)['estado_item'] ?? '';
        return e == 'aceptado' || e == 'eliminado';
      });

      if (todosProcessados) {
        await ordenRef.update({'estado': 'Completada'});

        setState(() {
          _itemsAceptados.remove(ordenId);
          _itemsEliminados.remove(ordenId);
          _itemsProcesando.remove(ordenId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Orden completada'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error al marcar estado del ítem: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // Header
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        const Icon(
                          Icons.local_shipping_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Envíos desde Tulcán → $sucursalUsuario',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido
          Expanded(
            child:
                _cargando
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4682B4),
                      ),
                    )
                    : ciRucSucursal.isEmpty
                    ? _buildAccesoDenegado()
                    : _buildListaOrdenes(),
          ),
        ],
      ),
    );
  }

  Widget _buildAccesoDenegado() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes acceso a esta pantalla',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Solo disponible para sedes Quito y Guayaquil',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildListaOrdenes() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ordenes_despacho')
              .where('ci_ruc', isEqualTo: ciRucSucursal)
              .where('estado', isEqualTo: 'Pendiente')
              .where(
                'fecha',
                isGreaterThan: Timestamp.fromDate(DateTime(2026, 4, 2)),
              )
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF4682B4)),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error al cargar órdenes: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green[300],
                ),
                const SizedBox(height: 16),
                Text(
                  '¡Todo al día!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay envíos pendientes de Tulcán',
                  style: TextStyle(fontSize: 15, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // En _buildListaOrdenes, guarda también la lista original:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final ordenId = doc.id;
            final items = List<dynamic>.from(
              data['items'] ?? [],
            ); // lista original

            final itemsVisibles =
                items.asMap().entries.where((e) {
                  final estado = e.value['estado_item'];
                  return estado != 'aceptado' && estado != 'eliminado';
                }).toList();

            // ✅ Pasa AMBAS: itemsVisibles para mostrar, items para operar
            return _buildOrdenCard(ordenId, data, itemsVisibles, items);
          },
        );
      },
    );
  }

  Widget _buildOrdenCard(
    String ordenId,
    Map<String, dynamic> data,
    List<MapEntry<int, dynamic>> itemsVisibles, // para mostrar
    List<dynamic> itemsOriginales, // para operar
  ) {
    final aceptados = _itemsAceptados[ordenId] ?? {};
    final eliminados = _itemsEliminados[ordenId] ?? {};
    final procesando = _itemsProcesando[ordenId] ?? {};
    final procesados = aceptados.length + eliminados.length;

    final fecha =
        data['fecha'] != null
            ? (data['fecha'] as Timestamp).toDate()
            : DateTime.now();
    final fechaStr =
        '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header de la orden
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.local_shipping,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Orden N° ${data['numero'] ?? '-'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Proforma N° ${data['numero_proforma'] ?? '-'} · $fechaStr',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de progreso
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        procesados == itemsOriginales.length
                            ? Colors.green[400]
                            : Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$procesados/${itemsOriginales.length} procesados',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tabla de ítems
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (itemsVisibles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4682B4),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Cerrando orden...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // Header tabla
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'REFERENCIA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'DESCRIPCIÓN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'CANTIDAD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 120), // espacio para botones
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filas de ítems
                  ...itemsVisibles.map((entry) {
                    final idx = entry.key;
                    final item = entry.value as Map<String, dynamic>;
                    final estaProcesando = procesando.contains(idx);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[200]!, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                item['ref'] ?? '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                item['descripcion'] ?? '-',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item['cantidad']?.toString() ?? '0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue[700],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Botón Aceptar
                            SizedBox(
                              width: 48,
                              height: 40,
                              child:
                                  estaProcesando
                                      ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.green,
                                        ),
                                      )
                                      : Tooltip(
                                        message: 'Aceptar ítem',
                                        child: ElevatedButton(
                                          onPressed:
                                              () => _aceptarItem(
                                                ordenId,
                                                itemsOriginales,
                                                idx,
                                              ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green[600],
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            minimumSize: const Size(48, 40),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                            ),
                            const SizedBox(width: 8),
                            // Botón Eliminar
                            SizedBox(
                              width: 48,
                              height: 40,
                              child: Tooltip(
                                message: 'Eliminar ítem',
                                child: ElevatedButton(
                                  onPressed:
                                      estaProcesando
                                          ? null
                                          : () => _eliminarItem(
                                            ordenId,
                                            itemsOriginales,
                                            idx,
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red[400],
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(48, 40),
                                    disabledBackgroundColor: Colors.grey[300],
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
