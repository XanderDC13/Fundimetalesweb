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
  }

  @override
  void dispose() {
    _clienteController.dispose();
    super.dispose();
  }

  double _calcularTotal() {
    return _productos.fold(0.0, (suma, prod) {
      final precio = prod['precio'] ?? 0.0;
      final cantidad = prod['cantidad'] ?? 1;
      return suma + (precio * cantidad);
    });
  }

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

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona un Producto'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: productosDisponibles.length,
              itemBuilder: (context, index) {
                final producto = productosDisponibles[index];
                final yaExiste = _productos.any(
                  (p) => p['nombre'] == producto['nombre'],
                );

                return ListTile(
                  title: Text(producto['nombre']),
                  subtitle: Text('\$${producto['precio'].toStringAsFixed(2)}'),
                  trailing:
                      yaExiste
                          ? const Icon(Icons.check, color: Colors.grey)
                          : null,
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
                          },
                );
              },
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
  }

  void _guardarCambios() async {
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
              // Encabezado personalizado con texto centrado y sin flecha
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

                      final nombreController = TextEditingController(
                        text: producto['nombre'],
                      );
                      final precioController = TextEditingController(
                        text: producto['precio'].toString(),
                      );
                      final cantidadController = TextEditingController(
                        text: producto['cantidad'].toString(),
                      );

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: nombreController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                ),
                                onChanged:
                                    (value) =>
                                        _productos[index]['nombre'] = value,
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Requerido'
                                            : null,
                              ),
                              TextFormField(
                                initialValue: producto['codigo'] ?? '',
                                decoration: const InputDecoration(
                                  labelText: 'Código',
                                ),
                                readOnly: true,
                              ),

                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: precioController,
                                      decoration: const InputDecoration(
                                        labelText: 'Precio',
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
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
                                  Expanded(
                                    child: TextFormField(
                                      controller: cantidadController,
                                      decoration: const InputDecoration(
                                        labelText: 'Cantidad',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged:
                                          (value) =>
                                              _productos[index]['cantidad'] =
                                                  int.tryParse(value) ?? 1,
                                      validator:
                                          (value) =>
                                              value == null ||
                                                      int.tryParse(value) ==
                                                          null
                                                  ? 'Inválido'
                                                  : null,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _productos.removeAt(index);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    tooltip: 'Eliminar producto',
                                  ),
                                ],
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
