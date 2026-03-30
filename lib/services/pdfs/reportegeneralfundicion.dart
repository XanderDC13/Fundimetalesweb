import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// ══════════════════════════════════════════════════════════════════════════════
//  PALETA
// ══════════════════════════════════════════════════════════════════════════════
class _C {
  static const navy      = PdfColor.fromInt(0xFF1F4E79);
  static const navyDark  = PdfColor.fromInt(0xFF0D2B4A);
  static const navyLight = PdfColor.fromInt(0xFFD6E4F0);
  static const navyMid   = PdfColor.fromInt(0xFF2E6EA6);
  static const gold      = PdfColor.fromInt(0xFFC9A84C);
  static const goldLight = PdfColor.fromInt(0xFFFFF4DC);
  static const white     = PdfColors.white;
  static const lightGrey = PdfColor.fromInt(0xFFF5F7FA);
  static const midGrey   = PdfColor.fromInt(0xFFCBD5E1);
  static const textDark  = PdfColor.fromInt(0xFF0D2B4A);
  static const textMid   = PdfColor.fromInt(0xFF4A6279);
  static const textLight = PdfColor.fromInt(0xFF8DA5BA);
  static const green     = PdfColor.fromInt(0xFF1A7A4A);
  static const orange    = PdfColor.fromInt(0xFFB45309);
  static const greyText  = PdfColor.fromInt(0xFF64748B);
}

// ══════════════════════════════════════════════════════════════════════════════
//  SERVICIO PRINCIPAL
// ══════════════════════════════════════════════════════════════════════════════
class ReporteGeneralPdfService {
  // Márgenes de página (usados tanto en header/footer como en contenido)
  static const double _hPad = 24;
  static const double _vPad = 16;

  static Future<Uint8List> generarReporteGeneral({
    required List<Map<String, dynamic>> tareas,
    required Map<String, String> nombresOperadores,
    DateTimeRange? rango,
    List<Map<String, dynamic>> tareasExtras = const [], required Uint8List logoBytes,
  }) async {
    final pdf = pw.Document();
    final logoBytes    = await rootBundle.load('lib/assets/logo.png');
    final logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());

    // ── Agrupaciones ──────────────────────────────────────────────────────────
    final Map<String, List<Map<String, dynamic>>> tareasPorOp  = {};
    for (final t in tareas) {
      final id = t['operador_id']?.toString() ?? 'desconocido';
      tareasPorOp.putIfAbsent(id, () => []).add(t);
    }

    final Map<String, List<Map<String, dynamic>>> extrasPorOp = {};
    for (final te in tareasExtras) {
      final id = te['operador_id']?.toString() ?? '';
      extrasPorOp.putIfAbsent(id, () => []).add(te);
    }

    // ── KPIs globales ─────────────────────────────────────────────────────────
    final totalTareas    = tareas.length;
    final totalFundido   = tareas.fold<int>(0, (s, t) => s + ((t['cantidad'] as num?)?.toInt() ?? 0));
    final totalOperadores = tareasPorOp.keys.length;

    // ── Resumen por operador ──────────────────────────────────────────────────
    final resumen = tareasPorOp.entries.map((e) {
      final nombre   = nombresOperadores[e.key] ?? 'Operador desconocido';
      final cantidad = e.value.fold<int>(0, (s, t) => s + ((t['cantidad'] as num?)?.toInt() ?? 0));
      return _ResumenOp(id: e.key, nombre: nombre, tareas: e.value.length, cantidad: cantidad);
    }).toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

    // ── Referencias globales ──────────────────────────────────────────────────
    final Map<String, int> sumaRefs = {};
    for (final t in tareas) {
      final ref  = t['referencia']?.toString();
      final cant = (t['cantidad'] as num?)?.toInt() ?? 0;
      if (ref != null && ref.isNotEmpty) sumaRefs[ref] = (sumaRefs[ref] ?? 0) + cant;
    }
    final listaRefs = sumaRefs.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final rangoTexto = rango == null
        ? 'Todas las fechas'
        : '${_fmt(rango.start)} — ${_fmt(rango.end)}';

