import 'package:basefundi/desktop/inventario/editar/categorias_desk.dart';
import 'package:basefundi/desktop/inventario/editar/editcant_prod_desk.dart';
import 'package:basefundi/desktop/inventario/editar/editdatos_prod_desk.dart';

import 'package:basefundi/settings/csv_desk.dart';
import 'package:basefundi/settings/csv_exportar_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Producto {
  String codigo;
  String referencia;
  String nombre;
  double precio;
  num cantidad;
  String categoria;
  int stockDisponible;

  Producto({
    required this.codigo,
    this.referencia = '',
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    this.stockDisponible = 0,
  });

  static Producto fromMap(Map<String, dynamic> map) {
    return Producto(
      codigo: map['codigo'] ?? '',
      referencia: map['referencia'] ?? '',
      nombre: map['nombre'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      cantidad: map['general'] ?? map['cantidad'] ?? 0,
      categoria: map['categoria'] ?? 'Sin categoría',
      stockDisponible: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'referencia': referencia,
      'nombre': nombre,
      'precio': precio,
      'cantidad': cantidad,
      'categoria': categoria,
    };
  }
}

class TotalInvDeskScreen extends StatefulWidget {
  const TotalInvDeskScreen({super.key});

  @override
  State<TotalInvDeskScreen> createState() => _TotalInvDeskScreenState();
}

