import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/settings/navbar_desk.dart';

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

  /// ✅ Corrige cálculo de stock disponible
  Future<void> _cargarDisponibles() async {
    final historialSnapshot =
        await FirebaseFirestore.instance
            .collection('historial_inventario_general')
            .get();

    final ventasSnapshot =
        await FirebaseFirestore.instance.collection('ventas').get();

    final ventasPorProducto = <String, int>{};
    for (var venta in ventasSnapshot.docs) {
      final productosVenta = List<Map<String, dynamic>>.from(
        venta['productos'] ?? [],
      );
      for (var producto in productosVenta) {
        final referencia = producto['referencia'] ?? producto['referencia'];
        final cantidad = (producto['cantidad'] ?? 0) as int;
        ventasPorProducto[referencia] =
            (ventasPorProducto[referencia] ?? 0) + cantidad;
      }
    }

    final disponibles = <String, int>{};
    for (var doc in historialSnapshot.docs) {
      final data = doc.data();
      final referencia = (data['referencia'] ?? '').toString();
      final cantidad = (data['cantidad'] ?? 0) as int;
      final tipo = (data['tipo'] ?? 'entrada').toString();
      final ajuste = tipo == 'salida' ? -cantidad : cantidad;

      disponibles[referencia] = (disponibles[referencia] ?? 0) + ajuste;
    }

    // Resta todas las ventas (incluye la actual)
    ventasPorProducto.forEach((referencia, vendidos) {
      disponibles[referencia] = (disponibles[referencia] ?? 0) - vendidos;
    });

    // ✅ Sumar lo que ya está agregado para no bloquear stock usado en esta edición
    for (var producto in _productos) {
      final referencia = producto['referencia'];
      final cantidad = producto['cantidad'] ?? 0;
      disponibles[referencia] =
          ((disponibles[referencia] ?? 0) + cantidad).toInt();
    }

    setState(() {
      _disponibles = disponibles;
    });
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
        await FirebaseFirestore.instance.collection('inventario_general').get();

    final productosDisponibles =
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'nombre': data['nombre'],
            'precios': data['precios'],
            'referencia': data['referencia'],
            'categoria': data['categoria'], // ✅ Agregamos categoría
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

                                          // ✅ Los productos de transporte siempre se pueden agregar
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
                                                            const SnackBar(
                                                              content: Text(
                                                                'Este producto no tiene precios registrados',
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
                                                                  Colors
                                                                      .white, // 👉 Forzamos fondo blanco
                                                              title: const Text(
                                                                'Selecciona el PVP',
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

                                                                            return Card(
                                                                              color:
                                                                                  Colors.white, // 👉 Fondo blanco en cada item
                                                                              child: ListTile(
                                                                                title: Text(
                                                                                  'PVP ${index + 1}',
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

                                                                        // 🔵 Campo para precio modificado
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
                                                                                Colors.white, // 👉 Fondo blanco dentro del campo
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
                                                              1; // cantidad inicial
                                                          final double
                                                          subtotal =
                                                              precioSeleccionado *
                                                              cantidad; // CALCULAR SUBTOTAL

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
                                                                  categoria, // ✅ Guardamos la categoría
                                                              'subtotal':
                                                                  subtotal,
                                                            });
                                                          });
                                                          Navigator.pop(
                                                            context,
                                                          ); // cerrar modal principal
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

  void _guardarCambios() async {
    for (var producto in _productos) {
      final referencia = producto['referencia'];
      final cantidad = producto['cantidad'] ?? 0;

      // Toma categoría o referencia como posible indicador de transporte
      final categoria = producto['categoria'] ?? producto['referencia'];

      if (!_esProductoTransporte(categoria)) {
        final disponible = _disponibles[referencia] ?? 0;
        if (cantidad > disponible) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cantidad de "${producto['nombre']}" excede stock disponible.',
              ),
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

      // Tipo de venta
      final tipoVenta = widget.datosVenta['tipo'] ?? 'Venta';

      // Totales
      final totalAnterior = widget.datosVenta['total'] ?? 0.0;
      final totalNuevo = _calcularTotal();

      // Actualiza la venta
      await FirebaseFirestore.instance
          .collection('ventas')
          .doc(widget.ventaId)
          .update({
            'cliente': _clienteController.text,
            'fecha': Timestamp.fromDate(_fecha),
            'productos': _productos,
            'total': totalNuevo,
            'conIva': _usarIva,
          });

      // Guarda auditoría
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
