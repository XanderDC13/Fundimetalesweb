import 'package:basefundi/desktop/inventario/tablas/tablainv_fundicion_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InventarioFundicionDeskScreen extends StatefulWidget {
  const InventarioFundicionDeskScreen({super.key});

  @override
  State<InventarioFundicionDeskScreen> createState() =>
      _InventarioFundicionDeskScreenState();
}

class _InventarioFundicionDeskScreenState
    extends State<InventarioFundicionDeskScreen>
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
    return MainDeskLayout(
      child: Column(
        children: [
          // CABECERA ESTILO DESK
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
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Inventario Fundición',
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
            child: Container(
              color: Colors.white, // ✅ Aplica el color aquí
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildBusqueda(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildTablaFundicion()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
    // ✅ NUEVA RUTA: inventarios/fundicion/productos
    stream: FirebaseFirestore.instance
        .collection('inventarios')
        .doc('fundicion')
        .collection('productos')
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final allDocs = snapshot.data!.docs;
      final List<Map<String, dynamic>> productos = [];

      // ✅ Procesar cada documento (cada documento es un producto con su referencia como ID)
      for (var doc in allDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final referencia = doc.id; // El ID del documento es la referencia
        final cantidad = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;
        
        // ✅ Obtener el nombre del producto desde la colección productos usando la referencia
        productos.add({
          'referencia': referencia,
          'cantidad': cantidad,
          'docId': doc.id, // Guardar el ID para eliminación
        });
      }

      // ✅ Crear un Future para obtener los nombres de los productos
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _obtenerProductosConNombres(productos),
        builder: (context, productosSnapshot) {
          if (!productosSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final productosCompletos = productosSnapshot.data!;
          
          final filtered = productosCompletos.where((data) {
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
              final double anchoReferencia = totalWidth * 0.3;
              final double anchoCantidad = totalWidth * 0.2;
              final double anchoAcciones = totalWidth * 0.1;

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
                  rows: filtered.map((data) {
                    return DataRow(
                      cells: [
                        DataCell(
                          SizedBox(
                            width: anchoNombre,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () {
                                  navegarConFade(
                                    context,
                                    TablaInvFundicionDeskScreen(
                                      referencia: data['referencia'],
                                      nombre: data['nombre'],
                                    ),
                                  );
                                },
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    data['nombre'] ?? 'Sin nombre',
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
                                final confirmar = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Confirmar eliminación'),
                                    content: Text(
                                      '¿Eliminar "${data['nombre']}" del inventario de Fundición?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                ) ?? false;

                                if (confirmar) {
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  if (currentUser == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Usuario no autenticado'),
                                      ),
                                    );
                                    return;
                                  }

                                  final userDoc = await FirebaseFirestore.instance
                                      .collection('usuarios_activos')
                                      .doc(currentUser.uid)
                                      .get();

                                  final nombreUsuario = userDoc.data()?['nombre'] ??
                                      currentUser.email ?? '---';

                                  // ✅ ELIMINAR DE LA NUEVA ESTRUCTURA
                                  await FirebaseFirestore.instance
                                      .collection('inventarios')
                                      .doc('fundicion')
                                      .collection('productos')
                                      .doc(data['referencia'])
                                      .delete();

                                  // ✅ Registrar en auditoría
                                  await FirebaseFirestore.instance
                                      .collection('auditoria_general')
                                      .add({
                                        'accion': 'Eliminación de Inventario Fundición',
                                        'detalle': 'Producto: ${data['nombre']}, Referencia: ${data['referencia']}, Cantidad eliminada: ${data['cantidad']}',
                                        'fecha': DateTime.now(),
                                        'usuario_uid': currentUser.uid,
                                        'usuario_nombre': nombreUsuario,
                                      });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Producto eliminado correctamente'),
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
    },
  );
}

// ✅ MÉTODO AUXILIAR PARA OBTENER NOMBRES DE PRODUCTOS
Future<List<Map<String, dynamic>>> _obtenerProductosConNombres(
  List<Map<String, dynamic>> productos,
) async {
  final List<Map<String, dynamic>> productosCompletos = [];
  
  for (var producto in productos) {
    try {
      // Buscar el producto en la colección productos usando la referencia
      final productoDoc = await FirebaseFirestore.instance
          .collection('productos')
          .where('referencia', isEqualTo: producto['referencia'])
          .limit(1)
          .get();
      
      String nombre = 'Producto no encontrado';
      if (productoDoc.docs.isNotEmpty) {
        nombre = productoDoc.docs.first.data()['nombre'] ?? 'Sin nombre';
      }
      
      productosCompletos.add({
        'referencia': producto['referencia'],
        'cantidad': producto['cantidad'],
        'nombre': nombre,
        'docId': producto['docId'],
      });
    } catch (e) {
      print('Error obteniendo producto ${producto['referencia']}: $e');
      productosCompletos.add({
        'referencia': producto['referencia'],
        'cantidad': producto['cantidad'],
        'nombre': 'Error al cargar',
        'docId': producto['docId'],
      });
    }
  }
  
  return productosCompletos;
}
}
