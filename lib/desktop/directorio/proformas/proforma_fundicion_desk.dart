import 'dart:async';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Proforma de Compras',
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
                                _buildCompactHeader(),
                                const SizedBox(height: 16),
                                _buildMobileClienteSection(),
                                const SizedBox(height: 16),
                                _buildMobileItemsSection(),
                                const SizedBox(height: 16),
                                _buildMobileTotalesSection(),
                                const SizedBox(height: 20),
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

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          _numeroProforma,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _previsualizarNumeroProforma();
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
    }

    setState(() {
      _numeroProforma = "PROFORMA N-$fechaFormateada-$numero";
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

  Widget _buildMobileItemsSection() {
    return _buildMobileSection(
      title: 'Items (${items.length})',
      icon: Icons.list_alt,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productos y servicios',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _agregarItem,
                  icon: Icon(Icons.add, color: Colors.white),
                  iconSize: 20,
                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            ItemProforma item = entry.value;
            return _buildMobileItemCard(index, item);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMobileItemCard(int index, ItemProforma item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del item
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Producto ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (items.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () => _eliminarItem(index),
                      icon: Icon(Icons.close, color: Colors.red[600]),
                      iconSize: 18,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),
              ],
            ),
          ),

          // Contenido del item en una sola línea
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: _buildItemInputField(
                    controller: item.descripcionController,
                    label: 'Descripción',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildItemInputField(
                    controller: item.kilosController,
                    label: 'Kilos',
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _calcularTotal(index),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildItemInputField(
                    controller: item.precioController,
                    label: 'Precio',
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (value) => _calcularTotal(index),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildItemInputField(
                    controller: item.totalController,
                    label: 'Subtotal',
                    readOnly: true,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    TextStyle? style,
    Function(String)? onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onChanged: onChanged,
        style: style ?? TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey[700],
          ),
          border: InputBorder.none,
          isDense: true,
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
                  onPressed: _vistaPrevia,
                  child: const Text('Vista previa'),
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
                  onPressed: _guardarProformaDirecto,
                  child: const Text('Guardar'),
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

  void _agregarItem() {
    setState(() {
      items.add(ItemProforma());
    });
  }

  void _eliminarItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
      });
    }
  }

  void _calcularTotal(int index) {
    setState(() {
      double kilos = double.tryParse(items[index].kilosController.text) ?? 0;
      double precio = double.tryParse(items[index].precioController.text) ?? 0;
      double total = kilos * precio;
      items[index].totalController.text = total.toStringAsFixed(2);
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

  void _vistaPrevia() async {
    final pdf = await _generarPDF();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<pw.Document> _generarPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFHeader(),
                    pw.SizedBox(height: 10),
                    _buildPDFClienteInfo(),
                    pw.SizedBox(height: 10),
                    _buildPDFItemsTable(),
                    pw.SizedBox(height: 10),
                    _buildPDFTotales(),
                    pw.SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(10), // tamaño intermedio
            color: PdfColor.fromHex('#4682B4'),
            child: pw.Text(
              'COMPRA DE MATERIA PRIMA',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 12, // intermedio: antes 14, grande era 20
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(8),
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Column(
              children: [
                pw.Text(
                  'FUNDIMETALES DEL NORTE',
                  style: pw.TextStyle(
                    fontSize: 10, // antes 10
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(_numeroProforma, style: pw.TextStyle(fontSize: 10)),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Dirección: Av Brasil y Panamá - (Tulcán Ecuador) - telf: 2962017',
                  style: pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFClienteInfo() {
    return pw.Container(
      padding: pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RECIBE CLIENTE',
            style: pw.TextStyle(
              fontSize: 10, // intermedio
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Cliente: ${_clienteController.text.toUpperCase()}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 3),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFItemsTable() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.all(6),
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'DESCRIPCIÓN',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'KILOS',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'PRECIO',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'SUBTOTAL',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => pw.Container(
              padding: pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item.descripcionController.text.toUpperCase(),
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.kilosController.text,
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.precioController.text}',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.totalController.text}',
                      style: pw.TextStyle(fontSize: 8),
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

  pw.Widget _buildPDFTotales() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Container(
          width: 180, // intermedio
          padding: pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Subtotal:',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                  pw.Text(
                    '\$${_calcularSubtotal()}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.normal,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 4),
                color: PdfColor.fromHex('#fff3cd'),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '\$${_calcularTotalFinal()}',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 30),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Container(
                width: 180,
                child: pw.Divider(thickness: 0.8, color: PdfColors.black),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Firma',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _guardarProformaDirecto() async {
    try {
      final fechaHoy = DateTime.now();
      final fechaFormateada =
          "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

      final counterRef = FirebaseFirestore.instance
          .collection('proformas_counters')
          .doc(fechaFormateada);

      final counterDoc = await counterRef.get();

      int numero = 1;
      if (counterDoc.exists) {
        numero = counterDoc['contador'] + 1;
        await counterRef.update({'contador': numero});
      } else {
        await counterRef.set({'contador': numero});
      }

      final numeroProformaFinal = "PROFORMA N-$fechaFormateada-$numero";
      print('✅ Número de proforma reservado: $numeroProformaFinal');

      final proformaData = {
        'numero': numeroProformaFinal,
        'cliente': _clienteController.text,
        'items':
            items
                .map(
                  (item) => {
                    'descripcion': item.descripcionController.text,
                    'kilos': item.kilosController.text,
                    'precio': item.precioController.text,
                    'total': item.totalController.text,
                  },
                )
                .toList(),
        'fecha': Timestamp.now(),
      };

      await FirebaseFirestore.instance
          .collection('proformasfundicion')
          .add(proformaData);

      print('✅ Proforma guardada en Firestore: $numeroProformaFinal');

      // Limpiar campos
      _clienteController.clear();
      items.clear();

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Proforma guardada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
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
