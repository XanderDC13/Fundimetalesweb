import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AuditoriaScreen extends StatefulWidget {
  const AuditoriaScreen({super.key});

  @override
  State<AuditoriaScreen> createState() => _AuditoriaScreenState();
}

class _AuditoriaScreenState extends State<AuditoriaScreen> {
  String _filtro = '';

  Future<void> _exportarPdf(List<QueryDocumentSnapshot> registros) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Reporte de Auditoría',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Fecha', 'User', 'Acción', 'Detalle'],
                data:
                    registros.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final fecha =
                          (data['fecha'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      final usuario = data['usuario_nombre'] ?? '---';
                      final accion = data['accion'] ?? '---';
                      final detalle = data['detalle'] ?? '';

                      return [
                        dateFormat.format(fecha),
                        usuario,
                        accion,
                        detalle,
                      ];
                    }).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
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
                      final snapshot =
                          await FirebaseFirestore.instance
                              .collection('auditoria_general')
                              .get();
                      final registros =
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

                            return usuario.contains(_filtro) ||
                                accion.contains(_filtro) ||
                                detalle.contains(_filtro);
                          }).toList();

                      if (registros.isNotEmpty) {
                        await _exportarPdf(registros);
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

            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
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
            ),

            // Lista de registros
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

                  final registros =
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

                        return usuario.contains(_filtro) ||
                            accion.contains(_filtro) ||
                            detalle.contains(_filtro);
                      }).toList();

                  if (registros.isEmpty) {
                    return const Center(
                      child: Text('No hay registros que coincidan.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: registros.length,
                    itemBuilder: (context, index) {
                      final data =
                          registros[index].data() as Map<String, dynamic>;
                      final fecha =
                          (data['fecha'] as Timestamp?)?.toDate() ??
                          DateTime.now();
                      final usuario = data['usuario_nombre'] ?? '---';
                      final accion = data['accion'] ?? '---';
                      final detalle = data['detalle'] ?? '';

                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.history),
                          title: Text('$usuario - $accion'),
                          subtitle: Text(
                            '${DateFormat('dd/MM/yyyy HH:mm').format(fecha)}\n$detalle',
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
    );
  }
}