    // ─────────────────────────────────────────────────────────────────────────
    // Builders de header / footer que MultiPage llama en cada página
    // ─────────────────────────────────────────────────────────────────────────
    pw.Widget headerBuilder(pw.Context ctx) =>
        _header(rangoTexto, totalOperadores, logoProvider);

    pw.Widget footerBuilder(pw.Context ctx) => _footer(ctx);

    // =========================================================================
    // BLOQUE 1 — Resumen general  (fluye con MultiPage)
    // =========================================================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat : PdfPageFormat.a4,
        margin     : const pw.EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
        header     : headerBuilder,
        footer     : footerBuilder,
        build      : (ctx) => [
          pw.SizedBox(height: 18),
          // KPIs
          _kpiRow([
            _KpiData('Total\nOperadores', '$totalOperadores', _C.navy,    _C.navyLight),
            _KpiData('Total\nTareas',     '$totalTareas',     _C.navyMid, _C.navyLight),
            _KpiData('Total\nMoldeado',    '$totalFundido',    _C.gold,    _C.goldLight),
          ]),
          pw.SizedBox(height: 22),
          _sectionTitle('RESUMEN POR OPERADOR'),
          pw.SizedBox(height: 8),
          _resumenTabla(resumen, totalTareas, totalFundido),
          pw.SizedBox(height: 24),
        ],
      ),
    );

    // =========================================================================
    // BLOQUE 2..N — Un MultiPage por operador  (el contenido fluye libremente)
    // =========================================================================
    final todosIds = <String>{...tareasPorOp.keys, ...extrasPorOp.keys};

    for (final opId in todosIds) {
      final nombre      = nombresOperadores[opId] ?? 'Operador desconocido';
      final tareasOp    = tareasPorOp[opId] ?? [];
      final extrasOp    = extrasPorOp[opId] ?? [];
      final totalOp     = tareasOp.fold<int>(0, (s, t) => s + ((t['cantidad'] as num?)?.toInt() ?? 0));

      // Referencias del operador
      final Map<String, int> refsOp = {};
      for (final t in tareasOp) {
        final ref  = t['referencia']?.toString();
        final cant = (t['cantidad'] as num?)?.toInt() ?? 0;
        if (ref != null && ref.isNotEmpty) refsOp[ref] = (refsOp[ref] ?? 0) + cant;
      }
      final listaRefsOp = refsOp.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      // Ordenar tareas completadas por fecha descendente
      final tareasOrdenadas = List<Map<String, dynamic>>.from(tareasOp)
        ..sort((a, b) {
          final fa = _tsToDate(a['fecha_completada']) ?? DateTime(2000);
          final fb = _tsToDate(b['fecha_completada']) ?? DateTime(2000);
          return fb.compareTo(fa);
        });

      pdf.addPage(
        pw.MultiPage(
          pageFormat : PdfPageFormat.a4,
          margin     : const pw.EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
          header     : headerBuilder,
          footer     : footerBuilder,
          build      : (ctx) => [
            pw.SizedBox(height: 10),

            // ── Cabecera del operador ──────────────────────────────────────
            pw.Container(
              color   : _C.navy,
              padding : const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child   : pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(children: [
                    pw.Container(width: 4, height: 20, color: _C.gold),
                    pw.SizedBox(width: 10),
                    pw.Text(nombre, style: pw.TextStyle(color: _C.white, fontWeight: pw.FontWeight.bold, fontSize: 13)),
                  ]),
                  pw.Row(children: [
                    _chip('${tareasOp.length} completadas', _C.navyMid),
                    pw.SizedBox(width: 6),
                    _chip('${extrasOp.length} extras',      _C.orange),
                    pw.SizedBox(width: 6),
                    _chip('Total: $totalOp',                _C.gold),
                  ]),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // ── Tareas completadas ─────────────────────────────────────────
            _sectionTitle('TAREAS COMPLETADAS'),
            pw.SizedBox(height: 6),
            if (tareasOrdenadas.isEmpty)
              pw.Text('Sin tareas completadas.', style: const pw.TextStyle(fontSize: 9, color: _C.textMid))
            else
              _tablaCompletadas(tareasOrdenadas),

            pw.SizedBox(height: 16),

            // ── Tareas extras ──────────────────────────────────────────────
            _sectionTitle('TAREAS EXTRAS'),
            pw.SizedBox(height: 6),
            if (extrasOp.isEmpty)
              pw.Text('Sin tareas extras.', style: const pw.TextStyle(fontSize: 9, color: _C.textMid))
            else
              _tablaExtras(extrasOp),

            pw.SizedBox(height: 16),

            // ── Referencias del operador ───────────────────────────────────
            _sectionTitle('REFERENCIAS MOLDEADAS'),
            pw.SizedBox(height: 6),
            if (listaRefsOp.isEmpty)
              pw.Text('Sin datos.', style: const pw.TextStyle(fontSize: 9, color: _C.textMid))
            else
              pw.Table(
                border       : pw.TableBorder.all(color: _C.midGrey, width: 0.5),
                columnWidths : const {0: pw.FixedColumnWidth(200), 1: pw.FixedColumnWidth(100)},
                children: [
                  _headerRow(['Referencia', 'Total Moldeado']),
                  ...listaRefsOp.asMap().entries.map((e) => _dataRow([e.value.key, '${e.value.value}'], e.key)),
                  _totalRow(['SUBTOTAL', '${listaRefsOp.fold<int>(0, (s, e) => s + e.value)}']),
                ],
              ),
            pw.SizedBox(height: 20),
          ],
        ),
      );
    }

    // =========================================================================
    // ÚLTIMA PÁGINA — Totales globales de referencias
    // =========================================================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat : PdfPageFormat.a4,
        margin     : const pw.EdgeInsets.symmetric(horizontal: _hPad, vertical: _vPad),
        header     : headerBuilder,
        footer     : footerBuilder,
        build      : (ctx) => [
          pw.SizedBox(height: 18),
          _sectionTitle('TOTALES GLOBALES DE PRODUCCIÓN POR REFERENCIA'),
          pw.SizedBox(height: 12),
          if (listaRefs.isEmpty)
            pw.Text('Sin datos de referencias.', style: const pw.TextStyle(fontSize: 9, color: _C.textMid))
          else
            pw.Table(
              border       : pw.TableBorder.all(color: _C.midGrey, width: 0.5),
              columnWidths : const {0: pw.FixedColumnWidth(220), 1: pw.FixedColumnWidth(110)},
              children: [
                _headerRow(['Referencia', 'Total Moldeado']),
                ...listaRefs.asMap().entries.map((e) => _dataRow([e.value.key, '${e.value.value}'], e.key)),
                _totalRow(['TOTAL GENERAL', '${listaRefs.fold<int>(0, (s, e) => s + e.value)}']),
              ],
            ),
          pw.SizedBox(height: 20),
        ],
      ),
    );

    return pdf.save();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  WIDGETS REUTILIZABLES
  // ══════════════════════════════════════════════════════════════════════════

  // ── Header ────────────────────────────────────────────────────────────────
  // NOTA: MultiPage llama header() ANTES de aplicar el margin, por lo que el
  // header ya viene con padding propio y no necesita insets externos.
  static pw.Widget _header(String rangoTexto, int totalOperadores, pw.MemoryImage logoProvider) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(height: 4, color: _C.gold),
        pw.Container(
          color  : _C.navy,
          padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child  : pw.Row(
            children: [
              pw.Container(
                width: 60, height: 50,
                alignment: pw.Alignment.center,
                child: pw.Image(logoProvider, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 14),
              pw.Container(width: 1, height: 50, color: _C.gold),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisSize      : pw.MainAxisSize.min,
                  children: [
                    pw.Text(
                      'REPORTE GENERAL DE FUNDICIÓN',
                      style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _C.white),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Row(
                      children: [
                        _headerChip('PERÍODO'),
                        pw.SizedBox(width: 6),
                        pw.Text(rangoTexto, style: const pw.TextStyle(color: _C.textLight, fontSize: 9)),
                        pw.SizedBox(width: 14),
                        _headerChip('OPERADORES'),
                        pw.SizedBox(width: 6),
                        pw.Text('$totalOperadores activos',
                            style: pw.TextStyle(color: _C.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                mainAxisSize      : pw.MainAxisSize.min,
                children: [
                  pw.Container(
                    padding   : const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const pw.BoxDecoration(color: _C.gold),
                    child     : pw.Text(
                      'FUNDIMETALES DEL NORTE',
                      style: pw.TextStyle(color: _C.navyDark, fontSize: 8, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text('RUC. 0401563812001',       style: const pw.TextStyle(fontSize: 7, color: _C.textLight)),
                  pw.SizedBox(height: 2),
                  pw.Text('Tulcán - Ecuador',          style: const pw.TextStyle(fontSize: 7, color: _C.textLight)),
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
        // Espacio entre header y contenido
        pw.SizedBox(height: 4),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────
  static pw.Widget _footer(pw.Context ctx) {
    return pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.SizedBox(height: 4),
        pw.Row(
          children: [
            pw.Expanded(child: pw.Container(height: 2, color: _C.gold)),
            pw.Expanded(child: pw.Container(height: 2, color: _C.navyMid)),
          ],
        ),
        pw.Container(
          color  : _C.navy,
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 24),
          child  : pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisSize      : pw.MainAxisSize.min,
                children: [
                  pw.Text(
                    'SOFTWARE ELABORADO POR FUNDIMETALES DEL NORTE',
                    style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: _C.gold),
                  ),
                  pw.Text('sistemas@fundimetalesdelnorte.com',
                      style: const pw.TextStyle(fontSize: 6, color: _C.textLight)),
                ],
              ),
              pw.Text(
                'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                style: const pw.TextStyle(color: _C.textLight, fontSize: 7),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── KPI row ───────────────────────────────────────────────────────────────
  static pw.Widget _kpiRow(List<_KpiData> kpis) {
    return pw.Row(
      children: kpis.asMap().entries.map((e) {
        final isLast = e.key == kpis.length - 1;
        return pw.Expanded(
          child: pw.Padding(
            padding: pw.EdgeInsets.only(right: isLast ? 0 : 10),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color : e.value.bgLight,
                border: pw.Border.all(color: e.value.accent, width: 0.8),
              ),
              child: pw.Row(
                children: [
                  pw.Container(width: 5, height: 60, color: e.value.accent),
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisSize      : pw.MainAxisSize.min,
                      children: [
                        pw.Text(e.value.value,
                            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: e.value.accent)),
                        pw.SizedBox(height: 3),
                        pw.Text(e.value.label, style: const pw.TextStyle(fontSize: 8, color: _C.textMid)),
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

  // ── Section title ─────────────────────────────────────────────────────────
  static pw.Widget _sectionTitle(String title) {
    return pw.Container(
      color  : _C.navyDark,
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      child  : pw.Row(
        children: [
          pw.Container(width: 4, height: 18, color: _C.gold),
          pw.SizedBox(width: 10),
          pw.Text(title,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _C.white, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  // ── Tabla resumen operadores (página 1) ───────────────────────────────────
  static pw.Widget _resumenTabla(List<_ResumenOp> ops, int totalTareas, int totalFundido) {
    return pw.Table(
      border       : pw.TableBorder.all(color: _C.midGrey, width: 0.5),
      columnWidths : const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2), 2: pw.FlexColumnWidth(2)},
      children: [
        _headerRow(['Operador', 'Tareas', 'Total Moldeado']),
        ...ops.asMap().entries.map((e) => _dataRow([e.value.nombre, '${e.value.tareas}', '${e.value.cantidad}'], e.key)),
        _totalRow(['TOTAL GENERAL', '$totalTareas', '$totalFundido']),
      ],
    );
  }

  // ── Tabla tareas completadas ──────────────────────────────────────────────
  // SIN límite de 25 filas: MultiPage se encarga de paginar automáticamente
  static pw.Widget _tablaCompletadas(List<Map<String, dynamic>> tareas) {
    final total = tareas.fold<int>(0, (s, t) => s + ((t['cantidad'] as num?)?.toInt() ?? 0));

    return pw.Table(
      border       : pw.TableBorder.all(color: _C.midGrey, width: 0.4),
      columnWidths : const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        _headerRow(['Referencia', 'Descripción', 'Cant.', 'Fecha Completada']),
        ...tareas.asMap().entries.map((e) {
          final t     = e.value;
          final fecha = _tsToDate(t['fecha_completada']);
          return _dataRow([
            t['referencia']?.toString() ?? '-',
            t['descripcion']?.toString() ?? '-',
            '${(t['cantidad'] as num?)?.toInt() ?? 0}',
            fecha != null ? _fmt(fecha) : '-',
          ], e.key);
        }),
        _totalRow(['Subtotal', '', '$total', '']),
      ],
    );
  }

  // ── Tabla tareas extras ───────────────────────────────────────────────────
  static pw.Widget _tablaExtras(List<Map<String, dynamic>> lista) {
    return pw.Table(
      border       : pw.TableBorder.all(color: _C.midGrey, width: 0.4),
      columnWidths : const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1.8),
      },
      children: [
        _headerRow(['Tipo', 'Descripción', 'Estado', 'Fecha']),
        ...lista.asMap().entries.map((e) {
          final i     = e.key;
          final t     = e.value;
          final fecha = _tsToDate(t['fecha_asignacion']);
          final estado = t['estado']?.toString() ?? '-';

          PdfColor estadoColor;
          switch (estado.toLowerCase()) {
            case 'terminado':
            case 'terminada':
            case 'completada':
              estadoColor = _C.green;
              break;
            case 'pendiente':
              estadoColor = _C.orange;
              break;
            default:
              estadoColor = _C.greyText;
          }

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: i % 2 == 0 ? _C.white : _C.lightGrey),
            children: [
              _cell(t['tipo_tarea']?.toString()  ?? '-', bold: true, color: _C.navy),
              _cell(t['descripcion']?.toString() ?? '-'),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: pw.Container(
                  padding   : const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: pw.BoxDecoration(
                    color       : estadoColor,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                  ),
                  child: pw.Text(estado,
                      style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _C.white)),
                ),
              ),
              _cell(fecha != null ? _fmt(fecha) : '-', color: _C.textMid),
            ],
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  TABLE BUILDERS
  // ══════════════════════════════════════════════════════════════════════════

  static pw.TableRow _headerRow(List<String> labels) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: _C.navyDark),
    children: labels.map((l) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child  : pw.Text(l, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _C.gold)),
    )).toList(),
  );

  static pw.TableRow _dataRow(List<String> values, int index) => pw.TableRow(
    decoration: pw.BoxDecoration(color: index % 2 == 0 ? _C.white : _C.lightGrey),
    children: values.asMap().entries.map((e) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child  : pw.Text(
        e.value,
        style: pw.TextStyle(
          fontSize  : 8,
          color     : e.key == 0 ? _C.navy : e.key == 2 ? _C.gold : _C.textDark,
          fontWeight: (e.key == 0 || e.key == 2) ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        overflow: pw.TextOverflow.clip,
      ),
    )).toList(),
  );

  static pw.TableRow _totalRow(List<String> values) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: _C.navyDark),
    children: values.map((v) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child  : pw.Text(v, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _C.gold)),
    )).toList(),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  MICRO WIDGETS
  // ══════════════════════════════════════════════════════════════════════════

  static pw.Widget _cell(String text, {bool bold = false, PdfColor color = _C.textDark}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child  : pw.Text(
          text,
          style   : pw.TextStyle(fontSize: 8, color: color, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal),
          overflow: pw.TextOverflow.clip,
        ),
      );

  static pw.Widget _chip(String label, PdfColor color) => pw.Container(
    padding   : const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: pw.BoxDecoration(color: color),
    child     : pw.Text(label, style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: _C.white)),
  );

  static pw.Widget _headerChip(String label) => pw.Container(
    padding   : const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: const pw.BoxDecoration(color: _C.gold),
    child     : pw.Text(label, style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: _C.navyDark)),
  );

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static DateTime? _tsToDate(dynamic v) {
    if (v == null) return null;
    try { return (v as Timestamp).toDate(); }
    catch (_) { return null; }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  DATA CLASSES
// ══════════════════════════════════════════════════════════════════════════════

class _KpiData {
  final String label, value;
  final PdfColor accent, bgLight;
  const _KpiData(this.label, this.value, this.accent, this.bgLight);
}

class _ResumenOp {
  final String id, nombre;
  final int tareas, cantidad;
  const _ResumenOp({required this.id, required this.nombre, required this.tareas, required this.cantidad});
}