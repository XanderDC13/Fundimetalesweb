import 'package:basefundi/services/localnotification/notification_service.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductosASolicitarScreenWeb extends StatefulWidget {
  const ProductosASolicitarScreenWeb({super.key});

  @override
  State<ProductosASolicitarScreenWeb> createState() =>
      _ProductosASolicitarScreenWebState();
}

class _ProductosASolicitarScreenWebState
    extends State<ProductosASolicitarScreenWeb> {
  String _sedaSeleccionada = '';
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _solicitudesPendientes = [];
  bool _cargando = true;
  String _mensajeError = '';

  // Para crear nueva solicitud
  final List<Map<String, dynamic>> _itemsSolicitud = [];
  final TextEditingController _cantidadController = TextEditingController();
  final TextEditingController _busquedaController = TextEditingController();
  List<Map<String, dynamic>> _productosFiltrados = [];
  bool _mostrarResultados = false;
  bool _creandoSolicitud = false;

  @override
  void initState() {
    super.initState();
    _obtenerSedaUsuario();
  }

  Future<void> _obtenerSedaUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _mensajeError = 'Usuario no autenticado';
          _cargando = false;
        });
        return;
      }

      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      if (!usuarioDoc.exists) {
        setState(() {
          _mensajeError = 'Usuario no encontrado';
          _cargando = false;
        });
        return;
      }

      final sede = usuarioDoc['sede'] ?? '';
      if (sede.isEmpty) {
        setState(() {
          _mensajeError = 'Sede no asignada';
          _cargando = false;
        });
        return;
      }

      setState(() {
        _sedaSeleccionada = sede;
      });

      await Future.wait([
        _cargarProductos(_sedaSeleccionada),
        _cargarSolicitudesPendientes(),
      ]);
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _mensajeError = 'Error: ${e.toString()}';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarProductos(String referencia) async {
    try {
      // 1. Quitar el .limit(100) para traer TODOS
      final snapshot =
          await FirebaseFirestore.instance.collection('productos').get();

      final productos =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              // 2. Asegurarse de leer el campo correcto
              'ref': data['referencia']?.toString() ?? doc.id,
              'nombre': data['nombre']?.toString() ?? '',
              ...data,
            };
          }).toList();

      setState(() {
        _productos = productos;
      });
    } catch (e) {
      print('❌ Error al cargar productos: $e');
    }
  }

  Future<void> _cargarSolicitudesPendientes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('solicitudes_productos')
              .where('sede_origen', isEqualTo: _sedaSeleccionada)
              .where('estado', isEqualTo: 'pendiente')
              .get();

      final solicitudes =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      setState(() {
        _solicitudesPendientes = solicitudes;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error al cargar solicitudes: $e');
      setState(() {
        _cargando = false;
      });
    }
  }

  void _agregarProductoASolicitud(Map<String, dynamic> producto) {
    showDialog(
      context: context,
      builder: (context) {
        _cantidadController.clear();
        return AlertDialog(
          title: Text('Agregar ${producto['ref']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Referencia: ${producto['ref']}'),
              const SizedBox(height: 16),
              TextField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final cantidad = double.tryParse(_cantidadController.text);
                if (cantidad == null || cantidad <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese una cantidad válida'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setState(() {
                  _itemsSolicitud.add({
                    'ref': producto['ref'],
                    'cantidad': cantidad,
                    'productoId': producto['id'],
                  });
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Producto agregado'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  void _removerProductoDeSolicitud(int index) {
    setState(() {
      _itemsSolicitud.removeAt(index);
    });
  }

  Future<void> _crearSolicitud() async {
    if (_itemsSolicitud.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregue al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() => _creandoSolicitud = true);
    try {
      await FirebaseFirestore.instance.collection('solicitudes_productos').add({
        'sede_origen': _sedaSeleccionada,
        'items': _itemsSolicitud,
        'fecha_solicitud': Timestamp.now(),
        'estado': 'pendiente',
        'usuario_uid': FirebaseAuth.instance.currentUser!.uid,
      });
      int totalProductos = _itemsSolicitud.length;
      double cantidadTotal =
          _itemsSolicitud
              .fold(0.0, (prev, item) => prev + (item['cantidad'] as num))
              .toDouble();

      await NotificationService().notificarSolicitudCreada(
        sede: _sedaSeleccionada,
        cantidadProductos: totalProductos,
        cantidadTotal: cantidadTotal,
      );
      setState(() {
        _itemsSolicitud.clear();
      });

      await _cargarSolicitudesPendientes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ Error al crear solicitud: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _creandoSolicitud = false); // 👈 desbloquear
    }
  }

  Future<void> _editarSolicitud(
    String solicitudId,
    List<dynamic> itemsActuales,
  ) async {
    // Copiar items actuales para editar
    List<Map<String, dynamic>> itemsEditados = List<Map<String, dynamic>>.from(
      itemsActuales.map((item) => Map<String, dynamic>.from(item as Map)),
    );
    final TextEditingController _busquedaEdicionController =
        TextEditingController();
    List<Map<String, dynamic>> _filtradosEdicion = [];
    bool _mostrarEdicion = false;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Editar Solicitud'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        itemCount: itemsEditados.length,
                        itemBuilder: (context, index) {
                          final item = itemsEditados[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Ref: ${item['ref']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Cant: ${item['cantidad']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setStateDialog(() {
                                      itemsEditados.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Agregar nuevo producto:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _busquedaEdicionController,
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (q) {
                          setStateDialog(() {
                            _filtradosEdicion =
                                q.trim().isEmpty
                                    ? []
                                    : _productos
                                        .where(
                                          (p) =>
                                              (p['ref'] ?? '')
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(q.toLowerCase()) ||
                                              (p['nombre'] ?? '')
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(q.toLowerCase()),
                                        )
                                        .toList();
                            _mostrarEdicion = q.trim().isNotEmpty;
                          });
                        },
                      ),
                      if (_mostrarEdicion && _filtradosEdicion.isNotEmpty)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 180),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filtradosEdicion.length,
                            itemBuilder: (context, i) {
                              final p = _filtradosEdicion[i];
                              return ListTile(
                                title: Text(p['ref'] ?? ''),
                                subtitle: Text(p['nombre'] ?? ''),
                                onTap: () {
                                  setStateDialog(() {
                                    _busquedaEdicionController.clear();
                                    _filtradosEdicion = [];
                                    _mostrarEdicion = false;
                                  });
                                  _agregarProductoAEdicion(
                                    p,
                                    itemsEditados,
                                    setStateDialog,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (itemsEditados.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La solicitud debe tener al menos un producto',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                      return;
                    }

                    try {
                      await FirebaseFirestore.instance
                          .collection('solicitudes_productos')
                          .doc(solicitudId)
                          .update({'items': itemsEditados});

                      Navigator.pop(context);
                      await _cargarSolicitudesPendientes();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Solicitud actualizada'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      print('❌ Error al actualizar: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _agregarProductoAEdicion(
    Map<String, dynamic> producto,
    List<Map<String, dynamic>> items,
    StateSetter setStateDialog,
  ) {
    final cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Agregar ${producto['ref']}'),
          content: TextField(
            controller: cantidadController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final cantidad = double.tryParse(cantidadController.text);
                if (cantidad == null || cantidad <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingrese una cantidad válida'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                setStateDialog(() {
                  items.add({
                    'ref': producto['ref'],
                    'cantidad': cantidad,
                    'productoId': producto['id'],
                  });
                });

                Navigator.pop(context);
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelarSolicitud(String solicitudId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Cancelar Solicitud'),
            content: const Text(
              '¿Está seguro de que desea cancelar esta solicitud?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sí, Cancelar'),
              ),
            ],
          ),
    );

    if (confirmar != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('solicitudes_productos')
          .doc(solicitudId)
          .delete();

      await _cargarSolicitudesPendientes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud cancelada'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildHeader() {
    return Transform.translate(
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
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Productos a Solicitar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sede: $_sedaSeleccionada',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormularioSolicitud() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.add_circle, color: Color(0xFF4682B4), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Nueva Solicitud',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleccionar Producto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _busquedaController,
                          builder: (context, value, child) {
                            return TextField(
                              controller: _busquedaController,
                              decoration: InputDecoration(
                                hintText: 'Buscar por referencia...',
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon:
                                    value.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _busquedaController.clear();
                                              _productosFiltrados = [];
                                              _mostrarResultados = false;
                                            });
                                          },
                                        )
                                        : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (query) {
                                setState(() {
                                  if (query.trim().isEmpty) {
                                    _productosFiltrados = [];
                                    _mostrarResultados = false;
                                  } else {
                                    _productosFiltrados =
                                        _productos
                                            .where(
                                              (p) => (p['ref'] ?? '')
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(
                                                    query.toLowerCase(),
                                                  ),
                                            )
                                            .toList();
                                    _mostrarResultados = true;
                                  }
                                });
                              },
                            );
                          },
                        ),
                        if (_mostrarResultados &&
                            _productosFiltrados.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            constraints: const BoxConstraints(maxHeight: 220),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _productosFiltrados.length,
                              itemBuilder: (context, index) {
                                final producto = _productosFiltrados[index];
                                return ListTile(
                                  title: Text(producto['ref'] ?? 'N/A'),
                                  subtitle: Text(
                                    producto['nombre']?.toString() ?? '',
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _busquedaController.clear();
                                      _productosFiltrados = [];
                                      _mostrarResultados = false;
                                    });
                                    _agregarProductoASolicitud(producto);
                                  },
                                );
                              },
                            ),
                          ),
                        if (_mostrarResultados && _productosFiltrados.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.search_off, color: Colors.grey),
                                SizedBox(width: 8),
                                Text(
                                  'No se encontraron productos',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_itemsSolicitud.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),
            const Text(
              'Productos en esta solicitud',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'REFERENCIA',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'CANTIDAD',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            'ACCIÓN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.grey[800],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _itemsSolicitud.length,
                    itemBuilder: (context, index) {
                      final item = _itemsSolicitud[index];
                      final isLast = index == _itemsSolicitud.length - 1;

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom:
                                isLast
                                    ? BorderSide.none
                                    : BorderSide(color: Colors.grey[200]!),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  item['ref'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Text(
                                  '${item['cantidad'].toInt()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    onPressed:
                                        () =>
                                            _removerProductoDeSolicitud(index),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: ElevatedButton(
                onPressed: _creandoSolicitud ? null : _crearSolicitud, // 👈
                child:
                    _creandoSolicitud
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                        : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Crear Solicitud',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSolicitudesList() {
    if (_solicitudesPendientes.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(48),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay solicitudes pendientes',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history, color: Color(0xFF4682B4), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Mis Solicitudes Pendientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: List.generate(_solicitudesPendientes.length, (index) {
                final solicitud = _solicitudesPendientes[index];
                final items = List.from(solicitud['items'] ?? []);
                final fecha =
                    (solicitud['fecha_solicitud'] as Timestamp).toDate();
                final isLast = index == _solicitudesPendientes.length - 1;

                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          isLast
                              ? BorderSide.none
                              : BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Solicitud #${solicitud['id'].substring(0, 8).toUpperCase()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Pendiente',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Productos:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(8),
                                        topRight: Radius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'REFERENCIA',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'CANTIDAD',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              color: Colors.grey[800],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: items.length,
                                    itemBuilder: (context, itemIndex) {
                                      final item = items[itemIndex];
                                      final isLastItem =
                                          itemIndex == items.length - 1;

                                      return Container(
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom:
                                                isLastItem
                                                    ? BorderSide.none
                                                    : BorderSide(
                                                      color: Colors.grey[200]!,
                                                    ),
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(12),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 2,
                                              child: Text(
                                                item['ref'],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 1,
                                              child: Text(
                                                '${item['cantidad'].toInt()}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text('Editar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed:
                                      () => _editarSolicitud(
                                        solicitud['id'],
                                        items,
                                      ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.delete, size: 16),
                                  label: const Text('Cancelar'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed:
                                      () => _cancelarSolicitud(solicitud['id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child:
                    _cargando
                        ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF4682B4),
                          ),
                        )
                        : _mensajeError.isNotEmpty
                        ? Center(
                          child: Container(
                            margin: const EdgeInsets.all(24),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _mensajeError,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        : SingleChildScrollView(
                          child: Column(
                            children: [
                              _buildFormularioSolicitud(),
                              _buildSolicitudesList(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _busquedaController.dispose();
    super.dispose();
  }
}
