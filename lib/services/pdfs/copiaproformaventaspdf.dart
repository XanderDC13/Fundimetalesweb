import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

Future<void> generarProformaVentasPDF(Map<String, dynamic> proformaData) async {
  // Cargar logo
  pw.ImageProvider? logoProvider;
  try {
    final logoBytes = await rootBundle.load('lib/assets/logoletters.png');
    logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
  } catch (e) {
    print('Error al cargar logo: $e');
  }

  // Obtener fecha de la proforma
  DateTime fechaProforma = DateTime.now();
  if (proformaData['fecha'] != null) {
    if (proformaData['fecha'] is Timestamp) {
      fechaProforma = (proformaData['fecha'] as Timestamp).toDate();
    }
  }

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      build: (context) {
        return pw.Column(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildHeaderVentas(
                    logoProvider,
                    proformaData['numero'] ?? '',
                    fechaProforma,
                  ),
                  pw.SizedBox(height: 10),
                  _buildClienteInfoVentas(
                    proformaData['cliente'] ?? '',
                    proformaData['empresa'] ?? '',
                    proformaData['ruc'] ?? '',
                    proformaData['telefono'] ?? '',
                    proformaData['ciudad'] ?? '',
                    proformaData['direccion'] ?? '',
                    proformaData['correo'] ?? '',
                  ),
                  pw.SizedBox(height: 10),
                  // Información de envío si existe
                  if (_buildEnvioInfoVentas(proformaData) != null) ...[
                    _buildEnvioInfoVentas(proformaData)!,
                    pw.SizedBox(height: 10),
                  ],
                  _buildItemsTableVentas(proformaData['items'] ?? []),
                  pw.SizedBox(height: 10),
                  _buildTotalesVentas(
                    proformaData['subtotal'] ?? '0.00',
                    proformaData['iva'] ?? '0.00',
                    proformaData['total_final'] ?? '0.00',
                    proformaData['aplicar_iva'] ?? false,
                    proformaData['subtotal_0'] ?? '0.00',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  // Mostrar / imprimir PDF
  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

pw.Widget _buildHeaderVentas(
  pw.ImageProvider? logoProvider,
  String numeroProforma,
  DateTime fecha,
) {
  return pw.Container(
    width: double.infinity,
    height: 70,
    padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: pw.Row(
      children: [
        // IZQUIERDA: LOGO (20% del ancho)
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            alignment: pw.Alignment.center,
            child:
                logoProvider != null
                    ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                    : pw.Container(
                      width: 60,
                      height: 40,
                      color: PdfColor.fromHex('#1f4e79'),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'FN',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
          ),
        ),

        // CENTRO: INFORMACIÓN DE LA EMPRESA (60% del ancho)
        pw.Expanded(
          flex: 6,
          child: pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'FUNDIMETALES DEL NORTE',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  'JOSE ALIRIO LOPEZ MARTINEZ',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  'Fábrica de Campanas o Tambores para frenos de Automotores',
                  style: pw.TextStyle(fontSize: 6),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'en todas las marcas y modelos - Fabricamos toda clase de adaptaciones',
                  style: pw.TextStyle(fontSize: 6),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  'Direc.: Brasil y Panamá - Telf.: 0979230282 - Tulcán - Ecuador',
                  style: pw.TextStyle(fontSize: 7),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // DERECHA: RUC, PROFORMA, NÚMERO Y FECHA (20% del ancho)
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            alignment: pw.Alignment.center,
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'RUC. 0401563812001',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'P R O F O R M A',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  numeroProforma,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    _buildFechaBoxVentas('D', '${fecha.day}', 14),
                    pw.SizedBox(width: 2),
                    _buildFechaBoxVentas('M', '${fecha.month}', 14),
                    pw.SizedBox(width: 2),
                    _buildFechaBoxVentas('A', '${fecha.year}', 18),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildFechaBoxVentas(String label, String value, double width) {
  return pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
      pw.Container(
        width: width,
        height: 9,
        alignment: pw.Alignment.center,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey, width: 0.3),
        ),
        child: pw.Text(
          value,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

pw.Widget _buildClienteInfoVentas(
  String cliente,
  String nombreComercial, 
  String ciRuc,
  String telefono,
  String ciudad, 
  String direccion,
  String correo, 
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
          'INFORMACIÓN DEL CLIENTE',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 4),

        // FILA 1: Cliente y Empresa
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Cliente: $cliente',
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                'Empresa: $nombreComercial',
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // FILA 2: RUC y Teléfono
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'C.I/RUC: $ciRuc',
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                'Teléfono: $telefono',
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // FILA 3: Ciudad y Dirección
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                'Ciudad: $ciudad',
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                'Dirección: $direccion',
                style: pw.TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 3),

        // FILA 4: Correo (ancho completo)
        pw.Text('Correo: $correo', style: pw.TextStyle(fontSize: 9)),
      ],
    ),
  );
}

pw.Widget? _buildEnvioInfoVentas(Map<String, dynamic> proformaData) {
  String transporte = proformaData['transporte']?.toString() ?? '';
  String destino = proformaData['destino']?.toString() ?? '';
  String transportista = proformaData['transportista']?.toString() ?? '';
  String fechaEnvio = proformaData['fecha_envio']?.toString() ?? '';

  // Verificar si hay al menos un campo con información
  bool tieneInfoEnvio =
      transporte.trim().isNotEmpty ||
      destino.trim().isNotEmpty ||
      transportista.trim().isNotEmpty ||
      fechaEnvio.trim().isNotEmpty;

  if (!tieneInfoEnvio) {
    return null;
  }

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
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 3),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (transporte.trim().isNotEmpty)
                    pw.Text(
                      'Transporte: $transporte',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  if (transporte.trim().isNotEmpty) pw.SizedBox(height: 2),
                  if (fechaEnvio.trim().isNotEmpty)
                    pw.Text(
                      'Fecha de Envío: $fechaEnvio',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (destino.trim().isNotEmpty)
                    pw.Text(
                      'Destino: $destino',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  if (destino.trim().isNotEmpty &&
                      transportista.trim().isNotEmpty)
                    pw.SizedBox(height: 2),
                  if (transportista.trim().isNotEmpty)
                    pw.Text(
                      'Transportista: $transportista',
                      style: pw.TextStyle(fontSize: 9),
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

pw.Widget _buildItemsTableVentas(List items) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey300),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Column(
      children: [
        // Header
        pw.Container(
          padding: pw.EdgeInsets.all(5),
          color: PdfColor.fromHex('#f8f9fa'),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'CÓDIGO',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  'DESCRIPCIÓN',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'CANT.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'P. UNIT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'TOTAL',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Items con datos
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
                    item['codigo'] ?? '',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    item['descripcion'] ?? '',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    item['cantidad'] ?? '',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '\$${item['precio'] ?? '0.00'}',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    '\$${item['total'] ?? '0.00'}',
                    style: pw.TextStyle(fontSize: 9),
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

pw.Widget _buildTotalesVentas(
  String subtotal,
  String iva,
  String total,
  bool aplicarIva,
  String subtotal0, // Agregar este parámetro
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
                pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 9)),
                pw.Text('\$$subtotal', style: pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal 0%:', style: pw.TextStyle(fontSize: 9)),
                pw.Text(
                  '\$$subtotal0',
                  style: pw.TextStyle(fontSize: 9),
                ), // Usar subtotal0 aquí
              ],
            ),
            pw.SizedBox(height: 3),
            // Solo mostrar IVA si está habilitado
            if (aplicarIva) ...[
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('(+) 15% IVA:', style: pw.TextStyle(fontSize: 9)),
                  pw.Text('\$$iva', style: pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.SizedBox(height: 3),
            ],
            pw.Container(
              padding: pw.EdgeInsets.symmetric(vertical: 2),
              color: PdfColor.fromHex('#fff3cd'),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL:',
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    '\$$total',
                    style: pw.TextStyle(
                      fontSize: 9,
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
