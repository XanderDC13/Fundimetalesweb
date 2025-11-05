import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportePedidosDeskScreen extends StatefulWidget {
  const ReportePedidosDeskScreen({super.key});

  @override
  State<ReportePedidosDeskScreen> createState() =>
      _ReportePedidosDeskScreenState();
}

class _ReportePedidosDeskScreenState extends State<ReportePedidosDeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _pedidosAsignados = [];
  List<Map<String, dynamic>> _pedidosTerminados = [];
  List<Map<String, dynamic>> _tareasExtras = [];
  List<Map<String, dynamic>> _retirosMercaderia = [];
  final Map<String, String> _nombresOperadores = {};
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _filtroCliente = '';
  String _filtroReferencia = '';
  bool _cargando = false;

  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _referenciaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Actualizar UI cuando cambie de pestaña
    });
    _obtenerDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _clienteController.dispose();
    _referenciaController.dispose();
    super.dispose();
  }

  Future<String> _obtenerNombreOperador(String operadorId) async {
    // Si ya tenemos el nombre en cache, lo retornamos
    if (_nombresOperadores.containsKey(operadorId)) {
      return _nombresOperadores[operadorId]!;
    }

    try {
      final operadorDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(operadorId)
              .get();

      if (operadorDoc.exists) {
        final data = operadorDoc.data();
        String nombre = data?['nombre'] ?? 'Sin nombre';

        // Guardamos en cache
        _nombresOperadores[operadorId] = nombre;
        return nombre;
      }
    } catch (e) {
      print('Error al obtener operador $operadorId: $e');
    }

    return 'Operador desconocido';
  }

  Future<void> _obtenerDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      Query query = FirebaseFirestore.instance
          .collection('tareas_operador')
          .orderBy('fecha_asignacion', descending: true);

      if (_fechaInicio != null) {
        query = query.where(
          'fecha_asignacion',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
        );
      }
      if (_fechaFin != null) {
        query = query.where(
          'fecha_asignacion',
          isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
        );
      }

      final snapshot = await query.get();

      List<Map<String, dynamic>> asignados = [];
      List<Map<String, dynamic>> terminados = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Obtener nombre del operador
        String operadorNombre = 'Sin operador';
        if (data['operador_id'] != null &&
            data['operador_id'].toString().isNotEmpty) {
          operadorNombre = await _obtenerNombreOperador(
            data['operador_id'].toString(),
          );
        }

        String referencia = data['referencia']?.toString() ?? 'Sin referencia';

        // Aplicar filtros
        bool cumpleFiltroCliente =
            _filtroCliente.isEmpty ||
            operadorNombre.toLowerCase().contains(_filtroCliente.toLowerCase());

        bool cumpleFiltroReferencia =
            _filtroReferencia.isEmpty ||
            referencia.toLowerCase().contains(_filtroReferencia.toLowerCase());

        if (cumpleFiltroCliente && cumpleFiltroReferencia) {
          final estado = data['estado']?.toString() ?? 'asignada';
          final cantidadOriginal = data['cantidad_original'] ?? 0;
          final cantidadActual = data['cantidad'] ?? 0;
          final cantidadYaCompletada = data['cantidad_ya_completada'] ?? 0;
          final esTareaParcial = data['es_tarea_parcial'] == true;

          // ✅ TAREAS ASIGNADAS (pendientes o parcialmente completadas)
          if (estado == 'asignada') {
            String estadoDisplay = 'asignada';

            // Si es tarea parcial, mostrar progreso
            if (esTareaParcial && cantidadYaCompletada > 0) {
              estadoDisplay =
                  'En progreso ($cantidadYaCompletada/$cantidadOriginal)';
            }

            asignados.add({
              'id': doc.id,
              'cliente': operadorNombre,
              'fecha': data['fecha_asignacion'],
              'referencia': referencia,
              'cantidadAFundir': cantidadActual, // Cantidad que falta
              'cantidadOriginal': cantidadOriginal,
              'cantidadCompletada': cantidadYaCompletada,
              'estado': estadoDisplay,
            });
          }

          // ✅ TAREAS COMPLETADAS (total o parcialmente)
          if (estado == 'completada' || estado == 'terminado') {
            final tipoCompletado =
                data['tipo_completado']?.toString() ?? 'completa';
            final cantidadCompletada =
                data['cantidad_completada'] ?? data['cantidad'] ?? 0;

            String estadoDisplay = 'Terminado';
            if (tipoCompletado == 'parcial') {
              estadoDisplay =
                  'Parcial ($cantidadCompletada/${cantidadOriginal > 0 ? cantidadOriginal : cantidadCompletada})';
            }

            terminados.add({
              'id': doc.id,
              'cliente': operadorNombre,
              'fecha': data['fecha_completada'] ?? data['fecha_asignacion'],
              'referencia': referencia,
              'cantidadAFundir': cantidadCompletada, // Lo que se completó
              'cantidadOriginal': cantidadOriginal,
              'tipoCompletado': tipoCompletado,
              'estado': estadoDisplay,
            });
          }
        }
      }
      // Obtener tareas extras
      final tareasExtrasSnapshot =
          await FirebaseFirestore.instance
              .collection('tareas_extras')
              .orderBy('fecha_asignacion', descending: true)
              .get();

      List<Map<String, dynamic>> extras = [];

      for (var doc in tareasExtrasSnapshot.docs) {
        final data = doc.data();

        String operadorNombre = 'Sin operador';
        if (data['operador_id'] != null &&
            data['operador_id'].toString().isNotEmpty) {
          operadorNombre = await _obtenerNombreOperador(
            data['operador_id'].toString(),
          );
        }

        String referencia = data['tipo_tarea']?.toString() ?? 'Sin tipo';

        bool cumpleFiltroCliente =
            _filtroCliente.isEmpty ||
            operadorNombre.toLowerCase().contains(_filtroCliente.toLowerCase());

        bool cumpleFiltroReferencia =
            _filtroReferencia.isEmpty ||
            referencia.toLowerCase().contains(_filtroReferencia.toLowerCase());

        if (cumpleFiltroCliente && cumpleFiltroReferencia) {
          extras.add({
            'id': doc.id,
            'cliente': operadorNombre,
            'fecha':
                data['estado'] == 'completada' || data['estado'] == 'terminado'
                    ? (data['fecha_completada'] ?? data['fecha_asignacion'])
                    : data['fecha_asignacion'],
            'referencia': referencia,
            'cantidadAFundir': data['cantidad'] ?? 0,
            'estado': data['estado']?.toString() ?? 'extra',
          });
        }
      }
      // Obtener retiros de mercadería
      final retirosSnapshot =
          await FirebaseFirestore.instance
              .collection('retiros_mercaderia')
              .orderBy('fecha_retiro', descending: true)
              .get();

      List<Map<String, dynamic>> retiros = [];

      for (var doc in retirosSnapshot.docs) {
        final data = doc.data();

        String personaRetiro =
            data['persona_retiro']?.toString() ?? 'Sin nombre';
        String descripcionMaterial =
            data['descripcion_material']?.toString() ?? 'Sin descripción';

        bool cumpleFiltroCliente =
            _filtroCliente.isEmpty ||
            personaRetiro.toLowerCase().contains(_filtroCliente.toLowerCase());

        bool cumpleFiltroReferencia =
            _filtroReferencia.isEmpty ||
            descripcionMaterial.toLowerCase().contains(
              _filtroReferencia.toLowerCase(),
            );

        if (cumpleFiltroCliente && cumpleFiltroReferencia) {
          retiros.add({
            'id': doc.id,
            'cliente': personaRetiro,
            'fecha': data['fecha_retiro'],
            'referencia': descripcionMaterial,
            'cantidadAFundir': data['cantidad'] ?? 0,
            'estado': 'retirado',
          });
        }
      }

      setState(() {
        _pedidosAsignados = asignados;
        _pedidosTerminados = terminados;
        _tareasExtras = extras;
        _retirosMercaderia = retiros; // ← AGREGAR ESTA LÍNEA
        _cargando = false;
      });
    } catch (e) {
      print('Error al obtener tareas: $e');
      setState(() {
        _cargando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar tareas: $e')));
      }
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _filtroCliente = '';
      _filtroReferencia = '';
      _clienteController.clear();
      _referenciaController.clear();
    });
    _obtenerDatos();
  }

  void _aplicarFiltroCliente() {
    setState(() {
      _filtroCliente = _clienteController.text;
    });
    _obtenerDatos();
  }

  void _aplicarFiltroReferencia() {
    setState(() {
      _filtroReferencia = _referenciaController.text;
    });
    _obtenerDatos();
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
      _obtenerDatos();
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
      _obtenerDatos();
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      if (fecha is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
      } else if (fecha is String) {
        return fecha;
      }
      return fecha.toString();
    } catch (e) {
      return '—';
    }
  }

  Future<void> _generarPDF() async {
    final pdf = pw.Document();

    List<Map<String, dynamic>> datos;
    String titulo;
    List<String> columnas;

    // Determinar qué pestaña está activa
    if (_tabController.index == 0) {
      datos = _pedidosAsignados;
      titulo = 'Reporte de Tareas Asignadas';
      columnas = ['Operador', 'Referencia', 'Cantidad', 'Fecha', 'Estado'];
    } else if (_tabController.index == 1) {
      datos = _pedidosTerminados;
      titulo = 'Reporte de Tareas Terminadas';
      columnas = ['Operador', 'Referencia', 'Cantidad', 'Fecha', 'Estado'];
    } else if (_tabController.index == 2) {
      datos = _tareasExtras;
      titulo = 'Reporte de Tareas Extras';
      columnas = ['Operador Asignado', 'Tipo de Tarea', 'Fecha'];
    } else {
      datos = _retirosMercaderia;
      titulo = 'Reporte de Retiros de Mercadería';
      columnas = ['Persona', 'Material', 'Cantidad', 'Fecha'];
    }

    // Construir filas según la pestaña
    List<List<String>> filas =
        datos.map((item) {
          if (_tabController.index == 2) {
            // Tareas Extras: 3 columnas
            return [
              item['cliente']?.toString() ?? '—',
              item['referencia']?.toString() ?? '—',
              _formatearFecha(item['fecha']),
            ];
          } else if (_tabController.index == 3) {
            // Retiros: 4 columnas
            return [
              item['cliente']?.toString() ?? '—',
              item['referencia']?.toString() ?? '—',
              item['cantidadAFundir']?.toString() ?? '0',
              _formatearFecha(item['fecha']),
            ];
          } else {
            // Asignadas/Terminadas: 5 columnas
            return [
              item['cliente']?.toString() ?? '—',
              item['referencia']?.toString() ?? '—',
              item['cantidadAFundir']?.toString() ?? '0',
              _formatearFecha(item['fecha']),
              item['estado']?.toString() ?? '—',
            ];
          }
        }).toList();

    // Construir rango de fechas
    String rangoFechas = '';
    if (_fechaInicio != null || _fechaFin != null) {
      rangoFechas = 'Período: ';
      if (_fechaInicio != null) {
        rangoFechas +=
            'Desde ${DateFormat('dd/MM/yyyy').format(_fechaInicio!)} ';
      }
      if (_fechaFin != null) {
        rangoFechas += 'Hasta ${DateFormat('dd/MM/yyyy').format(_fechaFin!)}';
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return [
            // Encabezado
            pw.Header(
              level: 0,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    titulo,
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  if (rangoFechas.isNotEmpty) pw.SizedBox(height: 8),
                  if (rangoFechas.isNotEmpty)
                    pw.Text(
                      rangoFechas,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generado el ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                  pw.Divider(thickness: 2),
                ],
              ),
            ),

            // Tabla
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths:
                  _tabController.index == 2
                      ? {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(3),
                        2: const pw.FlexColumnWidth(2.5),
                      }
                      : _tabController.index == 3
                      ? {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(2.5),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(2.5),
                      }
                      : {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(2.5),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(2.5),
                        4: const pw.FlexColumnWidth(1.5),
                      },
              children: [
                // Encabezado de tabla
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue300),
                  children:
                      columnas
                          .map(
                            (col) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                col,
                                style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          )
                          .toList(),
                ),

                // Filas de datos
                ...filas.map(
                  (fila) => pw.TableRow(
                    children:
                        fila
                            .map(
                              (celda) => pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  celda,
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),

            // Resumen
            pw.SizedBox(height: 20),
            pw.Text(
              'Total de registros: ${datos.length}',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );

    // Mostrar vista previa de impresión
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Widget _buildFiltros() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _seleccionarFechaInicio,
                icon: const Icon(Icons.date_range, color: Colors.white),
                label: Text(
                  _fechaInicio == null
                      ? 'Desde'
                      : DateFormat('dd/MM/yyyy').format(_fechaInicio!),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _seleccionarFechaFin,
                icon: const Icon(Icons.date_range, color: Colors.white),
                label: Text(
                  _fechaFin == null
                      ? 'Hasta'
                      : DateFormat('dd/MM/yyyy').format(_fechaFin!),
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: _limpiarFiltros,
              icon: const Icon(Icons.clear, color: Color(0xFF4682B4)),
              tooltip: 'Limpiar filtros',
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              // ← AGREGAR ESTE BOTÓN
              onPressed: _generarPDF,
              icon: const Icon(Icons.print, color: Colors.white),
              label: const Text(
                'Imprimir',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _clienteController,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por operador',
                    prefixIcon: const Icon(Icons.person),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _aplicarFiltroCliente,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) => _aplicarFiltroCliente(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _referenciaController,
                  decoration: InputDecoration(
                    labelText: 'Buscar por referencia',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _aplicarFiltroReferencia,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (value) => _aplicarFiltroReferencia(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTablaPedidos(List<Map<String, dynamic>> pedidos) {
    if (_cargando) {
      return const Expanded(child: Center(child: CircularProgressIndicator()));
    }

    if (pedidos.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No hay pedidos para mostrar.',
            style: TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
          ),
        ),
      );
    }

    final bool esTareasExtras = _tabController.index == 2;

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
            columnWidths:
                esTareasExtras
                    ? const {
                      0: FlexColumnWidth(3.0), // Operador
                      1: FlexColumnWidth(3.0), // Tipo de Tarea
                      2: FlexColumnWidth(2.5), // Fecha
                    }
                    : const {
                      0: FlexColumnWidth(3.0), // Cliente
                      1: FlexColumnWidth(2.5), // Referencia
                      2: FlexColumnWidth(1.5), // Cantidad
                      3: FlexColumnWidth(2.5), // Fecha
                      4: FlexColumnWidth(1.5), // Estado
                    },
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF4682B4)),
                children:
                    esTareasExtras
                        ? const [
                          _TablaHeader('Operador Asignado'),
                          _TablaHeader('Tipo de Tarea'),
                          _TablaHeader('Fecha'),
                        ]
                        : const [
                          _TablaHeader('Operador Asignado'),
                          _TablaHeader('Referencia'),
                          _TablaHeader('Cantidad'),
                          _TablaHeader('Fecha'),
                          _TablaHeader('Estado'),
                        ],
              ),
              ...pedidos.asMap().entries.map((entry) {
                final index = entry.key;
                final pedido = entry.value;
                final isEven = index % 2 == 0;

                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.grey.shade50 : Colors.white,
                  ),
                  children:
                      esTareasExtras
                          ? [
                            _TablaCell(pedido['cliente']?.toString() ?? '—'),
                            _TablaCell(pedido['referencia']?.toString() ?? '—'),
                            _TablaCell(_formatearFecha(pedido['fecha'])),
                          ]
                          : [
                            _TablaCell(pedido['cliente']?.toString() ?? '—'),
                            _TablaCell(pedido['referencia']?.toString() ?? '—'),
                            _TablaCell(
                              pedido['cantidadAFundir']?.toString() ?? '0',
                              isNumero: true,
                            ),
                            _TablaCell(_formatearFecha(pedido['fecha'])),
                            _TablaCellEstado(
                              pedido['estado']?.toString() ?? 'pendiente',
                            ),
                          ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> pedidosActuales;

    if (_tabController.index == 0) {
      pedidosActuales = _pedidosAsignados;
    } else if (_tabController.index == 1) {
      pedidosActuales = _pedidosTerminados;
    } else if (_tabController.index == 2) {
      pedidosActuales = _tareasExtras;
    } else {
      pedidosActuales = _retirosMercaderia;
    }

    return MainDeskLayout(
      child: Column(
        children: [
          // CABECERA
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
                      'Reporte de Fundición',
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

          // TABS
          Container(
            color: const Color(0xFF2C3E50),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Asignadas'),
                Tab(text: 'Terminadas'),
                Tab(text: 'Tareas Extras'),
                Tab(text: 'Retiros'),
              ],
            ),
          ),
          // CONTENIDO
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildFiltros(),
                  const SizedBox(height: 16),
                  _buildTablaPedidos(pedidosActuales),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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

    // Detectar diferentes tipos de estados
    if (estado.toLowerCase().contains('parcial')) {
      color = Colors.orange;
      texto = estado; // "Parcial (20/35)"
    } else if (estado.toLowerCase().contains('progreso')) {
      color = Colors.blue;
      texto = estado; // "En progreso (25/35)"
    } else {
      switch (estado.toLowerCase()) {
        case 'terminado':
        case 'terminada':
        case 'completada':
          color = Colors.green;
          texto = 'Terminado';
          break;
        case 'asignada':
        case 'pendiente':
          color = Colors.orange;
          texto = 'Asignada';
          break;
        default:
          color = Colors.grey;
          texto = estado;
      }
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
