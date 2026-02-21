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
  static const lightGrey   = PdfColor.fromInt(0xFFF5F7FA);
  static const midGrey     = PdfColor.fromInt(0xFFCBD5E1);
  static const textDark    = PdfColor.fromInt(0xFF0D2B4A);
  static const textMid     = PdfColor.fromInt(0xFF4A6279);
  static const textLight   = PdfColor.fromInt(0xFF8DA5BA);
}

class ReporteGeneralPdfService {
  static Future<Uint8List> generarReporteGeneral({
    required List<Map<String, dynamic>> tareas,
    required Map<String, String> nombresOperadores,
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

    // ── Agrupar por operador ──
    final Map<String, List<Map<String, dynamic>>> tareasPorOp = {};
    for (final t in tareas) {
      final id = t['operador_id']?.toString() ?? 'desconocido';
      tareasPorOp.putIfAbsent(id, () => []);
      tareasPorOp[id]!.add(t);
    }

    final totalTareas     = tareas.length;
    final totalFundido    = tareas.fold<int>(0, (s, t) => s + (t['cantidad'] as int? ?? 0));
    final totalOperadores = tareasPorOp.keys.length;

    final resumen = tareasPorOp.entries.map((e) {
      final nombre   = nombresOperadores[e.key] ?? 'Operador desconocido';
      final cantidad = e.value.fold<int>(0, (s, t) => s + (t['cantidad'] as int? ?? 0));
      return _ResumenOperador(
        id: e.key,
        nombre: nombre,
        tareas: e.value.length,
        cantidad: cantidad,
      );
    }).toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

    final rangoTexto = rango == null
        ? 'Todas las fechas'
        : '${_fmt(rango.start)} — ${_fmt(rango.end)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(0),
        header: (_) => _buildHeader(logoProvider, rangoTexto, totalOperadores),
        footer:  (ctx) => _buildFooter(ctx),
        build: (ctx) {
          final widgets = <pw.Widget>[];

          widgets.add(pw.SizedBox(height: 20));

          // ── KPI Cards globales ──
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildKpiRow([
              _KpiData('Total\nOperadores',  '$totalOperadores', _C.navy,    _C.navyLight),
              _KpiData('Total\nTareas',      '$totalTareas',     _C.navyMid, _C.navyLight),
              _KpiData('Total\nFundido',     '$totalFundido',    _C.gold,    _C.goldLight),
            ]),
          ));

          widgets.add(pw.SizedBox(height: 22));

          // ── Resumen por operador ──
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionTitle('RESUMEN POR OPERADOR'),
          ));
          widgets.add(pw.SizedBox(height: 6));
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildResumenTabla(resumen, totalTareas, totalFundido),
          ));

          widgets.add(pw.SizedBox(height: 22));

          // ── Detalle por operador ──
          widgets.add(pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionTitle('DETALLE POR OPERADOR'),
          ));
          widgets.add(pw.SizedBox(height: 6));

          for (final entry in tareasPorOp.entries) {
            final nombre = nombresOperadores[entry.key] ?? 'Desconocido';

            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24),
              child: _buildOperadorHeader(nombre, entry.value),
            ));
            widgets.add(pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 24),
              child: _buildOperadorTabla(entry.value, bgLogoProvider),
            ));
            widgets.add(pw.SizedBox(height: 16));
          }

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
    String rangoTexto,
    int totalOperadores,
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
              pw.Container(width: 1, height: 50, color: _C.gold),
              pw.SizedBox(width: 14),

              // Título y datos
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    pw.Text('REPORTE GENERAL DE FUNDICIÓN',
                        style: pw.TextStyle(
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          color: _C.white,
                          letterSpacing: 1,
                        )),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        _headerChip('PERÍODO'),
                        pw.SizedBox(width: 6),
                        pw.Text(rangoTexto,
                            style: const pw.TextStyle(
                              color: _C.textLight, fontSize: 9,
                            )),
                        pw.SizedBox(width: 14),
                        _headerChip('OPERADORES'),
                        pw.SizedBox(width: 6),
                        pw.Text('$totalOperadores activos',
                            style: pw.TextStyle(
                              color: _C.white,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            )),
                      ],
                    ),
                  ],
                ),
              ),

              // Info empresa
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
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      color: _C.navyDark,
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
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

  // ── TABLA RESUMEN ────────────────────────────────────────────────────────────
  static pw.Widget _buildResumenTabla(
    List<_ResumenOperador> ops,
    int totalTareas,
    int totalFundido,
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: _C.midGrey, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        _headerRow(['Operador', 'Tareas', 'Total Fundido']),
        ...ops.asMap().entries.map((e) => _dataRow([
          e.value.nombre,
          '${e.value.tareas}',
          '${e.value.cantidad}',
        ], e.key)),
        _totalRow(['TOTAL GENERAL', '$totalTareas', '$totalFundido']),
      ],
    );
  }

  // ── CABECERA OPERADOR ────────────────────────────────────────────────────────
  static pw.Widget _buildOperadorHeader(
    String nombre,
    List<Map<String, dynamic>> tareasOp,
  ) {
    final total = tareasOp.fold<int>(0, (s, t) => s + (t['cantidad'] as int? ?? 0));
    return pw.Container(
      width: double.infinity,
      color: _C.navy,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 4, height: 16, color: _C.gold),
              pw.SizedBox(width: 8),
              pw.Text(nombre,
                  style: pw.TextStyle(
                    color: _C.white,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  )),
            ],
          ),
          pw.Row(
            children: [
              _pillChip('${tareasOp.length} tareas', _C.navyMid),
              pw.SizedBox(width: 6),
              _pillChip('Total: $total', _C.gold),
            ],
          ),
        ],
      ),
    );
  }

  // ── TABLA TAREAS DE UN OPERADOR ──────────────────────────────────────────────
  static pw.Widget _buildOperadorTabla(
    List<Map<String, dynamic>> tareasOp,
    pw.ImageProvider? bgLogoProvider,
  ) {
    final sorted = List<Map<String, dynamic>>.from(tareasOp)..sort((a, b) {
      final fa = _tsToDate(a['fecha_completada']) ?? DateTime(2000);
      final fb = _tsToDate(b['fecha_completada']) ?? DateTime(2000);
      return fb.compareTo(fa);
    });
    final total = sorted.fold<int>(0, (s, t) => s + (t['cantidad'] as int? ?? 0));

    return pw.Stack(
      children: [
        if (bgLogoProvider != null)
          pw.Positioned.fill(
            child: pw.Opacity(
              opacity: 0.06,
              child: pw.Center(
                child: pw.Container(
                  width: 150,
                  height: 150,
                  child: pw.Image(bgLogoProvider, fit: pw.BoxFit.contain),
                ),
              ),
            ),
          ),
        pw.Table(
          border: pw.TableBorder.all(color: _C.midGrey, width: 0.4),
          columnWidths: const {
            0: pw.FlexColumnWidth(2),
            1: pw.FlexColumnWidth(3),
            2: pw.FlexColumnWidth(1),
            3: pw.FlexColumnWidth(2),
          },
          children: [
            _headerRow(['Referencia', 'Descripción', 'Cant.', 'Fecha Completada']),
            ...sorted.asMap().entries.map((e) {
              final t     = e.value;
              final fecha = _tsToDate(t['fecha_completada']);
              return _dataRow([
                t['referencia']?.toString()  ?? '-',
                t['descripcion']?.toString() ?? '-',
                '${t['cantidad'] ?? 0}',
                fecha != null ? _fmt(fecha) : '-',
              ], e.key);
            }),
            _totalRow(['Subtotal', '', '$total', '']),
          ],
        ),
      ],
    );
  }

  // ── TABLE BUILDERS ──────────────────────────────────────────────────────────
  static pw.TableRow _headerRow(List<String> labels) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: _C.navyDark),
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
  static pw.Widget _headerChip(String label) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: const pw.BoxDecoration(color: _C.gold),
    child: pw.Text(label,
        style: pw.TextStyle(
          fontSize: 6,
          fontWeight: pw.FontWeight.bold,
          color: _C.navyDark,
        )),
  );

  static pw.Widget _pillChip(String label, PdfColor color) => pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: pw.BoxDecoration(color: color),
    child: pw.Text(label,
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _C.white,
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

class _ResumenOperador {
  final String id, nombre;
  final int tareas, cantidad;
  const _ResumenOperador({
    required this.id,
    required this.nombre,
    required this.tareas,
    required this.cantidad,
  });
}