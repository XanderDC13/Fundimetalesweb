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
  final TextEditingController nuevaCategoriaController =
      TextEditingController();

  String? categoriaSeleccionada;
  List<String> categorias = [];

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

    if (widget.codigoBarras.isNotEmpty) {
      _cargarDatosExistentes();
    }

    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categorias').get();
      setState(() {
        categorias =
            snapshot.docs.map((doc) => doc['nombre'] as String).toList();
        // Ordenar alfabéticamente para mejor UX
        categorias.sort();
      });
    } catch (e) {
      print("Error al cargar categorías: $e");
      // Si no se pueden cargar, usar categorías por defecto
      setState(() {
        categorias = ['GENERAL', 'REPUESTOS', 'HERRAMIENTAS', 'SERVICIOS'];
      });
    }
  }

  Future<void> _cargarDatosExistentes() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('inventario_general')
              .doc(widget.codigoBarras)
              .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          nombreController.text = data['nombre'] ?? '';
          precioController.text = (data['precio'] ?? 0).toString();
          categoriaSeleccionada = data['categoria'];
        });
      }
    } catch (e) {
      print("Error al cargar datos existentes: $e");
    }
  }

  void guardarProducto() async {
    final codigo = codigoController.text.trim();
    final nombre = nombreController.text.trim();
    final precioText = precioController.text.trim();

    if (codigo.isEmpty ||
        nombre.isEmpty ||
        precioText.isEmpty ||
        categoriaSeleccionada == null) {
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

    // Datos del producto SIN cantidad
    final productoData = {
      'codigo': codigo,
      'nombre': nombre,
      'precio': precio,
      'categoria': categoriaSeleccionada,
      'fecha': FieldValue.serverTimestamp(),
    };

    try {
      // Usar set() sin merge para reemplazar completamente el documento
      // Esto eliminará cualquier campo 'cantidad' que pueda existir
      await FirebaseFirestore.instance
          .collection('inventario_general')
          .doc(codigo)
          .set(productoData); // Sin SetOptions(merge: true)

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

  void mostrarDialogoNuevaCategoria() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Nueva categoría'),
            content: TextField(
              controller: nuevaCategoriaController,
              decoration: const InputDecoration(
                hintText: 'Nombre de la categoría',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final nuevaCat =
                      nuevaCategoriaController.text.trim().toUpperCase();
                  if (nuevaCat.isNotEmpty && !categorias.contains(nuevaCat)) {
                    try {
                      await FirebaseFirestore.instance
                          .collection('categorias')
                          .add({'nombre': nuevaCat});

                      setState(() {
                        categorias.add(nuevaCat);
                        categorias.sort(); // Mantener orden alfabético
                        categoriaSeleccionada = nuevaCat;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Categoría "$nuevaCat" creada exitosamente',
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Error al crear la categoría'),
                        ),
                      );
                    }
                  } else if (categorias.contains(nuevaCat)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Esta categoría ya existe')),
                    );
                  }
                  nuevaCategoriaController.clear();
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );
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
        style: const TextStyle(
          color: Color(0xFF1B4F72),
          fontWeight: FontWeight.normal,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2C3E50)),
          labelText: label,
          labelStyle: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.normal,
          ),
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
        items:
            categorias
                .map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(
                      cat,
                      style: const TextStyle(
                        color: Color(0xFF1B4F72),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                )
                .toList(),
        onChanged: (value) {
          setState(() {
            categoriaSeleccionada = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Categoría',
          labelStyle: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: const Icon(Icons.category, color: Color(0xFF2C3E50)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        dropdownColor: Colors.white,
        style: const TextStyle(color: Color(0xFF1B4F72), fontSize: 16),
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
                  // Campo código de barras
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
                            const Icon(Icons.qr_code, color: Color(0xFF2C3E50)),
                            const SizedBox(width: 12),
                            Text(
                              'Código de Barras: ${widget.codigoBarras}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1B4F72),
                              ),
                            ),
                          ],
                        ),
                      ),

                  // Campo nombre
                  buildTextField(
                    label: 'Nombre del Producto',
                    icon: Icons.inventory_2,
                    controller: nombreController,
                  ),

                  // Campo precio
                  buildTextField(
                    label: 'Precio',
                    icon: Icons.attach_money,
                    controller: precioController,
                    inputType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),

                  // Dropdown categoría
                  buildCategoriaDropdown(),

                  // Botón crear nueva categoría
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: TextButton.icon(
                      onPressed: mostrarDialogoNuevaCategoria,
                      icon: const Icon(Icons.add, color: Color(0xFF2C3E50)),
                      label: const Text(
                        'Crear nueva categoría',
                        style: TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),

                  // Botón guardar
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton.icon(
                      onPressed: guardarProducto,
                      icon: const Icon(Icons.save, color: Colors.white),
                      label: const Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                        elevation: 3,
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

  @override
  void dispose() {
    nombreController.dispose();
    precioController.dispose();
    codigoController.dispose();
    nuevaCategoriaController.dispose();
    super.dispose();
  }
}
