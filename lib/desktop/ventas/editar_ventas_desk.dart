import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class EditarVentaDeskScreen extends StatefulWidget {
  final String ventaId;
  final Map<String, dynamic> datosVenta;

  const EditarVentaDeskScreen({
    super.key,
    required this.ventaId,
    required this.datosVenta,
  });

  @override
  State<EditarVentaDeskScreen> createState() => _EditarVentaDeskScreenState();
}

class _EditarVentaDeskScreenState extends State<EditarVentaDeskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clienteController;
  DateTime _fecha = DateTime.now();
  List<Map<String, dynamic>> _productos = [];
  Map<String, int> _disponibles = {};
  final Map<String, int> _cantidadesOriginalesVenta = {};
  bool _usarIva = false;
  String _codigoComprobante = '';

  @override
  void initState() {
    super.initState();
    _clienteController = TextEditingController(
      text: widget.datosVenta['cliente'] ?? '',
    );
    _fecha =
        (widget.datosVenta['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();

    // ✅ CRÍTICO: Guardar cantidades originales ANTES de cualquier otra cosa
    // Hacer una copia PROFUNDA para que sean completamente independientes
    final productosOriginalesRaw = widget.datosVenta['productos'] as List?;

    if (productosOriginalesRaw != null) {
      for (var prod in productosOriginalesRaw) {
        if (prod is Map<String, dynamic>) {
          final ref = prod['referencia'];
          final categoria = prod['categoria']?.toString().toUpperCase() ?? '';

          if (categoria != 'TRANSPORTE' && ref != null) {
            // Crear una COPIA INDEPENDIENTE del valor, no una referencia
            final cantidadOriginal = (prod['cantidad'] ?? 0) as int;
            _cantidadesOriginalesVenta[ref] = cantidadOriginal;

            print('🔒 Guardando cantidad original: $ref = $cantidadOriginal');
          }
        }
      }
    }

    // ✅ AHORA SÍ cargar _productos (que será modificado en la UI)
    _productos = List<Map<String, dynamic>>.from(
      widget.datosVenta['productos'] ?? [],
    );

    _codigoComprobante = widget.datosVenta['codigo_comprobante'] ?? '';

    _cargarDisponibles();
  }

  /// ✅ Función para verificar si un producto es de transporte
  bool _esProductoTransporte(String? categoria) {
    return categoria?.toUpperCase() == 'TRANSPORTE';
  }

  Future<void> _cargarDisponibles() async {
    try {
      final disponibles = <String, int>{};

      // ✅ Cargar inventario de TODAS las sucursales
      final sucursales = ['Quito', 'Guayaquil', 'Tulcán'];

      for (String sucursal in sucursales) {
        final inventarioBodegaSnapshot =
            await FirebaseFirestore.instance
                .collection('inventarios')
                .doc(sucursal)
                .collection('procesos')
                .doc('bodega')
                .collection('productos')
                .get();

        for (var doc in inventarioBodegaSnapshot.docs) {
          final referencia = doc.id;
          final cantidad = (doc.data()['cantidad'] ?? 0) as int;

          // Sumar las cantidades de todas las sucursales
          disponibles[referencia] = (disponibles[referencia] ?? 0) + cantidad;
        }
      }

      // ✅ Sumar las cantidades ORIGINALES de la venta

      for (var entry in _cantidadesOriginalesVenta.entries) {
        disponibles[entry.key] = (disponibles[entry.key] ?? 0) + entry.value;
      }

      setState(() {
        _disponibles = disponibles;
      });
    } catch (e) {
      print('Error al cargar disponibles: $e');
      setState(() {
        _disponibles = <String, int>{};
      });
    }
  }

  /// ✅ Calcula total, con IVA solo para productos que NO son de transporte
  double _calcularTotal() {
    double subtotalNormal = 0.0; // Productos que pueden tener IVA
    double subtotalTransporte = 0.0; // Transporte (sin IVA)

    for (var prod in _productos) {
      final precio = prod['precio'] ?? 0.0;
      final cantidad = prod['cantidad'] ?? 0;
      final referencia = (prod['referencia'] ?? '').toString().toUpperCase();
      final subtotalProducto = precio * cantidad;

      if (referencia == 'TRANSPORTE') {
        // Transporte siempre sin IVA
        subtotalTransporte += subtotalProducto;
      } else {
        // Otros productos sí aplican IVA
        subtotalNormal += subtotalProducto;
      }
    }

    double total = subtotalTransporte; // Transporte sin IVA
    if (_usarIva) {
      total += subtotalNormal * 1.15; // Solo los productos normales con IVA
    } else {
      total += subtotalNormal; // Si no se aplica IVA, se suman directo
    }

    return total;
  }

  /// ✅ Selector de productos con diseño elegante
  Future<void> _agregarProducto() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('productos').get();

    final productosDisponibles =
        snapshot.docs.map((doc) {
          final data = doc.data();

          // ✅ SOLUCIÓN: Leer precio20 y pvp en lugar de 'precios'
          List<double> preciosLista = [];

          // Agregar precio20 si existe
          if (data['precio20'] != null && data['precio20'] is num) {
            final precio = (data['precio20'] as num).toDouble();
            if (precio > 0) preciosLista.add(precio);
          }

          // Agregar pvp si existe
          if (data['pvp'] != null && data['pvp'] is num) {
            final pvp = (data['pvp'] as num).toDouble();
            if (pvp > 0) preciosLista.add(pvp);
          }

          return {
            'id': doc.id,
            'nombre': data['nombre'] ?? 'Sin nombre',
            'precios': preciosLista,
            'referencia': data['referencia'] ?? '',
            'categoria': data['categoria'] ?? '',
          };
        }).toList();

    String searchTerm = '';

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filtrados =
                productosDisponibles.where((p) {
                  final nombre = (p['nombre'] ?? '').toString().toLowerCase();
                  final referencia =
                      (p['referencia'] ?? '').toString().toLowerCase();
                  final query = searchTerm.toLowerCase();

                  return query.isEmpty ||
                      nombre.contains(query) ||
                      referencia.contains(query);
                }).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header con gradiente
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add_shopping_cart,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Agregar Producto',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),

                    // Contenido principal
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Barra de búsqueda elegante
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: const Color(0xFFE9ECEF),
                                  width: 1,
                                ),
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Buscar productos...',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 15,
                                  ),
                                ),
                                onChanged:
                                    (v) => setState(() => searchTerm = v),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Lista de productos elegante
                            Expanded(
                              child:
                                  filtrados.isEmpty
                                      ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.search_off,
                                              size: 64,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'No se encontraron productos',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : ListView.builder(
                                        itemCount: filtrados.length,
                                        itemBuilder: (context, index) {
                                          final producto = filtrados[index];
                                          final referencia =
                                              producto['referencia'];
                                          final categoria =
                                              producto['categoria'];
                                          final yaExiste = _productos.any(
                                            (p) =>
                                                p['referencia'] == referencia,
                                          );
                                          final disponibles =
                                              _disponibles[referencia] ?? 0;

                                          final esTransporte =
                                              _esProductoTransporte(categoria);
                                          final puedeAgregar =
                                              yaExiste
                                                  ? false
                                                  : (esTransporte ||
                                                      disponibles > 0);

                                          return Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    yaExiste
                                                        ? Colors.grey[300]!
                                                        : puedeAgregar
                                                        ? const Color(
                                                          0xFF2C3E50,
                                                        ).withOpacity(0.2)
                                                        : Colors.red
                                                            .withOpacity(0.2),
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.all(16),
                                              leading: Container(
                                                width: 50,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  color:
                                                      yaExiste
                                                          ? Colors.grey[100]
                                                          : puedeAgregar
                                                          ? (esTransporte
                                                              ? Colors.orange
                                                                  .withOpacity(
                                                                    0.1,
                                                                  )
                                                              : const Color(
                                                                0xFF2C3E50,
                                                              ).withOpacity(
                                                                0.1,
                                                              ))
                                                          : Colors.red
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  yaExiste
                                                      ? Icons.check_circle
                                                      : esTransporte
                                                      ? Icons.local_shipping
                                                      : puedeAgregar
                                                      ? Icons.inventory_2
                                                      : Icons.remove_circle,
                                                  color:
                                                      yaExiste
                                                          ? Colors.grey[600]
                                                          : esTransporte
                                                          ? Colors.orange
                                                          : puedeAgregar
                                                          ? const Color(
                                                            0xFF2C3E50,
                                                          )
                                                          : Colors.red,
                                                ),
                                              ),
                                              title: Text(
                                                producto['nombre'],
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      yaExiste || !puedeAgregar
                                                          ? Colors.grey[600]
                                                          : Colors.black87,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Ref: $referencia',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              esTransporte
                                                                  ? Colors
                                                                      .orange
                                                                      .withOpacity(
                                                                        0.1,
                                                                      )
                                                                  : disponibles >
                                                                      0
                                                                  ? Colors.green
                                                                      .withOpacity(
                                                                        0.1,
                                                                      )
                                                                  : Colors.red
                                                                      .withOpacity(
                                                                        0.1,
                                                                      ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                6,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          esTransporte
                                                              ? 'Servicio'
                                                              : 'Stock: $disponibles',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                esTransporte
                                                                    ? Colors
                                                                        .orange[700]
                                                                    : disponibles >
                                                                        0
                                                                    ? Colors
                                                                        .green[700]
                                                                    : Colors
                                                                        .red[700],
                                                            fontWeight:
                                                                FontWeight.w500,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              trailing: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color:
                                                      yaExiste || !puedeAgregar
                                                          ? Colors.grey[200]
                                                          : (esTransporte
                                                              ? Colors.orange
                                                              : const Color(
                                                                0xFF2C3E50,
                                                              )),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  yaExiste
                                                      ? Icons.check
                                                      : Icons.add,
                                                  color:
                                                      yaExiste || !puedeAgregar
                                                          ? Colors.grey[600]
                                                          : Colors.white,
                                                ),
                                              ),
                                              onTap:
                                                  !puedeAgregar
                                                      ? null
                                                      : () async {
                                                        final precios = List<
                                                          double
                                                        >.from(
                                                          producto['precios'] ??
                                                              [],
                                                        );

                                                        if (precios.isEmpty) {
                                                          ScaffoldMessenger.of(
                                                            context,
                                                          ).showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                'Este producto no tiene precios registrados.\n'
                                                                'Producto: ${producto['nombre']}\n'
                                                                'Referencia: ${producto['referencia']}',
                                                              ),
                                                              backgroundColor:
                                                                  Colors.red,
                                                              duration:
                                                                  const Duration(
                                                                    seconds: 4,
                                                                  ),
                                                            ),
                                                          );
                                                          return;
                                                        }

                                                        final precioSeleccionado = await showDialog<
                                                          double
                                                        >(
                                                          context: context,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              backgroundColor:
                                                                  Colors.white,
                                                              title: const Text(
                                                                'Selecciona el precio',
                                                              ),
                                                              content: StatefulBuilder(
                                                                builder: (
                                                                  context,
                                                                  setState,
                                                                ) {
                                                                  final TextEditingController
                                                                  _precioPersonalizadoController =
                                                                      TextEditingController();

                                                                  return SingleChildScrollView(
                                                                    child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: [
                                                                        // ✅ Mostrar precio20 y pvp con etiquetas claras
                                                                        ...List.generate(
                                                                          precios
                                                                              .length,
                                                                          (
                                                                            index,
                                                                          ) {
                                                                            final precioPvp =
                                                                                precios[index];
                                                                            final precioFinal =
                                                                                (esTransporte ||
                                                                                        !_usarIva)
                                                                                    ? precioPvp
                                                                                    : precioPvp *
                                                                                        1.15;

                                                                            // Determinar la etiqueta según el índice
                                                                            String
                                                                            etiqueta;
                                                                            if (index ==
                                                                                0) {
                                                                              etiqueta =
                                                                                  'Precio20';
                                                                            } else if (index ==
                                                                                1) {
                                                                              etiqueta =
                                                                                  'PVP';
                                                                            } else {
                                                                              etiqueta =
                                                                                  'Precio ${index + 1}';
                                                                            }

                                                                            return Card(
                                                                              color:
                                                                                  Colors.white,
                                                                              child: ListTile(
                                                                                title: Text(
                                                                                  etiqueta,
                                                                                ),
                                                                                subtitle: Text(
                                                                                  '\$${precioFinal.toStringAsFixed(2)}'
                                                                                  '${esTransporte ? ' (Sin IVA)' : ''}',
                                                                                ),
                                                                                onTap: () {
                                                                                  Navigator.pop(
                                                                                    context,
                                                                                    precioFinal,
                                                                                  );
                                                                                },
                                                                              ),
                                                                            );
                                                                          },
                                                                        ),

                                                                        const Divider(
                                                                          height:
                                                                              32,
                                                                        ),

                                                                        TextField(
                                                                          controller:
                                                                              _precioPersonalizadoController,
                                                                          keyboardType: const TextInputType.numberWithOptions(
                                                                            decimal:
                                                                                true,
                                                                          ),
                                                                          decoration: const InputDecoration(
                                                                            labelText:
                                                                                'Agregar precio modificado',
                                                                            prefixIcon: Icon(
                                                                              Icons.edit,
                                                                            ),
                                                                            border:
                                                                                OutlineInputBorder(),
                                                                            filled:
                                                                                true,
                                                                            fillColor:
                                                                                Colors.white,
                                                                          ),
                                                                        ),

                                                                        const SizedBox(
                                                                          height:
                                                                              16,
                                                                        ),

                                                                        SizedBox(
                                                                          width:
                                                                              double.infinity,
                                                                          child: ElevatedButton.icon(
                                                                            onPressed: () {
                                                                              final input =
                                                                                  _precioPersonalizadoController.text.trim();
                                                                              final valor = double.tryParse(
                                                                                input,
                                                                              );

                                                                              if (valor ==
                                                                                      null ||
                                                                                  valor <=
                                                                                      0) {
                                                                                ScaffoldMessenger.of(
                                                                                  context,
                                                                                ).showSnackBar(
                                                                                  const SnackBar(
                                                                                    content: Text(
                                                                                      'Ingresa un precio válido',
                                                                                    ),
                                                                                    duration: Duration(
                                                                                      seconds:
                                                                                          2,
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                                return;
                                                                              }

                                                                              final precioFinal =
                                                                                  (esTransporte ||
                                                                                          !_usarIva)
                                                                                      ? valor
                                                                                      : valor *
                                                                                          1.15;

                                                                              Navigator.pop(
                                                                                context,
                                                                                precioFinal,
                                                                              );
                                                                            },
                                                                            icon: const Icon(
                                                                              Icons.check,
                                                                            ),
                                                                            label: const Text(
                                                                              'Aceptar precio modificado',
                                                                            ),
                                                                            style: ElevatedButton.styleFrom(
                                                                              backgroundColor: const Color(
                                                                                0xFF4682B4,
                                                                              ),
                                                                              foregroundColor:
                                                                                  Colors.white,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );
                                                                },
                                                              ),
                                                            );
                                                          },
                                                        );

                                                        if (precioSeleccionado !=
                                                            null) {
                                                          final int cantidad =
                                                              1;
                                                          final double
                                                          subtotal =
                                                              precioSeleccionado *
                                                              cantidad;

                                                          setState(() {
                                                            _productos.add({
                                                              'nombre':
                                                                  producto['nombre'],
                                                              'precio':
                                                                  precioSeleccionado,
                                                              'cantidad':
                                                                  cantidad,
                                                              'referencia':
                                                                  referencia,
                                                              'categoria':
                                                                  categoria,
                                                              'subtotal':
                                                                  subtotal,
                                                            });
                                                          });
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                          _cargarDisponibles();
                                                        }
                                                      },
                                            ),
                                          );
                                        },
                                      ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // FUNCIÓN 2: _guardarCambios()

  void _guardarCambios() async {
    for (var producto in _productos) {
      final referencia = producto['referencia'];
      final cantidadNueva = producto['cantidad'] ?? 0;
      final categoria = producto['categoria']?.toString().toUpperCase() ?? '';

      // ✅ NO validar stock para productos de TRANSPORTE
      if (categoria != 'TRANSPORTE') {
        final disponibleTotal = _disponibles[referencia] ?? 0;
        final cantidadOriginal = _cantidadesOriginalesVenta[referencia] ?? 0;

        if (cantidadNueva > disponibleTotal) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cantidad de "${producto['nombre']}" excede stock disponible.\n'
                'Disponible: $disponibleTotal (incluye $cantidadOriginal de esta venta)',
              ),
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }
      }
    }

    if (_formKey.currentState?.validate() ?? false) {
      final user = FirebaseAuth.instance.currentUser;

      // Obtiene nombre de usuario
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user?.uid)
              .get();
      final usuarioNombre =
          usuarioDoc.exists
              ? (usuarioDoc['nombre'] ?? 'Desconocido')
              : 'Desconocido';

      final tipoVenta = widget.datosVenta['tipo'] ?? 'Venta';
      final totalAnterior = widget.datosVenta['total'] ?? 0.0;
      final totalNuevo = _calcularTotal();

      final sucursales = ['Quito', 'Guayaquil', 'Tulcán'];

      // ✅ CREAR MAPAS USANDO _cantidadesOriginalesVenta (datos guardados al inicio)
      Map<String, Map<String, dynamic>> productosOriginalesMap = {};

      for (var entry in _cantidadesOriginalesVenta.entries) {
        final referencia = entry.key;
        final cantidad = entry.value;

        // Buscar el nombre del producto
        final productoActual = _productos.firstWhere(
          (p) => p['referencia'] == referencia,
          orElse:
              () => {
                'nombre':
                    widget.datosVenta['productos'].firstWhere(
                      (p) => p['referencia'] == referencia,
                      orElse: () => {'nombre': 'Producto'},
                    )['nombre'],
              },
        );

        productosOriginalesMap[referencia] = {
          'cantidad': cantidad,
          'nombre': productoActual['nombre'] ?? 'Producto',
        };
      }
      Map<String, Map<String, dynamic>> productosNuevosMap = {};
      for (var prod in _productos) {
        final ref = prod['referencia'];
        final categoria = prod['categoria']?.toString().toUpperCase() ?? '';

        // ✅ INCLUIR TODOS LOS PRODUCTOS (incluido TRANSPORTE) para el kardex
        productosNuevosMap[ref] = {
          'cantidad': (prod['cantidad'] ?? 0) as int,
          'nombre': prod['nombre'] ?? 'Producto',
          'categoria': categoria, // ✅ Guardamos la categoría también
        };
      }

      // ✅ PROCESAR CAMBIOS EN EL INVENTARIO Y KARDEX
      Set<String> todasLasReferencias = {
        ...productosOriginalesMap.keys,
        ...productosNuevosMap.keys,
      };

      print('🔍 DEBUG - Procesando cambios en inventario:');

      for (String referencia in todasLasReferencias) {
        final cantOriginal =
            productosOriginalesMap[referencia]?['cantidad'] ?? 0;
        final cantNueva = productosNuevosMap[referencia]?['cantidad'] ?? 0;
        final nombreProducto =
            productosNuevosMap[referencia]?['nombre'] ??
            productosOriginalesMap[referencia]?['nombre'] ??
            'Producto';

        final diferencia = cantNueva - cantOriginal;
        final categoria =
            productosNuevosMap[referencia]?['categoria'] ?? ''; // ✅ AÑADE ESTO

        print('📦 Producto: $nombreProducto (Ref: $referencia)');
        print(
          '   Original: $cantOriginal | Nueva: $cantNueva | Diferencia: $diferencia',
        );

        // ✅ SOLO actualizar INVENTARIO si NO es transporte
        if (diferencia != 0 && categoria != 'TRANSPORTE') {
          // ✅ MODIFICA ESTA LÍNEA
          print('   ⚡ Actualizando inventario...');

          // ✅ DETERMINAR TIPO DE MOVIMIENTO Y MOTIVO
          String tipoMovimiento;
          String motivo;
          String detalle;

          if (cantOriginal == 0 && cantNueva > 0) {
            // ✅ CASO NUEVO: Producto agregado a la venta
            tipoMovimiento = 'salida';
            motivo = 'Producto agregado en edición de venta';
            detalle =
                'Venta editada - Cliente: ${_clienteController.text}. '
                'Producto: $nombreProducto agregado a la venta. '
                'Cantidad vendida: $cantNueva unidades';
          } else if (diferencia > 0) {
            // Se vendió MÁS producto (cantidad aumentó)
            tipoMovimiento = 'salida';
            motivo = 'Ajuste por edición de venta';
            detalle =
                'Venta editada - Cliente: ${_clienteController.text}. '
                'Producto: $nombreProducto. '
                'Cantidad original: $cantOriginal, Nueva: $cantNueva. '
                'Diferencia: +$diferencia unidades vendidas adicionales';
          } else if (cantNueva == 0) {
            // Se ELIMINÓ el producto de la venta
            tipoMovimiento = 'entrada';
            motivo = 'Devolución por eliminación de producto en venta';
            detalle =
                'Venta editada - Cliente: ${_clienteController.text}. '
                'Producto: $nombreProducto eliminado de la venta. '
                'Se devuelven ${diferencia.abs()} unidades al inventario';
          } else {
            // Se vendió MENOS producto (cantidad disminuyó)
            tipoMovimiento = 'entrada';
            motivo = 'Devolución por ajuste de venta';
            detalle =
                'Venta editada - Cliente: ${_clienteController.text}. '
                'Producto: $nombreProducto. '
                'Cantidad original: $cantOriginal, Nueva: $cantNueva. '
                'Se devuelven ${diferencia.abs()} unidades al inventario';
          }

          // Actualizar inventario en todas las sucursales
          for (String sucursal in sucursales) {
            final inventarioRef = FirebaseFirestore.instance
                .collection('inventarios')
                .doc(sucursal)
                .collection('procesos')
                .doc('bodega')
                .collection('productos')
                .doc(referencia);

            final doc = await inventarioRef.get();

            if (doc.exists) {
              final cantidadActual = (doc.data()?['cantidad'] ?? 0) as int;
              final nuevaCantidad = cantidadActual - diferencia;

              print('   📍 $sucursal: $cantidadActual → $nuevaCantidad');

              await inventarioRef.update({
                'cantidad': nuevaCantidad,
                'ultima_actualizacion': Timestamp.now(),
              });

              // ✅ REGISTRAR EN KARDEX
              await FirebaseFirestore.instance
                  .collection('kardex_movimientos')
                  .add({
                    'referencia': referencia,
                    'producto_nombre': nombreProducto,
                    'tipo': tipoMovimiento, // entrada | salida | ajuste
                    'cantidad': diferencia.abs(),
                    'motivo': motivo,
                    'detalle': detalle,
                    'sucursal': sucursal,
                    'fecha': Timestamp.now(),
                    'usuario': usuarioNombre,
                    'saldo_anterior': cantidadActual,
                    'saldo_actual': nuevaCantidad,
                  });

              print(
                '   ✅ Kardex registrado: $tipoMovimiento de ${diferencia.abs()} unidades',
              );
            } else {
              print('   ⚠️ Producto no encontrado en inventario de $sucursal');
            }
          }
        } else {
          print('   ⏭️ Sin cambios, omitiendo...');
        }
      }

      print('✅ Actualizando documento de venta en Firestore...');

      // ✅ ACTUALIZAR LA VENTA EN FIRESTORE
      await FirebaseFirestore.instance
          .collection('ventas')
          .doc(widget.ventaId)
          .update({
            'cliente': _clienteController.text,
            'fecha': Timestamp.fromDate(_fecha),
            'productos': _productos,
            'total': totalNuevo,
            'conIva': _usarIva,
            'fecha_modificacion': Timestamp.now(),
            'modificado_por': usuarioNombre,
          });

      print('✅ Guardando auditoría...');

      // ✅ GUARDAR AUDITORÍA
      await FirebaseFirestore.instance.collection('auditoria_general').add({
        'accion': 'Edición de $tipoVenta',
        'detalle':
            'Se editó una $tipoVenta del cliente: ${_clienteController.text}. '
            'Total anterior: \$${(totalAnterior as num).toStringAsFixed(2)}, '
            'Total actualizado: \$${totalNuevo.toStringAsFixed(2)}',
        'fecha': Timestamp.now(),
        'usuario_nombre': usuarioNombre,
        'usuario_uid': user?.uid ?? '',
      });

      print('✅ ¡Proceso completado exitosamente!');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Venta actualizada correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    }
  }

  Widget _buildCodigoComprobanteField() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE9ECEF), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.receipt, color: Color(0xFF2C3E50), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Código de Comprobante',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _codigoComprobante.isEmpty
                        ? 'No asignado'
                        : _codigoComprobante,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color:
                          _codigoComprobante.isEmpty
                              ? Colors.grey[500]
                              : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA UNIDA Y CENTRADA
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Editar Venta',
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

          // ✅ CONTENIDO CON FONDO BLANCO
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        padding: const EdgeInsets.all(32),
                        children: [
                          _buildCodigoComprobanteField(),

                          // Campo Cliente
                          Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: TextFormField(
                              controller: _clienteController,
                              decoration: InputDecoration(
                                labelText: 'Cliente',
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE9ECEF),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF2C3E50),
                                    width: 2,
                                  ),
                                ),
                              ),
                              validator:
                                  (value) =>
                                      value == null || value.isEmpty
                                          ? 'Requerido'
                                          : null,
                            ),
                          ),

                          ..._buildProductos(),
                          const SizedBox(height: 20),
                          _buildTotalConIva(),
                          const SizedBox(height: 30),

                          // Botón Guardar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C3E50),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _guardarCambios,
                              child: const Text(
                                'Guardar Cambios',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  // ✅ SOLUCIÓN AL OVERFLOW: Rediseñar completamente el layout de productos
  List<Widget> _buildProductos() {
    return [
      ..._productos.asMap().entries.map((entry) {
        final index = entry.key;
        final producto = entry.value;
        final categoria = producto['categoria'];
        final esTransporte = _esProductoTransporte(categoria);
        final disponibles =
            esTransporte
                ? 999
                : (_disponibles[producto['referencia']] ??
                    0); // ✅ Transporte tiene disponibilidad ilimitada

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  esTransporte
                      ? Colors.orange.withOpacity(0.3)
                      : const Color(0xFFE9ECEF),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del producto y botón eliminar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      producto['nombre'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                    onPressed: () {
                      setState(() {
                        _productos.removeAt(index);
                      });
                      _cargarDisponibles();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del stock
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4682B4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 20),
                          color: const Color(0xFF4682B4),
                          onPressed:
                              producto['cantidad'] > 1
                                  ? () {
                                    setState(() {
                                      _productos[index]['cantidad']--;
                                    });
                                  }
                                  : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            '${producto['cantidad']}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          color: const Color(0xFF4682B4),
                          onPressed:
                              producto['cantidad'] < disponibles
                                  ? () {
                                    setState(() {
                                      _productos[index]['cantidad']++;
                                    });
                                  }
                                  : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Precio total del producto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Precio unitario: \$${producto['precio'].toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  Text(
                    'Subtotal: \$${(producto['precio'] * producto['cantidad']).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4682B4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),

      // Botón agregar producto
      Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add, color: Color(0xFF4682B4)),
          label: const Text(
            'Agregar Producto',
            style: TextStyle(color: Color(0xFF4682B4)),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF4682B4)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _agregarProducto,
        ),
      ),
    ];
  }

  Widget _buildTotalConIva() {
    double subtotalSinTransporte = 0.0;
    double subtotalTransporte = 0.0;

    for (var prod in _productos) {
      final precio = prod['precio'] ?? 0.0;
      final cantidad = prod['cantidad'] ?? 0;
      final categoria =
          (prod['categoria'] ?? prod['referencia'] ?? '')
              .toString()
              .trim()
              .toUpperCase();

      if (categoria == 'TRANSPORTE') {
        subtotalTransporte += precio * cantidad;
      } else {
        subtotalSinTransporte += precio * cantidad;
      }
    }

    double iva = _usarIva ? subtotalSinTransporte * 0.15 : 0.0;
    double total = subtotalSinTransporte + iva + subtotalTransporte;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Switch de IVA
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Aplicar IVA 15% (No aplica a transporte)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Switch(
                value: _usarIva,
                onChanged: (value) {
                  setState(() {
                    _usarIva = value;
                  });
                },
                activeColor: const Color(0xFF4682B4),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Subtotal productos normales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal productos:', style: TextStyle(fontSize: 16)),
              Text(
                '\$${subtotalSinTransporte.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),

          // Subtotal transporte, solo si hay
          if (subtotalTransporte > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Transporte:', style: TextStyle(fontSize: 16)),
                Text(
                  '\$${subtotalTransporte.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],

          // IVA
          if (_usarIva) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('IVA (15%):', style: TextStyle(fontSize: 16)),
                Text(
                  '\$${iva.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ],

          const Divider(thickness: 1),

          // Total final
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4682B4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
