import 'package:basefundi/screens/inventarios/editinvprod.dart'; // <-- importamos la pantalla para editar
import 'package:basefundi/screens/inventarios/editprod.dart';
import 'package:basefundi/screens/inventarios/scaninv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Producto {
  String codigo;
  String nombre;
  double precio;
  num cantidad;

  Producto({
    required this.codigo,
    required this.nombre,
    required this.precio,
    required this.cantidad,
  });

  static Producto fromMap(Map<String, dynamic> map) {
    return Producto(
      codigo: map['codigo'] ?? '',
      nombre: map['nombre'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      cantidad: map['general'] ?? map['cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
    };
  }
}

class TotalInvScreen extends StatefulWidget {
  const TotalInvScreen({super.key});

  @override
  State<TotalInvScreen> createState() => _TotalInvScreenState();
}

class _TotalInvScreenState extends State<TotalInvScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> eliminarProductoPorNombre(String nombre) async {
    bool confirmar =
        await showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Eliminar producto'),
                content: const Text(
                  '¿Estás seguro de eliminar este producto? Esto eliminará todos los registros en Fundición, Pintura y General.',
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  TextButton(
                    child: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
        ) ??
        false;

    if (!confirmar) return;

    List<String> colecciones = [
      'inventario_general',
      'inventario_fundicion',
      'inventario_pintura',
      'historial_inventario_general',
    ];

    for (String col in colecciones) {
      QuerySnapshot snapshot =
          await _firestore
              .collection(col)
              .where('nombre', isEqualTo: nombre)
              .get();

      for (var doc in snapshot.docs) {
        await _firestore.collection(col).doc(doc.id).delete();
      }
    }
  }

  void agregarProductoDesdeEscaneo(String codigo) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditarProductoScreen(
              codigoBarras: codigo,
              nombreInicial: '',
              precioInicial: 0,
            ),
      ),
    );

    if (resultado != null) {
      await _firestore
          .collection('inventario_general')
          .doc(resultado['codigo'])
          .set({
            'codigo': resultado['codigo'],
            'nombre': resultado['nombre'],
            'precio': resultado['precio'],
            'cantidad': resultado['cantidad'],
            'fecha_creacion': Timestamp.now(),
            'estado': 'en_proceso',
          });
    }
  }

  void agregarProductoManual() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => EditarProductoScreen(
              codigoBarras: '',
              nombreInicial: '',
              precioInicial: 0,
            ),
      ),
    );

    if (resultado != null) {
      await _firestore
          .collection('inventario_general')
          .doc(resultado['codigo'])
          .set({
            'codigo': resultado['codigo'],
            'nombre': resultado['nombre'],
            'precio': resultado['precio'],
            'cantidad': resultado['cantidad'],
            'fecha_creacion': Timestamp.now(),
            'estado': 'en_proceso',
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: const Center(
                child: Text(
                  'Productos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Barra de búsqueda + iconos
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: const Color(0xFFE5E7EB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ScanInv(onCodigoEscaneado: agregarProductoDesdeEscaneo),
                  const SizedBox(width: 4),
                  Material(
                    color: Colors.white,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(
                        Icons.add,
                        size: 38,
                        color: Colors.black87,
                      ),
                      onPressed: agregarProductoManual,
                    ),
                  ),
                ],
              ),
            ),

            // Productos en grid
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('inventario_general').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final productos =
                      snapshot.data!.docs
                          .map(
                            (doc) => Producto.fromMap(
                              doc.data() as Map<String, dynamic>,
                            ),
                          )
                          .where(
                            (p) => p.nombre.toLowerCase().contains(
                              searchQuery.toLowerCase(),
                            ),
                          )
                          .toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: productos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                      itemBuilder: (context, index) {
                        final producto = productos[index];
                        return GestureDetector(
                          onTap: () async {
                            // Navegar a EditInvProdScreen con el producto completo
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        EditInvProdScreen(producto: producto),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.inventory_2,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                                Text(
                                  producto.nombre,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                      ),
                                      onPressed:
                                          () => eliminarProductoPorNombre(
                                            producto.nombre,
                                          ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.blue,
                                      ),
                                      onPressed: () async {
                                        // Navegamos a EditarProductoScreen para editar
                                        final resultado = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    EditarProductoScreen(
                                                      codigoBarras:
                                                          producto.codigo,
                                                      nombreInicial:
                                                          producto.nombre,
                                                      precioInicial:
                                                          producto.precio,
                                                    ),
                                          ),
                                        );
                                        // Actualizamos Firestore si se devuelve resultado
                                        if (resultado != null) {
                                          await _firestore
                                              .collection('inventario_general')
                                              .doc(resultado['codigo'])
                                              .set({
                                                'codigo': resultado['codigo'],
                                                'nombre': resultado['nombre'],
                                                'precio': resultado['precio'],
                                                'cantidad':
                                                    resultado['cantidad'],
                                                'fecha_creacion':
                                                    Timestamp.now(),
                                                'estado': 'en_proceso',
                                              });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
