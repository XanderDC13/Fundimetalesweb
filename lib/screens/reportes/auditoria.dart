import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  String _filtro = '';
  DateTime? _fechaSeleccionada;

  // Función para dividir la lista en chunks de tamaño dado
  List<List<T>> chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      int end = (i + chunkSize < list.length) ? i + chunkSize : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  Future<void> _exportarPdf(List<QueryDocumentSnapshot> registros) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Dividir en chunks de 50 filas por página
    final chunks = chunkList(registros, 50);

    for (var i = 0; i < chunks.length; i++) {
      final dataRows =
          chunks[i].map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final fecha =
                (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();
            final usuario = data['usuario_nombre'] ?? '---';
            final accion = data['accion'] ?? '---';
            final detalle = data['detalle'] ?? '';

            return [
              dateFormat.format(fecha),
              usuario.toString(),
              accion.toString(),
              detalle.toString(),
            ];
          }).toList();

      pdf.addPage(
        buildReportePDF(
          titulo: 'Reporte de Auditoría - Página ${i + 1} de ${chunks.length}',
          headers: ['Fecha', 'Usuario', 'Acción', 'Detalle'],
          dataRows: dataRows,
          footerText: 'Registros en esta página: ${dataRows.length}',
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  pw.MultiPage buildReportePDF({
    required String titulo,
    required List<String> headers,
    required List<List<String>> dataRows,
    String? footerText,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build:
          (context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                titulo,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              border: null,
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              rowDecoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
              ),
              cellPadding: const pw.EdgeInsets.symmetric(
                vertical: 6,
                horizontal: 4,
              ),
              headers: headers,
              data: dataRows,
            ),
            pw.SizedBox(height: 20),
            if (footerText != null)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  footerText,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
          ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado con botón PDF
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
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
                    'Auditoría',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                    tooltip: 'Exportar PDF',
                    onPressed: () async {
                      // Obtener todos los documentos
                      final snapshot =
                          await FirebaseFirestore.instance
                              .collection('auditoria_general')
                              .orderBy('fecha', descending: true)
                              .get();

                      // Filtrar usando texto y fecha
                      final registrosFiltrados =
                          snapshot.docs.where((doc) {
                            final data = doc.data();
                            final usuario =
                                (data['usuario_nombre'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final accion =
                                (data['accion'] ?? '').toString().toLowerCase();
                            final detalle =
                                (data['detalle'] ?? '')
                                    .toString()
                                    .toLowerCase();

                            final fecha =
                                (data['fecha'] as Timestamp?)?.toDate();
                            final cumpleFecha =
                                _fechaSeleccionada == null ||
                                (fecha != null &&
                                    fecha.year == _fechaSeleccionada!.year &&
                                    fecha.month == _fechaSeleccionada!.month &&
                                    fecha.day == _fechaSeleccionada!.day);

                            return (usuario.contains(_filtro) ||
                                    accion.contains(_filtro) ||
                                    detalle.contains(_filtro)) &&
                                cumpleFecha;
                          }).toList();

                      if (registrosFiltrados.isNotEmpty) {
                        await _exportarPdf(registrosFiltrados);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No hay datos para exportar.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            // Barra de búsqueda y filtro por fecha
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por usuario, acción o detalle...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _filtro = value.trim().toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          icon: const Icon(
                            Icons.event,
                            color: Color(0xFF2C3E50),
                          ),
                          label: Text(
                            _fechaSeleccionada == null
                                ? 'Seleccionar fecha'
                                : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_fechaSeleccionada!),
                            style: const TextStyle(
                              color: Color(0xFF2C3E50),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fechaSeleccionada ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _fechaSeleccionada = picked;
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Limpiar fecha',
                        icon: const Icon(Icons.clear, color: Color(0xFF2C3E50)),
                        onPressed: () {
                          setState(() {
                            _fechaSeleccionada = null;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tabla con scroll horizontal y vertical
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('auditoria_general')
                        .orderBy('fecha', descending: true)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final registrosFiltrados =
                      snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final usuario =
                            (data['usuario_nombre'] ?? '')
                                .toString()
                                .toLowerCase();
                        final accion =
                            (data['accion'] ?? '').toString().toLowerCase();
                        final detalle =
                            (data['detalle'] ?? '').toString().toLowerCase();

                        final fecha = (data['fecha'] as Timestamp?)?.toDate();
                        final cumpleFecha =
                            _fechaSeleccionada == null ||
                            (fecha != null &&
                                fecha.year == _fechaSeleccionada!.year &&
                                fecha.month == _fechaSeleccionada!.month &&
                                fecha.day == _fechaSeleccionada!.day);

                        return (usuario.contains(_filtro) ||
                                accion.contains(_filtro) ||
                                detalle.contains(_filtro)) &&
                            cumpleFecha;
                      }).toList();

                  if (registrosFiltrados.isEmpty) {
                    return const Center(child: Text('No hay registros aún.'));
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          const Color(0xFF4682B4),
                        ),
                        headingTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        columnSpacing: 2,
                        columns: [
                          DataColumn(
                            label: SizedBox(
                              width: 80,
                              child: const Text(
                                'Fecha',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 140,
                              child: const Text(
                                'Acción',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 70,
                              child: const Text(
                                'Usuario',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: SizedBox(
                              width: 300,
                              child: const Text(
                                'Detalle',
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ],
                        rows:
                            registrosFiltrados.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final fecha =
                                  (data['fecha'] as Timestamp?)?.toDate() ??
                                  DateTime.now();
                              final fechaStr = DateFormat(
                                'dd/MM/yy HH:mm',
                              ).format(fecha);
                              final accion = data['accion'] ?? '---';
                              final usuario = data['usuario_nombre'] ?? '---';
                              final detalle = data['detalle'] ?? '';

                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        fechaStr,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 140,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          accion,
                                          style: const TextStyle(fontSize: 10),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 90,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          usuario,
                                          style: const TextStyle(fontSize: 10),
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 300,
                                      child: Text(
                                        detalle,
                                        style: const TextStyle(fontSize: 10),
                                        softWrap: true,
                                        maxLines: 8,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
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
