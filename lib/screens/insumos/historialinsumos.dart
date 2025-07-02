import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class HistorialInsumosWidget extends StatefulWidget {
  const HistorialInsumosWidget({super.key});

  @override
  State<HistorialInsumosWidget> createState() => _HistorialInsumosWidgetState();
}

class _HistorialInsumosWidgetState extends State<HistorialInsumosWidget> {
  String _formatearFecha(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Future<String> _obtenerNombreInsumo(String insumoId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('inventario_insumos')
            .doc(insumoId)
            .get();
    return doc.exists
        ? (doc['nombre'] ?? 'Insumo desconocido')
        : 'Insumo eliminado';
  }

  Future<String> _obtenerNombreEmpleado(String empleadoId) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(empleadoId)
            .get();
    return doc.exists
        ? (doc['nombre'] ?? 'Empleado desconocido')
        : 'Empleado eliminado';
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('solicitudes_insumos')
            .orderBy('fecha', descending: true)
            .get();

    if (querySnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay historial para exportar.')),
        );
      }
      return;
    }

    final lista = await Future.wait(
      querySnapshot.docs.map((doc) async {
        final cantidad = doc['cantidad'] ?? 0;
        final insumoId = doc['insumo_id'] ?? '';
        final empleadoId = doc['empleado_id'] ?? '';
        final fecha = (doc['fecha'] as Timestamp?)?.toDate();
        final nombreInsumo = await _obtenerNombreInsumo(insumoId);
        final nombreEmpleado = await _obtenerNombreEmpleado(empleadoId);
        final fechaTexto =
            fecha != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
                : 'Fecha desconocida';

        return {
          'insumo': nombreInsumo,
          'empleado': nombreEmpleado,
          'cantidad': cantidad,
          'fecha': fechaTexto,
        };
      }).toList(),
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Historial de Solicitudes de Insumos',
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
                headers: ['Insumo', 'Cantidad', 'Empleado', 'Fecha'],
                data:
                    lista.map((item) {
                      return [
                        item['insumo'],
                        item['cantidad'].toString(),
                        item['empleado'],
                        item['fecha'],
                      ];
                    }).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total de solicitudes: ${lista.length}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> _eliminarSolicitud(
    String docId,
    String insumoId,
    int cantidad,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Solicitud'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta solicitud? El stock será devuelto al inventario.',
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final insumoRef = FirebaseFirestore.instance
          .collection('inventario_insumos')
          .doc(insumoId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final insumoSnapshot = await transaction.get(insumoRef);

        if (!insumoSnapshot.exists) {
          throw Exception('Insumo no encontrado para devolución de stock.');
        }

        final stockActual = (insumoSnapshot['cantidad'] ?? 0) as int;

        transaction.update(insumoRef, {'cantidad': stockActual + cantidad});

        transaction.delete(
          FirebaseFirestore.instance
              .collection('solicitudes_insumos')
              .doc(docId),
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitud eliminada y stock devuelto')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('solicitudes_insumos')
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay historial registrado'));
        }

        final movimientos = snapshot.data!.docs;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton.icon(
                onPressed: _exportarPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Exportar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: movimientos.length,
                itemBuilder: (context, index) {
                  final mov = movimientos[index];
                  final cantidad = mov['cantidad'] ?? 0;
                  final insumoId = mov['insumo_id'] ?? '';
                  final empleadoId = mov['empleado_id'] ?? '';
                  final fechaTimestamp = mov['fecha'] as Timestamp?;
                  final docId = mov.id;

                  final fechaTexto =
                      fechaTimestamp != null
                          ? _formatearFecha(fechaTimestamp)
                          : 'Fecha desconocida';

                  return FutureBuilder<Map<String, String>>(
                    future: Future.wait([
                      _obtenerNombreInsumo(insumoId),
                      _obtenerNombreEmpleado(empleadoId),
                    ]).then(
                      (valores) => {
                        'insumo': valores[0],
                        'empleado': valores[1],
                      },
                    ),
                    builder: (context, snapshotNombres) {
                      if (!snapshotNombres.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(8),
                          child: LinearProgressIndicator(),
                        );
                      }

                      final nombreInsumo = snapshotNombres.data!['insumo']!;
                      final nombreEmpleado = snapshotNombres.data!['empleado']!;

                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(
                            Icons.assignment_turned_in,
                            color: Color(0xFF4682B4),
                            size: 32,
                          ),
                          title: Text(
                            nombreInsumo,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Cantidad: $cantidad\nEmpleado: $nombreEmpleado\nFecha: $fechaTexto',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Eliminar solicitud',
                            onPressed:
                                () => _eliminarSolicitud(
                                  docId,
                                  insumoId,
                                  cantidad,
                                ),
                          ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
