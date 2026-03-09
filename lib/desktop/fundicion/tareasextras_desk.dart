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

class _TareasExtrasScreenState extends State<TareasExtrasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _tareasExtras = [];
  List<Map<String, dynamic>> _retirosMercaderia = [];
  Map<String, String> _nombresOperadores = {};
  bool _cargando = false;

  final List<String> _tiposTareas = [
    'Descargar camioneta',
    'Cargar camioneta',
    'Bajar viruta',
    'Limpiar hornos',
    'Mantenimiento de equipos',
    'Limpieza general',
    'Organizar material',
    'Otro',
  ];

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
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _obtenerDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _obtenerNombreOperador(String operadorId) async {
    if (_nombresOperadores.containsKey(operadorId))
      return _nombresOperadores[operadorId]!;
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(operadorId)
              .get();
      if (doc.exists) {
        final nombre = doc.data()?['nombre'] ?? 'Sin nombre';
        _nombresOperadores[operadorId] = nombre;
        return nombre;
      }
    } catch (e) {
      debugPrint('Error operador $operadorId: $e');
    }
    return 'Operador desconocido';
  }

  Future<void> _obtenerDatos() async {
    setState(() => _cargando = true);
    try {
      final tareasSnap =
          await FirebaseFirestore.instance
              .collection('tareas_extras')
              .orderBy('fecha_asignacion', descending: true)
              .get();

      final List<Map<String, dynamic>> tareas = [];
      for (final doc in tareasSnap.docs) {
        final data = doc.data();
        String opNombre = 'Sin operador';
        if (data['operador_id'] != null &&
            data['operador_id'].toString().isNotEmpty) {
          opNombre = await _obtenerNombreOperador(
            data['operador_id'].toString(),
          );
        }
        tareas.add({
          'id': doc.id,
          'operador': opNombre,
          'tipo_tarea': data['tipo_tarea'] ?? 'Sin especificar',
          'descripcion': data['descripcion'] ?? '',
          'fecha': data['fecha_asignacion'],
          'estado': data['estado']?.toString() ?? 'pendiente',
        });
      }

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
        _tareasExtras = tareas;
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
                        ['Persona Retira', 'Origen', 'Destino', 'Referencias', 'Fecha']
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
                              // ✅ CORRECTO
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

  void _mostrarDialogoNuevaTarea() async {
    final usuarios = await _cargarUsuarios();
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (context) => _DialogoNuevaTarea(
            tiposTareas: _tiposTareas,
            todosLosUsuarios: usuarios,
            onGuardar: (tipoTarea, operadorId, descripcion) async {
              await FirebaseFirestore.instance.collection('tareas_extras').add({
                'tipo_tarea': tipoTarea,
                'operador_id': operadorId,
                'descripcion': descripcion,
                'fecha_asignacion': Timestamp.now(),
                'estado': 'pendiente',
              });
              _obtenerDatos();
            },
          ),
    );
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

  Widget _buildTablaTareasExtras() {
    if (_cargando)
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    if (_tareasExtras.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No hay tareas extras registradas.',
            style: TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
          ),
        ),
      );
    }
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(3.0),
              3: FlexColumnWidth(2.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFF4682B4)),
                children: [
                  _TablaHeader('Operador'),
                  _TablaHeader('Tipo de Tarea'),
                  _TablaHeader('Descripción'),
                  _TablaHeader('Fecha'),
                  _TablaHeader('Estado'),
                ],
              ),
              ..._tareasExtras.asMap().entries.map((entry) {
                final index = entry.key;
                final tarea = entry.value;
                return TableRow(
                  decoration: BoxDecoration(
                    color: index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                  ),
                  children: [
                    _TablaCell(tarea['operador']?.toString() ?? '—'),
                    _TablaCell(tarea['tipo_tarea']?.toString() ?? '—'),
                    _TablaCell(
                      (tarea['descripcion']?.toString().isEmpty ?? true)
                          ? '—'
                          : tarea['descripcion'].toString(),
                    ),
                    _TablaCell(_formatearFecha(tarea['fecha'])),
                    _TablaCellEstado(
                      tarea['estado']?.toString() ?? 'pendiente',
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
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
                        initialDate: _fechaHastaRetiros ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        locale: const Locale('es', 'ES'),
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
                                                  // ✅ CORRECTO
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
                      'Tareas Extras y Retiros',
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
          Container(
            color: const Color(0xFF2C3E50),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Tareas Extras'),
                Tab(text: 'Retiros de Mercadería'),
              ],
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
                        onPressed:
                            _tabController.index == 0
                                ? _mostrarDialogoNuevaTarea
                                : _mostrarDialogoNuevoRetiro,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          _tabController.index == 0
                              ? 'Nueva Tarea'
                              : 'Registrar Retiro',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _tabController.index == 0
                      ? _buildTablaTareasExtras()
                      : _buildTablaRetiros(),
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
// DIÁLOGO NUEVA TAREA
// ═══════════════════════════════════════════════════════════════════════════
class _DialogoNuevaTarea extends StatefulWidget {
  final List<String> tiposTareas;
  final List<Map<String, dynamic>> todosLosUsuarios;
  final Future<void> Function(
    String tipoTarea,
    String operadorId,
    String descripcion,
  )
  onGuardar;

  const _DialogoNuevaTarea({
    required this.tiposTareas,
    required this.todosLosUsuarios,
    required this.onGuardar,
  });

  @override
  State<_DialogoNuevaTarea> createState() => _DialogoNuevaTareaState();
}

class _DialogoNuevaTareaState extends State<_DialogoNuevaTarea> {
  late String _tipoTarea;
  String? _operadorId;
  String? _operadorNombre;
  late List<Map<String, dynamic>> _filtrados;
  final _busquedaCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tipoTarea = widget.tiposTareas[0];
    _filtrados = List.from(widget.todosLosUsuarios);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  void _filtrar(String q) {
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Tarea Extra'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _tipoTarea,
                decoration: const InputDecoration(
                  labelText: 'Tipo de tarea',
                  border: OutlineInputBorder(),
                ),
                items:
                    widget.tiposTareas
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                onChanged: (v) => setState(() => _tipoTarea = v!),
              ),
              const SizedBox(height: 16),
              const Text(
                'Asignar a operador',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 6),
              if (_operadorNombre != null)
                _ChipSeleccionado(
                  nombre: _operadorNombre!,
                  onQuitar:
                      () => setState(() {
                        _operadorId = null;
                        _operadorNombre = null;
                        _busquedaCtrl.clear();
                        _filtrados = List.from(widget.todosLosUsuarios);
                      }),
                )
              else ...[
                TextField(
                  controller: _busquedaCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Buscar operador...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: _filtrar,
                ),
                const SizedBox(height: 6),
                _ListaUsuarios(
                  usuarios: _filtrados,
                  onSeleccionar:
                      (u) => setState(() {
                        _operadorId = u['id'];
                        _operadorNombre = u['nombre'];
                      }),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
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
                    if (_operadorId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Debe seleccionar un operador'),
                        ),
                      );
                      return;
                    }
                    setState(() => _guardando = true);
                    try {
                      await widget.onGuardar(
                        _tipoTarea,
                        _operadorId!,
                        _descripcionCtrl.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Tarea creada exitosamente'),
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
                  : const Text('Crear', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIÁLOGO NUEVO RETIRO  ← VERSIÓN CORREGIDA
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

  // Referencias seleccionadas: {id, referencia, nombre, cantidadCtrl}
  final List<Map<String, dynamic>> _referenciasSeleccionadas = [];

  // Buscador de productos con debounce
  List<Map<String, dynamic>> _resultadosBusqueda = [];
  final _busquedaProductoCtrl = TextEditingController();
  bool _buscandoProducto = false;
  Timer? _debounceProducto;
  final _scrollCtrl = ScrollController(); // ← scroll del diálogo

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

  // ── Búsqueda con debounce ─────────────────────────────────────────────────
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
    // Scroll al final para mostrar el campo de cantidad recién agregado
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

              // ── 2. ENCABEZADO REFERENCIAS (solo título + badge contador) ──
              // ¡¡IMPORTANTE: el bloque de cantidades está FUERA de este Row!!
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
              // Verde cuando la referencia ya fue agregada
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
                          // Badge de referencia — azul normal, verde si ya está
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
                          // Texto indicador cuando ya está seleccionada
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

              // ── 5. BANNER + CAMPOS DE CANTIDAD ──────────────────────────
              // Este bloque está completamente FUERA del Row de "Referencias"
              if (_referenciasSeleccionadas.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Banner verde
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
                // Una fila por referencia seleccionada
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
                        // Badge referencia
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
                        // Campo cantidad
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
                        // Botón eliminar
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

class _TablaCellEstado extends StatelessWidget {
  final String estado;
  const _TablaCellEstado(this.estado);

  @override
  Widget build(BuildContext context) {
    Color color;
    String texto;
    switch (estado.toLowerCase()) {
      case 'terminado':
      case 'terminada':
      case 'completada':
        color = Colors.green;
        texto = 'Terminado';
        break;
      case 'pendiente':
        color = Colors.orange;
        texto = 'Pendiente';
        break;
      default:
        color = Colors.grey;
        texto = estado;
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
