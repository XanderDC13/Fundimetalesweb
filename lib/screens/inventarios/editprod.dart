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
  bool datosInicializados = false;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController();
    precioController = TextEditingController();
    codigoController = TextEditingController(text: widget.codigoBarras);

    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    await _cargarCategorias();
    if (widget.codigoBarras.isNotEmpty) {
      await _cargarDatosExistentes();
    } else {
      setState(() {
        nombreController.text = widget.nombreInicial;
        precioController.text =
            widget.precioInicial == 0
                ? ''
                : widget.precioInicial.toStringAsFixed(2);
        if (categorias.isNotEmpty) {
          categoriaSeleccionada = categorias.first;
        }
      });
    }
    setState(() {
      datosInicializados = true;
    });
  }

  Future<void> _cargarCategorias() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('categorias').get();
      categorias = snapshot.docs.map((doc) => doc['nombre'] as String).toList();
      categorias.sort();
    } catch (e) {
      print("Error al cargar categorías: $e");
      categorias = ['GENERAL', 'SIN CATEGORÍA'];
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
        final categoriaEnDB = data['categoria'];

        print(
          "Cargando datos -> Nombre: ${data['nombre']}, Precio: ${data['precio']}, Categoría: $categoriaEnDB",
        );

        if (categoriaEnDB != null && !categorias.contains(categoriaEnDB)) {
          categorias.add(categoriaEnDB);
          categorias.sort();
        }

        setState(() {
          nombreController.text = data['nombre'] ?? widget.nombreInicial;
          precioController.text =
              data['precio'] != null ? data['precio'].toString() : '';
          categoriaSeleccionada =
              categoriaEnDB ??
              (categorias.isNotEmpty ? categorias.first : null);
        });
      } else {
        setState(() {
          nombreController.text = widget.nombreInicial;
          precioController.text =
              widget.precioInicial == 0
                  ? ''
                  : widget.precioInicial.toStringAsFixed(2);
          categoriaSeleccionada =
              categorias.isNotEmpty ? categorias.first : null;
        });
      }
    } catch (e) {
      print("Error al cargar datos existentes: $e");
    }
  }

  Future<void> guardarProducto() async {
    final codigo = codigoController.text.trim();
    final nombre = nombreController.text.trim();
    final precioText = precioController.text.trim();

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

    try {
      final docRef = FirebaseFirestore.instance
          .collection('inventario_general')
          .doc(codigo);
      final docSnapshot = await docRef.get();

      final Map<String, dynamic> datosAGuardar = {
        'codigo': codigo,
        'nombre': nombre,
        'precio': precio,
        'fecha': FieldValue.serverTimestamp(),
      };

      // ✅ Solo actualiza la categoría si realmente hay un valor nuevo
      if (categoriaSeleccionada != null) {
        datosAGuardar['categoria'] = categoriaSeleccionada;
      }

      if (docSnapshot.exists) {
        await docRef.update(datosAGuardar);
        print("Producto actualizado: $datosAGuardar");
      } else {
        // Para uno nuevo, la categoría debe existir
        if (categoriaSeleccionada == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selecciona una categoría')),
          );
          return;
        }
        await docRef.set(datosAGuardar, SetOptions(merge: true));
        print("Producto creado: $datosAGuardar");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado correctamente')),
      );

      Navigator.pop(context, {
        'codigo': codigo,
        'nombre': nombre,
        'precio': precio,
        'categoria': categoriaSeleccionada,
      });
    } catch (e) {
      print("Error al guardar producto: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar el producto')),
      );
    }
  }

  void mostrarDialogoNuevaCategoria() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.category,
                    size: 40,
                    color: Color(0xFF4682B4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nueva Categoría',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4682B4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nuevaCategoriaController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la categoría',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar'),
                      ),
                      FloatingActionButton.extended(
                        onPressed: () async {
                          final nuevaCat =
                              nuevaCategoriaController.text
                                  .trim()
                                  .toUpperCase();
                          if (nuevaCat.isNotEmpty &&
                              !categorias.contains(nuevaCat)) {
                            await FirebaseFirestore.instance
                                .collection('categorias')
                                .add({'nombre': nuevaCat});
                            setState(() {
                              categorias.add(nuevaCat);
                              categorias.sort();
                              categoriaSeleccionada = nuevaCat;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Categoría "$nuevaCat" creada'),
                              ),
                            );
                          }
                          nuevaCategoriaController.clear();
                          Navigator.pop(context);
                        },
                        label: const Text(
                          'Guardar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        icon: const Icon(Icons.save, color: Colors.white),
                        backgroundColor: const Color(0xFF4682B4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF2C3E50)),
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
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
        onChanged: (value) {
          setState(() {
            categoriaSeleccionada = value;
          });
        },
        decoration: InputDecoration(
          labelText: 'Categoría',
          prefixIcon: const Icon(Icons.category, color: Color(0xFF2C3E50)),
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
            child:
                datosInicializados
                    ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: ListView(
                        children: [
                          buildTextField(
                            label: 'Código de Barras',
                            icon: Icons.qr_code,
                            controller: codigoController,
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
                          TextButton.icon(
                            onPressed: mostrarDialogoNuevaCategoria,
                            icon: const Icon(
                              Icons.add,
                              color: Color(0xFF2C3E50),
                            ),
                            label: const Text(
                              'Crear nueva categoría',
                              style: TextStyle(color: Color(0xFF2C3E50)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: guardarProducto,
                            icon: const Icon(Icons.save),
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
                        ],
                      ),
                    )
                    : const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Color(0xFF4682B4)),
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
