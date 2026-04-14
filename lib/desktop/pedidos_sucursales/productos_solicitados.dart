import 'package:basefundi/services/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductosSolicitadosScreenWeb extends StatefulWidget {
  const ProductosSolicitadosScreenWeb({super.key});

  @override
  State<ProductosSolicitadosScreenWeb> createState() =>
      _ProductosSolicitadosScreenWebState();
}

class _ProductosSolicitadosScreenWebState
    extends State<ProductosSolicitadosScreenWeb> {
  List<Map<String, dynamic>> _solicitudes = [];
  bool _cargando = true;
  String _mensajeError = '';
  String _filtroSede = 'Todas';
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _verificarRolYCargar();
  }

  Future<void> _verificarRolYCargar() async {
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

      final rol = usuarioDoc['rol'] ?? '';
      if (rol != 'Gerente' && rol != 'Administrador General') {
        setState(() {
          _mensajeError = 'No tiene permisos para acceder a esta pantalla';
          _cargando = false;
        });
        return;
      }

      await _cargarSolicitudes();
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _mensajeError = 'Error: ${e.toString()}';
        _cargando = false;
      });
    }
  }

  Future<void> _cargarSolicitudes() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('solicitudes_productos')
              .where('estado', isEqualTo: 'pendiente')
              .get();

      final solicitudes =
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();

      // Ordenar por fecha más reciente primero
      solicitudes.sort((a, b) {
        final fechaA = (a['fecha_solicitud'] as Timestamp).toDate();
        final fechaB = (b['fecha_solicitud'] as Timestamp).toDate();
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        _solicitudes = solicitudes;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error al cargar solicitudes: $e');
      setState(() {
        _cargando = false;
      });
    }
  }

  Future<void> _aprobarSolicitud(String solicitudId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(
      context,
    ); // ✅ guarda referencia antes

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Aprobar Solicitud'),
          content: const Text(
            '¿Está seguro de que desea aprobar esta solicitud?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                ); // ✅ cierra diálogo ANTES del await
                try {
                  await FirebaseFirestore.instance
                      .collection('solicitudes_productos')
                      .doc(solicitudId)
                      .update({
                        'estado': 'aprobado',
                        'fecha_aprobacion': Timestamp.now(),
                        'usuario_aprobacion':
                            FirebaseAuth.instance.currentUser!.uid,
                      });

                  await _cargarSolicitudes();

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      // ✅ usa referencia guardada
                      const SnackBar(
                        content: Text('Solicitud aprobada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print('❌ Error al aprobar: $e');
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      // ✅ usa referencia guardada
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Sí, Aprobar'),
            ),
          ],
        );
      },
    );
  }


  List<Map<String, dynamic>> _getSolicitudesFiltradas() {
    var filtradas = _solicitudes;

    if (_filtroSede != 'Todas') {
      filtradas =
          filtradas.where((s) => s['sede_origen'] == _filtroSede).toList();
    }

    if (_busqueda.isNotEmpty) {
      filtradas =
          filtradas.where((s) {
            final items = List.from(s['items'] ?? []);
            return s['id'].toLowerCase().contains(_busqueda.toLowerCase()) ||
                items.any(
                  (item) => item['ref'].toLowerCase().contains(
                    _busqueda.toLowerCase(),
                  ),
                );
          }).toList();
    }

    return filtradas;
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
                'Productos Solicitados',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControles() {
    final sedes = ['Todas', 'Quito', 'Guayaquil'];

    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          const Text(
            'Filtros y Búsqueda',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sede',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            sedes.map((sede) {
                              final isSelected = _filtroSede == sede;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(sede),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _filtroSede = sede;
                                    });
                                  },
                                  backgroundColor: Colors.grey[200],
                                  selectedColor: const Color(0xFF4682B4),
                                  labelStyle: TextStyle(
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buscar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          _busqueda = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Por ID o referencia...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    final solicitudesFiltradas = _getSolicitudesFiltradas();
    int totalProductos = 0;
    double cantidadTotal = 0;

    for (var solicitud in solicitudesFiltradas) {
      final items = List.from(solicitud['items'] ?? []);
      totalProductos += items.length;
      for (var item in items) {
        cantidadTotal += (item['cantidad'] as num).toDouble();
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4682B4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.summarize, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Resumen',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildResumenItem(
                    icon: Icons.shopping_cart,
                    titulo: 'Solicitudes Pendientes',
                    valor: '${solicitudesFiltradas.length}',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResumenItem(
                    icon: Icons.inventory,
                    titulo: 'Productos Únicos',
                    valor: '$totalProductos',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildResumenItem(
                    icon: Icons.production_quantity_limits,
                    titulo: 'Cantidad Total',
                    valor: '${cantidadTotal.toInt()}',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolicitudesTable() {
    final solicitudesFiltradas = _getSolicitudesFiltradas();

    if (solicitudesFiltradas.isEmpty) {
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF4682B4),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.list, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'Solicitudes Pendientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 24,
              dataRowHeight: 120,
              columns: const [
                DataColumn(label: Text('ID')),
                DataColumn(label: Text('Sede')),
                DataColumn(label: Text('Fecha')),
                DataColumn(label: Text('Productos')),
                DataColumn(label: Text('Acción')),
              ],
              rows:
                  solicitudesFiltradas.map((solicitud) {
                    final items = List.from(solicitud['items'] ?? []);
                    final fecha =
                        (solicitud['fecha_solicitud'] as Timestamp).toDate();
                    final sede = solicitud['sede_origen'] ?? 'N/A';

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '#${solicitud['id'].substring(0, 8).toUpperCase()}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              sede,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm').format(fecha),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  items.map((item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${item['ref']} (${item['cantidad'].toInt()})',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                        DataCell(
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Aprobar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () => _aprobarSolicitud(solicitud['id']),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
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
                              _buildControles(),
                              _buildResumenCard(),
                              const SizedBox(height: 8),
                              _buildSolicitudesTable(),
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
}
