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
  late TextEditingController codigoController;
  final TextEditingController nuevaCategoriaController =
      TextEditingController();

  String? categoriaSeleccionada;
  List<String> categorias = [];
  List<TextEditingController> costoControllers = [TextEditingController()];
  List<TextEditingController> pvpControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.nombreInicial);
    codigoController = TextEditingController(text: widget.codigoBarras);

    // Inicializar el primer PVP con el precio inicial si existe
    if (widget.precioInicial > 0) {
      pvpControllers[0].text = widget.precioInicial.toStringAsFixed(2);
    }

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
        categorias.sort();
      });
    } catch (e) {
      print("Error al cargar categorías: $e");
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
          if (nombreController.text.isEmpty) {
            nombreController.text = data['nombre'] ?? '';
          }
          categoriaSeleccionada = data['categoria'];

          // Cargar costos existentes (nuevo formato de arrays)
          if (data['costos'] != null && data['costos'] is List) {
            final costos = List<double>.from(data['costos']);
            costoControllers.clear();
            for (int i = 0; i < costos.length; i++) {
              costoControllers.add(
                TextEditingController(text: costos[i].toStringAsFixed(2)),
              );
            }
          } else {
            // Cargar costos individuales (formato legacy: costo1, costo2, etc.)
            costoControllers.clear();
            int costoIndex = 1;
            while (data['costo$costoIndex'] != null) {
              final costo = data['costo$costoIndex'];
              if (costo is num) {
                costoControllers.add(
                  TextEditingController(text: costo.toStringAsFixed(2)),
                );
              }
              costoIndex++;
            }
            // Si no hay costos, mantener al menos uno vacío
            if (costoControllers.isEmpty) {
              costoControllers.add(TextEditingController());
            }
          }

          // Cargar PVPs existentes (nuevo formato de arrays)
          if (data['pvps'] != null && data['pvps'] is List) {
            final pvps = List<double>.from(data['pvps']);
            pvpControllers.clear();
            for (int i = 0; i < pvps.length; i++) {
              pvpControllers.add(
                TextEditingController(text: pvps[i].toStringAsFixed(2)),
              );
            }
          } else {
            // Cargar PVPs individuales (formato legacy: pvp1, pvp2, etc.)
            pvpControllers.clear();
            int pvpIndex = 1;
            while (data['pvp$pvpIndex'] != null) {
              final pvp = data['pvp$pvpIndex'];
              if (pvp is num) {
                pvpControllers.add(
                  TextEditingController(text: pvp.toStringAsFixed(2)),
                );
              }
              pvpIndex++;
            }
            // Si no hay PVPs pero hay precio legacy, usarlo
            if (pvpControllers.isEmpty && data['precio'] != null) {
              final precio = data['precio'];
              if (precio is num && precio > 0) {
                pvpControllers.add(
                  TextEditingController(text: precio.toStringAsFixed(2)),
                );
              }
            }
            // Si no hay PVPs, mantener al menos uno vacío
            if (pvpControllers.isEmpty) {
              pvpControllers.add(TextEditingController());
            }
          }
        });
      }
    } catch (e) {
      print("Error al cargar datos existentes: $e");
    }
  }

  void agregarCosto() {
    setState(() {
      costoControllers.add(TextEditingController());
    });
  }

  void eliminarCosto(int index) {
    if (costoControllers.length > 1) {
      setState(() {
        costoControllers[index].dispose();
        costoControllers.removeAt(index);
      });
    }
  }

  void agregarPVP() {
    setState(() {
      pvpControllers.add(TextEditingController());
    });
  }

  void eliminarPVP(int index) {
    if (pvpControllers.length > 1) {
      setState(() {
        pvpControllers[index].dispose();
        pvpControllers.removeAt(index);
      });
    }
  }

  void guardarProducto() async {
    final codigo = codigoController.text.trim();
    final nombre = nombreController.text.trim();

    if (codigo.isEmpty || nombre.isEmpty || categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código, nombre y categoría son obligatorios'),
        ),
      );
      return;
    }

    // Procesar costos
    List<double> costos = [];
    for (var controller in costoControllers) {
      if (controller.text.trim().isNotEmpty) {
        final costo = double.tryParse(controller.text.trim());
        if (costo != null && costo >= 0) {
          costos.add(costo);
        }
      }
    }

    // Procesar PVPs
    List<double> pvps = [];
    for (var controller in pvpControllers) {
      if (controller.text.trim().isNotEmpty) {
        final pvp = double.tryParse(controller.text.trim());
        if (pvp != null && pvp >= 0) {
          pvps.add(pvp);
        }
      }
    }

    // Crear datos individuales para costos y PVPs
    Map<String, dynamic> costosData = {};
    Map<String, dynamic> pvpsData = {};

    for (int i = 0; i < costos.length; i++) {
      costosData['costo${i + 1}'] = costos[i];
    }

    for (int i = 0; i < pvps.length; i++) {
      pvpsData['pvp${i + 1}'] = pvps[i];
    }

    // Datos del producto
    final productoData = {
      'codigo': codigo,
      'nombre': nombre,
      'categoria': categoriaSeleccionada,
      'fecha': FieldValue.serverTimestamp(),
      // Mantener compatibilidad con el precio original si existe al menos un PVP
      if (pvps.isNotEmpty) 'precio': pvps[0],
      // Agregar arrays para nueva funcionalidad
      'costos': costos,
      'pvps': pvps,
      // Agregar campos individuales para compatibilidad
      ...costosData,
      ...pvpsData,
    };

    try {
      // Debug: mostrar qué se va a guardar
      print("Guardando producto con datos: $productoData");

      await FirebaseFirestore.instance
          .collection('inventario_general')
          .doc(codigo)
          .set(productoData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto guardado exitosamente')),
      );

      Navigator.pop(context, {
        'codigo': codigo,
        'nombre': nombre,
        'categoria': categoriaSeleccionada,
        'costos': costos,
        'pvps': pvps,
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
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.category,
                    color: Color(0xFF4682B4),
                    size: 40,
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
                            try {
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
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al crear la categoría'),
                                ),
                              );
                            }
                          } else if (categorias.contains(nuevaCat)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Esta categoría ya existe'),
                              ),
                            );
                          }

                          nuevaCategoriaController.clear();
                          Navigator.pop(context);
                        },
                        label: const Text(
                          'Guardar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
        style: const TextStyle(
          color: Color.fromARGB(255, 0, 0, 0),
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

  Widget buildCostoField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Expanded(
            child: TextField(
              controller: costoControllers[index],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.normal,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.monetization_on,
                  color: Color(0xFF2C3E50),
                ),
                labelText: 'Costo ${index + 1}',
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
          ),
          if (costoControllers.length > 1)
            IconButton(
              onPressed: () => eliminarCosto(index),
              icon: const Icon(Icons.remove_circle, color: Colors.red),
            ),
        ],
      ),
    );
  }

  Widget buildPVPField(int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Expanded(
            child: TextField(
              controller: pvpControllers[index],
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                color: Color.fromARGB(255, 0, 0, 0),
                fontWeight: FontWeight.normal,
              ),
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: Color(0xFF2C3E50),
                ),
                labelText: 'PVP ${index + 1}',
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
          ),
          if (pvpControllers.length > 1)
            IconButton(
              onPressed: () => eliminarPVP(index),
              icon: const Icon(Icons.remove_circle, color: Colors.red),
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

                  // Sección de Costos
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Costos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        IconButton(
                          onPressed: agregarCosto,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF4682B4),
                          ),
                          tooltip: 'Agregar costo',
                        ),
                      ],
                    ),
                  ),

                  // Campos de costos dinámicos
                  ...costoControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    return buildCostoField(index);
                  }).toList(),

                  const SizedBox(height: 20),

                  // Sección de PVPs
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Precios de Venta (PVP)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        IconButton(
                          onPressed: agregarPVP,
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF4682B4),
                          ),
                          tooltip: 'Agregar PVP',
                        ),
                      ],
                    ),
                  ),

                  // Campos de PVPs dinámicos
                  ...pvpControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    return buildPVPField(index);
                  }).toList(),

                  const SizedBox(height: 20),

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
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 14,
                        ),
                        elevation: 0,
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
    codigoController.dispose();
    nuevaCategoriaController.dispose();

    for (var controller in costoControllers) {
      controller.dispose();
    }
    for (var controller in pvpControllers) {
      controller.dispose();
    }

    super.dispose();
  }
}
