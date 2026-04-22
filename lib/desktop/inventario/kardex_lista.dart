import 'package:basefundi/desktop/inventario/kardex_detalle.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class KardexListScreen extends StatefulWidget {
  const KardexListScreen({super.key});

  @override
  State<KardexListScreen> createState() => _KardexListScreenState();
}

class _KardexListScreenState extends State<KardexListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String categoriaSeleccionada = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, int>> _obtenerTotalesKardex(String referencia) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('kardex_movimientos')
              .where('referencia', isEqualTo: referencia)
              .get();

      int totalEntradas = 0;
      int totalSalidas = 0;
      int totalRechazos = 0;

      for (var doc in snapshot.docs) {
        final tipo = doc['tipo'] as String;
        final cantidad = (doc['cantidad'] ?? 0) as int;

        if (tipo == 'entrada' || tipo == 'inventario_inicial') {
          // ← CAMBIO
          totalEntradas += cantidad;
        } else if (tipo == 'salida') {
          totalSalidas += cantidad;
        } else if (tipo == 'rechazo') {
          totalRechazos += cantidad;
        }
      }

      final saldoActual = totalEntradas - totalSalidas - totalRechazos;

      return {
        'entradas': totalEntradas,
        'salidas': totalSalidas,
        'rechazos': totalRechazos,
        'saldo': saldoActual,
      };
    } catch (e) {
      print('Error obteniendo totales kardex: $e');
      return {'entradas': 0, 'salidas': 0, 'rechazos': 0, 'saldo': 0};
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Kardex de Inventario',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Barra de búsqueda y filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Búsqueda
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o referencia...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
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

                const SizedBox(height: 12),

                // Filtro de categorías
                FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance.collection('categorias').get(),
                  builder: (context, snapshot) {
                    List<String> categorias = ['Todas'];

                    if (snapshot.hasData) {
                      final firestoreCategorias =
                          snapshot.data!.docs
                              .map((doc) => doc['nombre'] as String)
                              .toList()
                            ..sort(
                              (a, b) =>
                                  a.toLowerCase().compareTo(b.toLowerCase()),
                            );
                      categorias.addAll(firestoreCategorias);
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<String>(
                        value: categoriaSeleccionada,
                        isExpanded: true,
                        underline: Container(),
                        icon: const Icon(
                          Icons.filter_list,
                          color: Color(0xFF4682B4),
                        ),
                        items:
                            categorias.map((String categoria) {
                              return DropdownMenuItem<String>(
                                value: categoria,
                                child: Text(categoria),
                              );
                            }).toList(),
                        onChanged: (String? nueva) {
                          if (nueva != null) {
                            setState(() {
                              categoriaSeleccionada = nueva;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de productos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('productos')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay productos registrados'),
                  );
                }

                final productos =
                    snapshot.data!.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre =
                          (data['nombre'] ?? '').toString().toLowerCase();
                      final referencia =
                          (data['referencia'] ?? '').toString().toLowerCase();
                      final categoria = data['categoria'] ?? '';

                      final coincideBusqueda =
                          searchQuery.isEmpty ||
                          nombre.contains(searchQuery.toLowerCase()) ||
                          referencia.contains(searchQuery.toLowerCase());

                      final coincideCategoria =
                          categoriaSeleccionada == 'Todas' ||
                          categoria == categoriaSeleccionada;

                      return coincideBusqueda && coincideCategoria;
                    }).toList();

                if (productos.isEmpty) {
                  return const Center(
                    child: Text(
                      'No se encontraron productos con esos criterios',
                    ),
                  );
                }

                return Column(
                  children: [
                    // Contador
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Total: ${productos.length} productos',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ),

                    // Grid de productos
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          itemCount: productos.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6, // ✅ 6 columnas mínimo
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.0, // ✅ Cuadrados perfectos
                              ),
                          itemBuilder: (context, index) {
                            final doc = productos[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final referencia = data['referencia'] ?? doc.id;
                            final nombre = data['nombre'] ?? 'Sin nombre';
                            final categoria =
                                data['categoria'] ?? 'Sin categoría';

                            return FutureBuilder<Map<String, int>>(
                              future: _obtenerTotalesKardex(referencia),
                              builder: (context, totalesSnapshot) {
                                final totales =
                                    totalesSnapshot.data ??
                                    {
                                      'entradas': 0,
                                      'salidas': 0,
                                      'rechazos': 0,
                                      'saldo': 0,
                                    };

                                return GestureDetector(
                                  onTap: () {
                                    navegarConFade(
                                      context,
                                      KardexDetailScreen(
                                        referencia: referencia,
                                        nombre: nombre,
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.08),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Ícono + Categoría compacta
                                        Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.inventory_2_outlined,
                                                color: Color(0xFF2C3E50),
                                                size: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              categoria.length > 6
                                                  ? categoria
                                                      .substring(0, 6)
                                                      .toUpperCase()
                                                  : categoria.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 6,
                                                color: Color(0xFF4682B4),
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        ),

                                        // Nombre del producto
                                        Text(
                                          nombre,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 9,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),

                                        // Referencia
                                        Text(
                                          referencia,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 7,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),

                                        // Saldo actual destacado
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                totales['saldo']! > 0
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            border: Border.all(
                                              color:
                                                  totales['saldo']! > 0
                                                      ? Colors.green.shade200
                                                      : Colors.red.shade200,
                                              width: 0.5,
                                            ),
                                          ),
                                          child: Text(
                                            '${totales['saldo']}',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  totales['saldo']! > 0
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700,
                                            ),
                                          ),
                                        ),

                                        // Totales E/S/R ultra compactos
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildMiniStat(
                                              'E',
                                              totales['entradas']!,
                                              Colors.blue,
                                            ),
                                            _buildMiniStat(
                                              'S',
                                              totales['salidas']!,
                                              Colors.orange,
                                            ),
                                            _buildMiniStat(
                                              'R',
                                              totales['rechazos']!,
                                              Colors.red,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, int valor, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 6,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$valor',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
