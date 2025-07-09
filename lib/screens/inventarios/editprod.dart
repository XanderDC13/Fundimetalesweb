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
  late TextEditingController costoController;
  late TextEditingController codigoController;
  late TextEditingController referenciaController;

  final TextEditingController precio1Controller = TextEditingController();
  final TextEditingController precio2Controller = TextEditingController();
  final TextEditingController precio3Controller = TextEditingController();
  final TextEditingController precio4Controller = TextEditingController();
  final TextEditingController precio5Controller = TextEditingController();
  final TextEditingController precio6Controller = TextEditingController();

  final TextEditingController nuevaCategoriaController =
      TextEditingController();

  String? categoriaSeleccionada;
  List<String> categorias = [];
  bool datosInicializados = false;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController();
    costoController = TextEditingController();
    codigoController = TextEditingController(text: widget.codigoBarras);
    referenciaController = TextEditingController();
    // Los controladores de precios ya están inicializados arriba

    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    await _cargarCategorias();
    if (widget.codigoBarras.isNotEmpty) {
      await _cargarDatosExistentes();
    } else {
      setState(() {
        nombreController.text = widget.nombreInicial;
        // Establecer el precio inicial en el primer campo
        precio1Controller.text =
            widget.precioInicial == 0
                ? ''
                : widget.precioInicial.toStringAsFixed(2);
        costoController.text = '';
        referenciaController.text = '';
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
          "Cargando datos -> Nombre: ${data['nombre']}, Precios: ${data['precios']}, Costo: ${data['costo']}, Categoría: $categoriaEnDB",
        );

        if (categoriaEnDB != null && !categorias.contains(categoriaEnDB)) {
          categorias.add(categoriaEnDB);
          categorias.sort();
        }

        setState(() {
          nombreController.text = data['nombre'] ?? widget.nombreInicial;
          costoController.text =
              data['costo'] != null ? data['costo'].toString() : '';
          referenciaController.text = data['referencia'] ?? '';
          categoriaSeleccionada =
              categoriaEnDB ??
              (categorias.isNotEmpty ? categorias.first : null);

          // Cargar los 6 precios
          final precios = data['precios'] as List<dynamic>?;
          if (precios != null && precios.isNotEmpty) {
            precio1Controller.text =
                precios.length > 0 ? precios[0].toString() : '';
            precio2Controller.text =
                precios.length > 1 ? precios[1].toString() : '';
            precio3Controller.text =
                precios.length > 2 ? precios[2].toString() : '';
            precio4Controller.text =
                precios.length > 3 ? precios[3].toString() : '';
            precio5Controller.text =
                precios.length > 4 ? precios[4].toString() : '';
            precio6Controller.text =
                precios.length > 5 ? precios[5].toString() : '';
          } else {
            // Si no hay precios guardados, usar el precio inicial
            precio1Controller.text =
                widget.precioInicial == 0
                    ? ''
                    : widget.precioInicial.toStringAsFixed(2);
          }
        });
      } else {
        setState(() {
          nombreController.text = widget.nombreInicial;
          precio1Controller.text =
              widget.precioInicial == 0
                  ? ''
                  : widget.precioInicial.toStringAsFixed(2);
          costoController.text = '';
          referenciaController.text = '';
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
    final referencia = referenciaController.text.trim();
    final costoText = costoController.text.trim();

    if (codigo.isEmpty || nombre.isEmpty || costoText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código, nombre y costo son obligatorios'),
        ),
      );
      return;
    }

    final costo = double.tryParse(costoText);
    if (costo == null || costo < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Costo inválido')));
      return;
    }

    // Recopilar todos los precios
    List<double> precios = [];
    final preciosTexto = [
      precio1Controller.text.trim(),
      precio2Controller.text.trim(),
      precio3Controller.text.trim(),
      precio4Controller.text.trim(),
      precio5Controller.text.trim(),
      precio6Controller.text.trim(),
    ];

    for (String precioTexto in preciosTexto) {
      if (precioTexto.isNotEmpty) {
        final precio = double.tryParse(precioTexto);
        if (precio != null && precio >= 0) {
          precios.add(precio);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hay precios inválidos')),
          );
          return;
        }
      }
    }

    if (precios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar al menos un precio')),
      );
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('inventario_general')
          .doc(codigo);
      final docSnapshot = await docRef.get();

      final Map<String, dynamic> datosAGuardar = {
        'codigo': codigo,
        'referencia': referencia,
        'nombre': nombre,
        'precios': precios,
        'costo': costo,
        'fecha': FieldValue.serverTimestamp(),
      };

      if (categoriaSeleccionada != null) {
        datosAGuardar['categoria'] = categoriaSeleccionada;
      }

      if (docSnapshot.exists) {
        await docRef.update(datosAGuardar);
        print("Producto actualizado: $datosAGuardar");
      } else {
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
        'referencia': referencia,
        'nombre': nombre,
        'precios': precios,
        'costo': costo,
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

  Widget buildPrecioField({
    required String label,
    required TextEditingController controller,
  }) {
    return Container(
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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF2C3E50)),
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

  Widget buildPreciosGrid() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Precios',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 80, 49, 44),
            ),
          ),
          const SizedBox(height: 12),
          // Primera fila - 3 precios
          Row(
            children: [
              Expanded(
                child: buildPrecioField(
                  label: 'PVP1',
                  controller: precio1Controller,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildPrecioField(
                  label: 'PVP2',
                  controller: precio2Controller,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildPrecioField(
                  label: 'PVP3',
                  controller: precio3Controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Segunda fila - 3 precios
          Row(
            children: [
              Expanded(
                child: buildPrecioField(
                  label: 'PVP4',
                  controller: precio4Controller,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildPrecioField(
                  label: 'PVP5',
                  controller: precio5Controller,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildPrecioField(
                  label: 'PVP6',
                  controller: precio6Controller,
                ),
              ),
            ],
          ),
        ],
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
                            label: 'Referencia',
                            icon: Icons.code,
                            controller: referenciaController,
                          ),
                          buildTextField(
                            label: 'Nombre del Producto',
                            icon: Icons.inventory_2,
                            controller: nombreController,
                          ),
                          buildTextField(
                            label: 'Costo',
                            icon: Icons.attach_money,
                            controller: costoController,
                            inputType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                          buildPreciosGrid(),
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
    costoController.dispose();
    codigoController.dispose();
    precio1Controller.dispose();
    precio2Controller.dispose();
    precio3Controller.dispose();
    precio4Controller.dispose();
    precio5Controller.dispose();
    precio6Controller.dispose();
    nuevaCategoriaController.dispose();
    super.dispose();
  }
}
