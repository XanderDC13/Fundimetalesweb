import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReporteVentasScreen extends StatefulWidget {
  const ReporteVentasScreen({super.key});

  @override
  State<ReporteVentasScreen> createState() => _ReporteVentasScreenState();
}

class _ReporteVentasScreenState extends State<ReporteVentasScreen>
    with SingleTickerProviderStateMixin {
  String _filtroCliente = '';
  String? _vendedorSeleccionado;
  List<String> _vendedoresDisponibles = [];
  DateTimeRange? _rangoFechas;

  TabController? _tabController;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargarVendedores();
      }
    });
  }

  Future<void> _cargarVendedores() async {
    try {
      final ventasSnapshot =
          await FirebaseFirestore.instance.collection('ventas').get();

      if (!mounted) return;

      final vendedores =
          ventasSnapshot.docs
              .map((doc) => doc.data()['usuario_nombre'] ?? '')
              .where((nombre) => nombre.toString().trim().isNotEmpty)
              .toSet()
              .toList();

      setState(() {
        _vendedoresDisponibles = vendedores.cast<String>();
      });
    } catch (e) {
      if (!mounted) return;
      print('Error al cargar vendedores: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar vendedores: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tabController?.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      setState(fn);
    }
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4682B4),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _safeSetState(() {
        _rangoFechas = picked;
      });
    }
  }

  void _limpiarFiltros() {
    _safeSetState(() {
      _filtroCliente = '';
      _vendedorSeleccionado = null;
      _rangoFechas = null;
    });
  }

  // Función helper para crear filas del desglose de totales
  pw.Widget _buildTotalRow(String label, double value) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFF000000)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '\$${value.toStringAsFixed(2)}',
            style: pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  Future<void> _generarPdf(
    List<Map<String, dynamic>> ventas, {
    String? titulo,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');

      final Uint8List logoBytes = await rootBundle
          .load('lib/assets/logo.png')
          .then((value) => value.buffer.asUint8List());
      final logoImage = pw.MemoryImage(logoBytes);

      for (var venta in ventas) {
        final productos = (venta['productos'] ?? []) as List;

        // Separar productos regulares de transporte
        List productosRegulares = [];
        double valorTransporte = 0.0;

        // Debug: Imprimir cada producto para verificar

        for (var item in productos) {
          final producto = item as Map<String, dynamic>;

          // Debug completo de todos los campos del producto

          producto.forEach((key, value) {});

          final categoria =
              producto['categoria']?.toString().trim().toUpperCase() ?? '';
          final codigo =
              producto['codigo']?.toString().trim().toUpperCase() ?? '';
          final nombre = producto['nombre']?.toString() ?? '';
          final referencia =
              producto['referencia']?.toString().trim().toUpperCase() ?? '';

          // Verificar si es transporte por múltiples criterios
          bool esTransporte = false;

          if (categoria == 'TRANSPORTE') {
            esTransporte = true;
          } else if (codigo.startsWith('TRA')) {
            esTransporte = true;
          } else if (referencia.startsWith('TRA')) {
            esTransporte = true;
          } else if (nombre.toUpperCase().contains('TRANSPORTE') ||
              nombre.toUpperCase().contains('EMBALAJE') ||
              nombre.toUpperCase().contains('ENVIO') ||
              nombre.toUpperCase().contains('ENVÍO')) {
            esTransporte = true;
          }

          if (esTransporte) {
            // Calcular valor del transporte (precio * cantidad)
            final precio = producto['precio'] ?? 0;
            final cantidad = producto['cantidad'] ?? 0;

            final precioDouble =
                precio is num
                    ? precio.toDouble()
                    : double.tryParse(precio.toString()) ?? 0;
            final cantidadDouble =
                cantidad is num
                    ? cantidad.toDouble()
                    : double.tryParse(cantidad.toString()) ?? 0;

            final subtotalTransporte = precioDouble * cantidadDouble;
            valorTransporte += subtotalTransporte;
          } else {
            productosRegulares.add(producto);
          }
        }

        // Calcular subtotal solo de productos regulares
        double subtotalProductosRegulares = productosRegulares.fold<double>(0, (
          sum,
          item,
        ) {
          final producto = item as Map<String, dynamic>;
          final precio = producto['precio'] ?? 0;
          final cantidad = producto['cantidad'] ?? 0;

          final precioDouble =
              precio is num
                  ? precio.toDouble()
                  : double.tryParse(precio.toString()) ?? 0;
          final cantidadDouble =
              cantidad is num
                  ? cantidad.toDouble()
                  : double.tryParse(cantidad.toString()) ?? 0;

          return sum + (precioDouble * cantidadDouble);
        });

        final tipoComprobanteRaw = venta['tipoComprobante'];
        final tipoComprobante =
            (tipoComprobanteRaw == null ||
                    tipoComprobanteRaw == '' ||
                    tipoComprobanteRaw == '---')
                ? 'Nota de Venta'
                : tipoComprobanteRaw;

        final esFactura = tipoComprobante.toLowerCase() == 'factura';

        // CÁLCULOS FINALES
        double subtotal15, subtotal0, subtotalSinImpuestos, iva, totalFinal;

        if (esFactura) {
          subtotal15 = subtotalProductosRegulares;
          subtotal0 = valorTransporte;
          subtotalSinImpuestos = subtotal15 + subtotal0;
          iva = subtotalProductosRegulares * 0.15;
          totalFinal = subtotalSinImpuestos + iva;
        } else {
          subtotal15 = 0.0;
          subtotal0 = 0.0;
          subtotalSinImpuestos = subtotalProductosRegulares + valorTransporte;
          iva = 0.0;
          totalFinal = subtotalSinImpuestos;
        }

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build:
                (context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // HEADER PROFESIONAL
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColor.fromInt(0xFF000000),
                          width: 2,
                        ),
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          // Información de la empresa
                          pw.Expanded(
                            flex: 2,
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  height: 50,
                                  width: 50,
                                  child: pw.Image(logoImage),
                                ),
                                pw.SizedBox(height: 10),
                                pw.Text(
                                  'FUNDIMETALES DEL NORTE',
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'NIT: 0401593812001',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Dirección: AV BRASIL Y PANAMA',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Teléfono: (123) 456-7890',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  'Email: ventas@tuempresa.com',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),

                          // Información del documento
                          pw.Expanded(
                            flex: 1,
                            child: pw.Container(
                              padding: const pw.EdgeInsets.all(10),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromInt(0xFFF0F0F0),
                                border: pw.Border.all(
                                  color: PdfColor.fromInt(0xFF000000),
                                ),
                              ),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    tipoComprobante.toUpperCase(),
                                    style: pw.TextStyle(
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5),
                                  pw.Text(
                                    'No. ${venta['codigo'] ?? '001'}',
                                    style: pw.TextStyle(
                                      fontSize: 12,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5),
                                  pw.Row(
                                    mainAxisSize: pw.MainAxisSize.min,
                                    children: [
                                      pw.Text(
                                        'FECHA: ',
                                        style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.Text(
                                        venta['fecha'] != null
                                            ? dateFormat.format(venta['fecha'])
                                            : 'Sin fecha',
                                        style: pw.TextStyle(fontSize: 10),
                                      ),
                                    ],
                                  ),

                                  if (esFactura) ...[
                                    pw.SizedBox(height: 5),
                                    pw.Text(
                                      'RÉGIMEN: COMÚN',
                                      style: pw.TextStyle(fontSize: 8),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 15),

                    // INFORMACIÓN DEL CLIENTE
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColor.fromInt(0xFF000000),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DATOS DEL CLIENTE',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  'CLIENTE: ${venta['cliente'] ?? 'Cliente General'}',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Expanded(
                                child: pw.Text(
                                  'VENDEDOR: ${venta['usuario_nombre'] ?? '---'}',
                                  style: pw.TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'MÉTODO DE PAGO: ${venta['metodoPago'] ?? 'Efectivo'}',
                            style: pw.TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 15),

                    // TABLA DE PRODUCTOS CON DISEÑO PROFESIONAL
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(
                          color: PdfColor.fromInt(0xFF000000),
                        ),
                      ),
                      child: pw.Table(
                        border: pw.TableBorder.all(
                          color: PdfColor.fromInt(0xFF000000),
                        ),
                        columnWidths: {
                          0: const pw.FixedColumnWidth(60), // REF
                          1: const pw.FlexColumnWidth(3), // NOMBRE
                          2: const pw.FixedColumnWidth(50), // CANT
                          3: const pw.FixedColumnWidth(80), // PRECIO
                          4: const pw.FixedColumnWidth(80), // SUBTOTAL
                        },
                        children: [
                          // Header
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xFF000000),
                            ),
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  'Cod Principal',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromInt(0xFFFFFFFF),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  'Descripción',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromInt(0xFFFFFFFF),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  'Cant',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromInt(0xFFFFFFFF),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  'Precio',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromInt(0xFFFFFFFF),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(
                                  'Total sin impuestos',
                                  style: pw.TextStyle(
                                    color: PdfColor.fromInt(0xFFFFFFFF),
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                  textAlign: pw.TextAlign.right,
                                ),
                              ),
                            ],
                          ),

                          // Productos
                          ...productos.map<pw.TableRow>((p) {
                            final producto = p as Map<String, dynamic>;
                            final precio = producto['precio'] ?? 0;
                            final cantidad = producto['cantidad'] ?? 0;
                            final precioDouble =
                                precio is num
                                    ? precio.toDouble()
                                    : double.tryParse(precio.toString()) ?? 0;
                            final cantidadInt =
                                cantidad is num
                                    ? cantidad.toInt()
                                    : int.tryParse(cantidad.toString()) ?? 0;
                            final subtotalCalculado =
                                precioDouble * cantidadInt;

                            return pw.TableRow(
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    producto['referencia'] ??
                                        producto['codigo'] ??
                                        '',
                                    style: pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    producto['nombre'] ?? '',
                                    style: pw.TextStyle(fontSize: 9),
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    cantidadInt.toString(),
                                    style: pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    '\$${precioDouble.toStringAsFixed(2)}',
                                    style: pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ),
                                pw.Container(
                                  padding: const pw.EdgeInsets.all(5),
                                  child: pw.Text(
                                    '\$${subtotalCalculado.toStringAsFixed(2)}',
                                    style: pw.TextStyle(fontSize: 9),
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    pw.SizedBox(height: 15),

                    // SECCIÓN DE TOTALES ESTILO FACTURA OFICIAL CON DESGLOSE COMPLETO
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Espacio izquierdo
                        pw.Expanded(flex: 2, child: pw.Container()),

                        // Cuadro de totales
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(
                                color: PdfColor.fromInt(0xFF000000),
                              ),
                            ),
                            child: pw.Column(
                              children: [
                                // SUBTOTAL 15% y 0% (solo si es factura)
                                if (esFactura) ...[
                                  _buildTotalRow('SUBTOTAL 15%', subtotal15),
                                  _buildTotalRow('SUBTOTAL 0%', subtotal0),
                                ],

                                // SUBTOTAL SIN IMPUESTOS
                                _buildTotalRow(
                                  'SUBTOTAL SIN IMPUESTOS',
                                  subtotalSinImpuestos,
                                ),

                                // IVA (solo si es factura)
                                if (esFactura) _buildTotalRow('IVA', iva),

                                // VALOR TOTAL
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColor.fromInt(0xFFF0F0F0),
                                    border: pw.Border(
                                      top: pw.BorderSide(
                                        color: PdfColor.fromInt(0xFF000000),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  child: pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(
                                        'VALOR TOTAL',
                                        style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                      pw.Text(
                                        '\$${totalFinal.toStringAsFixed(2)}',
                                        style: pw.TextStyle(
                                          fontSize: 11,
                                          fontWeight: pw.FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    pw.SizedBox(height: 20),

                    // INFORMACIÓN LEGAL (solo para facturas)
                    if (esFactura) ...[
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromInt(0xFF000000),
                          ),
                          color: PdfColor.fromInt(0xFFF8F8F8),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'INFORMACIÓN LEGAL',
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(
                              'Este documento incluye el 15% de IVA según la normativa vigente. Los servicios de transporte están exentos de IVA.',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Para notas de venta
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromInt(0xFF000000),
                          ),
                          color: PdfColor.fromInt(0xFFFFF8DC),
                        ),
                        child: pw.Text(
                          'NOTA DE VENTA - Este documento no tiene valor tributario. No incluye IVA.',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                    ],

                    pw.Spacer(),

                    // PIE DE PÁGINA
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(vertical: 10),
                      child: pw.Text(
                        'Gracias por su compra',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),
          ),
        );
      }

      await Printing.layoutPdf(onLayout: (format) => pdf.save());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar PDF: $e')));
      }
    }
  }

  List<Map<String, dynamic>> _filtrarVentas(
    List<Map<String, dynamic>> ventas,
    bool esFactura,
  ) {
    return ventas.where((v) {
      final esFacturaReal =
          (v['tipoComprobante'] ?? '').toString().toLowerCase() == 'factura';
      final esNotaVenta = !esFacturaReal;

      final coincideCliente = v['cliente'].toString().toLowerCase().contains(
        _filtroCliente.toLowerCase(),
      );

      final coincideVendedor =
          _vendedorSeleccionado == null ||
          _vendedorSeleccionado == v['usuario_nombre'];

      bool coincideFecha = true;
      if (_rangoFechas != null && v['fecha'] != null) {
        final fechaVenta = v['fecha'] as DateTime;
        coincideFecha =
            fechaVenta.isAfter(
              _rangoFechas!.start.subtract(const Duration(days: 1)),
            ) &&
            fechaVenta.isBefore(_rangoFechas!.end.add(const Duration(days: 1)));
      }

      return (esFactura ? esFacturaReal : esNotaVenta) &&
          coincideCliente &&
          coincideVendedor &&
          coincideFecha;
    }).toList();
  }

  Widget _buildTablaVentas(bool esFactura) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ventas')
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final todasLasVentas =
            snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {
                'cliente': data['cliente'] ?? 'Desconocido',
                'fecha': data['fecha']?.toDate(),
                'metodoPago': data['metodoPago'] ?? '---',
                'tipoComprobante': data['tipoComprobante'] ?? '---',
                'productos': data['productos'] ?? [],
                'usuario_nombre': data['usuario_nombre'] ?? '',
                'codigo': data['codigo_comprobante'] ?? 'Sin código',
                'total': data['total'] ?? 0,
              };
            }).toList();

        final ventasFiltradas = _filtrarVentas(todasLasVentas, esFactura);

        if (ventasFiltradas.isEmpty) {
          return const Center(child: Text('No hay ventas que coincidan.'));
        }

        final tipoTexto = esFactura ? 'Facturas' : 'Notas de Venta';

        return Column(
          children: [
            // Botón para imprimir todo
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed:
                    () => _generarPdf(
                      ventasFiltradas,
                      titulo: 'Reporte de $tipoTexto',
                    ),
                icon: const Icon(Icons.print),
                label: Text(
                  'Imprimir Todas las $tipoTexto (${ventasFiltradas.length})',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // Tabla
            Expanded(
              child: SingleChildScrollView(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double totalWidth = constraints.maxWidth;
                    final double anchoFecha = totalWidth * 0.14;
                    final double anchoCP = totalWidth * 0.20;
                    final double anchoVendedor = totalWidth * 0.17;
                    final double anchoCliente = totalWidth * 0.15;
                    final double anchoTotal = totalWidth * 0.15;
                    final double anchoAccion = totalWidth * 0.12;

                    return DataTable(
                      columnSpacing: 0,
                      headingRowColor: WidgetStateColor.resolveWith(
                        (states) => const Color(0xFF4682B4),
                      ),
                      headingTextStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      columns: [
                        DataColumn(
                          label: SizedBox(
                            width: anchoFecha,
                            child: const Text(
                              'Fecha',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: anchoCP,
                            child: const Text(
                              'CP',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: anchoVendedor,
                            child: const Text(
                              'Vendedor',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: anchoCliente,
                            child: const Text(
                              'Cliente',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: anchoTotal,
                            child: const Text(
                              'Total',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: SizedBox(
                            width: anchoAccion,
                            child: const Text(
                              'Acción',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                      rows:
                          ventasFiltradas.map((venta) {
                            final fecha =
                                venta['fecha'] != null
                                    ? DateFormat(
                                      'dd/MM/yy',
                                    ).format(venta['fecha'])
                                    : 'Sin fecha';

                            // ✅ USAR EL TOTAL DIRECTAMENTE DE LA BASE DE DATOS
                            final totalRaw = venta['total'] ?? 0;
                            final total =
                                totalRaw is num
                                    ? totalRaw.toDouble()
                                    : double.tryParse(totalRaw.toString()) ??
                                        0.0;

                            return DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: anchoFecha,
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        fecha,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: anchoCP,
                                    child: Center(
                                      child: Text(
                                        venta['codigo'] ?? '',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: anchoVendedor,
                                    child: Center(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          venta['usuario_nombre'] ?? '',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: anchoCliente,
                                    child: Center(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          venta['cliente'] ?? '',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: anchoTotal,
                                    child: Center(
                                      child: Text(
                                        '\$${total.toStringAsFixed(2)}',
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF4682B4),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: anchoAccion,
                                    child: Center(
                                      child: IconButton(
                                        tooltip: 'Exportar PDF',
                                        onPressed: () => _generarPdf([venta]),
                                        icon: const Icon(
                                          Icons.picture_as_pdf,
                                          size: 20,
                                          color: Color(0xFF4682B4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabController == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
              child: const Center(
                child: Text(
                  'Reporte de Ventas',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Filtros
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar por cliente...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) {
                            _safeSetState(() {
                              _filtroCliente = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _seleccionarRangoFechas,
                        icon: const Icon(Icons.date_range),
                        label: Text(_rangoFechas == null ? 'Fechas' : 'Rango'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4682B4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          value: _vendedorSeleccionado,
                          hint: const Text('Filtrar por vendedor'),
                          items:
                              _vendedoresDisponibles.map((vendedor) {
                                return DropdownMenuItem(
                                  value: vendedor,
                                  child: Text(vendedor),
                                );
                              }).toList(),
                          onChanged: (value) {
                            _safeSetState(() {
                              _vendedorSeleccionado = value;
                            });
                          },
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _limpiarFiltros,
                        icon: const Icon(Icons.clear, color: Color(0xFF4682B4)),
                        label: const Text(
                          'Limpiar',
                          style: TextStyle(color: Color((0xFF4682B4))),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFFFFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_rangoFechas != null)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info,
                            color: Color(0xFF4682B4),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filtrado del ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.start)} al ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.end)}',
                            style: const TextStyle(color: Color(0xFF4682B4)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: TabBar(
                  controller: _tabController!,
                  labelColor: const Color(0xFF4682B4),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF4682B4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF4682B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Facturas'),
                    Tab(text: 'Notas de Venta'),
                  ],
                ),
              ),
            ),

            // Contenido de las tabs
            Expanded(
              child: TabBarView(
                controller: _tabController!,
                children: [_buildTablaVentas(true), _buildTablaVentas(false)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
