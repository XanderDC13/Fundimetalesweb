import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Originales para auditoría
  late String originalCodigo;
  late String originalReferencia;
  late String originalNombre;
  late String originalCosto;
  late String? originalCategoria;
  late List<String> originalPrecios;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController();
    costoController = TextEditingController();
    codigoController = TextEditingController(text: widget.codigoBarras);
    referenciaController = TextEditingController();
    originalCodigo = widget.codigoBarras;
    originalNombre = widget.nombreInicial;
    originalReferencia = '';
    originalCosto = '';
    originalCategoria = null;
    originalPrecios = [];

    _inicializarDatos();
  }

  Future<void> _inicializarDatos() async {
    await _cargarCategorias();
    if (widget.codigoBarras.isNotEmpty) {
      await _cargarDatosExistentes();
    } else {
      setState(() {
        nombreController.text = widget.nombreInicial;
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

      // Originales
      originalCodigo = widget.codigoBarras;
      originalNombre = widget.nombreInicial;
      originalReferencia = '';
      originalCosto = '';
      originalCategoria = categorias.isNotEmpty ? categorias.first : null;
      originalPrecios = [widget.precioInicial.toStringAsFixed(2)];
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

        if (categoriaEnDB != null && !categorias.contains(categoriaEnDB)) {
          categorias.add(categoriaEnDB);
          categorias.sort();
        }

        final precios =
            (data['precios'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

        setState(() {
          nombreController.text = data['nombre'] ?? widget.nombreInicial;
          costoController.text =
              data['costo'] != null ? data['costo'].toString() : '';
          referenciaController.text = data['referencia'] ?? '';
          categoriaSeleccionada =
              categoriaEnDB ??
              (categorias.isNotEmpty ? categorias.first : null);

          precio1Controller.text = precios.isNotEmpty ? precios[0] : '';
          precio2Controller.text = precios.length > 1 ? precios[1] : '';
          precio3Controller.text = precios.length > 2 ? precios[2] : '';
          precio4Controller.text = precios.length > 3 ? precios[3] : '';
          precio5Controller.text = precios.length > 4 ? precios[4] : '';
          precio6Controller.text = precios.length > 5 ? precios[5] : '';

          originalCodigo = widget.codigoBarras;
          originalNombre = nombreController.text;
          originalReferencia = referenciaController.text;
          originalCosto = costoController.text;
          originalCategoria = categoriaSeleccionada;
          originalPrecios = [
            precio1Controller.text,
            precio2Controller.text,
            precio3Controller.text,
            precio4Controller.text,
            precio5Controller.text,
            precio6Controller.text,
          ];
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
    if (costo == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Costo inválido')));
      return;
    }

    final precios =
        [
          precio1Controller.text.trim(),
          precio2Controller.text.trim(),
          precio3Controller.text.trim(),
          precio4Controller.text.trim(),
          precio5Controller.text.trim(),
          precio6Controller.text.trim(),
        ].where((e) => e.isNotEmpty).toList();

    if (precios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar al menos un precio')),
      );
      return;
    }

    // Verificar cambios
    List<String> cambios = [];

    if (codigo != originalCodigo)
      cambios.add('Código: "$originalCodigo" → "$codigo"');
    if (nombre != originalNombre)
      cambios.add('Nombre: "$originalNombre" → "$nombre"');
    if (referencia != originalReferencia)
      cambios.add('Referencia: "$originalReferencia" → "$referencia"');
    if (costoText != originalCosto)
      cambios.add('Costo: "$originalCosto" → "$costoText"');
    if (categoriaSeleccionada != originalCategoria)
      cambios.add('Categoría: "$originalCategoria" → "$categoriaSeleccionada"');

    for (int i = 0; i < precios.length; i++) {
      final pActual = precios[i];
      final pOrig = i < originalPrecios.length ? originalPrecios[i] : '';
      if (pActual != pOrig) {
        cambios.add('Precio ${i + 1}: "$pOrig" → "$pActual"');
      }
    }

    if (cambios.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se detectaron cambios.')),
      );
      return;
    }

    // Guardar producto
    final docRef = FirebaseFirestore.instance
        .collection('inventario_general')
        .doc(codigo);
    final datos = {
      'codigo': codigo,
      'nombre': nombre,
      'referencia': referencia,
      'costo': costo,
      'precios': precios.map((e) => double.tryParse(e) ?? 0).toList(),
      'categoria': categoriaSeleccionada,
      'fecha': FieldValue.serverTimestamp(),
    };

    await docRef.set(datos, SetOptions(merge: true));

    // Guardar auditoría
    if (cambios.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;

      String auditor = 'Desconocido';
      String uid = user?.uid ?? 'sin_uid';

      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();

        if (userDoc.exists && userDoc.data()!.containsKey('nombre')) {
          auditor = userDoc['nombre'];
        }
      }

      await FirebaseFirestore.instance.collection('auditoria_general').add({
        'accion': 'Edición de producto',
        'detalle': cambios.join('\n'),
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': auditor,
        'usuario_uid': uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cambios:\n${cambios.join('\n')}')),
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Cambios:\n${cambios.join('\n')}')));

    Navigator.pop(context);
  }

  // --- UI helpers se mantienen igual ---
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
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
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
    referenciaController.dispose();
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
