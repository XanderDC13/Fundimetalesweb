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

  String _generarCodigoComprobante(Map<String, dynamic> venta, int index) {
    final tipoComprobante = venta['tipoComprobante'] ?? '';
    final prefijo = tipoComprobante.toLowerCase() == 'factura' ? 'FAC' : 'NV';
    final numero = (index + 1).toString().padLeft(6, '0');
    return '$prefijo-$numero';
  }

  Future<void> _generarPdf(
    List<Map<String, dynamic>> ventas, {
    String? titulo,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy - HH:mm');

      final Uint8List logoBytes = await rootBundle
          .load('lib/assets/logo.png')
          .then((value) => value.buffer.asUint8List());
      final logoImage = pw.MemoryImage(logoBytes);

      for (var venta in ventas) {
        final productos = (venta['productos'] ?? []) as List;

        double subtotal = 0;
        for (var item in productos) {
          final p = item as Map<String, dynamic>;
          final sub = p['subtotal'];
          final valor =
              sub is num
                  ? sub.toDouble()
                  : double.tryParse(sub.toString()) ?? 0;
          subtotal += valor;
        }

        final tipoComprobanteRaw = venta['tipoComprobante'];
        final tipoComprobante =
            (tipoComprobanteRaw == null ||
                    tipoComprobanteRaw == '' ||
                    tipoComprobanteRaw == '---')
                ? 'Nota de Venta'
                : tipoComprobanteRaw;

        final total =
            tipoComprobante.toLowerCase() == 'factura'
                ? subtotal * 1.15
                : subtotal;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build:
                (context) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              titulo ?? tipoComprobante,
                              style: pw.TextStyle(
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromInt(0xFF4682B4),
                              ),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text('Cliente: ${venta['cliente'] ?? '---'}'),
                            pw.Text(
                              'Vendedor: ${venta['usuario_nombre'] ?? '---'}',
                            ),
                            pw.Text(
                              'Fecha: ${venta['fecha'] != null ? dateFormat.format(venta['fecha']) : 'Sin fecha'}',
                            ),
                            pw.Text(
                              'Método de Pago: ${venta['metodoPago'] ?? '---'}',
                            ),
                            pw.Text('Tipo Comprobante: $tipoComprobante'),
                            pw.Text('Código: ${venta['codigo'] ?? '---'}'),
                          ],
                        ),
                        pw.Container(
                          height: 60,
                          width: 60,
                          child: pw.Image(logoImage),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 20),
                    pw.Table.fromTextArray(
                      headerDecoration: pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF4682B4),
                      ),
                      headerStyle: pw.TextStyle(
                        color: PdfColor.fromInt(0xFFFFFFFF),
                        fontWeight: pw.FontWeight.bold,
                      ),
                      border: pw.TableBorder.all(
                        color: PdfColor.fromInt(0xFF4682B4),
                      ),
                      headers: ['Ref', 'Nombre', 'Cant', 'Precio', 'Subtotal'],
                      data:
                          productos.map<List<String>>((p) {
                            final producto = p as Map<String, dynamic>;
                            return [
                              producto['referencia'] ?? '',
                              producto['nombre'] ?? '',
                              producto['cantidad'].toString(),
                              '\$${(producto['precio'] ?? 0).toStringAsFixed(2)}',
                              '\$${(producto['subtotal'] ?? 0).toStringAsFixed(2)}',
                            ];
                          }).toList(),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColor.fromInt(0xFF4682B4),
                          ),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Text(
                          'TOTAL: \$${total.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 16,
                            color: PdfColor.fromInt(0xFF4682B4),
                          ),
                        ),
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
              };
            }).toList();

        final ventasFiltradas = _filtrarVentas(todasLasVentas, esFactura);

        // Agregar códigos de comprobante
        for (int i = 0; i < ventasFiltradas.length; i++) {
          ventasFiltradas[i]['codigo'] = _generarCodigoComprobante(
            ventasFiltradas[i],
            i,
          );
        }

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
                    headingRowColor: MaterialStateColor.resolveWith(
                      (states) => const Color(0xFF4682B4),
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    //border: TableBorder.all(
                    //color: Colors.grey.withOpacity(0.3),
                    //width: 1,
                    //),
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
                          child: const Text('CP', textAlign: TextAlign.center),
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
                          final tipoComprobante =
                              venta['tipoComprobante'] ?? '---';
                          final subtotal = (venta['productos'] as List).fold<
                            double
                          >(0, (sum, item) {
                            final producto = item as Map<String, dynamic>;
                            final precio = producto['precio'] ?? 0;
                            final cantidad = producto['cantidad'] ?? 0;
                            final sub =
                                (precio is num
                                    ? precio.toDouble()
                                    : double.tryParse(precio.toString()) ?? 0) *
                                (cantidad is num
                                    ? cantidad.toDouble()
                                    : double.tryParse(cantidad.toString()) ??
                                        0);
                            return sum + sub;
                          });
                          final total =
                              tipoComprobante.toLowerCase() == 'factura'
                                  ? subtotal * 1.15
                                  : subtotal;

                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: anchoFecha,
                                  child: Container(
                                    alignment:
                                        Alignment
                                            .center, // Usar Container con alignment
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
