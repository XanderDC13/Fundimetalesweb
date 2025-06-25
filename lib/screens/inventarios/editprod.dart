import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditarProductoScreen extends StatefulWidget {
  final String codigoBarras;
  final String nombreInicial;
  final double precioInicial;

  const EditarProductoScreen({
    super.key,
    required this.codigoBarras,
    required this.nombreInicial,
    required this.precioInicial,
  });

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen> {
  late TextEditingController nombreController;
  late TextEditingController precioController;
  late TextEditingController codigoController;
  late TextEditingController cantidadController;

  final List<String> categoriasDisponibles = [
    'AGRICOLA',
    'ALCANTARILLADO',
    'ARAÑAS',
    'ARTILLEROS',
    'BOCINES',
    'DISCOS',
    'GIMNASIO',
    'LIVIANOS',
    'PLANCHAS',
    'SERVICIOS',
    'SISTEMAS',
    'SOPORTERIA',
    'TAMBORES',
    'TRANSPORTE',
  ];

  String? categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.nombreInicial);
    precioController = TextEditingController(
      text:
          widget.precioInicial == 0
              ? ''
              : widget.precioInicial.toStringAsFixed(2),
    );
    codigoController = TextEditingController(text: widget.codigoBarras);
    cantidadController = TextEditingController();

    if (widget.codigoBarras.isNotEmpty) {
      _cargarDatosExistentes();
    } else {
      categoriaSeleccionada = categoriasDisponibles.first;
    }
  }

  Future<void> _cargarDatosExistentes() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('inventario_general')
            .doc(widget.codigoBarras)
            .get();

    if (doc.exists) {
      final data = doc.data()!;
      final cat = data['categoria'];
      if (cat != null && categoriasDisponibles.contains(cat)) {
        setState(() {
          categoriaSeleccionada = cat;
        });
      } else {
        setState(() {
          categoriaSeleccionada = categoriasDisponibles.first;
        });
      }
    }
  }

  void guardarProducto() async {
    final codigo = codigoController.text.trim();
    final nombre = nombreController.text.trim();
    final precioText = precioController.text.trim();
    final cantidadText = cantidadController.text.trim();

    if (codigo.isEmpty || nombre.isEmpty || precioText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios')),
      );
      return;
    }

    final precio = double.tryParse(precioText);
    if (precio == null || precio < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Precio inválido')));
      return;
    }

    if (categoriaSeleccionada == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Seleccione una categoría')));
      return;
    }

    final productoData = {
      'codigo': codigo,
      'nombre': nombre,
      'precio': precio,
      'fecha': FieldValue.serverTimestamp(),
      'categoria': categoriaSeleccionada,
    };

    if (widget.codigoBarras.isEmpty) {
      final cantidad = int.tryParse(cantidadText) ?? 0;
      productoData['cantidad'] = cantidad;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inventario_general')
          .doc(codigo)
          .set(productoData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado exitosamente')),
      );

      Navigator.pop(context, {
        'codigo': codigo,
        'nombre': nombre,
        'precio': precio,
        'categoria': categoriaSeleccionada,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el producto')),
      );
      print("Error al guardar el producto: $e");
    }
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        style: const TextStyle(color: Color(0xFF1B4F72)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF2C3E50)),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF2C3E50)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget buildCategoriaDropdown() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonFormField<String>(
        value: categoriaSeleccionada,
        decoration: InputDecoration(
          labelText: 'Categoría',
          filled: true,
          fillColor: Colors.white,
          prefixIcon: Icon(Icons.category, color: const Color(0xFF2C3E50)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
        dropdownColor: Colors.white,
        items:
            categoriasDisponibles.map((categoria) {
              return DropdownMenuItem<String>(
                value: categoria,
                child: Text(categoria),
              );
            }).toList(),
        onChanged: (value) {
          setState(() {
            categoriaSeleccionada = value;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Column(
        children: [
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
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
              child: const Center(
                child: Text(
                  'Editar Producto',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  widget.codigoBarras.isEmpty
                      ? buildTextField(
                        label: 'Código de Barras',
                        icon: Icons.qr_code,
                        controller: codigoController,
                      )
                      : Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade300,
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code, color: Color(0xFF2C3E50)),
                            const SizedBox(width: 12),
                            Text(
                              'Código de Barras: ${widget.codigoBarras}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  buildTextField(
                    label: 'Nombre del Producto',
                    icon: Icons.inventory_2,
                    controller: nombreController,
                  ),
                  buildTextField(
                    label: 'Precio',
                    icon: Icons.attach_money,
                    controller: precioController,
                    inputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  buildCategoriaDropdown(),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: guardarProducto,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text('Guardar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
