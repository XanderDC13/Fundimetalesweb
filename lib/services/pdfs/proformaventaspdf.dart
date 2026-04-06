import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFGenerator {
  static Future<pw.Document> generarPDF({
    required String numeroProforma,
    required String cliente,
    required String direccion,
    required String ciudad,
    required String correo,
    required String ruc,
    required String telefono,
    required List<ItemProforma> items,
    required String subtotalCero,
    required bool aplicarIVA,
    required String validez,
    required String saldo,
    required String entrega,
    required String lugar,
  }) async {
    final pdf = pw.Document();

    // Cargar el logo al inicio
    pw.ImageProvider? logoProvider;
    try {
      final logoBytes = await rootBundle.load('lib/assets/logoletters.png');
      logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Error al cargar logo: $e');
    }

    final double subtotalCeroValue = double.tryParse(subtotalCero) ?? 0.0;

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
                    _buildPDFHeader(
                      logoProvider,
                      numeroProforma,
                      DateTime.now(),
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFItemsTable(items),
                    pw.SizedBox(height: 10),
                    _buildPDFTotales(items, subtotalCeroValue, aplicarIVA),
                    pw.SizedBox(height: 10),
                    _buildPDFCondiciones(validez, saldo, entrega, lugar),
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

  static pw.Widget _buildPDFHeader(
    pw.ImageProvider? logoProvider,
    String numeroProforma,
    DateTime fecha,
  ) {
    return pw.Container(
      width: double.infinity,
      height: 70,
      padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: pw.Row(
        children: [
          // IZQUIERDA: LOGO (20% del ancho)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child:
                  logoProvider != null
                      ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                      : pw.Container(
                        width: 60,
                        height: 40,
                        color: PdfColor.fromHex('#1f4e79'),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'FN',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
            ),
          ),

          // CENTRO: INFORMACIÓN DE LA EMPRESA (60% del ancho)
          pw.Expanded(
            flex: 6,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'FUNDIMETALES DEL NORTE',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'JOSE ALIRIO LOPEZ MARTINEZ',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Fábrica de Campanas o Tambores para frenos de Automotores',
                    style: pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.Text(
                    'en todas las marcas y modelos - Fabricamos toda clase de adaptaciones',
                    style: pw.TextStyle(fontSize: 6),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Direc.: Brasil y Panamá - Telf.: 0979230282 - Tulcán - Ecuador',
                    style: pw.TextStyle(fontSize: 7),
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // DERECHA: RUC, PROFORMA, NÚMERO Y FECHA (20% del ancho)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'RUC. 0401563812001',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    numeroProforma,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _buildFechaBox(
                        'D',
                        '${fecha.day.toString().padLeft(2, '0')}',
                        18,
                      ),
                      pw.SizedBox(width: 2),
                      _buildFechaBox(
                        'M',
                        '${fecha.month.toString().padLeft(2, '0')}',
                        18,
                      ),
                      pw.SizedBox(width: 2),
                      _buildFechaBox('A', '${fecha.year}', 28),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFechaBox(String label, String value, double width) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
        pw.Container(
          width: width,
          height: 9,
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.3),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
        ),
      ],
    );
  }


  static pw.Widget _buildPDFItemsTable(List<ItemProforma> items) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.all(5),
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'CÓDIGO',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
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
                    'CANT.',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'P. UNIT',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'TOTAL',
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
              padding: pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.codigoController.text,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item.descripcionController.text,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.cantidadController.text,
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.precioController.text}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.totalController.text}',
                      style: pw.TextStyle(fontSize: 9),
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

  static pw.Widget _buildPDFTotales(
    List<ItemProforma> items,
    double subtotalCero,
    bool aplicarIVA,
  ) {
    String calcularSubtotal() {
      double subtotal = 0;
      for (var item in items) {
        subtotal += double.tryParse(item.totalController.text) ?? 0;
      }
      return subtotal.toStringAsFixed(2);
    }

    String calcularIVA() {
      if (!aplicarIVA) return '0.00';
      double subtotal = double.tryParse(calcularSubtotal()) ?? 0;
      double iva = subtotal * 0.15;
      return iva.toStringAsFixed(2);
    }

    String calcularTotalFinal() {
      double subtotal = double.tryParse(calcularSubtotal()) ?? 0;
      double iva = aplicarIVA ? double.tryParse(calcularIVA()) ?? 0 : 0;
      double total = subtotal + subtotalCero + iva;
      return total.toStringAsFixed(2);
    }

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 140,
          padding: pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    '\$${calcularSubtotal()}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal 0%:', style: pw.TextStyle(fontSize: 9)),
                  pw.Text(
                    '\$${subtotalCero.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 3),
              if (aplicarIVA) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('(+) 15% IVA:', style: pw.TextStyle(fontSize: 9)),
                    pw.Text(
                      '\$${calcularIVA()}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
              ],
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 2),
                color: PdfColor.fromHex('#fff3cd'),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '\$${calcularTotalFinal()}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFCondiciones(
    String validez,
    String saldo,
    String entrega,
    String lugar,
  ) {
    return pw.Center(
      child: pw.Container(
        padding: pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        width: 350,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'CONDICIONES GENERALES DE LA OFERTA',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Validez de la oferta: $validez',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Forma de pago: $saldo',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Plazo de entrega: $entrega',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Lugar de entrega: $lugar',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> vistaPrevia({
    required String numeroProforma,
    required String cliente,
    required String nombreComercial,
    required String direccion,
    required String ciudad,
    required String correo,
    required String ruc,
    required String telefono,
    required List<ItemProforma> items,
    required String subtotalCero,
    required bool aplicarIVA,
    required String validez,
    required String saldo,
    required String entrega,
    required String lugar,
  }) async {
    final pdf = await generarPDF(
      numeroProforma: numeroProforma,
      cliente: cliente,
     direccion: direccion,
      ciudad: ciudad,
      correo: correo,
      ruc: ruc,
      telefono: telefono,
      items: items,
      subtotalCero: subtotalCero,
      aplicarIVA: aplicarIVA,
      validez: validez,
      saldo: saldo,
      entrega: entrega,
      lugar: lugar,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}

// Clase ItemProforma necesaria para el PDFGenerator
class ItemProforma {
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController ciudadController = TextEditingController();
  final TextEditingController correoController = TextEditingController();

  void dispose() {
    codigoController.dispose();
    descripcionController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    totalController.dispose();
    ciudadController.dispose();
    correoController.dispose();
  }
}
