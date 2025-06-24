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

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.nombreInicial);
    precioController = TextEditingController(
      text: widget.precioInicial.toStringAsFixed(2),
    );
    codigoController = TextEditingController(text: widget.codigoBarras);
    cantidadController = TextEditingController();
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

    final productoData = {
      'codigo': codigo,
      'nombre': nombre,
      'precio': precio,
      'fecha': FieldValue.serverTimestamp(),
    };

    // Si es nuevo (no tiene código preexistente), también guarda cantidad
    if (widget.codigoBarras.isEmpty) {
      final cantidad = int.tryParse(cantidadText) ?? 0;
      productoData['cantidad'] = cantidad;
    }

    try {
      await FirebaseFirestore.instance
          .collection('productos')
          .doc(codigo)
          .set(productoData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado exitosamente')),
      );

      Navigator.pop(context, {
        'codigo': codigo,
        'nombre': nombre,
        'precio': precio,
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
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          labelText: label,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // AppBar con degradado
          SafeArea(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
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

          // Formulario
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                children: [
                  // Código de barras
                  widget.codigoBarras.isEmpty
                      ? buildTextField(
                        label: 'Código de Barras',
                        icon: Icons.qr_code,
                        controller: codigoController,
                      )
                      : Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Código de Barras: ${widget.codigoBarras}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  const SizedBox(height: 20),

                  // Nombre
                  buildTextField(
                    label: 'Nombre del Producto',
                    icon: Icons.inventory_2,
                    controller: nombreController,
                  ),

                  // Precio
                  buildTextField(
                    label: 'Precio',
                    icon: Icons.attach_money,
                    controller: precioController,
                    inputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: guardarProducto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
