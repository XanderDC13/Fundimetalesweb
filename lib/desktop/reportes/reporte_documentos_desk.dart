import 'package:basefundi/services/pdfs/copiaordenpdf_desk.dart';
import 'package:basefundi/services/pdfs/copiaproformapdf_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ReporteDocumentosDeskScreen extends StatefulWidget {
  const ReporteDocumentosDeskScreen({super.key});

  @override
  State<ReporteDocumentosDeskScreen> createState() =>
      _ReporteDocumentosDeskScreenState();
}

class _ReporteDocumentosDeskScreenState
    extends State<ReporteDocumentosDeskScreen> {
  List<Map<String, dynamic>> _documentos = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _filtroCliente = '';
  String _filtroCedula = '';
  bool _cargando = false;

  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _obtenerDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      // Obtener proformas
      Query queryProformas = FirebaseFirestore.instance
          .collection('proformas')
          .orderBy('fecha', descending: true);

      if (_fechaInicio != null) {
        queryProformas = queryProformas.where(
          'fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
        );
      }
      if (_fechaFin != null) {
        queryProformas = queryProformas.where(
          'fecha',
          isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
        );
      }

      final snapshotProformas = await queryProformas.get();

      // Obtener órdenes de despacho
      Query queryOrdenes = FirebaseFirestore.instance
          .collection('ordenes_despacho')
          .orderBy('fecha', descending: true);

      if (_fechaInicio != null) {
        queryOrdenes = queryOrdenes.where(
          'fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
        );
      }
      if (_fechaFin != null) {
        queryOrdenes = queryOrdenes.where(
          'fecha',
          isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
        );
      }

      final snapshotOrdenes = await queryOrdenes.get();

      // Crear mapa para organizar documentos por número
      Map<String, Map<String, dynamic>> documentosPorNumero = {};

      // Procesar proformas
      for (var doc in snapshotProformas.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final numero = data['numero']?.toString() ?? '';
        final cliente = data['cliente']?.toString() ?? '';
        final ciRuc = data['ci_ruc']?.toString() ?? '';

        if (numero.isNotEmpty) {
          documentosPorNumero[numero] = {
            'numero': numero,
            'cliente': cliente,
            'ci_ruc': ciRuc,
            'proforma': data,
            'orden': null,
            'fechaProforma': (data['fecha'] as Timestamp?)?.toDate(),
            'fechaOrden': null,
          };
        }
      }

      // Procesar órdenes de despacho
      for (var doc in snapshotOrdenes.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final numero = data['numero']?.toString() ?? '';
        final cliente = data['cliente']?.toString() ?? '';
        final ciRuc = data['ci_ruc']?.toString() ?? '';

        if (numero.isNotEmpty) {
          // Buscar si ya existe un documento con el mismo cliente/cédula
          final documentoExistente = documentosPorNumero.values.firstWhere(
            (doc) => doc['ci_ruc'] == ciRuc && ciRuc.isNotEmpty,
            orElse: () => {},
          );

          if (documentoExistente.isNotEmpty) {
            // Encontró un documento del mismo cliente, agregar la orden ahí
            final key = documentoExistente['numero'];
            documentosPorNumero[key]!['orden'] = data;
            documentosPorNumero[key]!['fechaOrden'] =
                (data['fecha'] as Timestamp?)?.toDate();
          } else {
            // No existe documento previo de este cliente, crear nueva entrada
            documentosPorNumero[numero] = {
              'numero': numero,
              'cliente': cliente,
              'ci_ruc': ciRuc,
              'proforma': null,
              'orden': data,
              'fechaProforma': null,
              'fechaOrden': (data['fecha'] as Timestamp?)?.toDate(),
            };
          }
        }
      }

      // Convertir a lista y aplicar filtros adicionales
      List<Map<String, dynamic>> documentos =
          documentosPorNumero.values.toList();

      // Filtrar por cliente
      if (_filtroCliente.isNotEmpty) {
        documentos =
            documentos.where((doc) {
              final cliente = doc['cliente']?.toString().toLowerCase() ?? '';
              return cliente.contains(_filtroCliente.toLowerCase());
            }).toList();
      }

      // Filtrar por cédula
      if (_filtroCedula.isNotEmpty) {
        documentos =
            documentos.where((doc) {
              final ciRuc = doc['ci_ruc']?.toString() ?? '';
              return ciRuc.contains(_filtroCedula);
            }).toList();
      }

      // Ordenar por fecha más reciente (proforma o orden)
      documentos.sort((a, b) {
        final fechaA = a['fechaProforma'] ?? a['fechaOrden'];
        final fechaB = b['fechaProforma'] ?? b['fechaOrden'];
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        _documentos = documentos;
        _cargando = false;
      });
    } catch (e) {
      print('Error al obtener documentos: $e');
      setState(() {
        _cargando = false;
      });
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _filtroCliente = '';
      _filtroCedula = '';
      _clienteController.clear();
      _cedulaController.clear();
    });
    _obtenerDatos();
  }

  void _aplicarFiltroCliente() {
    setState(() {
      _filtroCliente = _clienteController.text;
    });
    _obtenerDatos();
  }

  void _aplicarFiltroCedula() {
    setState(() {
      _filtroCedula = _cedulaController.text;
    });
    _obtenerDatos();
  }

  String _construirTextoNumeros(Map<String, dynamic> documento) {
    final numeroProforma = documento['proforma']?['numero']?.toString();
    final numeroOrden = documento['orden']?['numero']?.toString();

    final List<String> partes = [];

    if (numeroProforma != null) {
      partes.add('PROFORMA: $numeroProforma');
    }

    if (numeroOrden != null) {
      partes.add('ORDEN: $numeroOrden');
    }

    return partes.isEmpty ? '—' : partes.join(' | ');
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

  @override
  Widget build(BuildContext context) {
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Reporte de Documentos',
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

          // INDICADORES RESUMEN
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF4682B4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.description,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Total Documentos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_documentos.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: const Color(0xFF4682B4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Proformas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_documentos.where((doc) => doc['proforma'] != null).length}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: const Color(0xFF4682B4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_shipping,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Órdenes Despacho',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_documentos.where((doc) => doc['orden'] != null).length}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENIDO principal
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // FILTROS
                  Column(
                    children: [
                      // Primera fila de filtros - Fechas
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _seleccionarFechaInicio,
                              icon: const Icon(
                                Icons.date_range,
                                color: Colors.white,
                              ),
                              label: Text(
                                _fechaInicio == null
                                    ? 'Desde'
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaInicio!),
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
                              icon: const Icon(
                                Icons.date_range,
                                color: Colors.white,
                              ),
                              label: Text(
                                _fechaFin == null
                                    ? 'Hasta'
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaFin!),
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
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF4682B4),
                            ),
                            tooltip: 'Limpiar filtros',
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Segunda fila de filtros - Cliente y Cédula
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
                                  labelText: 'Filtrar por cliente',
                                  prefixIcon: const Icon(Icons.person),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _aplicarFiltroCliente,
                                  ),
                                  border: InputBorder.none, // 👈 sin bordes
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
                                controller: _cedulaController,
                                decoration: InputDecoration(
                                  labelText: 'Buscar por cédula',
                                  prefixIcon: const Icon(Icons.credit_card),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _aplicarFiltroCedula,
                                  ),
                                  border: InputBorder.none, // 👈 sin bordes
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (value) => _aplicarFiltroCedula(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // TABLA DE DOCUMENTOS
                  _cargando
                      ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : _documentos.isEmpty
                      ? const Expanded(
                        child: Center(
                          child: Text(
                            'No hay documentos para mostrar.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      )
                      : Expanded(
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
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                top: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              columnWidths: const {
                                0: FlexColumnWidth(1.5), // N°
                                1: FlexColumnWidth(3.0), // Cliente
                                2: FlexColumnWidth(2.0), // Proforma
                                3: FlexColumnWidth(2.0), // Orden
                              },
                              children: [
                                // ENCABEZADO
                                const TableRow(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4682B4),
                                  ),
                                  children: [
                                    _TablaHeaderMain('N°'),
                                    _TablaHeaderMain('Cliente'),
                                    _TablaHeaderMain('Proforma'),
                                    _TablaHeaderMain('Orden'),
                                  ],
                                ),
                                // FILAS DE DATOS
                                ..._documentos.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final documento = entry.value;
                                  final isEven = index % 2 == 0;

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color:
                                          isEven
                                              ? Colors.grey.shade50
                                              : Colors.white,
                                    ),
                                    children: [
                                      _TablaCellMain(
                                        _construirTextoNumeros(documento),
                                        false,
                                      ),
                                      _TablaCellMain(
                                        documento['cliente']?.toString() ?? '—',
                                        false,
                                      ),
                                      // Columna Proforma
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Center(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                () => generarProformaPDF(
                                                  documento['numero'],
                                                  documento['ci_ruc'],
                                                ),
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'PDF',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  documento['proforma'] != null
                                                      ? const Color(0xFF4682B4)
                                                      : Colors.grey,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              minimumSize: const Size(0, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Columna Orden
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Center(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                () => generarOrdenPDF(
                                                  documento['numero'],
                                                  documento['ci_ruc'],
                                                ),
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'PDF',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  documento['orden'] != null
                                                      ? const Color(0xFF4682B4)
                                                      : Colors.grey,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              minimumSize: const Size(0, 32),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
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
}

class _TablaHeaderMain extends StatelessWidget {
  final String text;
  const _TablaHeaderMain(this.text);

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

class _TablaCellMain extends StatelessWidget {
  final String? text;
  final bool isMoneda;

  const _TablaCellMain(this.text, this.isMoneda);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text ?? '—',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isMoneda ? FontWeight.bold : FontWeight.normal,
          color: isMoneda ? Colors.green.shade700 : const Color(0xFF2C3E50),
        ),
        textAlign: isMoneda ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}
