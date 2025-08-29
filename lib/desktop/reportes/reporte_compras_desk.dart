import 'package:basefundi/services/pdfs/materiaprimacopiapdf.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ReporteComprasDeskScreen extends StatefulWidget {
  const ReporteComprasDeskScreen({super.key});

  @override
  State<ReporteComprasDeskScreen> createState() =>
      _ReporteComprasDeskScreenState();
}

class _ReporteComprasDeskScreenState extends State<ReporteComprasDeskScreen> {
  List<Map<String, dynamic>> _reporte = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _cargando = false;
  double _totalGeneral = 0.0;
  double _promedioMensual = 0.0;

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    setState(() {
      _cargando = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('proformasfundicion')
        .orderBy('fecha', descending: true);

    if (_fechaInicio != null) {
      query = query.where(
        'fecha',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
      );
    }
    if (_fechaFin != null) {
      query = query.where(
        'fecha',
        isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
      );
    }

    final snapshot = await query.get();

    List<Map<String, dynamic>> reporte = [];
    double totalGeneral = 0.0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final fecha = (data['fecha'] as Timestamp?)?.toDate();
      final items = data['items'] as List<dynamic>? ?? [];

      // Calcular total de la proforma
      double totalProforma = 0.0;
      for (var item in items) {
        final itemMap = item as Map<String, dynamic>;
        final total =
            double.tryParse(itemMap['total']?.toString() ?? '0') ?? 0.0;
        totalProforma += total;
      }

      totalGeneral += totalProforma;

      reporte.add({
        'numero': data['numero'] ?? '—',
        'cliente': data['cliente'] ?? '—',
        'fecha': fecha,
        'items': items,
        'totalProforma': totalProforma,
      });
    }

    // Calcular promedio mensual
    double promedioMensual = 0.0;
    if (reporte.isNotEmpty) {
      // Agrupar por mes y año
      Map<String, double> totalesPorMes = {};

      for (var item in reporte) {
        final fecha = item['fecha'] as DateTime?;
        if (fecha != null) {
          final mesAno = DateFormat('yyyy-MM').format(fecha);
          totalesPorMes[mesAno] =
              (totalesPorMes[mesAno] ?? 0) + item['totalProforma'];
        }
      }

      if (totalesPorMes.isNotEmpty) {
        final sumaTotal = totalesPorMes.values.reduce((a, b) => a + b);
        promedioMensual = sumaTotal / totalesPorMes.length;
      }
    }

    setState(() {
      _reporte = reporte;
      _totalGeneral = totalGeneral;
      _promedioMensual = promedioMensual;
      _cargando = false;
    });
  }

  void _limpiarFiltro() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
    });
    _obtenerDatos();
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return DateFormat('dd/MM/yyyy hh:mm a').format(fecha);
  }

  String _formatearMoneda(double valor) {
    return '\$${valor.toStringAsFixed(2)}';
  }

  Future<void> _generarPDFIndividual(Map<String, dynamic> proforma) async {
    try {
      final items = proforma['items'] as List<dynamic>? ?? [];
      
      // Convertir items a formato esperado por el generador
      List<Map<String, String>> itemsFormateados = items.map((item) {
        final itemMap = item as Map<String, dynamic>;
        return {
          'descripcion': itemMap['descripcion']?.toString() ?? '',
          'kilos': itemMap['kilos']?.toString() ?? '',
          'precio': itemMap['precio']?.toString() ?? '',
          'total': itemMap['total']?.toString() ?? '',
        };
      }).toList();

      await CopiaMateriaPrimaPDFGenerator.showPreview(
        numero: proforma['numero']?.toString() ?? 'SIN NÚMERO',
        cliente: proforma['cliente']?.toString() ?? 'SIN CLIENTE',
        fecha: proforma['fecha'] ?? DateTime.now(),
        items: itemsFormateados,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                      'Reporte Compras Materia Prima',
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
                          Icon(
                            Icons.monetization_on,
                            color: const Color(0xFFFFFFFF),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total General',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFFFFFFFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearMoneda(_totalGeneral),
                            style: TextStyle(
                              fontSize: 18,
                              color: const Color(0xFFFFFFFF),
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
                          Icon(
                            Icons.trending_up,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Promedio Mensual',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatearMoneda(_promedioMensual),
                            style: TextStyle(
                              fontSize: 18,
                              color: const Color.fromARGB(255, 255, 255, 255),
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
                          Icon(
                            Icons.receipt_long,
                            color: const Color.fromARGB(255, 255, 255, 255),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total Proformas',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color.fromARGB(255, 255, 255, 255),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_reporte.length}',
                            style: TextStyle(
                              fontSize: 18,
                              color: const Color.fromARGB(255, 255, 255, 255),
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
                  // FILTROS FECHA
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
                        onPressed: _limpiarFiltro,
                        icon: const Icon(Icons.clear, color: Color(0xFF4682B4)),
                        tooltip: 'Limpiar filtro',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // TABLA DE REGISTROS
                  _cargando
                      ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : _reporte.isEmpty
                      ? const Expanded(
                        child: Center(
                          child: Text(
                            'No hay registros para mostrar.',
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
                                0: FlexColumnWidth(2.0), // Fecha
                                1: FlexColumnWidth(2.5), // Proforma
                                2: FlexColumnWidth(2.0), // Cliente
                                3: FlexColumnWidth(1.5), // Total
                                4: FlexColumnWidth(2.0), // Acción
                              },
                              children: [
                                // ENCABEZADO
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4682B4),
                                  ),
                                  children: const [
                                    _TablaHeaderMain('Fecha'),
                                    _TablaHeaderMain('Proforma'),
                                    _TablaHeaderMain('Cliente'),
                                    _TablaHeaderMain('Total'),
                                    _TablaHeaderMain('Acción'),
                                  ],
                                ),
                                // FILAS DE DATOS
                                ..._reporte.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final item = entry.value;
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
                                        _formatearFecha(item['fecha']),
                                      ),
                                      _TablaCellMain(
                                        item['numero']?.toString() ?? '—',
                                      ),
                                      _TablaCellMain(
                                        item['cliente']?.toString() ?? '—',
                                      ),
                                      _TablaCellMain(
                                        _formatearMoneda(
                                          item['totalProforma'] ?? 0.0,
                                        ),
                                        isMoneda: true,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Center(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _generarPDFIndividual(item),
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'PDF',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF4682B4,
                                              ),
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

  const _TablaCellMain(this.text, {this.isMoneda = false});

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