import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ══════════════════════════════════════════════════════════════════════════════
//  PALETA — Colores corporativos Fundimetales del Norte
// ══════════════════════════════════════════════════════════════════════════════
class _C {
  static const navy        = PdfColor.fromInt(0xFF1F4E79); // Azul corporativo
  static const navyDark    = PdfColor.fromInt(0xFF0D2B4A); // Azul oscuro
  static const navyLight   = PdfColor.fromInt(0xFFD6E4F0); // Azul claro
  static const navyMid     = PdfColor.fromInt(0xFF2E6EA6); // Azul medio
  static const gold        = PdfColor.fromInt(0xFFC9A84C); // Dorado/acento
  static const goldLight   = PdfColor.fromInt(0xFFFFF4DC); // Dorado claro
  static const white       = PdfColors.white;
  static const lightGrey   = PdfColor.fromInt(0xFFF5F7FA); // Fondo filas alt
  static const midGrey     = PdfColor.fromInt(0xFFCBD5E1); // Bordes
  static const textDark    = PdfColor.fromInt(0xFF0D2B4A);
  static const textMid     = PdfColor.fromInt(0xFF4A6279);
  static const textLight   = PdfColor.fromInt(0xFF8DA5BA);
}

class ReportePdfService {
  static Future<Uint8List> generarReporteOperador({
    required String operadorNombre,
    required List<Map<String, dynamic>> tareas,
    DateTimeRange? rango,
  }) async {
    final pdf = pw.Document();

    // ── Cargar logo ──
    pw.ImageProvider? logoProvider;
    try {
      final logoBytes = await rootBundle.load('lib/assets/logoletters.png');
      logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // logo no disponible
    }

    pw.ImageProvider? bgLogoProvider;
    try {
      final logoBytes = await rootBundle.load('lib/assets/LOGOREDESFTN.png');
      bgLogoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // logo de fondo no disponible
    }

    // ── Calcular datos ──
    final Map<String, _ResumenReferencia> resumenPorReferencia = {};
    for (final tarea in tareas) {
      final ref      = tarea['referencia']?.toString() ?? 'Sin referencia';
      final cantidad = tarea['cantidad'] as int? ?? 0;
      resumenPorReferencia.putIfAbsent(ref, () => _ResumenReferencia(referencia: ref));
      resumenPorReferencia[ref]!.cantidad += cantidad;
      resumenPorReferencia[ref]!.veces    += 1;
    }

    final totalFundido = tareas.fold<int>(0, (s, t) => s + (t['cantidad'] as int? ?? 0));
    final rangoTexto   = rango == null
        ? 'Todas las fechas'
        : '${_fmt(rango.start)} — ${_fmt(rango.end)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        header: (_) => _buildHeader(logoProvider, operadorNombre, rangoTexto),
        footer:  (ctx) => _buildFooter(ctx),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          widgets.add(pw.SizedBox(height: 20));

          // KPI cards
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildKpiRow([
              _KpiData('Tareas\nCompletadas', '${tareas.length}',               _C.navy,    _C.navyLight),
              _KpiData('Total\nFundido',       '$totalFundido',                  _C.navyMid, _C.navyLight),
              _KpiData('Referencias\nÚnicas',  '${resumenPorReferencia.length}', _C.gold,    _C.goldLight),
            ]),
          ));

          widgets.add(pw.SizedBox(height: 22));

          // Resumen por referencia
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionTitle('RESUMEN POR REFERENCIA', _C.navyMid),
          ));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildResumenRefTable(resumenPorReferencia, totalFundido, tareas.length),
          ));

          widgets.add(pw.SizedBox(height: 22));

          // Detalle de tareas
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionTitle('DETALLE DE TAREAS COMPLETADAS', _C.navy),
          ));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildDetalleTareasTable(tareas, bgLogoProvider),
          ));

          widgets.add(pw.SizedBox(height: 10));
          return widgets;
        },
      ),
    );

    return pdf.save();
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(
    pw.ImageProvider? logoProvider,
    String operador,
    String rango,
  ) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        // Franja dorada superior
        pw.Container(height: 4, width: double.infinity, color: _C.gold),

        pw.Container(
          width: double.infinity,
          color: _C.navy,
          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: pw.Row(
            children: [
              // Logo
              pw.Container(
                width: 60,
                height: 50,
                alignment: pw.Alignment.center,
                child: logoProvider != null
                    ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                    : pw.Container(
                        width: 50,
                        height: 40,
                        color: _C.navyDark,
                        alignment: pw.Alignment.center,
                        child: pw.Text('FN',
                            style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              color: _C.white,
                            )),
                      ),
              ),

              pw.SizedBox(width: 14),

              // Línea separadora vertical
              pw.Container(width: 1, height: 50, color: _C.gold),

              pw.SizedBox(width: 14),

              // Título y datos del reporte
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('REPORTE DE PRODUCCIÓN',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: _C.white,
                          letterSpacing: 1,
                        )),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        _headerChip('OPERADOR', _C.gold, _C.navyDark),
                        pw.SizedBox(width: 6),
                        pw.Text(operador,
                            style: pw.TextStyle(
                              color: _C.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            )),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      children: [
                        _headerChip('PERÍODO', _C.navyMid, _C.navyDark),
                        pw.SizedBox(width: 6),
                        pw.Text(rango,
                            style: const pw.TextStyle(
                              color: _C.textLight, fontSize: 9,
                            )),
                      ],
                    ),
                  ],
                ),
              ),

              // Info empresa (derecha)
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(color: _C.gold),
                    child: pw.Text('FUNDIMETALES DEL NORTE',
                        style: pw.TextStyle(
                          color: _C.navyDark,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        )),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('RUC. 0401563812001',
                      style: const pw.TextStyle(fontSize: 7, color: _C.textLight)),
                  pw.SizedBox(height: 2),
                  pw.Text('Tulcán - Ecuador',
                      style: const pw.TextStyle(fontSize: 7, color: _C.textLight)),
                  pw.SizedBox(height: 2),
                  pw.Text('Generado: ${_fmt(DateTime.now())}',
                      style: const pw.TextStyle(color: _C.textLight, fontSize: 7)),
                ],
              ),
            ],
          ),
        ),

        // Franja inferior degradada (simulada con dos contenedores)
        pw.Row(
          children: [
            pw.Expanded(child: pw.Container(height: 2, color: _C.navyMid)),
            pw.Expanded(child: pw.Container(height: 2, color: _C.gold)),
          ],
        ),
      ],
    );
  }

  // ── FOOTER ─────────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(pw.Context ctx) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Row(
          children: [
            pw.Expanded(child: pw.Container(height: 2, color: _C.gold)),
            pw.Expanded(child: pw.Container(height: 2, color: _C.navyMid)),
          ],
        ),
        pw.Container(
          width: double.infinity,
          color: _C.navy,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 24),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  pw.Text('SOFTWARE ELABORADO POR FUNDIMETALES DEL NORTE',
                      style: pw.TextStyle(
                        fontSize: 6,
                        fontWeight: pw.FontWeight.bold,
                        color: _C.gold,
                      )),
                  pw.Text('sistemas@fundimetalesdelnorte.com',
                      style: const pw.TextStyle(fontSize: 6, color: _C.textLight)),
                ],
              ),
              pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                  style: const pw.TextStyle(color: _C.textLight, fontSize: 7)),
            ],
          ),
        ),
      ],
    );
  }

  // ── KPI CARDS ───────────────────────────────────────────────────────────────
  static pw.Widget _buildKpiRow(List<_KpiData> kpis) {
    return pw.Row(
      children: kpis.asMap().entries.map((e) {
        final isLast = e.key == kpis.length - 1;
        return pw.Expanded(
          child: pw.Padding(
            padding: pw.EdgeInsets.only(right: isLast ? 0 : 10),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: e.value.bgLight,
                border: pw.Border.all(color: e.value.accent, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  pw.Container(width: 5, height: 60, color: e.value.accent),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(e.value.value,
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: e.value.accent,
                            )),
                        pw.SizedBox(height: 3),
                        pw.Text(e.value.label,
                            style: const pw.TextStyle(fontSize: 8, color: _C.textMid)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── SECTION TITLE ───────────────────────────────────────────────────────────
  static pw.Widget _buildSectionTitle(String title, PdfColor accent) {
    return pw.Container(
      width: double.infinity,
      color: _C.navyDark,
      padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 0),
      child: pw.Row(
        children: [
          pw.Container(width: 4, height: 18, color: _C.gold),
          pw.SizedBox(width: 10),
          pw.Text(title,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: _C.white,
                letterSpacing: 0.8,
              )),
        ],
      ),
    );
  }

  // ── TABLA RESUMEN POR REFERENCIA ─────────────────────────────────────────────
  static pw.Widget _buildResumenRefTable(
      Map<String, _ResumenReferencia> data, int totalFundido, int totalTareas) {
    return pw.Table(
      border: pw.TableBorder.all(color: _C.midGrey, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        _headerRow(['Referencia', 'Cantidad Total', 'Nº de Registros']),
        ...data.values.toList().asMap().entries.map((e) => _dataRow(
          [e.value.referencia, '${e.value.cantidad}', '${e.value.veces}'], e.key,
        )),
        _totalRow(['TOTAL GENERAL', '$totalFundido', '$totalTareas']),
      ],
    );
  }

  // ── TABLA DETALLE DE TAREAS ──────────────────────────────────────────────────
  static pw.Widget _buildDetalleTareasTable(
    List<Map<String, dynamic>> tareas,
    pw.ImageProvider? bgLogoProvider,
  ) {
    return pw.Stack(
      children: [
        if (bgLogoProvider != null)
          pw.Positioned.fill(
            child: pw.Opacity(
              opacity: 0.07,
              child: pw.Center(
                child: pw.Container(
                  width: 200,
                  height: 200,
                  child: pw.Image(bgLogoProvider, fit: pw.BoxFit.contain),
                ),
              ),
            ),
          ),
        pw.Table(
          border: pw.TableBorder.all(color: _C.midGrey, width: 0.5),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(2),
            4: pw.FlexColumnWidth(2),
          },
          children: [
            _headerRow(['Referencia', 'Descripción', 'Cant.', 'F. Asignación', 'F. Completada']),
            ...tareas.asMap().entries.map((e) {
              final t     = e.value;
              final fAsig = _tsToDate(t['fecha_asignacion']);
              final fComp = _tsToDate(t['fecha_completada']);
              return _dataRow([
                t['referencia']?.toString()  ?? '-',
                t['descripcion']?.toString() ?? '-',
                '${t['cantidad'] ?? 0}',
                fAsig != null ? _fmt(fAsig) : '-',
                fComp != null ? _fmt(fComp) : '-',
              ], e.key);
            }),
          ],
        ),
      ],
    );
  }

  // ── TABLE BUILDERS ──────────────────────────────────────────────────────────
  static pw.TableRow _headerRow(List<String> labels) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: _C.navy),
    children: labels.map((l) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(l,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _C.gold,
          )),
    )).toList(),
  );

  static pw.TableRow _dataRow(List<String> values, int index) => pw.TableRow(
    decoration: pw.BoxDecoration(
      color: index % 2 == 0 ? _C.white : _C.lightGrey,
    ),
    children: values.asMap().entries.map((e) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(e.value,
          style: pw.TextStyle(
            fontSize: 8,
            color: e.key == 0
                ? _C.navy
                : e.key == 2
                ? _C.gold
                : _C.textDark,
            fontWeight: (e.key == 0 || e.key == 2)
                ? pw.FontWeight.bold
                : pw.FontWeight.normal,
          ),
          overflow: pw.TextOverflow.clip),
    )).toList(),
  );

  static pw.TableRow _totalRow(List<String> values) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: _C.navyDark),
    children: values.map((v) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(v,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _C.gold,
          )),
    )).toList(),
  );

  // ── MICRO WIDGETS ───────────────────────────────────────────────────────────
  static pw.Widget _headerChip(String label, PdfColor bg, PdfColor textColor) =>
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: pw.BoxDecoration(color: bg),
        child: pw.Text(label,
            style: pw.TextStyle(
              fontSize: 6,
              fontWeight: pw.FontWeight.bold,
              color: textColor,
            )),
      );

  // ── HELPERS ─────────────────────────────────────────────────────────────────
  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  static DateTime? _tsToDate(dynamic v) {
    if (v == null) return null;
    try { return (v as Timestamp).toDate(); } catch (_) { return null; }
  }
}

class _KpiData {
  final String label, value;
  final PdfColor accent, bgLight;
  const _KpiData(this.label, this.value, this.accent, this.bgLight);
}

class _ResumenReferencia {
  final String referencia;
  int cantidad = 0;
  int veces    = 0;
  _ResumenReferencia({required this.referencia});
}