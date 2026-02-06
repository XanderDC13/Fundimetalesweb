import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class ProformaPDFGenerator {
  static Future<pw.Document> generatePDF({
    required String numeroProforma,
    required String cliente,
    required String ciRuc,
    required String direccion,
    required String telefono,
    required List<Map<String, String>> items,
    required String subtotal,
    required String iva,
    required String total,
    required bool efectivo,
    required bool dineroElectronico,
    required bool tarjetaCredito,
    required bool otros,
  }) async {
    final pdf = pw.Document();

    // Cargar logo
    pw.ImageProvider? logoProvider;
    try {
      final logoBytes = await rootBundle.load('lib/assets/logoletters.png');
      logoProvider = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      print('Error al cargar logo: $e');
    }

    // Constantes para paginación
    const itemsPaginaIntermedia = 20; // Páginas sin totales
    const itemsUltimaPagina = 14; // Última página con totales

    // Calcular paginación
    int totalPaginas;
    int itemsRestantes = items.length;

    if (items.length <= itemsUltimaPagina) {
      // Solo una página
      totalPaginas = 1;
    } else {
      // Calcular cuántas intermedias necesito
      itemsRestantes = items.length - itemsUltimaPagina;
      final paginasIntermedias =
          (itemsRestantes / itemsPaginaIntermedia).ceil();
      totalPaginas = paginasIntermedias + 1; // +1 por la última
    }

    for (int pagina = 0; pagina < totalPaginas; pagina++) {
      final esUltimaPagina = (pagina == totalPaginas - 1);

      int inicio;
      int fin;

      if (esUltimaPagina) {
        // Última página: toma los items restantes
        inicio = pagina * itemsPaginaIntermedia;
        fin = items.length;
      } else {
        // Páginas intermedias: toma 20 items
        inicio = pagina * itemsPaginaIntermedia;
        fin = inicio + itemsPaginaIntermedia;
      }

      final itemsPagina = items.sublist(inicio, fin);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(10),
          build: (pw.Context context) {
            return pw.Row(
              children: [
                // Primera proforma (izquierda)
                pw.Expanded(
                  child: pw.Container(
                    margin: pw.EdgeInsets.only(right: 5),
                    child: pw.Column(
                      children: [
                        _buildHeader(logoProvider, numeroProforma),
                        pw.SizedBox(height: 12),
                        _buildClienteInfo(cliente, ciRuc, direccion, telefono),
                        pw.SizedBox(height: 12),
                        _buildItemsTable(itemsPagina),
                        if (esUltimaPagina) ...[
                          pw.SizedBox(height: 12),
                          _buildTotalesYFormaPago(
                            subtotal,
                            iva,
                            total,
                            efectivo,
                            dineroElectronico,
                            tarjetaCredito,
                            otros,
                          ),
                        ] else
                          pw.Spacer(),
                      ],
                    ),
                  ),
                ),

                // Línea divisoria vertical
                pw.Container(
                  width: 1,
                  color: PdfColors.grey,
                  margin: pw.EdgeInsets.symmetric(horizontal: 5),
                ),

                // Segunda proforma (derecha) - IDÉNTICA
                pw.Expanded(
                  child: pw.Container(
                    margin: pw.EdgeInsets.only(left: 5),
                    child: pw.Column(
                      children: [
                        _buildHeader(logoProvider, numeroProforma),
                        pw.SizedBox(height: 12),
                        _buildClienteInfo(cliente, ciRuc, direccion, telefono),
                        pw.SizedBox(height: 12),
                        _buildItemsTable(itemsPagina),
                        if (esUltimaPagina) ...[
                          pw.SizedBox(height: 12),
                          _buildTotalesYFormaPago(
                            subtotal,
                            iva,
                            total,
                            efectivo,
                            dineroElectronico,
                            tarjetaCredito,
                            otros,
                          ),
                        ] else
                          pw.Spacer(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf;
  }

  static pw.Widget _buildHeader(
    pw.ImageProvider? logoProvider,
    String numeroProforma,
  ) {
    return pw.Container(
      width: double.infinity,
      height: 70, // 🔹 Alto fijo
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

          // DERECHA: RUC, ORDEN, NÚMERO Y FECHA (20% del ancho)
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
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    numeroProforma,
                    style: pw.TextStyle(
                      fontSize: 10,
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
                      _buildFechaBox('D', '${DateTime.now().day}', 14),
                      pw.SizedBox(width: 2),
                      _buildFechaBox('M', '${DateTime.now().month}', 14),
                      pw.SizedBox(width: 2),
                      _buildFechaBox('A', '${DateTime.now().year}', 18),
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

  static pw.Widget _buildFechaBox(String label, String value, double width) {
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

  static pw.Widget _buildClienteInfo(
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
                        child: pw.Text(
                          cliente,
                          style: pw.TextStyle(fontSize: 9),
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

  static pw.Widget _buildItemsTable(List<Map<String, String>> items) {
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
                    child: pw.Center(
                      child: pw.Text(
                        'V.TOTAL',
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Items (sin filas vacías de relleno)
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
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
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
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
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
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
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
                          right: pw.BorderSide(
                            color: PdfColors.grey,
                            width: 0.3,
                          ),
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
        ],
      ),
    );
  }

  static pw.Widget _buildTotalesYFormaPago(
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
                        bottom: pw.BorderSide(
                          color: PdfColors.grey,
                          width: 0.3,
                        ),
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
                  right: pw.BorderSide(
                    color: PdfColors.grey,
                    width: 0.3,
                  ), // 🔹 Línea vertical hacia Totales
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
                          // 🔹 Línea va abajo, separando de Firma Autorizada
                          pw.Container(height: 1, color: PdfColors.grey),
                        ],
                      ),
                    ),
                  ),

                  // Parte inferior - Firma Autorizada (sin línea arriba)
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

          // Columna Derecha - Totales (cajones iguales)
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

  static pw.Widget _buildCajaTotal(
    String label,
    String value, {
    bool isBold = false,
  }) {
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

  static pw.Widget _buildOpcionPago(String label, bool seleccionado) {
    return pw.Row(
      children: [
        pw.Container(
          width: 8,
          height: 8,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
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

  static Future<void> showPreview({
    required String numeroProforma,
    required String cliente,
    required String ciRuc,
    required String direccion,
    required String telefono,
    required List<Map<String, String>> items,
    required String subtotal,
    required String iva,
    required String total,
    required bool efectivo,
    required bool dineroElectronico,
    required bool tarjetaCredito,
    required bool otros,
  }) async {
    final pdf = await generatePDF(
      numeroProforma: numeroProforma,
      cliente: cliente,
      ciRuc: ciRuc,
      direccion: direccion,
      telefono: telefono,
      items: items,
      subtotal: subtotal,
      iva: iva,
      total: total,
      efectivo: efectivo,
      dineroElectronico: dineroElectronico,
      tarjetaCredito: tarjetaCredito,
      otros: otros,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
