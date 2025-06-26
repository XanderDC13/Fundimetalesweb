import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReporteTransporteScreen extends StatefulWidget {
  const ReporteTransporteScreen({super.key});

  @override
  State<ReporteTransporteScreen> createState() =>
      _ReporteTransporteScreenState();
}

class _ReporteTransporteScreenState extends State<ReporteTransporteScreen> {
  List<Map<String, dynamic>> _reporte = [];

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('transporte')
            .orderBy('fecha_registro', descending: true)
            .get();

    List<Map<String, dynamic>> reporte = [];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final fecha = (data['fecha_registro'] as Timestamp?)?.toDate();

      reporte.add({
        'codigo': data['codigo'],
        'nombre': data['nombre'],
        'fecha': fecha,
        'hora_salida': data['hora_salida'],
        'hora_llegada': data['hora_llegada'],
        'tiempo_demora': data['tiempo_demora'],
      });
    }

    setState(() {
      _reporte = reporte;
    });
  }

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return '—';
    return DateFormat('dd/MM/yyyy hh:mm a').format(fecha);
  }

  Future<void> _generarPDF(
    List<Map<String, dynamic>> data, {
    bool unoSolo = false,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte de Transporte',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              for (var item in data) ...[
                pw.Text('Transporte', style: pw.TextStyle(fontSize: 16)),
                pw.Text('Fecha registro: ${_formatearFecha(item['fecha'])}'),
                pw.Text('Salida: ${item['hora_salida'] ?? '—'}'),
                pw.Text('Llegada: ${item['hora_llegada'] ?? '—'}'),
                pw.Text('Demora: ${item['tiempo_demora'] ?? '—'}'),
                pw.Divider(),
              ],
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // AppBar con degradado
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Reporte de Transporte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          color: Colors.white,
                        ),
                        onPressed: () => _generarPDF(_reporte),
                        tooltip: 'Descargar todo',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child:
                  _reporte.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _reporte.length,
                        itemBuilder: (context, index) {
                          final item = _reporte[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    '📅 Fecha registro: ${_formatearFecha(item['fecha'])}',
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '🚚 Salida: ${item['hora_salida'] ?? '—'}',
                                      ),
                                      Text(
                                        '📥 Llegada: ${item['hora_llegada'] ?? '—'}',
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '⏳ Demora: ${item['tiempo_demora'] ?? '—'}',
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () => _generarPDF([
                                            item,
                                          ], unoSolo: true),
                                      icon: const Icon(Icons.picture_as_pdf),
                                      label: const Text('Exportar PDF'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF4682B4,
                                        ),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
