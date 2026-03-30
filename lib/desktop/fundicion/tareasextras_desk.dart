import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TareasExtrasScreen extends StatefulWidget {
  const TareasExtrasScreen({super.key});

  @override
  State<TareasExtrasScreen> createState() => _TareasExtrasScreenState();
}

class _TareasExtrasScreenState extends State<TareasExtrasScreen> {
  List<Map<String, dynamic>> _retirosMercaderia = [];
  bool _cargando = false;

  DateTime? _fechaDesdeRetiros;
  DateTime? _fechaHastaRetiros;
  String? _personaFiltroRetiros;

  List<Map<String, dynamic>> get _retirosFiltrados {
    return _retirosMercaderia.where((r) {
      if (_personaFiltroRetiros != null && _personaFiltroRetiros!.isNotEmpty) {
        final nombre = r['persona_retiro']?.toString().toLowerCase() ?? '';
        if (!nombre.contains(_personaFiltroRetiros!.toLowerCase()))
          return false;
      }
      if (_fechaDesdeRetiros != null || _fechaHastaRetiros != null) {
        final fecha = r['fecha'];
        if (fecha is Timestamp) {
          final dt = fecha.toDate();
          if (_fechaDesdeRetiros != null && dt.isBefore(_fechaDesdeRetiros!))
            return false;
          if (_fechaHastaRetiros != null &&
              dt.isAfter(_fechaHastaRetiros!.add(const Duration(days: 1))))
            return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    setState(() => _cargando = true);
    try {
      final retirosSnap =
          await FirebaseFirestore.instance
              .collection('retiros_mercaderia')
              .orderBy('fecha_retiro', descending: true)
              .get();

      final List<Map<String, dynamic>> retiros = [];
      for (final doc in retirosSnap.docs) {
        final data = doc.data();
        List<Map<String, dynamic>> referencias = [];
        if (data['referencias'] != null && data['referencias'] is List) {
          referencias = List<Map<String, dynamic>>.from(
            (data['referencias'] as List).map(
              (r) => Map<String, dynamic>.from(r as Map),
            ),
          );
        } else {
          referencias = [
            {'cantidad': data['cantidad'] ?? 0},
          ];
        }
        retiros.add({
          'id': doc.id,
          'persona_retiro': data['persona_retiro'] ?? 'Sin especificar',
          'persona_id': data['persona_id'] ?? '',
          'sucursal_origen': data['sucursal_origen'] ?? 'Fundición',
          'sucursal_destino':
              data['sucursal_destino'] ?? 'Producto Bruto Oficina',
          'referencias': referencias,
          'fecha': data['fecha_retiro'],
        });
      }

      setState(() {
        _retirosMercaderia = retiros;
        _cargando = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => _cargando = false);
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar datos: $e')));
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      if (fecha is Timestamp)
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
      if (fecha is String) return fecha;
      return fecha.toString();
    } catch (_) {
      return '—';
    }
  }

  Future<List<Map<String, dynamic>>> _cargarUsuarios() async {
    final snap = await FirebaseFirestore.instance.collection('usuarios').get();
    final lista =
        snap.docs.map((doc) {
          final d = doc.data();
          return {
            'id': doc.id,
            'nombre': d['nombre']?.toString() ?? 'Sin nombre',
          };
        }).toList();
    lista.sort(
      (a, b) => (a['nombre'] as String).compareTo(b['nombre'] as String),
    );
    return lista;
  }

  Future<void> _generarPDFRetiros() async {
    final pdf = pw.Document();
    final datos = _retirosFiltrados;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build:
            (context) => [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Retiros de Mercadería',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              if (_fechaDesdeRetiros != null || _fechaHastaRetiros != null)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    'Período: ${_fechaDesdeRetiros != null ? DateFormat('dd/MM/yyyy').format(_fechaDesdeRetiros!) : '—'} hasta ${_fechaHastaRetiros != null ? DateFormat('dd/MM/yyyy').format(_fechaHastaRetiros!) : '—'}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              if (_personaFiltroRetiros != null &&
                  _personaFiltroRetiros!.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    'Persona Retira: $_personaFiltroRetiros',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(1.5),
                  2: pw.FlexColumnWidth(1.5),
                  3: pw.FlexColumnWidth(4),
                  4: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF4682B4),
                    ),
                    children:
                        [
                              'Persona Retira',
                              'Origen',
                              'Destino',
                              'Referencias',
                              'Fecha',
                            ]
                            .map(
                              (h) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  h,
                                  style: pw.TextStyle(
                                    color: PdfColors.white,
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  ...datos.asMap().entries.map((entry) {
                    final i = entry.key;
                    final r = entry.value;
                    final refs =
                        r['referencias'] as List<Map<String, dynamic>>? ?? [];
                    final refsText = refs
                        .map(
                          (ref) =>
                              '${ref['referencia'] ?? ''} x ${ref['cantidad'] ?? 0}',
                        )
                        .join('\n');
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: i % 2 == 0 ? PdfColors.grey100 : PdfColors.white,
                      ),
                      children:
                          [
                                r['persona_retiro']?.toString() ?? '—',
                                r['sucursal_origen']?.toString() ?? '—',
                                r['sucursal_destino']?.toString() ?? '—',
                                refsText.isEmpty ? '—' : refsText,
                                _formatearFecha(r['fecha']),
                              ]
                              .map(
                                (text) => pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: pw.Text(
                                    text,
                                    style: const pw.TextStyle(fontSize: 9),
                                  ),
                                ),
                              )
                              .toList(),
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Text(
                'Resumen por Referencia:',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Row(
                children: [
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    columnWidths: const {
                      0: pw.FixedColumnWidth(180),
                      1: pw.FixedColumnWidth(80),
                    },
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF2C3E50),
                        ),
                        children:
                            ['Referencia', 'Total Retirado']
                                .map(
                                  (h) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(7),
                                    child: pw.Text(
                                      h,
                                      style: pw.TextStyle(
                                        color: PdfColors.white,
                                        fontWeight: pw.FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                      ...() {
                        final Map<String, int> totalesPorRef = {};
                        for (final r in datos) {
                          final refs =
                              r['referencias'] as List<Map<String, dynamic>>? ??
                              [];
                          for (final ref in refs) {
                            final nombre = ref['referencia']?.toString() ?? '—';
                            final cant =
                                (ref['cantidad'] as num?)?.toInt() ?? 0;
                            totalesPorRef[nombre] =
                                (totalesPorRef[nombre] ?? 0) + cant;
                          }
                        }
                        final lista =
                            totalesPorRef.entries.toList()
                              ..sort((a, b) => a.key.compareTo(b.key));
                        return lista.asMap().entries.map((entry) {
                          final i = entry.key;
                          final e = entry.value;
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color:
                                  i % 2 == 0
                                      ? PdfColors.grey100
                                      : PdfColors.white,
                            ),
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(7),
                                child: pw.Text(
                                  e.key,
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(7),
                                child: pw.Text(
                                  '${e.value}',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      }(),
                    ],
                  ),
                  pw.Expanded(child: pw.SizedBox()),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Total de registros: ${datos.length}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _mostrarDialogoNuevoRetiro() async {
    final usuarios = await _cargarUsuarios();
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => _DialogoNuevoRetiro(
            todosLosUsuarios: usuarios,
            onGuardar: (personaNombre, personaId, referencias) async {
              await FirebaseFirestore.instance
                  .collection('retiros_mercaderia')
                  .add({
                    'persona_retiro': personaNombre,
                    'persona_id': personaId,
                    'sucursal_origen': 'Fundición',
                    'sucursal_destino': 'Producto Bruto Oficina',
                    'referencias': referencias,
                    'fecha_retiro': Timestamp.now(),
                  });
              _obtenerDatos();
            },
          ),
    );
  }

  Widget _buildTablaRetiros() {
    if (_cargando)
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    final datos = _retirosFiltrados;

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Filtrar por persona...',
                      prefixIcon: const Icon(Icons.person_search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged:
                        (v) => setState(
                          () => _personaFiltroRetiros = v.isEmpty ? null : v,
                        ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        initialDate: _fechaDesdeRetiros ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setState(() => _fechaDesdeRetiros = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _fechaDesdeRetiros != null
                                  ? const Color(0xFF4682B4)
                                  : Colors.grey.shade400,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color:
                                _fechaDesdeRetiros != null
                                    ? const Color(0xFF4682B4)
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _fechaDesdeRetiros != null
                                  ? DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_fechaDesdeRetiros!)
                                  : 'Desde',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    _fechaDesdeRetiros != null
                                        ? const Color(0xFF2C3E50)
                                        : Colors.grey,
                              ),
                            ),
                          ),
                          if (_fechaDesdeRetiros != null)
                            GestureDetector(
                              onTap:
                                  () =>
                                      setState(() => _fechaDesdeRetiros = null),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final p = await showDatePicker(
                        context: context,
                        useRootNavigator: true,
                        initialDate: _fechaHastaRetiros ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (p != null) setState(() => _fechaHastaRetiros = p);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _fechaHastaRetiros != null
                                  ? const Color(0xFF4682B4)
                                  : Colors.grey.shade400,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color:
                                _fechaHastaRetiros != null
                                    ? const Color(0xFF4682B4)
                                    : Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _fechaHastaRetiros != null
                                  ? DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(_fechaHastaRetiros!)
                                  : 'Hasta',
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    _fechaHastaRetiros != null
                                        ? const Color(0xFF2C3E50)
                                        : Colors.grey,
                              ),
                            ),
                          ),
                          if (_fechaHastaRetiros != null)
                            GestureDetector(
                              onTap:
                                  () =>
                                      setState(() => _fechaHastaRetiros = null),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: datos.isEmpty ? null : _generarPDFRetiros,
                  icon: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text(
                    'PDF',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_retirosMercaderia.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${datos.length} registro${datos.length != 1 ? 's' : ''}${datos.length != _retirosMercaderia.length ? ' (filtrado de ${_retirosMercaderia.length})' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 6),
          if (datos.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _retirosMercaderia.isEmpty
                          ? 'No hay retiros de mercadería registrados.'
                          : 'No hay resultados para los filtros aplicados.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.15),
                        spreadRadius: 2,
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      bottom: BorderSide(color: Colors.grey.shade200, width: 1),
                      top: BorderSide(color: Colors.grey.shade200, width: 1),
                    ),
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    columnWidths: const {
                      0: FlexColumnWidth(2.2),
                      1: FlexColumnWidth(1.4),
                      2: FlexColumnWidth(1.6),
                      3: FlexColumnWidth(4.5),
                      4: FlexColumnWidth(2.0),
                    },
                    children: [
                      const TableRow(
                        decoration: BoxDecoration(color: Color(0xFF4682B4)),
                        children: [
                          _TablaHeader('Persona Retira'),
                          _TablaHeader('Origen'),
                          _TablaHeader('Destino'),
                          _TablaHeader('Referencias'),
                          _TablaHeader('Fecha'),
                        ],
                      ),
                      ...datos.asMap().entries.map((entry) {
                        final index = entry.key;
                        final retiro = entry.value;
                        final referencias =
                            retiro['referencias']
                                as List<Map<String, dynamic>>? ??
                            [];
                        return TableRow(
                          decoration: BoxDecoration(
                            color:
                                index % 2 == 0
                                    ? Colors.grey.shade50
                                    : Colors.white,
                          ),
                          children: [
                            // ✅ BIEN - sin isNumero, usa el valor por defecto false
                            _TablaCell(
                              retiro['persona_retiro']?.toString() ?? '—',
                            ),
                            _TablaCell(
                              retiro['sucursal_origen']?.toString() ?? '—',
                            ),
                            _TablaCell(
                              retiro['sucursal_destino']?.toString() ?? '—',
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children:
                                    referencias.isEmpty
                                        ? [
                                          const Text(
                                            '—',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                        ]
                                        : referencias.map((ref) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: Colors.blue.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  ref['referencia']
                                                          ?.toString() ??
                                                      '—',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                ),
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                    left: 6,
                                                  ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF4682B4,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'x${ref['cantidad'] ?? 0}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                              ),
                            ),
                            _TablaCell(_formatearFecha(retiro['fecha'])),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Retiros de Mercadería',
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
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _mostrarDialogoNuevoRetiro,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'Registrar Retiro',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTablaRetiros(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIÁLOGO NUEVO RETIRO
// ═══════════════════════════════════════════════════════════════════════════
class _DialogoNuevoRetiro extends StatefulWidget {
  final List<Map<String, dynamic>> todosLosUsuarios;
  final Future<void> Function(
    String personaNombre,
    String personaId,
    List<Map<String, dynamic>> referencias,
  )
  onGuardar;

  const _DialogoNuevoRetiro({
    required this.todosLosUsuarios,
    required this.onGuardar,
  });

  @override
  State<_DialogoNuevoRetiro> createState() => _DialogoNuevoRetiroState();
}

class _DialogoNuevoRetiroState extends State<_DialogoNuevoRetiro> {
  String? _personaId;
  String? _personaNombre;
  late List<Map<String, dynamic>> _filtrados;
  final _busquedaCtrl = TextEditingController();
  bool _guardando = false;

  final List<Map<String, dynamic>> _referenciasSeleccionadas = [];

  List<Map<String, dynamic>> _resultadosBusqueda = [];
  final _busquedaProductoCtrl = TextEditingController();
  bool _buscandoProducto = false;
  Timer? _debounceProducto;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _filtrados = List.from(widget.todosLosUsuarios);
  }

  @override
  void dispose() {
    _debounceProducto?.cancel();
    _scrollCtrl.dispose();
    _busquedaCtrl.dispose();
    _busquedaProductoCtrl.dispose();
    for (final r in _referenciasSeleccionadas) {
      (r['cantidadCtrl'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  void _buscarProductoConDebounce(String query) {
    if (_debounceProducto?.isActive ?? false) _debounceProducto!.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _resultadosBusqueda = [];
        _buscandoProducto = false;
      });
      return;
    }
    setState(() => _buscandoProducto = true);
    _debounceProducto = Timer(
      const Duration(milliseconds: 500),
      () => _buscarProducto(query.trim().toUpperCase()),
    );
  }

  Future<void> _buscarProducto(String query) async {
    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('productos')
              .where('referencia', isGreaterThanOrEqualTo: query)
              .where('referencia', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(8)
              .get();
      setState(() {
        _resultadosBusqueda =
            snap.docs.map((doc) {
              final d = doc.data();
              return {
                'id': doc.id,
                'referencia': d['referencia']?.toString() ?? '',
                'nombre': d['nombre']?.toString() ?? '',
              };
            }).toList();
        _buscandoProducto = false;
      });
    } catch (e) {
      setState(() => _buscandoProducto = false);
    }
  }

  void _filtrarPersonas(String q) {
    setState(() {
      _filtrados =
          widget.todosLosUsuarios
              .where(
                (u) => u['nombre'].toString().toLowerCase().contains(
                  q.toLowerCase(),
                ),
              )
              .toList();
    });
  }

  bool _yaSeleccionado(String productoId) =>
      _referenciasSeleccionadas.any((r) => r['id'] == productoId);

  void _agregarProducto(Map<String, dynamic> producto) {
    if (_yaSeleccionado(producto['id'])) return;
    setState(() {
      _referenciasSeleccionadas.add({
        'id': producto['id'],
        'referencia': producto['referencia'],
        'nombre': producto['nombre'],
        'cantidadCtrl': TextEditingController(),
      });
      _busquedaProductoCtrl.clear();
      _resultadosBusqueda = [];
    });
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _eliminarReferencia(int i) {
    setState(() {
      (_referenciasSeleccionadas[i]['cantidadCtrl'] as TextEditingController)
          .dispose();
      _referenciasSeleccionadas.removeAt(i);
    });
  }

  Future<void> _actualizarInventarioBruto(
    List<Map<String, dynamic>> referencias,
  ) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final ref in referencias) {
      final docRef = FirebaseFirestore.instance
          .collection('inventarios')
          .doc('Tulcán')
          .collection('procesos')
          .doc('bruto')
          .collection('productos')
          .doc(ref['referencia'] as String);

      batch.set(docRef, {
        'cantidad': FieldValue.increment(ref['cantidad'] as int),
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar Retiro de Mercadería'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. PERSONA QUE RETIRA ────────────────────────────────────
              const Text(
                'Persona que retira',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              if (_personaNombre != null)
                _ChipSeleccionado(
                  nombre: _personaNombre!,
                  onQuitar:
                      () => setState(() {
                        _personaId = null;
                        _personaNombre = null;
                        _busquedaCtrl.clear();
                        _filtrados = List.from(widget.todosLosUsuarios);
                      }),
                )
              else ...[
                TextField(
                  controller: _busquedaCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar persona...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: _filtrarPersonas,
                ),
                const SizedBox(height: 6),
                _ListaUsuarios(
                  usuarios: _filtrados,
                  onSeleccionar:
                      (u) => setState(() {
                        _personaId = u['id'];
                        _personaNombre = u['nombre'];
                      }),
                ),
              ],

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),

              // ── 2. ENCABEZADO REFERENCIAS ────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Referencias',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  if (_referenciasSeleccionadas.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_referenciasSeleccionadas.length} agregada${_referenciasSeleccionadas.length > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // ── 3. BUSCADOR DE PRODUCTO ──────────────────────────────────
              TextField(
                controller: _busquedaProductoCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Buscar por referencia...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  suffixIcon:
                      _buscandoProducto
                          ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : _busquedaProductoCtrl.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () {
                              _busquedaProductoCtrl.clear();
                              setState(() => _resultadosBusqueda = []);
                            },
                          )
                          : null,
                ),
                onChanged: (value) {
                  final upper = value.toUpperCase();
                  if (_busquedaProductoCtrl.text != upper) {
                    _busquedaProductoCtrl
                        .value = _busquedaProductoCtrl.value.copyWith(
                      text: upper,
                      selection: TextSelection.collapsed(offset: upper.length),
                    );
                  }
                  _buscarProductoConDebounce(upper);
                },
              ),
              const SizedBox(height: 6),

              // ── 4. LISTA DE RESULTADOS ───────────────────────────────────
              if (_resultadosBusqueda.isNotEmpty)
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _resultadosBusqueda.length,
                    itemBuilder: (context, index) {
                      final p = _resultadosBusqueda[index];
                      final yaEsta = _yaSeleccionado(p['id']);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        color:
                            yaEsta ? Colors.green.shade50 : Colors.transparent,
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  yaEsta
                                      ? Colors.green.shade100
                                      : const Color(
                                        0xFF4682B4,
                                      ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color:
                                    yaEsta
                                        ? Colors.green.shade400
                                        : const Color(
                                          0xFF4682B4,
                                        ).withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              p['referencia'],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color:
                                    yaEsta
                                        ? Colors.green.shade700
                                        : const Color(0xFF4682B4),
                              ),
                            ),
                          ),
                          title:
                              yaEsta
                                  ? Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green.shade500,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Ya agregada — ingresa la cantidad abajo',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.green.shade600,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  )
                                  : const SizedBox.shrink(),
                          trailing:
                              yaEsta
                                  ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade500,
                                    size: 20,
                                  )
                                  : Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.blue.shade400,
                                    size: 20,
                                  ),
                          onTap: yaEsta ? null : () => _agregarProducto(p),
                        ),
                      );
                    },
                  ),
                ),

              // ── 5. CAMPOS DE CANTIDAD ────────────────────────────────────
              if (_referenciasSeleccionadas.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_referenciasSeleccionadas.length} referencia${_referenciasSeleccionadas.length > 1 ? 's' : ''} agregada${_referenciasSeleccionadas.length > 1 ? 's' : ''} — ingresa las cantidades:',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                ..._referenciasSeleccionadas.asMap().entries.map((entry) {
                  final i = entry.key;
                  final ref = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4682B4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ref['referencia'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller:
                                ref['cantidadCtrl'] as TextEditingController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Ej: 10',
                              labelText: 'Cantidad *',
                              labelStyle: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4682B4),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () => _eliminarReferencia(i),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed:
              _guardando
                  ? null
                  : () async {
                    if (_personaNombre == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Debe seleccionar la persona que retira',
                          ),
                        ),
                      );
                      return;
                    }
                    if (_referenciasSeleccionadas.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debe agregar al menos una referencia'),
                        ),
                      );
                      return;
                    }
                    for (final ref in _referenciasSeleccionadas) {
                      final cant = int.tryParse(
                        (ref['cantidadCtrl'] as TextEditingController).text,
                      );
                      if (cant == null || cant <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'La referencia ${ref['referencia']} necesita una cantidad válida',
                            ),
                          ),
                        );
                        return;
                      }
                    }
                    setState(() => _guardando = true);
                    try {
                      final refsData =
                          _referenciasSeleccionadas
                              .map(
                                (ref) => {
                                  'referencia': ref['referencia'],
                                  'cantidad': int.parse(
                                    (ref['cantidadCtrl']
                                            as TextEditingController)
                                        .text,
                                  ),
                                },
                              )
                              .toList();
                      await widget.onGuardar(
                        _personaNombre!,
                        _personaId ?? '',
                        refsData,
                      );
                      await _actualizarInventarioBruto(refsData);
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Retiro registrado e inventario actualizado ✓',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                        setState(() => _guardando = false);
                      }
                    }
                  },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4682B4),
          ),
          child:
              _guardando
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : const Text(
                    'Registrar',
                    style: TextStyle(color: Colors.white),
                  ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// WIDGETS REUTILIZABLES
// ═══════════════════════════════════════════════════════════════════════════

class _ChipSeleccionado extends StatelessWidget {
  final String nombre;
  final VoidCallback onQuitar;
  const _ChipSeleccionado({required this.nombre, required this.onQuitar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF4682B4).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4682B4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Color(0xFF4682B4), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nombre,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: onQuitar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ListaUsuarios extends StatelessWidget {
  final List<Map<String, dynamic>> usuarios;
  final void Function(Map<String, dynamic>) onSeleccionar;
  const _ListaUsuarios({required this.usuarios, required this.onSeleccionar});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.builder(
        itemCount: usuarios.length,
        itemBuilder: (context, index) {
          final u = usuarios[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.person_outline, size: 18),
            title: Text(u['nombre'], style: const TextStyle(fontSize: 13)),
            onTap: () => onSeleccionar(u),
          );
        },
      ),
    );
  }
}

// ─── WIDGETS DE TABLA ────────────────────────────────────────────────────────

class _TablaHeader extends StatelessWidget {
  final String text;
  const _TablaHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TablaCell extends StatelessWidget {
  final String text;
  final bool isNumero;
  // ignore: unused_element_parameter
  const _TablaCell(this.text, {this.isNumero = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isNumero ? FontWeight.bold : FontWeight.normal,
          color: isNumero ? Colors.blue.shade700 : const Color(0xFF2C3E50),
        ),
        textAlign: isNumero ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}
