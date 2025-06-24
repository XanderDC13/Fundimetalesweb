import 'package:basefundi/screens/inventarios/editinvprod.dart';
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                title: Row(
                  children: const [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 30,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Eliminar producto',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  '¿Estás seguro de eliminar este producto? Se eliminarán todos los registros en Fundición, Pintura y General.',
                  style: TextStyle(fontSize: 16),
                ),
                actionsPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                actions: [
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    icon: const Icon(
                      Icons.delete_forever,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Eliminar',
                      style: TextStyle(color: Colors.white, fontSize: 16),
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
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
            Container(
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
                        fillColor: const Color.fromARGB(255, 255, 255, 255),
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
                            (p) =>
                                p.nombre.toLowerCase().contains(
                                  searchQuery.toLowerCase(),
                                ) ||
                                p.codigo.toLowerCase().contains(
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
                            childAspectRatio: 0.7,
                          ),
                      itemBuilder: (context, index) {
                        final producto = productos[index];
                        return GestureDetector(
                          onTap: () async {
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
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),

                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF2ECC71),
                                        Color(0xFF2ECC71),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.tire_repair,
                                    size: 28,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  producto.nombre,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                                Text(
                                  'Stock: ${producto.cantidad}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFB0BEC5),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Tooltip(
                                      message: 'Eliminar',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap:
                                            () => eliminarProductoPorNombre(
                                              producto.nombre,
                                            ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Tooltip(
                                      message: 'Editar',
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(12),
                                        onTap: () async {
                                          final resultado =
                                              await Navigator.push(
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
                                          if (resultado != null) {
                                            await _firestore
                                                .collection(
                                                  'inventario_general',
                                                )
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
                                        child: const Padding(
                                          padding: EdgeInsets.all(6),
                                          child: Icon(
                                            Icons.edit_outlined,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ),
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
