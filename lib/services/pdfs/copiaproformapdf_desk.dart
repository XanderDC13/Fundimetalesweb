import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

Future<void> generarProformaPDF(String numero, String? ciRuc) async {
  // Convertir número a int si es posible
  final numeroInt = int.tryParse(numero);

  // Una sola consulta optimizada
  final query =
      await FirebaseFirestore.instance
          .collection('proformas')
          .where('numero', isEqualTo: numeroInt ?? numero)
          .limit(1)
          .get();

  if (query.docs.isEmpty) {
    print('No se encontró la proforma con número: $numero');
    return;
  }

  final data = query.docs.first.data();

  // Cargar logo
  pw.ImageProvider? logoProvider;
  try {
    final logoBytes = await rootBundle.load('lib/assets/logoletters.png');
    logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
  } catch (e) {
    print('Error al cargar logo: $e');
  }

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape, // 👈 LANDSCAPE
      margin: const pw.EdgeInsets.all(10),
      build: (context) {
        return pw.Row(
          // 👈 ROW para dos columnas
          children: [
            // 👈 PRIMERA COPIA (IZQUIERDA)
            pw.Expanded(
              child: pw.Container(
                margin: pw.EdgeInsets.only(right: 5),
                child: pw.Column(
                  children: [
                    _buildHeader(
                      logoProvider,
                      data['numero']?.toString() ?? '',
                    ),
                    pw.SizedBox(height: 12),
                    _buildClienteInfo(
                      data['cliente']?.toString() ?? '',
                      data['ci_ruc']?.toString() ?? '',
                      data['direccion']?.toString() ?? '',
                      data['telefono']?.toString() ?? '',
                    ),
                    pw.SizedBox(height: 12),
                    _buildItemsTable(data['items'] ?? []),
                    pw.SizedBox(height: 12),
                    _buildTotalesYFormaPago(
                      data['subtotal']?.toString() ?? '0.00',
                      data['iva']?.toString() ?? '0.00',
                      data['total']?.toString() ?? '0.00',
                      data['efectivo'] ?? false,
                      data['dinero_electronico'] ?? false,
                      data['tarjeta_credito'] ?? false,
                      data['otros'] ?? false,
                    ),
                  ],
                ),
              ),
            ),

            // 👈 LÍNEA DIVISORIA
            pw.Container(
              width: 1,
              color: PdfColors.grey,
              margin: pw.EdgeInsets.symmetric(horizontal: 5),
            ),

            // 👈 SEGUNDA COPIA (DERECHA) - IDÉNTICA
            pw.Expanded(
              child: pw.Container(
                margin: pw.EdgeInsets.only(left: 5),
                child: pw.Column(
                  children: [
                    _buildHeader(
                      logoProvider,
                      data['numero']?.toString() ?? '',
                    ),
                    pw.SizedBox(height: 12),
                    _buildClienteInfo(
                      data['cliente']?.toString() ?? '',
                      data['ci_ruc']?.toString() ?? '',
                      data['direccion']?.toString() ?? '',
                      data['telefono']?.toString() ?? '',
                    ),
                    pw.SizedBox(height: 12),
                    _buildItemsTable(data['items'] ?? []),
                    pw.SizedBox(height: 12),
                    _buildTotalesYFormaPago(
                      data['subtotal']?.toString() ?? '0.00',
                      data['iva']?.toString() ?? '0.00',
                      data['total']?.toString() ?? '0.00',
                      data['efectivo'] ?? false,
                      data['dinero_electronico'] ?? false,
                      data['tarjeta_credito'] ?? false,
                      data['otros'] ?? false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

// 👇 AHORA ACTUALIZA EL _buildHeader CON TAMAÑOS REDUCIDOS
pw.Widget _buildHeader(pw.ImageProvider? logoProvider, String numeroOrden) {
  final numeroStr = numeroOrden.toString();
  return pw.Container(
    width: double.infinity,
    height: 70, // 👈 Reducido de 90
    padding: pw.EdgeInsets.symmetric(
      horizontal: 10,
      vertical: 4,
    ), // 👈 Reducido
    child: pw.Row(
      children: [
        // LOGO
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            alignment: pw.Alignment.center,
            child:
                logoProvider != null
                    ? pw.Image(logoProvider, fit: pw.BoxFit.contain)
                    : pw.Container(
                      width: 60, // 👈 Reducido
                      height: 40, // 👈 Reducido
                      color: PdfColor.fromHex('#1f4e79'),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'FN',
                        style: pw.TextStyle(
                          fontSize: 18, // 👈 Reducido
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
          ),
        ),

        // CENTRO
        pw.Expanded(
          flex: 6, // 👈 Aumentado de 4 a 6
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
                    fontSize: 11, // 👈 Reducido
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 1),
                pw.Text(
                  'JOSE ALIRIO LOPEZ MARTINEZ',
                  style: pw.TextStyle(
                    fontSize: 9, // 👈 Reducido
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
                  style: pw.TextStyle(fontSize: 7), // 👈 Reducido
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ),

        // DERECHA
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
                    fontSize: 7, // 👈 Reducido
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'P R O F O R M A',
                  style: pw.TextStyle(
                    fontSize: 7, // 👈 Reducido
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  numeroStr,
                  style: pw.TextStyle(
                    fontSize: 10, // 👈 Reducido
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    _buildFechaBox(
                      'D',
                      '${DateTime.now().day}',
                      14,
                    ), // 👈 Reducido
                    pw.SizedBox(width: 2),
                    _buildFechaBox(
                      'M',
                      '${DateTime.now().month}',
                      14,
                    ), // 👈 Reducido
                    pw.SizedBox(width: 2),
                    _buildFechaBox(
                      'A',
                      '${DateTime.now().year}',
                      18,
                    ), // 👈 Reducido
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

pw.Widget _buildFechaBox(String label, String value, double width) {
  return pw.Column(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold),
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
          style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

pw.Widget _buildClienteInfo(
  String cliente,
  String ciRuc,
  String direccion,
  String telefono,
) {
  return pw.Container(
    width: double.infinity,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey, width: 0.3),
    ),
    child: pw.Column(
      children: [
        // Primera fila: CLIENTE y C.I/RUC
        pw.Row(
          children: [
            pw.Expanded(
              flex: 3,
              child: pw.Container(
                padding: pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                  ),
                ),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'CLIENTE: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(cliente, style: pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: pw.EdgeInsets.all(6),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'C.I/RUC: ',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(ciRuc, style: pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Segunda fila: DIRECCION y TELEFONO
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'DIRECCION: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          direccion,
                          style: pw.TextStyle(fontSize: 9),
                          maxLines: 1,
                          overflow: pw.TextOverflow.clip,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(6),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'TELEFONO: ',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          telefono,
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildItemsTable(List items) {
  return pw.Container(
    width: double.infinity,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey, width: 0.3),
    ),
    child: pw.Column(
      children: [
        // Header
        pw.Container(
          decoration: pw.BoxDecoration(color: PdfColor.fromHex('#1f4e79')),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'REF.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 4,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'DESCRIPCION',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'CANT.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'V.UNIT.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Center(
                    child: pw.Text(
                      'V.TOTAL',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Items con datos
        ...items.map(
          (item) => pw.Container(
            height: 20,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        item['ref'] ?? '',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                    child: pw.Text(
                      item['descripcion'] ?? '',
                      style: pw.TextStyle(fontSize: 8),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        item['cantidad'] ?? '',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        item['v_unit'] ?? '',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    child: pw.Center(
                      child: pw.Text(
                        item['v_total'] ?? '',
                        style: pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Filas vacías para completar la tabla
        for (int i = items.length; i < 14; i++)
          pw.Container(
            height: 20,
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 1,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(flex: 1, child: pw.Container()),
              ],
            ),
          ),
      ],
    ),
  );
}

pw.Widget _buildTotalesYFormaPago(
  String subtotal,
  String iva,
  String total,
  bool efectivo,
  bool dineroElectronico,
  bool tarjetaCredito,
  bool otros,
) {
  return pw.Container(
    width: double.infinity,
    height: 90,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey, width: 0.3),
    ),
    child: pw.Row(
      children: [
        // Columna Izquierda - Forma de pago
        pw.Expanded(
          flex: 1,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header forma de pago
                pw.Container(
                  width: double.infinity,
                  height: 18,
                  padding: pw.EdgeInsets.all(2),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#1f4e79'),
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'FORMA DE PAGO',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                // Opciones de pago (ajustadas al espacio)
                pw.Expanded(
                  child: pw.Padding(
                    padding: pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        _buildOpcionPago('EFECTIVO', efectivo),
                        _buildOpcionPago(
                          'DINERO ELECTRÓNICO',
                          dineroElectronico,
                        ),
                        _buildOpcionPago(
                          'TARJETA CRÉDITO/DÉBITO',
                          tarjetaCredito,
                        ),
                        _buildOpcionPago('OTROS', otros),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Columna Centro - Firmas
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
              ),
            ),
            child: pw.Column(
              children: [
                // Parte superior - Recibí Cliente
                pw.Expanded(
                  child: pw.Container(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'RECIBÍ CLIENTE',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Container(height: 1, color: PdfColors.grey),
                      ],
                    ),
                  ),
                ),

                // Parte inferior - Firma Autorizada
                pw.Expanded(
                  child: pw.Container(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Column(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          'FIRMA AUTORIZADA',
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Columna Derecha - Totales
        pw.Expanded(
          flex: 1,
          child: pw.Column(
            children: [
              _buildCajaTotal('Sub-Total', subtotal),
              _buildCajaTotal('I.V.A. 0 %', '0.00'),
              _buildCajaTotal('I.V.A. 15 %', iva),
              _buildCajaTotal('TOTAL \$', total, isBold: true),
            ],
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildCajaTotal(String label, String value, {bool isBold = false}) {
  return pw.Expanded(
    child: pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 0.3),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );
}

pw.Widget _buildOpcionPago(String label, bool seleccionado) {
  return pw.Row(
    children: [
      pw.Container(
        width: 8,
        height: 8,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey, width: 0.3),
        ),
        child:
            seleccionado
                ? pw.Center(
                  child: pw.Text('X', style: pw.TextStyle(fontSize: 6)),
                )
                : null,
      ),
      pw.SizedBox(width: 3),
      pw.Text(label, style: pw.TextStyle(fontSize: 6)),
    ],
  );
}
