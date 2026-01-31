import 'dart:async';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFGeneratorAnticipo {
  static Future<pw.Document> generarPDF({
    required String numeroAnticipo,
    required String nombreSolicitante,
    required String montoAnticipo,
    required String motivo,
    required String justificacion,
    required String fechaSolicitud,
    required String fechaAprobacion,
    required String fechaDevolucion,
    required bool urgente,
    required String nombreAprobador,
    required String cargoAprobador,
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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20), // Reducido margen
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPDFHeader(logoProvider, numeroAnticipo),
              pw.SizedBox(height: 8), // Reducido espaciado
              _buildPDFSolicitanteInfo(
                nombreSolicitante,
                fechaSolicitud,
                urgente,
              ),
              pw.SizedBox(height: 6), // Reducido espaciado
              _buildPDFAnticipoDetails(montoAnticipo, motivo),
              pw.SizedBox(height: 8), // Reducido espaciado
              _buildPDFAutorizacion(nombreAprobador, cargoAprobador),
              pw.SizedBox(height: 6), // Reducido espaciado
            ],
          );
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildPDFHeader(
    pw.ImageProvider? logoProvider,
    String numeroAnticipo,
  ) {
    return pw.Container(
      width: double.infinity,
      height: 55, // Reducido altura
      padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: pw.Row(
        children: [
          // IZQUIERDA: LOGO (20% del ancho)
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: logoProvider != null
                  ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                  : pw.Container(
                      width: 45, // Reducido tamaño
                      height: 30,
                      color: PdfColor.fromHex('#1f4e79'),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'FN',
                        style: pw.TextStyle(
                          fontSize: 14, // Reducido tamaño de fuente
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
                      fontSize: 9, // Reducido tamaño de fuente
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'JOSE ALIRIO LOPEZ MARTINEZ',
                    style: pw.TextStyle(
                      fontSize: 7, // Reducido tamaño de fuente
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 1),
                  pw.Text(
                    'Direc.: Brasil y Panamá - Telf.: 0979230282 - Tulcán - Ecuador',
                    style: pw.TextStyle(fontSize: 6), // Reducido tamaño de fuente
                    textAlign: pw.TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // DERECHA: RUC Y NÚMERO DE ANTICIPO (20% del ancho)
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
                      fontSize: 6, // Reducido tamaño de fuente
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    padding: pw.EdgeInsets.all(3),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      numeroAnticipo,
                      style: pw.TextStyle(
                        fontSize: 7, // Reducido tamaño de fuente
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2C3E50'),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.SizedBox(height: 1),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _buildFechaBox('D', '${DateTime.now().day}', 12), // Reducido ancho
                      pw.SizedBox(width: 1),
                      _buildFechaBox('M', '${DateTime.now().month}', 12),
                      pw.SizedBox(width: 1),
                      _buildFechaBox('A', '${DateTime.now().year}', 20),
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
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold), // Reducido tamaño
        ),
        pw.Container(
          width: width,
          height: 8, // Reducido altura
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey, width: 0.3),
          ),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold), // Reducido tamaño
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPDFSolicitanteInfo(
    String nombreSolicitante,
    String fechaSolicitud,
    bool urgente,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6), // Reducido padding
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'DATOS DEL SOLICITANTE',
                style: pw.TextStyle(
                  fontSize: 9, // Reducido tamaño de fuente
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Spacer(),
              if (urgente)
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.red,
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Text(
                    'URGENTE',
                    style: pw.TextStyle(
                      fontSize: 6, // Reducido tamaño de fuente
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
            ],
          ),
          pw.SizedBox(height: 4), // Reducido espaciado

          // Nombre del solicitante
          pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Text(
                  'Nombre: $nombreSolicitante',
                  style: pw.TextStyle(
                    fontSize: 8, // Reducido tamaño de fuente
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Fecha: $fechaSolicitud',
                  style: pw.TextStyle(fontSize: 8), // Reducido tamaño de fuente
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFAnticipoDetails(
    String montoAnticipo,
    String motivo,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6), // Reducido padding
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DETALLES DEL ANTICIPO',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), // Reducido tamaño
          ),
          pw.SizedBox(height: 4), // Reducido espaciado

          // Monto y Motivo en una sola fila
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Monto (lado izquierdo)
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Monto Solicitado:',
                      style: pw.TextStyle(
                        fontSize: 8, // Reducido tamaño
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.all(4), // Reducido padding
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        '\$ $montoAnticipo',
                        style: pw.TextStyle(
                          fontSize: 11, // Reducido tamaño
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#856404'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 8),
              
              // Motivo (lado derecho)
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Motivo del Anticipo:',
                      style: pw.TextStyle(
                        fontSize: 8, // Reducido tamaño
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      width: double.infinity,
                      height: 35, // Altura fija para mantener alineación
                      padding: pw.EdgeInsets.all(4), // Reducido padding
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text(
                        motivo.isEmpty ? 'No especificado' : motivo,
                        style: pw.TextStyle(fontSize: 8), // Reducido tamaño
                        maxLines: 3, // Limitar líneas
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFAutorizacion(
    String nombreAprobador,
    String cargoAprobador,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6), // Reducido padding
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AUTORIZACIÓN Y FIRMAS',
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold), // Reducido tamaño
          ),
          pw.SizedBox(height: 6), // Reducido espaciado

          pw.Row(
            children: [
              // Columna del Solicitante
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      height: 25, // Reducido altura
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'FIRMA DEL SOLICITANTE',
                      style: pw.TextStyle(
                        fontSize: 7, // Reducido tamaño
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 15), // Reducido espaciado

              // Columna del Aprobador
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      height: 25, // Reducido altura
                      width: double.infinity,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'FIRMA DE AUTORIZACIÓN',
                      style: pw.TextStyle(
                        fontSize: 7, // Reducido tamaño
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    if (nombreAprobador.isNotEmpty)
                      pw.Text(
                        nombreAprobador,
                        style: pw.TextStyle(fontSize: 6), // Reducido tamaño
                      ),
                    if (cargoAprobador.isNotEmpty)
                      pw.Text(
                        cargoAprobador, 
                        style: pw.TextStyle(fontSize: 6) // Reducido tamaño
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> vistaPrevia({
    required String numeroAnticipo,
    required String nombreSolicitante,
    required String montoAnticipo,
    required String motivo,
    required String justificacion,
    required String fechaSolicitud,
    required String fechaAprobacion,
    required String fechaDevolucion,
    required String nombreAprobador,
    required String cargoAprobador,
  }) async {
    final pdf = await generarPDF(
      numeroAnticipo: numeroAnticipo,
      nombreSolicitante: nombreSolicitante,
      montoAnticipo: montoAnticipo,
      motivo: motivo,
      justificacion: justificacion,
      fechaSolicitud: fechaSolicitud,
      fechaAprobacion: fechaAprobacion,
      fechaDevolucion: fechaDevolucion,
      nombreAprobador: nombreAprobador,
      cargoAprobador: cargoAprobador, urgente: false,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}