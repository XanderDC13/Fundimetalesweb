import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RechazosPdfService {
  static Future<void> generarYCompartir({
    required List<Map<String, dynamic>> rechazos,
    DateTimeRange? rango,
  }) async {
    final pdfBytes = await _generarPDF(rechazos: rechazos, rango: rango);
    final fecha = DateTime.now();
    final nombre =
        'rechazos_fundicion_${fecha.year}${fecha.month.toString().padLeft(2, '0')}${fecha.day.toString().padLeft(2, '0')}.pdf';
    await Printing.sharePdf(bytes: pdfBytes, filename: nombre);
  }

  static Future<Uint8List> _generarPDF({
    required List<Map<String, dynamic>> rechazos,
    DateTimeRange? rango,
  }) async {
    final pdf = pw.Document();

    // Colores
    const colorPrimario = PdfColor.fromInt(0xFF2C3E50);
    const colorRojo = PdfColor.fromInt(0xFFE74C3C);
    const colorGris = PdfColor.fromInt(0xFFF5F5F5);
    const colorGrisBorde = PdfColor.fromInt(0xFFDDDDDD);

    // Totales
    final totalRechazados = rechazos.fold<int>(
      0,
      (sum, r) => sum + ((r['cantidad'] as num?)?.toInt() ?? 0),
    );

    String rangoTexto = 'Todos los registros';
    if (rango != null) {
      final d1 =
          '${rango.start.day.toString().padLeft(2, '0')}/${rango.start.month.toString().padLeft(2, '0')}/${rango.start.year}';
      final d2 =
          '${rango.end.day.toString().padLeft(2, '0')}/${rango.end.month.toString().padLeft(2, '0')}/${rango.end.year}';
      rangoTexto = 'Del $d1 al $d2';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(
          colorPrimario: colorPrimario,
          colorRojo: colorRojo,
          rangoTexto: rangoTexto,
          totalRegistros: rechazos.length,
          totalCantidad: totalRechazados,
        ),
        footer: (context) => _buildFooter(context, colorPrimario),
        build: (context) => [
          pw.SizedBox(height: 16),
          _buildTabla(rechazos, colorGris, colorGrisBorde, colorRojo),
          pw.SizedBox(height: 24),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader({
    required PdfColor colorPrimario,
    required PdfColor colorRojo,
    required String rangoTexto,
    required int totalRegistros,
    required int totalCantidad,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Barra superior
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: pw.BoxDecoration(color: colorPrimario),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'REPORTE DE RECHAZOS',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Fundición — Control de Calidad',
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'FUNDIMETALES DEL NORTE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    _fechaHoy(),
                    style: const pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        // Fila de resumen
        pw.Row(
          children: [
            _buildResumenCard(
              'Período',
              rangoTexto,
              colorPrimario,
              flex: 3,
            ),
            pw.SizedBox(width: 8),
            _buildResumenCard(
              'Total Registros',
              '$totalRegistros',
              colorRojo,
            ),
            pw.SizedBox(width: 8),
            _buildResumenCard(
              'Piezas Rechazadas',
              '$totalCantidad',
              colorRojo,
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
      ],
    );
  }

  static pw.Widget _buildResumenCard(
    String label,
    String value,
    PdfColor color, {
    int flex = 1,
  }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: const pw.TextStyle(
                color: PdfColors.white,
                fontSize: 9,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTabla(
    List<Map<String, dynamic>> rechazos,
    PdfColor colorGris,
    PdfColor colorGrisBorde,
    PdfColor colorRojo,
  ) {
    const headerStyle = pw.TextStyle(
      color: PdfColors.white,
      fontSize: 10,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: colorGrisBorde, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.5), // Fecha
        1: pw.FlexColumnWidth(1.5), // Referencia
        2: pw.FlexColumnWidth(0.8), // Cantidad
        3: pw.FlexColumnWidth(2.5), // Motivo
        4: pw.FlexColumnWidth(1.5), // Registrado por
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: const PdfColor.fromInt(0xFF2C3E50),
          ),
          children: [
            _celdaHeader('Fecha', headerStyle),
            _celdaHeader('Referencia', headerStyle),
            _celdaHeader('Cant.', headerStyle),
            _celdaHeader('Motivo', headerStyle),
            _celdaHeader('Registrado por', headerStyle),
          ],
        ),
        // Filas
        ...rechazos.asMap().entries.map((entry) {
          final i = entry.key;
          final r = entry.value;
          final esPar = i % 2 == 0;

          final fecha = (r['fecha'] as Timestamp?)?.toDate();
          final fechaStr = fecha != null
              ? '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}'
              : '—';

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: esPar ? PdfColors.white : colorGris,
            ),
            children: [
              _celdaDato(fechaStr),
              _celdaDato(r['referencia']?.toString() ?? '—', bold: true),
              _celdaDato(
                r['cantidad']?.toString() ?? '0',
                align: pw.TextAlign.center,
                color: colorRojo,
                bold: true,
              ),
              _celdaDato(r['motivo']?.toString() ?? 'Sin motivo'),
              _celdaDato(r['registrado_por']?.toString() ?? '—'),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _celdaHeader(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _celdaDato(
    String text, {
    bool bold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context, PdfColor colorPrimario) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Fundimetales del Norte — Reporte Confidencial',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
            pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _fechaHoy() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }
}