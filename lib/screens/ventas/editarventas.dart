import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  Future<void> _cargarDisponibles() async {
    final historialSnapshot =
        await FirebaseFirestore.instance
            .collection('historial_inventario_general')
            .orderBy('fecha_actualizacion', descending: true)
            .get();

    final ventasSnapshot =
        await FirebaseFirestore.instance.collection('ventas').get();

    final ventasPorProducto = <String, int>{};
    for (var venta in ventasSnapshot.docs) {
      // Evitar sumar la venta que se está editando
      if (venta.id == widget.ventaId) continue;

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

    // Restar ventas
    ventasPorProducto.forEach((codigo, vendidos) {
      disponibles[codigo] = (disponibles[codigo] ?? 0) - vendidos;
    });

    // Sumar lo que ya está en esta venta (para no bloquear los productos que el usuario ya tiene asignados)

    setState(() {
      _disponibles = disponibles;
    });
  }

  double _calcularTotal() {
    return _productos.fold(0.0, (suma, prod) {
      final codigo = prod['codigo'];
      final disponibles = _disponibles[codigo] ?? 0;
      final cantidad = prod['cantidad'] ?? 1;
      if (cantidad > disponibles) return suma;
      final precio = prod['precio'] ?? 0.0;
      return suma + (precio * cantidad);
    });
  }

  Future<void> _agregarProducto() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('inventario_general').get();

    List<Map<String, dynamic>> productosDisponibles =
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

            return AlertDialog(
              title: const Text('Selecciona un Producto'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar producto...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() => searchTerm = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtrados.length,
                        itemBuilder: (context, index) {
                          final producto = filtrados[index];
                          final yaExiste = _productos.any(
                            (p) => p['codigo'] == producto['codigo'],
                          );

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(producto['nombre']),
                              subtitle: Text(
                                'Código: ${producto['codigo']} • \$${producto['precio'].toStringAsFixed(2)}',
                              ),
                              trailing:
                                  yaExiste
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.grey,
                                      )
                                      : const Icon(
                                        Icons.add_circle_outline,
                                        color: Color(0xFF1E40AF),
                                      ),
                              onTap:
                                  yaExiste
                                      ? null
                                      : () {
                                        setState(() {
                                          _productos.add({
                                            'nombre': producto['nombre'],
                                            'precio': producto['precio'],
                                            'cantidad': 1,
                                            'codigo': producto['codigo'],
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
              ],
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
              'Cantidad de "${producto['nombre']}" excede los disponibles',
            ),
          ),
        );
        return;
      }
    }

    if (_formKey.currentState?.validate() ?? false) {
      await FirebaseFirestore.instance
          .collection('ventas')
          .doc(widget.ventaId)
          .update({
            'cliente': _clienteController.text,
            'fecha': Timestamp.fromDate(_fecha),
            'productos': _productos,
            'total': _calcularTotal(),
          });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
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
                    colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
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
                    ListTile(
                      tileColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: const Text('Fecha de Venta'),
                      subtitle: Text(
                        DateFormat('dd/MM/yyyy hh:mm a').format(_fecha),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fecha,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _fecha = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              _fecha.hour,
                              _fecha.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Productos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._productos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final producto = entry.value;
                      final codigo = producto['codigo'];
                      final disponibles = _disponibles[codigo] ?? 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      producto['nombre'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _productos.removeAt(index);
                                      });
                                      _cargarDisponibles();
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Código: $codigo',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      initialValue:
                                          producto['precio'].toString(),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: 'Precio',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFF1F5FF),
                                      ),
                                      onChanged:
                                          (value) =>
                                              _productos[index]['precio'] =
                                                  double.tryParse(value) ?? 0.0,
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      double.tryParse(value) ==
                                                          null
                                                  ? 'Inválido'
                                                  : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      color: const Color(0xFFF9FAFB),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed:
                                              producto['cantidad'] > 1
                                                  ? () {
                                                    setState(() {
                                                      _productos[index]['cantidad']--;
                                                    });
                                                  }
                                                  : null,
                                        ),
                                        Text(
                                          '${producto['cantidad']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
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
                              const SizedBox(height: 6),
                              Text(
                                'Disponibles: $disponibles',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: _agregarProducto,
                      icon: const Icon(Icons.add, color: Color(0xFF1E40AF)),
                      label: const Text(
                        'Añadir Producto',
                        style: TextStyle(color: Color(0xFF1E40AF)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_calcularTotal().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _guardarCambios,
                        child: const Text(
                          'Guardar Cambios',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
