import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarVentaScreen extends StatefulWidget {
  final String ventaId;
  final Map<String, dynamic> datosVenta;

  const EditarVentaScreen({
    super.key,
    required this.ventaId,
    required this.datosVenta,
  });

  @override
  State<EditarVentaScreen> createState() => _EditarVentaScreenState();
}

class _EditarVentaScreenState extends State<EditarVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _clienteController;
  DateTime _fecha = DateTime.now();
  List<Map<String, dynamic>> _productos = [];
  Map<String, int> _disponibles = {};
  bool _usarIva = false; // ✅ Nuevo: switch para aplicar IVA

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
    _cargarDisponibles();
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
        final codigo = producto['codigo'];
        final cantidad = (producto['cantidad'] ?? 0) as int;
        ventasPorProducto[codigo] = (ventasPorProducto[codigo] ?? 0) + cantidad;
      }
    }

    final disponibles = <String, int>{};
    for (var doc in historialSnapshot.docs) {
      final data = doc.data();
      final codigo = (data['codigo'] ?? '').toString();
      final cantidad = (data['cantidad'] ?? 0) as int;
      final tipo = (data['tipo'] ?? 'entrada').toString();
      final ajuste = tipo == 'salida' ? -cantidad : cantidad;

      disponibles[codigo] = (disponibles[codigo] ?? 0) + ajuste;
    }

    // Resta todas las ventas (incluye la actual)
    ventasPorProducto.forEach((codigo, vendidos) {
      disponibles[codigo] = (disponibles[codigo] ?? 0) - vendidos;
    });

    // NO sumar lo de _productos de la venta actual

    // ✅ Sumar lo que ya está agregado para no bloquear stock usado en esta edición
    for (var producto in _productos) {
      final codigo = producto['codigo'];
      final cantidad = producto['cantidad'] ?? 0;
      disponibles[codigo] = ((disponibles[codigo] ?? 0) + cantidad).toInt();
    }

    setState(() {
      _disponibles = disponibles;
    });
  }

  /// ✅ Calcula total, con IVA si corresponde
  double _calcularTotal() {
    double subtotal = _productos.fold(0.0, (suma, prod) {
      final precio = prod['precio'] ?? 0.0;
      final cantidad = prod['cantidad'] ?? 0;
      return suma + (precio * cantidad);
    });

    if (_usarIva) {
      return subtotal * 1.15;
    }
    return subtotal;
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
            'precio': data['precio'],
            'codigo': data['codigo'],
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
                productosDisponibles
                    .where(
                      (p) => p['nombre'].toLowerCase().contains(
                        searchTerm.toLowerCase(),
                      ),
                    )
                    .toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
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
                          colors: [Color(0xFF4682B4), Color(0xFF5A9BD4)],
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

                            // Switch de IVA con diseño elegante
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE9ECEF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calculate,
                                        color: Colors.grey[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Aplicar IVA 15%',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Switch(
                                    value: _usarIva,
                                    onChanged: (v) {
                                      setState(() {
                                        _usarIva = v;
                                      });
                                    },
                                    activeColor: const Color(0xFF4682B4),
                                  ),
                                ],
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
                                          final codigo = producto['codigo'];
                                          final yaExiste = _productos.any(
                                            (p) => p['codigo'] == codigo,
                                          );
                                          final disponibles =
                                              _disponibles[codigo] ?? 0;
                                          final precioBase =
                                              producto['precio'] ?? 0;
                                          final precioFinal =
                                              _usarIva
                                                  ? precioBase * 1.15
                                                  : precioBase;

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
                                                        : disponibles > 0
                                                        ? const Color(
                                                          0xFF4682B4,
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
                                                          : disponibles > 0
                                                          ? const Color(
                                                            0xFF4682B4,
                                                          ).withOpacity(0.1)
                                                          : Colors.red
                                                              .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  yaExiste
                                                      ? Icons.check_circle
                                                      : disponibles > 0
                                                      ? Icons.inventory_2
                                                      : Icons.remove_circle,
                                                  color:
                                                      yaExiste
                                                          ? Colors.grey[600]
                                                          : disponibles > 0
                                                          ? const Color(
                                                            0xFF4682B4,
                                                          )
                                                          : Colors.red,
                                                ),
                                              ),
                                              title: Text(
                                                producto['nombre'],
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      yaExiste ||
                                                              disponibles <= 0
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
                                                    'Código: $codigo',
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
                                                              disponibles > 0
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
                                                          'Stock: $disponibles',
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color:
                                                                disponibles > 0
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
                                                      Text(
                                                        'PVP: \$${precioFinal.toStringAsFixed(2)}',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: const Color(
                                                            0xFF4682B4,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              trailing: Container(
                                                width: 40,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color:
                                                      yaExiste ||
                                                              disponibles <= 0
                                                          ? Colors.grey[200]
                                                          : const Color(
                                                            0xFF4682B4,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Icon(
                                                  yaExiste
                                                      ? Icons.check
                                                      : Icons.add,
                                                  color:
                                                      yaExiste ||
                                                              disponibles <= 0
                                                          ? Colors.grey[600]
                                                          : Colors.white,
                                                ),
                                              ),
                                              onTap:
                                                  yaExiste || disponibles <= 0
                                                      ? null
                                                      : () {
                                                        setState(() {
                                                          _productos.add({
                                                            'nombre':
                                                                producto['nombre'],
                                                            'precio':
                                                                precioFinal,
                                                            'cantidad': 1,
                                                            'codigo': codigo,
                                                          });
                                                        });
                                                        Navigator.pop(context);
                                                        _cargarDisponibles();
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
      final codigo = producto['codigo'];
      final cantidad = producto['cantidad'] ?? 0;
      final disponible = _disponibles[codigo] ?? 0;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(0),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: const Center(
                  child: Text(
                    'Editar Venta',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _clienteController,
                      decoration: const InputDecoration(
                        labelText: 'Cliente',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Requerido'
                                  : null,
                    ),
                    const SizedBox(height: 16),
                    ..._buildProductos(),
                    const SizedBox(height: 20),
                    _buildTotal(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _guardarCambios,
                      child: const Text(
                        'Guardar Cambios',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ SOLUCIÓN AL OVERFLOW: Rediseñar completamente el layout de productos
  List<Widget> _buildProductos() {
    return [
      ..._productos.asMap().entries.map((entry) {
        final index = entry.key;
        final producto = entry.value;
        final disponibles = _disponibles[producto['codigo']] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
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
              // Nombre del producto y botón eliminar
              Row(
                children: [
                  Expanded(
                    child: Text(
                      producto['nombre'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () {
                      setState(() {
                        _productos.removeAt(index);
                      });
                      _cargarDisponibles();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Información del stock
              Text(
                'Stock disponible: $disponibles',
                style: TextStyle(
                  fontSize: 14,
                  color: disponibles > 0 ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Controles de cantidad centrados
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

  Widget _buildTotal() {
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '\$${_calcularTotal().toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4682B4),
            ),
          ),
        ],
      ),
    );
  }
}
