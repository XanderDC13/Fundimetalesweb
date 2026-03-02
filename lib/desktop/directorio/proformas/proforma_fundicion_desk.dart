import 'dart:async';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/pdfs/materiaprimapdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProformaFundicionDeskScreen extends StatefulWidget {
  const ProformaFundicionDeskScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProformaFundicionDeskScreenState createState() =>
      _ProformaFundicionDeskScreenState();
}

class _ProformaFundicionDeskScreenState
    extends State<ProformaFundicionDeskScreen> {
  final TextEditingController _clienteController = TextEditingController();
  String _numeroProforma = '';
  // AGREGAR ESTOS
  final TextEditingController _formDescripcionController =
      TextEditingController();
  final TextEditingController _formKilosController = TextEditingController();
  final TextEditingController _formPrecioController = TextEditingController();
  final TextEditingController _formTotalController = TextEditingController();

  // Lista de items
  List<ItemProforma> items = [ItemProforma()];

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA CON TRANSFORM
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      _numeroProforma,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ CONTENIDO CON FONDO BLANCO
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildMobileClienteSection(),
                                const SizedBox(height: 16),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // IZQUIERDA: Formulario agregar
                                    Expanded(
                                      flex: 1,
                                      child: _buildProductosSection(),
                                    ),
                                    const SizedBox(width: 16),
                                    // DERECHA: Lista de productos
                                    Expanded(
                                      flex: 1,
                                      child: _buildListaProductosSection(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildMobileTotalesSection(),
                              ],
                            ),
                          ),
                        ),
                        // Action bar dentro del contenido
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: _buildMobileActionBar(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _previsualizarNumeroProforma();
    items = [];
  }

  Future<void> _previsualizarNumeroProforma() async {
    final fechaHoy = DateTime.now();
    final fechaFormateada =
        "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

    final counterRef = FirebaseFirestore.instance
        .collection('proformas_compras_counter')
        .doc(fechaFormateada);

    final counterDoc = await counterRef.get();

    int numero = 1;

    if (counterDoc.exists) {
      numero = counterDoc['contador'] + 1;
    } else {
      // Inicializar el documento con contador 0 si no existe
      await counterRef.set({'contador': 0});
    }

    setState(() {
      _numeroProforma = "ORDEN N-$fechaFormateada-$numero";
    });
  }

  Widget _buildMobileClienteSection() {
    return _buildMobileSection(
      title: 'Cliente',
      icon: Icons.person_outline,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _clienteController,
              textCapitalization:
                  TextCapitalization.characters, // Convierte a mayúsculas
              onChanged: (value) {
                // Forzar mayúsculas en tiempo real
                final upperCaseValue = value.toUpperCase();
                if (value != upperCaseValue) {
                  _clienteController.value = _clienteController.value.copyWith(
                    text: upperCaseValue,
                    selection: TextSelection.collapsed(
                      offset: upperCaseValue.length,
                    ),
                  );
                }
              },
              decoration: InputDecoration(
                hintText: 'Ingrese el nombre del cliente',
                prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildProductosSection() {
    return _buildMobileSection(
      title: 'Agregar Producto',
      icon: Icons.inventory_2_outlined,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          _buildItemInputField(
            controller: _formDescripcionController,
            label: 'Descripción',
            options: [
              'FUNDICION',
              'CHATARRA',
              'COBRE SUCIO',
              'COBRE LIMPIO',
              'ALUMINIO SUCIO',
              'ALUMINIO LIMPIO',
              'HIERRO',
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildItemInputField(
                  controller: _formKilosController,
                  label: 'Kilos',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _calcularTotalFormulario(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildItemInputField(
                  controller: _formPrecioController,
                  label: 'Precio',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => _calcularTotalFormulario(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildItemInputField(
                  controller: _formTotalController,
                  label: 'Subtotal',
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _agregarItem,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductosSection() {
    return _buildMobileSection(
      title: 'Lista Productos (${items.length})',
      icon: Icons.list_alt,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          // Header tabla
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Text(
                    'DESCRIPCIÓN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'KILOS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'PRECIO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'SUBTOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 36),
              ],
            ),
          ),
          const SizedBox(height: 8),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay productos agregados',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        item.descripcionController.text,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.kilosController.text,
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '\$${item.precioController.text}',
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        item.totalController.text,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      child: IconButton(
                        onPressed: () => _eliminarItem(index),
                        icon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.red[400],
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildItemInputField({
    required TextEditingController controller,
    required String label,
    List<String>? options,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    TextStyle? style,
    Function(String)? onChanged,
  }) {
    if (options != null && options.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Autocomplete<String>(
          initialValue: TextEditingValue(text: controller.text),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return options;
            }
            return options.where(
              (option) => option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              ),
            );
          },
          onSelected: (String selection) {
            controller.text =
                selection.toUpperCase(); // Mayúsculas al seleccionar
            if (onChanged != null) onChanged(controller.text);
          },
          fieldViewBuilder: (
            context,
            textEditingController,
            focusNode,
            onFieldSubmitted,
          ) {
            // Mantener el controlador original sincronizado
            textEditingController.text = controller.text;
            textEditingController.selection = TextSelection.collapsed(
              offset: textEditingController.text.length,
            );

            textEditingController.addListener(() {
              // Convertir a mayúsculas automáticamente
              final upperCaseValue = textEditingController.text.toUpperCase();

              // Solo actualizar si es diferente para evitar bucles infinitos
              if (textEditingController.text != upperCaseValue) {
                textEditingController.value = textEditingController.value
                    .copyWith(
                      text: upperCaseValue,
                      selection: TextSelection.collapsed(
                        offset: upperCaseValue.length,
                      ),
                    );
              }

              controller.text = upperCaseValue;
              if (onChanged != null) onChanged(controller.text);
            });

            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              keyboardType: keyboardType,
              readOnly: readOnly,
              textCapitalization:
                  TextCapitalization.characters, // Mayúsculas automáticas
              style: style ?? const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
                border: InputBorder.none,
              ),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(option),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            option,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Caso normal sin lista - TAMBIÉN CON MAYÚSCULAS AUTOMÁTICAS
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        textCapitalization:
            TextCapitalization.characters, // Mayúsculas automáticas
        onChanged: (value) {
          // Solo para campos de texto (no numéricos)
          if (keyboardType == TextInputType.text || label == 'Descripción') {
            final upperCaseValue = value.toUpperCase();
            if (value != upperCaseValue) {
              controller.value = controller.value.copyWith(
                text: upperCaseValue,
                selection: TextSelection.collapsed(
                  offset: upperCaseValue.length,
                ),
              );
            }
          }
          if (onChanged != null) onChanged(controller.text);
        },
        style: style ?? const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildMobileTotalesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.grey[800], size: 20),
              SizedBox(width: 8),
              Text(
                'Resumen de Totales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          _buildTotalRow('Subtotal:', '\$${_calcularSubtotal()}', large: false),
          SizedBox(height: 12),

          // Total final
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _buildTotalRow(
              'TOTAL FINAL:',
              '\$${_calcularTotalFinal()}',
              bold: true,
              large: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide.none,
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4682B4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4682B4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _guardarYGenerarPDF,
                  child: const Text('Guardar e Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool bold = false,
    required bool large,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  void _calcularTotalFormulario() {
    setState(() {
      double kilos = double.tryParse(_formKilosController.text) ?? 0;
      double precio = double.tryParse(_formPrecioController.text) ?? 0;
      _formTotalController.text = (kilos * precio).toStringAsFixed(2);
    });
  }

  void _agregarItem() {
    if (_formDescripcionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Ingrese una descripción'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final nuevoItem = ItemProforma();
    nuevoItem.descripcionController.text = _formDescripcionController.text;
    nuevoItem.kilosController.text = _formKilosController.text;
    nuevoItem.precioController.text = _formPrecioController.text;
    nuevoItem.totalController.text = _formTotalController.text;

    setState(() {
      items.add(nuevoItem);
      _formDescripcionController.clear();
      _formKilosController.clear();
      _formPrecioController.clear();
      _formTotalController.clear();
    });
  }

  void _eliminarItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  String _calcularSubtotal() {
    double subtotal = 0;
    for (var item in items) {
      subtotal += double.tryParse(item.totalController.text) ?? 0;
    }
    return subtotal.toStringAsFixed(2);
  }

  String _calcularTotalFinal() {
    double subtotal = double.tryParse(_calcularSubtotal()) ?? 0;
    double total = subtotal;
    return total.toStringAsFixed(2);
  }

  Future<void> _guardarYGenerarPDF() async {
    try {
      // Validaciones básicas
      if (_clienteController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Por favor ingrese el nombre del cliente'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Validar que al menos un item tenga datos
      bool tieneItemsValidos = items.any(
        (item) =>
            item.descripcionController.text.trim().isNotEmpty &&
            item.kilosController.text.trim().isNotEmpty &&
            item.precioController.text.trim().isNotEmpty,
      );

      if (!tieneItemsValidos) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Por favor complete al menos un item'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final fechaHoy = DateTime.now();
      final fechaFormateada =
          "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

      final counterRef = FirebaseFirestore.instance
          .collection('proformas_compras_counter')
          .doc(fechaFormateada);

      final counterDoc = await counterRef.get();

      int numero = 1;
      if (counterDoc.exists) {
        numero = counterDoc['contador'] + 1;
        await counterRef.update({'contador': numero});
      } else {
        await counterRef.set({'contador': numero});
      }

      final numeroProformaFinal = "ORDEN N-$fechaFormateada-$numero";

      final proformaData = {
        'numero': numeroProformaFinal,
        'cliente':
            _clienteController.text.toUpperCase(), // Guardar en mayúsculas
        'items':
            items
                .where(
                  (item) =>
                      item.descripcionController.text.trim().isNotEmpty &&
                      item.kilosController.text.trim().isNotEmpty &&
                      item.precioController.text.trim().isNotEmpty,
                )
                .map(
                  (item) => {
                    'descripcion':
                        item.descripcionController.text.toUpperCase(),
                    'kilos': item.kilosController.text,
                    'precio': item.precioController.text,
                    'total': item.totalController.text,
                  },
                )
                .toList(),
        'fecha': Timestamp.now(),
      };

      final user = FirebaseAuth.instance.currentUser;

      // Buscar el nombre en la colección usuarios_activos
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user?.uid)
              .get();

      final usuarioNombre =
          usuarioDoc.exists
              ? (usuarioDoc['nombre'] ?? 'Desconocido')
              : 'Desconocido';

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('proformasfundicion')
          .add(proformaData);

      // Registrar en auditoría
      final auditoriaRef =
          FirebaseFirestore.instance.collection('auditoria_general').doc();

      await auditoriaRef.set({
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': usuarioNombre,
        'usuario_uid': user?.uid ?? 'uid_desconocido',
        'accion': 'Nueva proforma fundición',
        'detalle': 'Número de proforma: $numeroProformaFinal',
      });

      // Cerrar loading
      Navigator.of(context, rootNavigator: true).pop();

      // Convertir items a formato Map<String, String> para el PDF
      List<Map<String, String>> itemsData =
          items
              .where(
                (item) =>
                    item.descripcionController.text.trim().isNotEmpty &&
                    item.kilosController.text.trim().isNotEmpty &&
                    item.precioController.text.trim().isNotEmpty,
              )
              .map(
                (item) => {
                  'descripcion': item.descripcionController.text.toUpperCase(),
                  'kilos': item.kilosController.text,
                  'precio': item.precioController.text,
                  'total': item.totalController.text,
                },
              )
              .toList();

      // Generar PDF automáticamente
      await MateriaPrimaPDFGenerator.showPreview(
        numero: numeroProformaFinal,
        cliente: _clienteController.text.toUpperCase(),
        fecha: fechaHoy,
        items: itemsData,
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Proforma guardada correctamente y lista para imprimir',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Limpiar campos después del éxito
      _clienteController.clear();
      items.clear();
      items.add(ItemProforma()); // Agregar un item vacío

      setState(() {
        _numeroProforma = ''; // Limpiar número para regenerarlo
      });

      // Regenerar número de proforma para la próxima
      _previsualizarNumeroProforma();
    } catch (e) {
      // Cerrar loading si está abierto
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      print('❌ Error al guardar proforma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

class ItemProforma {
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController kilosController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController totalController = TextEditingController();

  void dispose() {
    descripcionController.dispose();
    kilosController.dispose();
    precioController.dispose();
    totalController.dispose();
  }
}
