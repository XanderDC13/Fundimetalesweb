import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ProformasGuardadasDeskScreen extends StatefulWidget {
  const ProformasGuardadasDeskScreen({super.key});

  @override
  State<ProformasGuardadasDeskScreen> createState() =>
      _ProformasGuardadasDeskScreenState();
}

class _ProformasGuardadasDeskScreenState
    extends State<ProformasGuardadasDeskScreen> {
  String _busqueda = '';
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  Future<void> _seleccionarFechaInicio() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaInicio) {
      setState(() => _fechaInicio = picked);
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaFin) {
      setState(() => _fechaFin = picked);
    }
  }

  void _limpiarFiltro() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _busqueda = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA
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
                      'Proformas Guardadas',
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

          // ✅ BARRA DE FILTROS
Container(
  color: Colors.white, // <- Esto asegura fondo blanco
  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 20),
  child: Column(
    children: [
      TextField(
        onChanged: (value) =>
            setState(() => _busqueda = value.toLowerCase()),
        decoration: InputDecoration(
          labelText: 'Buscar por cliente o número',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      const SizedBox(height: 16),
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
            onPressed: _limpiarFiltro,
            icon: const Icon(Icons.clear, color: Color(0xFF4682B4)),
            tooltip: 'Limpiar filtro',
          ),
        ],
      ),
    ],
  ),
),


          // ✅ CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildProformasList('proformasventas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProformasList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(collection)
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar proformas: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs =
            snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final numero = (data['numero'] ?? '').toString().toLowerCase();
              final cliente = (data['cliente'] ?? '').toString().toLowerCase();
              final fecha =
                  (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();

              final coincideBusqueda =
                  numero.contains(_busqueda) || cliente.contains(_busqueda);
              final coincideFecha =
                  (_fechaInicio == null ||
                      fecha.isAfter(
                        _fechaInicio!.subtract(const Duration(days: 1)),
                      )) &&
                  (_fechaFin == null ||
                      fecha.isBefore(_fechaFin!.add(const Duration(days: 1))));

              return coincideBusqueda && coincideFecha;
            }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay proformas guardadas.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Las proformas de ventas aparecerán aquí.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final numero = data['numero'] ?? 'Sin número';
            final cliente = data['cliente'] ?? 'Cliente no definido';
            final fecha =
                (data['fecha'] as Timestamp?)?.toDate() ?? DateTime.now();

            return GestureDetector(
              onTap: () => _vistaPrevia(data),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: Color(0xFF4682B4),
                      size: 36,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                numero,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Ventas',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Cliente: $cliente',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Fecha: ${fecha.toLocal().toString().split('.')[0]}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.download,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () => _descargarPDF(context, data),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // VISTA PREVIA PDF
  void _vistaPrevia(Map<String, dynamic> data) async {
    // Generar PDF desde datos
    final pdf = await _generarPDFDesdeData(data);

    // Mostrar en vista previa
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  // DESCARGAR O COMPARTIR PDF
  Future<void> _descargarPDF(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Generar PDF desde datos
      final pdf = await _generarPDFDesdeData(data);
      final pdfBytes = await pdf.save();

      // Cerrar indicador
      Navigator.of(context).pop();

      // Compartir PDF
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${data['numero'] ?? 'proforma'}.pdf',
      );
    } catch (e) {
      // Cerrar indicador si hay error
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al generar PDF: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<pw.Document> _generarPDFDesdeData(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Extraer datos de la base de datos
    final numero = data['numero'] ?? 'Sin número';
    final cliente = data['cliente'] ?? 'Cliente no definido';
    final ruc = data['ruc'] ?? '';
    final telefono = data['telefono'] ?? '';
    final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
    final fechaTimestamp = data['fecha'] as Timestamp?;
    final fecha =
        fechaTimestamp != null ? fechaTimestamp.toDate() : DateTime.now();
    final subtotalCero =
        double.tryParse(data['subtotal_0']?.toString() ?? '0.00') ?? 0.0;

    final transporte = data['transporte'] ?? '';
    final destino = data['destino'] ?? '';
    final fechaEnvio = data['fecha_envio'] ?? '';
    final transportista = data['transportista'] ?? '';

    // Calcular totales
    double subtotal = 0.0;
    for (var item in items) {
      final total = double.tryParse(item['total']?.toString() ?? '0') ?? 0.0;
      subtotal += total;
    }

    final iva = subtotal * 0.15;
    final totalFinal = subtotal + subtotalCero + iva;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFHeader(numero, fecha),
                    pw.SizedBox(height: 10),
                    _buildPDFClienteInfo(cliente, ruc, telefono),
                    pw.SizedBox(height: 10),
                    _buildPDFEnvioInfo(
                      transporte,
                      destino,
                      fechaEnvio,
                      transportista,
                    ),
                    pw.SizedBox(height: 10),
                    _buildPDFItemsTable(items),
                    pw.SizedBox(height: 10),
                    _buildPDFTotales(subtotal, subtotalCero, iva, totalFinal),
                    pw.SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFHeader(String numero, DateTime fecha) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(8),
            color: PdfColor.fromHex('#4682B4'),
            child: pw.Text(
              'COTIZACIÓN',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(6),
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Column(
              children: [
                pw.Text(
                  'FUNDIMETALES DEL NORTE',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(numero, style: pw.TextStyle(fontSize: 8)),
                pw.Text(
                  'Dirección: Av Brasil y Panamá - (Tulcán Ecuador) - telf: 2962017',
                  style: pw.TextStyle(fontSize: 7),
                ),
                pw.Text(
                  'Fecha: ${fecha.day}/${fecha.month}/${fecha.year}',
                  style: pw.TextStyle(fontSize: 7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFClienteInfo(String cliente, String ruc, String telefono) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL CLIENTE',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Cliente: $cliente',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text('RUC: $ruc', style: pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nombre Comercial: ',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Teléfono: $telefono',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFEnvioInfo(
    String transporte,
    String destino,
    String fechaEnvio,
    String transportista,
  ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DE ENVÍO',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Transporte: $transporte',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Fecha de Envío: $fechaEnvio',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Destino: $destino',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Transportista: $transportista',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFItemsTable(List<Map<String, dynamic>> items) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.all(4),
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'CÓDIGO',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'DESCRIPCIÓN',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'CANT.',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'P. UNIT',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => pw.Container(
              padding: pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item['codigo']?.toString() ?? '',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item['descripcion']?.toString() ?? '',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item['cantidad']?.toString() ?? '',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item['precio']?.toString() ?? '0'}',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item['total']?.toString() ?? '0'}',
                      style: pw.TextStyle(fontSize: 6),
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

  pw.Widget _buildPDFTotales(
    double subtotal,
    double subtotalCero,
    double iva,
    double totalFinal,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 140,
          padding: pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal 0%:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(
                    '\$${subtotalCero.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('(+) 15% IVA:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(
                    '\$${iva.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 2),
                color: PdfColor.fromHex('#fff3cd'),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '\$${totalFinal.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
