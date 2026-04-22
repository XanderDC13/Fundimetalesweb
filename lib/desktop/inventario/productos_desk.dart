import 'dart:async';
import 'package:basefundi/desktop/inventario/editar/editcant_prod_desk.dart';
import 'package:basefundi/desktop/inventario/editar/editdatos_prod_desk.dart';
import 'package:basefundi/services/csv_importar_desk.dart';
import 'package:basefundi/services/csv_exportar_desk.dart';
import 'package:basefundi/services/navbar_desk.dart';
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
  Map<String, int> stockPorProceso;

  Producto({
    required this.codigo,
    this.referencia = '',
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.categoria,
    this.stockPorProceso = const {},
  });

  static Producto fromMap(Map<String, dynamic> map) {
    return Producto(
      codigo: map['codigo'] ?? '',
      referencia: map['referencia'] ?? '',
      nombre: map['nombre'] ?? '',
      // Antes: (map['precio'] ?? 0).toDouble()  ← falla si viene como String
      precio:
          double.tryParse(map['precio']?.toString() ?? '0') ??
          double.tryParse(map['precios']?['pvp']?.toString() ?? '0') ??
          0.0,
      cantidad:
          num.tryParse(map['general']?.toString() ?? '') ??
          num.tryParse(map['cantidad']?.toString() ?? '') ??
          0,
      categoria: map['categoria'] ?? 'Sin categoría',
      stockPorProceso: {},
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

class Proceso {
  String id;
  String nombre;
  int orden;

  Proceso({required this.id, required this.nombre, required this.orden});

  static Proceso fromMap(String id, Map<String, dynamic> map) {
    return Proceso(
      id: id,
      nombre: map['nombre'] ?? '',
      orden: map['orden'] ?? 0,
    );
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
  String procesoSeleccionado = 'Todos';
  int totalProductosFiltrados = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Proceso> procesos = [];
  StreamSubscription<QuerySnapshot>? _ventasSubscription;
  List<Map<String, dynamic>> _resultados = [];
  bool _haBuscado = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _cargarProcesos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ventasSubscription?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _cargarProcesos() async {
    try {
      final snapshot =
          await _firestore.collection('procesos').orderBy('orden').get();

      setState(() {
        procesos =
            snapshot.docs
                .map((doc) => Proceso.fromMap(doc.id, doc.data()))
                .toList();
      });
    } catch (e) {
      print('Error cargando procesos: $e');
    }
  }

  Future<void> _buscarProductos(String query) async {
    if (query.trim().length < 1) {
      setState(() {
        _resultados = [];
        _haBuscado = false;
      });
      return;
    }

    final snapshot = await _firestore.collection('productos').get();
    final filtrados =
        snapshot.docs.where((doc) {
          final data = doc.data();
          final nombre = (data['nombre'] ?? '').toString().toLowerCase();
          final codigo = (data['codigo'] ?? '').toString().toLowerCase();
          final ref = (data['referencia'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          final categoria = (data['categoria'] ?? '').toString();

          final coincideBusqueda =
              nombre.contains(q) || codigo.contains(q) || ref.contains(q);
          final coincideCategoria =
              categoriaSeleccionada == 'Todas' ||
              categoria == categoriaSeleccionada;
          return coincideBusqueda && coincideCategoria;
        }).toList();

    setState(() {
      _resultados = filtrados.map((doc) => doc.data()).toList();
      _haBuscado = true;
    });
  }

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

  Future<void> eliminarProductoPorCodigo(String codigo, String nombre) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Eliminar producto',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Seguro que deseas eliminar "$nombre"?',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    if (!confirmar!) return;

    final FirebaseAuth _auth = FirebaseAuth.instance;
    final user = _auth.currentUser;
    final nombreUsuario = 'Administrador';
    final usuarioUid = user?.uid ?? 'Desconocido';

    {
      // Eliminar de la colección productos
      await _firestore.collection('productos').doc(codigo).delete();

      // Eliminar inventarios de todos los procesos
      for (var proceso in procesos) {
        await _firestore
            .collection('inventarios')
            .doc(proceso.id)
            .collection('productos')
            .doc(codigo)
            .delete();
      }

      // Eliminar de rezagos
      await _firestore
          .collection('inventarios')
          .doc('rezagos')
          .collection('productos')
          .doc(codigo)
          .delete();

      // Registrar en auditoría
      await _firestore.collection('auditoria_general').add({
        'accion': 'Eliminar producto',
        'detalle':
            'Producto: $nombre (Código: $codigo) - Eliminado de todos los procesos',
        'fecha': Timestamp.now(),
        'usuario_nombre': nombreUsuario,
        'usuario_uid': usuarioUid,
      });
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
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(resultado['codigo'])
          .set({
            'codigo': resultado['codigo'],
            'referencia': resultado['referencia'],
            'nombre': resultado['nombre'],
            'precios': resultado['precios'],
            'categoria': resultado['categoria'],
            'fecha_creacion': Timestamp.now(),
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
                  Expanded(
                    child: Center(
                      child: Text(
                        'Inventario',
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

                        // Barra de búsqueda + filtros + botones de acción
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
                                    if (_debounce?.isActive ?? false)
                                      _debounce!.cancel();
                                    _debounce = Timer(
                                      const Duration(milliseconds: 600),
                                      () {
                                        _buscarProductos(value);
                                      },
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Dropdown de categorías
                              FutureBuilder<QuerySnapshot>(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('categorias')
                                        .get(),
                                builder: (context, snapshot) {
                                  List<String> todasCategorias = ['Todas'];

                                  if (snapshot.hasData) {
                                    final firestoreCategorias =
                                        snapshot.data!.docs
                                            .map(
                                              (doc) => doc['nombre'] as String,
                                            )
                                            .toList()
                                          ..sort(
                                            (a, b) => a.toLowerCase().compareTo(
                                              b.toLowerCase(),
                                            ),
                                          );
                                    todasCategorias.addAll(firestoreCategorias);
                                  }

                                  return Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFFFFFFF),
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.white,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    child: DropdownButton<String>(
                                      value: categoriaSeleccionada,
                                      hint: const Text('Categoría'),
                                      underline: Container(),
                                      dropdownColor: Colors.white,
                                      icon: const Icon(
                                        Icons.filter_list,
                                        color: Color(0xFF4682B4),
                                      ),
                                      items:
                                          todasCategorias.map((
                                            String categoria,
                                          ) {
                                            return DropdownMenuItem<String>(
                                              value: categoria,
                                              child: Text(
                                                categoria,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (String? nuevaCategoria) {
                                        if (nuevaCategoria != null) {
                                          setState(() {
                                            categoriaSeleccionada =
                                                nuevaCategoria;
                                          });
                                          // Agrega esta línea:
                                          _buscarProductos(searchQuery);
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(width: 12),

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
                                    const ImportarDualScreen(),
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
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Lista de productos con stock por proceso
                        Expanded(
                          child:
                              !_haBuscado
                                  ? const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.search,
                                          size: 64,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'Escribe el nombre, código o referencia\npara buscar productos',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : _resultados.isEmpty
                                  ? Center(
                                    child: Text(
                                      'Sin resultados para "$searchQuery"',
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                  : Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 32,
                                          vertical: 8,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              'Total: ${_resultados.length} productos',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                          ),
                                          child: GridView.builder(
                                            padding: const EdgeInsets.only(
                                              bottom: 10,
                                            ),
                                            itemCount: _resultados.length,
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 6,
                                                  crossAxisSpacing: 12,
                                                  mainAxisSpacing: 12,
                                                  childAspectRatio: 1.2,
                                                ),
                                            itemBuilder: (context, index) {
                                              final producto = Producto.fromMap(
                                                _resultados[index],
                                              );
                                              return GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (context) => Dialog(
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  12,
                                                                ),
                                                          ),
                                                          child: SizedBox(
                                                            width: 400,
                                                            child:
                                                                EditInvProdDeskScreen(
                                                                  producto:
                                                                      producto,
                                                                ),
                                                          ),
                                                        ),
                                                  );
                                                },
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          Colors.grey.shade400,
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.grey
                                                            .withOpacity(0.08),
                                                        blurRadius: 6,
                                                        offset: const Offset(
                                                          0,
                                                          1,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    6,
                                                  ),
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade50,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              4,
                                                            ),
                                                        child: const Icon(
                                                          Icons.construction,
                                                          size: 24,
                                                          color: Color(
                                                            0xFF2C3E50,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
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
                                                      if (producto
                                                          .referencia
                                                          .isNotEmpty) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
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
                                                      ],
                                                      const SizedBox(
                                                        height: 30,
                                                      ),
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
                                                                    8,
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
                                                                        'productos',
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
                                                                        'precios':
                                                                            resultado['precios'],
                                                                        'categoria':
                                                                            resultado['categoria'],
                                                                        'fecha_creacion':
                                                                            Timestamp.now(),
                                                                      });
                                                                  // Refresca resultados
                                                                  _buscarProductos(
                                                                    searchQuery,
                                                                  );
                                                                }
                                                              },
                                                              child: const Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      4,
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
                                                                    8,
                                                                  ),
                                                              onTap: () async {
                                                                await eliminarProductoPorCodigo(
                                                                  producto
                                                                      .codigo,
                                                                  producto
                                                                      .nombre,
                                                                );
                                                                // Refresca resultados
                                                                _buscarProductos(
                                                                  searchQuery,
                                                                );
                                                              },
                                                              child: const Padding(
                                                                padding:
                                                                    EdgeInsets.all(
                                                                      4,
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
                                          ),
                                        ),
                                      ),
                                    ],
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
