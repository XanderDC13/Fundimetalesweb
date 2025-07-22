import 'package:basefundi/desktop/inventario/tablas/tablainv_general_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InventarioGeneralDeskScreen extends StatefulWidget {
  const InventarioGeneralDeskScreen({super.key});

  @override
  State<InventarioGeneralDeskScreen> createState() =>
      _InventarioGeneralDeskScreenState();
}

class _InventarioGeneralDeskScreenState
    extends State<InventarioGeneralDeskScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  void _navegarConFade(BuildContext context, Widget pantalla) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => pantalla,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(-0.5, 0),
              child: Container(
                width: double.infinity,
                color: const Color(0xFF2C3E50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 38,
                ),
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
                    const Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Inventario General',
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
            ),
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildBarraBusqueda(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildTablaGeneral()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o referencia...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4682B4)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildTablaGeneral() {
    final historialStream =
        FirebaseFirestore.instance
            .collection('historial_inventario_general')
            .orderBy('fecha_actualizacion', descending: true)
            .snapshots();

    final ventasFuture = FirebaseFirestore.instance.collection('ventas').get();

    return FutureBuilder<QuerySnapshot>(
      future: ventasFuture,
      builder: (context, ventasSnapshot) {
        if (ventasSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (ventasSnapshot.hasError) {
          return const Center(child: Text('Error al cargar las ventas.'));
        }

        final ventasDocs = ventasSnapshot.data?.docs ?? [];
        final ventasPorReferencia = <String, int>{};

        for (var venta in ventasDocs) {
          final productos = List<Map<String, dynamic>>.from(venta['productos']);
          for (var producto in productos) {
            final referencia = producto['referencia']?.toString() ?? '';
            final cantidad = (producto['cantidad'] ?? 0) as num;
            ventasPorReferencia[referencia] =
                (ventasPorReferencia[referencia] ?? 0) + cantidad.toInt();
          }
        }

        return StreamBuilder<QuerySnapshot>(
          stream: historialStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data!.docs;
            final Map<String, Map<String, dynamic>> grouped = {};

            for (var doc in allDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final referencia = (data['referencia'] ?? '').toString();
              final nombre = (data['nombre'] ?? '').toString();
              final cantidad = (data['cantidad'] ?? 0) as int;
              final tipo = (data['tipo'] ?? 'entrada').toString();

              final ajusteCantidad = tipo == 'salida' ? -cantidad : cantidad;

              if (!grouped.containsKey(referencia)) {
                grouped[referencia] = {
                  'referencia': referencia,
                  'nombre': nombre,
                  'cantidad': ajusteCantidad,
                };
              } else {
                grouped[referencia]!['cantidad'] += ajusteCantidad;
              }
            }

            ventasPorReferencia.forEach((referencia, cantidadVendida) {
              if (grouped.containsKey(referencia)) {
                grouped[referencia]!['cantidad'] -= cantidadVendida;
              }
            });

            final filtered =
                grouped.values.where((data) {
                  final ref = data['referencia'].toString().toLowerCase();
                  final nombre = data['nombre'].toString().toLowerCase();
                  return searchQuery.isEmpty ||
                      ref.contains(searchQuery) ||
                      nombre.contains(searchQuery);
                }).toList();

            if (filtered.isEmpty) {
              return const Center(
                child: Text('No hay registros para mostrar.'),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final double anchoNombre = totalWidth * 0.3;
                final double anchoReferencia = totalWidth * 0.3;
                final double anchoCantidad = totalWidth * 0.2;
                final double anchoAcciones = totalWidth * 0.1;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: DataTable(
                        columnSpacing: 0,
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFF4682B4),
                        ),
                        headingTextStyle: const TextStyle(color: Colors.white),
                        columns: const [
                          DataColumn(label: Text('Nombre')),
                          DataColumn(label: Text('Referencia')),
                          DataColumn(label: Text('Cantidad')),
                          DataColumn(label: Text('Acción')),
                        ],
                        rows:
                            filtered.map((data) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: anchoNombre,
                                      child: GestureDetector(
                                        onTap: () {
                                          _navegarConFade(
                                            context,
                                            TablainvDeskScreen(
                                              referencia: data['referencia'],
                                              nombre: data['nombre'],
                                            ),
                                          );
                                        },
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Text(
                                            data['nombre'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF4682B4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: anchoReferencia,
                                      child: Align(
                                        alignment: const Alignment(-0.6, 0.0),
                                        child: Text(
                                          data['referencia'],
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: anchoCantidad,
                                      child: Text(
                                        data['cantidad'].toString(),
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: anchoAcciones,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Eliminar',
                                        onPressed: () async {
                                          final confirmar =
                                              await showDialog<bool>(
                                                context: context,
                                                builder:
                                                    (_) => AlertDialog(
                                                      title: const Text(
                                                        'Confirmar eliminación',
                                                      ),
                                                      content: Text(
                                                        '¿Estás seguro de eliminar todos los registros del producto "${data['nombre']}"?',
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                          child: const Text(
                                                            'Cancelar',
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          style:
                                                              ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                          child: const Text(
                                                            'Eliminar',
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              ) ??
                                              false;

                                          if (confirmar) {
                                            final currentUser =
                                                FirebaseAuth
                                                    .instance
                                                    .currentUser;
                                            if (currentUser == null) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Usuario no autenticado',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }

                                            final userDoc =
                                                await FirebaseFirestore.instance
                                                    .collection(
                                                      'usuarios_activos',
                                                    )
                                                    .doc(currentUser.uid)
                                                    .get();

                                            final nombreUsuario =
                                                userDoc.data()?['nombre'] ??
                                                currentUser.email ??
                                                '---';

                                            final docsToDelete = snapshot
                                                .data!
                                                .docs
                                                .where(
                                                  (doc) =>
                                                      doc['referencia']
                                                          .toString() ==
                                                      data['referencia'],
                                                );

                                            for (var doc in docsToDelete) {
                                              await doc.reference.delete();
                                            }

                                            await FirebaseFirestore.instance
                                                .collection('auditoria_general')
                                                .add({
                                                  'accion':
                                                      'Eliminación de Inventario General',
                                                  'detalle':
                                                      'Producto: ${data['nombre']}, Cantidad eliminada: ${data['cantidad']}',
                                                  'fecha': DateTime.now(),
                                                  'usuario_uid':
                                                      currentUser.uid,
                                                  'usuario_nombre':
                                                      nombreUsuario,
                                                });

                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Registros eliminados correctamente.',
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
