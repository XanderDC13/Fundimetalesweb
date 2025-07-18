import 'package:basefundi/movil/inventario/tablas/tablainv_fundicion_movil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InventarioFundicionScreen extends StatefulWidget {
  const InventarioFundicionScreen({super.key});

  @override
  State<InventarioFundicionScreen> createState() =>
      _InventarioFundicionScreenState();
}

class _InventarioFundicionScreenState extends State<InventarioFundicionScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

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
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Column(
        children: [
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                child: const Center(
                  child: Text(
                    'Inventario Fundición',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildBusqueda(),
          const SizedBox(height: 8),
          Expanded(child: _buildTablaFundicion()),
        ],
      ),
    );
  }

  Widget _buildBusqueda() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o código...',
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

  Widget _buildTablaFundicion() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('inventario_fundicion')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;
        final Map<String, Map<String, dynamic>> grouped = {};

        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final nombre = (data['nombre'] ?? '').toString();
          final referencia = (data['referencia'] ?? '').toString();
          final cantidad =
              int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;

          if (!grouped.containsKey(nombre)) {
            grouped[nombre] = {
              'nombre': nombre,
              'referencia': referencia,
              'cantidad': cantidad,
            };
          } else {
            grouped[nombre]!['cantidad'] += cantidad;
          }
        }

        final filtered =
            grouped.values.where((data) {
              final nombre = data['nombre'].toString().toLowerCase();
              final referencia = data['referencia'].toString().toLowerCase();
              return searchQuery.isEmpty ||
                  nombre.contains(searchQuery) ||
                  referencia.contains(searchQuery);
            }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No hay registros para mostrar.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final double anchoNombre = totalWidth * 0.3;
            final double anchoreferencia = totalWidth * 0.30;
            final double anchoCantidad = totalWidth * 0.2;
            final double anchoAcciones = totalWidth * 0.10;

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
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
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => TablaInvFundicionScreen(
                                              referencia: data['referencia'],
                                              nombre: data['nombre'],
                                            ),
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
                          ),
                          DataCell(
                            SizedBox(
                              width: anchoreferencia,
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
                                                '¿Eliminar todos los registros de "${data['nombre']}" en Fundición?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancelar'),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Eliminar'),
                                                ),
                                              ],
                                            ),
                                      ) ??
                                      false;

                                  if (confirmar) {
                                    final currentUser =
                                        FirebaseAuth.instance.currentUser;
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
                                            .collection('usuarios_activos')
                                            .doc(currentUser.uid)
                                            .get();

                                    final nombreUsuario =
                                        userDoc.data()?['nombre'] ??
                                        currentUser.email ??
                                        '---';

                                    final docsToDelete = snapshot.data!.docs
                                        .where(
                                          (doc) =>
                                              doc['nombre'].toString() ==
                                              data['nombre'],
                                        );

                                    for (var doc in docsToDelete) {
                                      await doc.reference.delete();
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('auditoria_general')
                                        .add({
                                          'accion':
                                              'Eliminación de Inventario Fundición',
                                          'detalle':
                                              'Producto: ${data['nombre']}, Cantidad eliminada: ${data['cantidad']}',
                                          'fecha': DateTime.now(),
                                          'usuario_uid': currentUser.uid,
                                          'usuario_nombre': nombreUsuario,
                                        });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Registros eliminados correctamente',
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
            );
          },
        );
      },
    );
  }
}
