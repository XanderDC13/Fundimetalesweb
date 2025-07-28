import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:basefundi/settings/navbar_desk.dart'; // Asegúrate de tener este layout

class AuditoriaDeskScreen extends StatefulWidget {
  const AuditoriaDeskScreen({super.key});

  @override
  State<AuditoriaDeskScreen> createState() => _AuditoriaDeskScreenState();
}

class _AuditoriaDeskScreenState extends State<AuditoriaDeskScreen> {
  String _filtro = '';
  DateTime? _fechaSeleccionada;

  // Divide lista en chunks para el PDF
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
    return MainDeskLayout(
      child: Column(
        children: [
          // CABECERA
          Transform.translate(
            offset: const Offset(-0.5, 0), // desplaza levemente a la izquierda
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
                      tooltip: 'Regresar',
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Auditoría',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.white,
                      ),
                      tooltip: 'Exportar PDF',
                      onPressed: () async {
                        final snapshot =
                            await FirebaseFirestore.instance
                                .collection('auditoria_general')
                                .orderBy('fecha', descending: true)
                                .get();

                        final registrosFiltrados =
                            snapshot.docs.where((doc) {
                              final data = doc.data();
                              final usuario =
                                  (data['usuario_nombre'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              final accion =
                                  (data['accion'] ?? '')
                                      .toString()
                                      .toLowerCase();
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
                                      fecha.month ==
                                          _fechaSeleccionada!.month &&
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
                  ),
                ],
              ),
            ),
          ),

          // CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Barra búsqueda y filtro fecha
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        // Campo búsqueda
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Buscar por usuario, acción o detalle...',
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
                        ),

                        const SizedBox(width: 12),

                        // Selector fecha
                        Expanded(
                          flex: 1,
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                                initialDate:
                                    _fechaSeleccionada ?? DateTime.now(),
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

                        const SizedBox(width: 4),

                        // Limpiar filtro fecha
                        IconButton(
                          tooltip: 'Limpiar fecha',
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF2C3E50),
                          ),
                          onPressed: () {
                            setState(() {
                              _fechaSeleccionada = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tabla con registros
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('auditoria_general')
                              .orderBy('fecha', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final registrosFiltrados =
                            snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final usuario =
                                  (data['usuario_nombre'] ?? '')
                                      .toString()
                                      .toLowerCase();
                              final accion =
                                  (data['accion'] ?? '')
                                      .toString()
                                      .toLowerCase();
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
                                      fecha.month ==
                                          _fechaSeleccionada!.month &&
                                      fecha.day == _fechaSeleccionada!.day);

                              return (usuario.contains(_filtro) ||
                                      accion.contains(_filtro) ||
                                      detalle.contains(_filtro)) &&
                                  cumpleFecha;
                            }).toList();

                        if (registrosFiltrados.isEmpty) {
                          return const Center(
                            child: Text('No hay registros aún.'),
                          );
                        }

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(
                                      const Color(0xFF4682B4),
                                    ),
                                    headingTextStyle: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    columnSpacing: 12,
                                    columns: const [
                                      DataColumn(
                                        label: SizedBox(
                                          width: 110,
                                          child: Center(child: Text('Fecha')),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 150,
                                          child: Center(child: Text('Usuario')),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 150,
                                          child: Center(child: Text('Acción')),
                                        ),
                                      ),
                                      DataColumn(
                                        label: SizedBox(
                                          width: 350,
                                          child: Text('Detalle'),
                                        ),
                                      ),
                                    ],
                                    rows:
                                        registrosFiltrados.map((doc) {
                                          final data =
                                              doc.data()
                                                  as Map<String, dynamic>;
                                          final fecha =
                                              (data['fecha'] as Timestamp?)
                                                  ?.toDate() ??
                                              DateTime.now();
                                          final fechaStr = DateFormat(
                                            'dd/MM/yyyy HH:mm',
                                          ).format(fecha);
                                          final usuario =
                                              data['usuario_nombre'] ?? '---';
                                          final accion =
                                              data['accion'] ?? '---';
                                          final detalle = data['detalle'] ?? '';

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Center(
                                                  child: Text(
                                                    fechaStr,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Center(
                                                  child: Text(
                                                    usuario,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Center(
                                                  child: Text(
                                                    accion,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                SizedBox(
                                                  width: 350,
                                                  child: Text(
                                                    detalle,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                    softWrap: true,
                                                    maxLines: 8,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
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
