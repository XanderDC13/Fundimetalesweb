import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

Future<void> generarOrdenPDF(String numero, String? ciRuc) async {
  // Convertir número a int si es posible
  final numeroInt = int.tryParse(numero);

  // Una sola consulta optimizada
  final query =
      await FirebaseFirestore.instance
          .collection('ordenes_despacho')
          .where('numero', isEqualTo: numeroInt ?? numero)
          .limit(1)
          .get();

  if (query.docs.isEmpty) {
    print('No se encontró la orden de despacho con número: $numero');
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

  // 👇 LÓGICA DE PAGINACIÓN
  final items = data['items'] ?? [];
  const itemsPaginaIntermedia = 20;
  const itemsUltimaPagina = 16;

  int totalPaginas;
  if (items.length <= itemsUltimaPagina) {
    totalPaginas = 1;
  } else {
    final itemsRestantes = items.length - itemsUltimaPagina;
    final paginasIntermedias = (itemsRestantes / itemsPaginaIntermedia).ceil();
    totalPaginas = paginasIntermedias + 1;
  }

  // 👇 BUCLE PARA CADA PÁGINA
  for (int pagina = 0; pagina < totalPaginas; pagina++) {
    final esUltimaPagina = (pagina == totalPaginas - 1);

    int inicio;
    int fin;

    if (esUltimaPagina) {
      inicio = pagina * itemsPaginaIntermedia;
      fin = items.length;
    } else {
      inicio = pagina * itemsPaginaIntermedia;
      fin = inicio + itemsPaginaIntermedia;
    }

    final itemsPagina = items.sublist(inicio, fin);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(10),
        build: (context) {
          return pw.Row(
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
                        data['email']?.toString() ?? '',
                        data['telefono']?.toString() ?? '',
                        data['direccion']?.toString() ?? '',
                        data['ciudad']?.toString() ?? '',
                      ),
                      pw.SizedBox(height: 12),
                      _buildLeyenda(),
                      pw.SizedBox(height: 8),
                      _buildItemsTable(itemsPagina),
                      pw.Spacer(),
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
                        data['email']?.toString() ?? '',
                        data['telefono']?.toString() ?? '',
                        data['direccion']?.toString() ?? '',
                        data['ciudad']?.toString() ?? '',
                      ),
                      pw.SizedBox(height: 12),
                      _buildLeyenda(),
                      pw.SizedBox(height: 8),
                      _buildItemsTable(itemsPagina),
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

  await Printing.layoutPdf(onLayout: (format) async => pdf.save());
}

pw.Widget _buildHeader(pw.ImageProvider? logoProvider, String numeroOrden) {
  return pw.Container(
    width: double.infinity,
    height: 70,
    padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    child: pw.Row(
      children: [
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
                  'ORDEN DE DESPACHO',
                  style: pw.TextStyle(
                    fontSize: 7,
                    fontWeight: pw.FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  numeroOrden,
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
  String email,
  String telefono,
  String direccion,
  String ciudad,
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
                padding: pw.EdgeInsets.all(4),
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
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(cliente, style: pw.TextStyle(fontSize: 8)),
                    ),
                  ],
                ),
              ),
            ),
            pw.Expanded(
              flex: 2,
              child: pw.Container(
                padding: pw.EdgeInsets.all(4),
                child: pw.Row(
                  children: [
                    pw.Text(
                      'C.I/RUC: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Text(ciRuc, style: pw.TextStyle(fontSize: 8)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Segunda fila: EMAIL y TELEFONO
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'EMAIL: ',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(email, style: pw.TextStyle(fontSize: 8)),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'TELEFONO: ',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          telefono,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Tercera fila: CIUDAD y DIRECCION
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey, width: 0.3),
            ),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                      right: pw.BorderSide(color: PdfColors.grey, width: 0.3),
                    ),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'CIUDAD: ',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          ciudad,
                          style: pw.TextStyle(fontSize: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  padding: pw.EdgeInsets.all(4),
                  height: 24, // Altura fija para múltiples líneas
                  child: pw.Row(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start, // Alinear arriba
                    children: [
                      pw.Text(
                        'DIRECCION: ',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Text(
                          direccion,
                          style: pw.TextStyle(fontSize: 8),
                          maxLines: 3, // Permitir hasta 3 líneas
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

pw.Widget _buildLeyenda() {
  return pw.Container(
    width: double.infinity,
    padding: pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Center(
      child: pw.Text(
        'DESPACHAMOS A USTEDES LOS SIGUIENTES ARTICULOS',
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
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
                        fontSize: 8,
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
                        fontSize: 8,
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
                  child: pw.Center(
                    child: pw.Text(
                      'DESCRIPCION DEL ARTICULO',
                      style: pw.TextStyle(
                        fontSize: 8,
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
        // Items con datos
        ...items.map(
          (item) => pw.Container(
            height: 18,
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
                        style: pw.TextStyle(fontSize: 7),
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
                        item['cantidad'] ?? '',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: pw.EdgeInsets.all(2),
                    child: pw.Text(
                      item['descripcion'] ?? '',
                      style: pw.TextStyle(fontSize: 7),
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