class _TotalInvDeskScreenState extends State<TotalInvDeskScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<String> categorias = ['Todas'];
  String categoriaSeleccionada = 'Todas';
  int totalProductosFiltrados = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<T?> _navegarConFade<T>(BuildContext context, Widget pantalla) {
    return Navigator.of(context).push<T>(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => pantalla,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 150),
      ),
    );
  }

  Future<Map<String, int>> _cargarStockMultiplesProductos(
    List<String> referencias,
  ) async {
    Map<String, int> stockMap = {};

    for (String referencia in referencias) {
      stockMap[referencia] = 0;
    }
    final listaReferencias = referencias.take(10).toList();

    if (listaReferencias.isEmpty) {
      return {};
    }

    final historialSnapshot =
        await FirebaseFirestore.instance
            .collection('historial_inventario_general')
            .where('referencia', whereIn: referencias.take(10).toList())
            .get();

    for (var doc in historialSnapshot.docs) {
      final data = doc.data();
      final referencia = data['referencia']?.toString() ?? '';
      final tipo = (data['tipo'] ?? 'entrada').toString();
      final cantidad = (data['cantidad'] ?? 0) as int;

      if (stockMap.containsKey(referencia)) {
        if (tipo == 'salida') {
          stockMap[referencia] = stockMap[referencia]! - cantidad;
        } else {
          stockMap[referencia] = stockMap[referencia]! + cantidad;
        }
      }
    }

    final ventasSnapshot =
        await FirebaseFirestore.instance.collection('ventas').get();

    for (var venta in ventasSnapshot.docs) {
      final productos = List<Map<String, dynamic>>.from(venta['productos']);
      for (var producto in productos) {
        final referencia = producto['referencia']?.toString() ?? '';
        final cantidadVendida = (producto['cantidad'] ?? 0) as int;

        if (stockMap.containsKey(referencia)) {
          stockMap[referencia] = stockMap[referencia]! - cantidadVendida;
        }
      }
    }

    return stockMap;
  }

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
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;
    final nombreUsuario = 'Administrador';
    final usuarioUid = user?.uid ?? 'Desconocido';

    for (String col in colecciones) {
      QuerySnapshot snapshot =
          await _firestore
              .collection(col)
              .where('nombre', isEqualTo: nombre)
              .get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final cantidadEliminada = data['cantidad'] ?? 0;

        await _firestore.collection(col).doc(doc.id).delete();

        await _firestore.collection('auditoria_general').add({
          'accion': 'Producto eliminado',
          'detalle':
              'Producto: $nombre, Cantidad eliminada: $cantidadEliminada',
          'fecha': Timestamp.now(),
          'usuario_nombre': nombreUsuario,
          'usuario_uid': usuarioUid,
        });
      }
    }
  }

  void agregarProductoManual() async {
    final resultado = await _navegarConFade(
      context,
      EditarProductoDeskScreen(
        codigoBarras: '',
        nombreInicial: '',
        precioInicial: 0,
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
            'categoria': resultado['categoria'],
            'fecha_creacion': Timestamp.now(),
            'estado': 'en_proceso',
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA CON TÍTULO CENTRADO Y BOTÓN A LA DERECHA
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Botón de regreso
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  // Título centrado (expande para mantenerlo en el centro)
                  Expanded(
                    child: Center(
                      child: Text(
                        'Inventario General',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ CONTENIDO CON FONDO BLANCO
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1400),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Barra de búsqueda + botones de acción
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Buscar por nombre, código o referencia...',
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
                              ),
                              const SizedBox(width: 16),

                              // Botón agregar producto manual
                              ElevatedButton.icon(
                                onPressed: agregarProductoManual,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar Producto'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4682B4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Botón importar CSV
                              ElevatedButton.icon(
                                onPressed: () {
                                  _navegarConFade(
                                    context,
                                    const ImportarProductosDeskScreen(),
                                  );
                                },

                                icon: const Icon(Icons.file_upload),
                                label: const Text('Importar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF27AE60),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón de exportación
                              ElevatedButton.icon(
                                onPressed: () {
                                  exportarInventarioDesk(context);
                                },
                                icon: const Icon(Icons.download),
                                label: const Text('Exportar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(
                                    0xFF4682B4,
                                  ), // azul que quieres
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Filtros de categorías
                        Container(
                          height: 33,
                          margin: const EdgeInsets.symmetric(horizontal: 32),
                          child: FutureBuilder<QuerySnapshot>(
                            future:
                                FirebaseFirestore.instance
                                    .collection('categorias')
                                    .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              if (snapshot.hasData) {
                                final firestoreCategorias =
                                    snapshot.data!.docs
                                        .map((doc) => doc['nombre'] as String)
                                        .toList()
                                      ..sort(
                                        (a, b) => a.toLowerCase().compareTo(
                                          b.toLowerCase(),
                                        ),
                                      );

                                final todasCategorias = [
                                  'Todas',
                                  ...firestoreCategorias,
                                ];

                                return Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        _navegarConFade(
                                          context,
                                          const CategoriasDeskScreen(),
                                        );
                                      },

                                      icon: const Icon(Icons.edit, size: 18),
                                      label: const Text('Editar Categorías'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4682B4,
                                        ),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),

                                    Expanded(
                                      child: ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: todasCategorias.length,
                                        separatorBuilder:
                                            (_, __) => const SizedBox(width: 8),
                                        itemBuilder: (context, index) {
                                          final categoria =
                                              todasCategorias[index];
                                          final isSelected =
                                              categoria ==
                                              categoriaSeleccionada;

                                          return GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                categoriaSeleccionada =
                                                    categoria;
                                              });
                                            },
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical:
                                                    4, // Más delgado verticalmente
                                              ),
                                              constraints: const BoxConstraints(
                                                minHeight:
                                                    28, // Opcional: ajusta la altura mínima
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    isSelected
                                                        ? const Color(
                                                          0xFF4682B4,
                                                        )
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color:
                                                      isSelected
                                                          ? const Color(
                                                            0xFF4682B4,
                                                          )
                                                          : Colors
                                                              .grey
                                                              .shade300,
                                                ),
                                                boxShadow:
                                                    isSelected
                                                        ? [
                                                          BoxShadow(
                                                            color: Colors.blue
                                                                .withOpacity(
                                                                  0.3,
                                                                ),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                  0,
                                                                  3,
                                                                ),
                                                          ),
                                                        ]
                                                        : [],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  categoria,
                                                  style: TextStyle(
                                                    color:
                                                        isSelected
                                                            ? Colors.white
                                                            : Colors.black87,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        12, // También puedes bajar un punto la fuente
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                return const Center(
                                  child: Text('Sin categorías'),
                                );
                              }
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Lista de productos con stock calculado
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                _firestore
                                    .collection('inventario_general')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final productos =
                                  snapshot.data!.docs
                                      .map(
                                        (doc) => Producto.fromMap(
                                          doc.data() as Map<String, dynamic>,
                                        ),
                                      )
                                      .where((p) {
                                        final coincideBusqueda =
                                            p.nombre.toLowerCase().contains(
                                              searchQuery.toLowerCase(),
                                            ) ||
                                            p.codigo.toLowerCase().contains(
                                              searchQuery.toLowerCase(),
                                            ) ||
                                            p.referencia.toLowerCase().contains(
                                              searchQuery.toLowerCase(),
                                            );
                                        final coincideCategoria =
                                            categoriaSeleccionada == 'Todas' ||
                                            p.categoria ==
                                                categoriaSeleccionada;
                                        return coincideBusqueda &&
                                            coincideCategoria;
                                      })
                                      .toList();

                              final total = productos.length;

                              return Column(
                                children: [
                                  // Contador de productos
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          'Total: $total productos en "${categoriaSeleccionada == 'Todas' ? 'Todas las categorías' : categoriaSeleccionada}"',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Grid de productos
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                      ),
                                      child: FutureBuilder<Map<String, int>>(
                                        future: _cargarStockMultiplesProductos(
                                          productos
                                              .map((p) => p.referencia)
                                              .toList(),
                                        ),
                                        builder: (context, stockSnapshot) {
                                          if (stockSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CircularProgressIndicator(),
                                                  SizedBox(height: 16),
                                                  Text(
                                                    'Calculando stocks disponibles...',
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          final stockMap =
                                              stockSnapshot.data ?? {};

                                          return GridView.builder(
                                            padding: const EdgeInsets.only(
                                              bottom: 20,
                                            ),
                                            itemCount: productos.length,
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount:
                                                      5, // Más columnas para desktop
                                                  crossAxisSpacing: 16,
                                                  mainAxisSpacing: 16,
                                                  childAspectRatio: 0.75,
                                                ),
                                            itemBuilder: (context, index) {
                                              final producto = productos[index];
                                              final stockDisponible =
                                                  stockMap[producto
                                                      .referencia] ??
                                                  0;

                                              return GestureDetector(
                                                onTap: () {
                                                  _navegarConFade(
                                                    context,
                                                    EditInvProdDeskScreen(
                                                      producto: producto,
                                                    ),
                                                  );
                                                },

                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          stockDisponible <= 0
                                                              ? Colors
                                                                  .red
                                                                  .shade300
                                                              : stockDisponible <
                                                                  5
                                                              ? Colors
                                                                  .orange
                                                                  .shade300
                                                              : Colors
                                                                  .green
                                                                  .shade300,
                                                      width: 2,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.1),
                                                        blurRadius: 8,
                                                        offset: const Offset(
                                                          0,
                                                          2,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    12,
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      // Ícono del producto
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8,
                                                            ),
                                                        child: const Icon(
                                                          Icons.construction,
                                                          size: 32,
                                                          color: Color(
                                                            0xFF2C3E50,
                                                          ),
                                                        ),
                                                      ),

                                                      // Nombre del producto
                                                      Text(
                                                        producto.nombre,
                                                        textAlign:
                                                            TextAlign.center,
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 12,
                                                          color: Color(
                                                            0xFF2C3E50,
                                                          ),
                                                        ),
                                                      ),

                                                      // Referencia si existe
                                                      if (producto
                                                          .referencia
                                                          .isNotEmpty)
                                                        Text(
                                                          'Ref: ${producto.referencia}',
                                                          textAlign:
                                                              TextAlign.center,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 10,
                                                                color:
                                                                    Colors.grey,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                              ),
                                                        ),

                                                      // Stock disponible
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              stockDisponible <=
                                                                      0
                                                                  ? Colors
                                                                      .red
                                                                      .shade100
                                                                  : stockDisponible <
                                                                      5
                                                                  ? Colors
                                                                      .orange
                                                                      .shade100
                                                                  : Colors
                                                                      .green
                                                                      .shade100,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'Disponible: $stockDisponible',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                stockDisponible <=
                                                                        0
                                                                    ? Colors
                                                                        .red
                                                                        .shade700
                                                                    : stockDisponible <
                                                                        5
                                                                    ? Colors
                                                                        .orange
                                                                        .shade700
                                                                    : Colors
                                                                        .green
                                                                        .shade700,
                                                          ),
                                                        ),
                                                      ),

                                                      // Botones de acción
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          Tooltip(
                                                            message: 'Editar',
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              onTap: () async {
                                                                final resultado = await _navegarConFade(
                                                                  context,
                                                                  EditarProductoDeskScreen(
                                                                    codigoBarras:
                                                                        producto
                                                                            .codigo,
                                                                    nombreInicial:
                                                                        producto
                                                                            .nombre,
                                                                    precioInicial:
                                                                        producto
                                                                            .precio,
                                                                  ),
                                                                );

                                                                if (resultado !=
                                                                    null) {
                                                                  await _firestore
                                                                      .collection(
                                                                        'inventario_general',
                                                                      )
                                                                      .doc(
                                                                        resultado['codigo'],
                                                                      )
                                                                      .set({
                                                                        'codigo':
                                                                            resultado['codigo'],
                                                                        'referencia':
                                                                            resultado['referencia'],
                                                                        'nombre':
                                                                            resultado['nombre'],
                                                                        'costo':
                                                                            resultado['costo'],
                                                                        'precios':
                                                                            resultado['precios'],
                                                                        'categoria':
                                                                            resultado['categoria'],
                                                                        'fecha_creacion':
                                                                            Timestamp.now(),
                                                                      });
                                                                }
                                                              },

                                                              child: const Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      8,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .edit_outlined,
                                                                  color: Color(
                                                                    0xFF4682B4,
                                                                  ),
                                                                  size: 20,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          Tooltip(
                                                            message: 'Eliminar',
                                                            child: InkWell(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                              onTap:
                                                                  () => eliminarProductoPorNombre(
                                                                    producto
                                                                        .nombre,
                                                                  ),
                                                              child: const Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      8,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .delete_outline,
                                                                  color:
                                                                      Colors
                                                                          .redAccent,
                                                                  size: 20,
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
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
