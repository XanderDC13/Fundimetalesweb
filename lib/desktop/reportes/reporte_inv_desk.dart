import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class ReporteInventarioDeskScreen extends StatefulWidget {
  const ReporteInventarioDeskScreen({super.key});

  @override
  _ReporteInventarioDeskScreenState createState() =>
      _ReporteInventarioDeskScreenState();
}

class _ReporteInventarioDeskScreenState
    extends State<ReporteInventarioDeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filtroTexto = '';
  DateTimeRange? _rangoFechas;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Función para convertir fecha con seguridad
  DateTime? parseFechaCampo(dynamic fechaCampo) {
    if (fechaCampo is Timestamp) {
      return fechaCampo.toDate();
    } else if (fechaCampo is String) {
      try {
        return DateTime.parse(fechaCampo);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  pw.MultiPage buildReporteInventarioPDF({
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

  // Nueva lógica: Obtener productos de la colección productos
  Future<Map<String, Map<String, dynamic>>> _getProductos() async {
    final productosSnapshot =
        await FirebaseFirestore.instance.collection('productos').get();

    final productos = <String, Map<String, dynamic>>{};
    print('=== PRODUCTOS CARGADOS ===');
    for (var doc in productosSnapshot.docs) {
      final data = doc.data();
      // Usar la referencia como clave en lugar del ID del documento
      final referencia = data['referencia'] ?? doc.id;
      productos[referencia] = data;
      print('Referencia: $referencia, Datos: $data');
    }
    print('Total productos: ${productos.length}');
    print('========================');
    return productos;
  }

  // Nueva lógica: Obtener entradas de las subcolecciones
  Future<List<Map<String, dynamic>>> _getEntradasFromSubcolecciones(
    List<String> subcolecciones,
    Map<String, Map<String, dynamic>> productos,
  ) async {
    List<Map<String, dynamic>> todasLasEntradas = [];

    for (String subcoleccion in subcolecciones) {
      try {
        // Acceder a la subcolección de productos dentro del documento de cada área
        final productosSubcoleccionRef = FirebaseFirestore.instance
            .collection('inventarios')
            .doc(subcoleccion) // bodega, bruto, fundicion, etc.
            .collection('productos'); // Subcolección de productos

        // Obtener los documentos de productos
        final productosSubcoleccion = await productosSubcoleccionRef.get();

        for (var productoDoc in productosSubcoleccion.docs) {
          final data = productoDoc.data();
          final productoId = productoDoc.id;

          // Debug: imprimir información del producto
          print('Producto ID en inventario: $productoId');
          print('Datos del inventario: $data');

          // Buscar el producto por referencia en lugar de por ID
          // El productoId debería ser la referencia del producto
          final infoProducto = productos[productoId] ?? {};
          print('Info producto encontrada: $infoProducto');

          final entradaCompleta = {
            ...data,
            'nombre': infoProducto['nombre'] ?? 'Producto no encontrado',
            'referencia':
                infoProducto['referencia'] ??
                productoId, // usar el productoId como referencia si no se encuentra
            'subcoleccion': subcoleccion,
          };

          print('Entrada completa: $entradaCompleta');
          print('---');

          // Aplicar filtros
          final nombre =
              (entradaCompleta['nombre'] ?? '').toString().toLowerCase();
          final referencia =
              (entradaCompleta['referencia'] ?? '').toString().toLowerCase();
          final textoCoincide =
              nombre.contains(_filtroTexto.toLowerCase()) ||
              referencia.contains(_filtroTexto.toLowerCase());

          // Para el filtro de fechas, usar 'ultima_actualizacion' o 'ultima_venta'
          DateTime? fecha;
          if (entradaCompleta['ultima_actualizacion'] != null) {
            fecha = parseFechaCampo(entradaCompleta['ultima_actualizacion']);
          } else if (entradaCompleta['ultima_venta'] != null) {
            // Si ultima_venta es un string, parsearlo
            final ultimaVentaStr = entradaCompleta['ultima_venta'].toString();
            try {
              fecha = DateTime.parse(ultimaVentaStr);
            } catch (_) {
              fecha = null;
            }
          }

          bool cumpleFiltroFecha = true;
          if (_rangoFechas != null && fecha != null) {
            cumpleFiltroFecha =
                fecha.isAfter(_rangoFechas!.start) &&
                fecha.isBefore(_rangoFechas!.end.add(const Duration(days: 1)));
          }

          if (textoCoincide && cumpleFiltroFecha) {
            todasLasEntradas.add(entradaCompleta);
          }
        }
      } catch (e) {
        print('Error obteniendo datos de subcolección $subcoleccion: $e');
        // Agregar más información de debug
        print(
          'Estructura esperada: inventarios/$subcoleccion/productos/[producto_id]',
        );
      }
    }

    // Ordenar por fecha (más reciente primero)
    todasLasEntradas.sort((a, b) {
      DateTime? fechaA;
      DateTime? fechaB;

      // Para a
      if (a['ultima_actualizacion'] != null) {
        fechaA = parseFechaCampo(a['ultima_actualizacion']);
      } else if (a['ultima_venta'] != null) {
        try {
          fechaA = DateTime.parse(a['ultima_venta'].toString());
        } catch (_) {
          fechaA = null;
        }
      }

      // Para b
      if (b['ultima_actualizacion'] != null) {
        fechaB = parseFechaCampo(b['ultima_actualizacion']);
      } else if (b['ultima_venta'] != null) {
        try {
          fechaB = DateTime.parse(b['ultima_venta'].toString());
        } catch (_) {
          fechaB = null;
        }
      }

      if (fechaA == null && fechaB == null) return 0;
      if (fechaA == null) return 1;
      if (fechaB == null) return -1;
      return fechaB.compareTo(fechaA);
    });

    return todasLasEntradas;
  }

  // ✅ SOLUCIÓN ALTERNATIVA: Usar FutureBuilder en lugar de StreamBuilder
  Widget _buildTabla(String tipo) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      // ✅ Usar Future en lugar de Stream para evitar el problema de múltiples listeners
      future: _getEntradasFuture(tipo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No hay registros.'));
        }

        final entradas = snapshot.data!;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateColor.resolveWith(
                    (states) => const Color(0xFF4682B4),
                  ),
                  columnSpacing: 16,
                  dataRowMinHeight: 48,
                  dataRowMaxHeight: 72,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Fecha',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Referencia',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Nombre',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Cantidad',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows:
                      entradas.map((entrada) {
                        DateTime? fecha;

                        // Usar ultima_actualizacion o ultima_venta para mostrar la fecha
                        if (entrada['ultima_actualizacion'] != null) {
                          fecha = parseFechaCampo(
                            entrada['ultima_actualizacion'],
                          );
                        } else if (entrada['ultima_venta'] != null) {
                          try {
                            fecha = DateTime.parse(
                              entrada['ultima_venta'].toString(),
                            );
                          } catch (_) {
                            fecha = null;
                          }
                        }

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                fecha != null
                                    ? fecha.toLocal().toString().split(' ')[0]
                                    : '-',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${entrada['referencia'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DataCell(
                              Text(
                                '${entrada['nombre'] ?? '-'}',
                                style: const TextStyle(fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                            ),
                            DataCell(
                              Center(
                                child: Text(
                                  '${entrada['cantidad'] ?? 0}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ✅ NUEVA FUNCIÓN: Versión Future de _getEntradas
  Future<List<Map<String, dynamic>>> _getEntradasFuture(String tipo) async {
    // Obtener los productos una vez
    final productos = await _getProductos();

    // Definir las subcolecciones según el tipo
    List<String> subcolecciones;
    switch (tipo) {
      case 'general':
        subcolecciones = ['bodega'];
        break;
      case 'fundicion':
        subcolecciones = ['fundicion'];
        break;
      case 'procesos':
        subcolecciones = ['bruto', 'mecanizado', 'pintura', 'pulido'];
        break;
      default:
        subcolecciones = [];
    }

    // Obtener datos de todas las subcolecciones combinadas
    return await _getEntradasFromSubcolecciones(subcolecciones, productos);
  }

  Future<void> _exportarPDF(String tipo) async {
    final pdf = pw.Document();

    // Obtener los productos
    final productos = await _getProductos();

    // Definir las subcolecciones según el tipo
    List<String> subcolecciones;
    switch (tipo) {
      case 'general':
        subcolecciones = ['bodega'];
        break;
      case 'fundicion':
        subcolecciones = ['fundicion'];
        break;
      case 'procesos':
        subcolecciones = ['bruto', 'mecanizado', 'pintura', 'pulido'];
        break;
      default:
        subcolecciones = [];
    }

    // Obtener todas las entradas
    final entradas = await _getEntradasFromSubcolecciones(
      subcolecciones,
      productos,
    );

    final lista =
        entradas.map((entrada) {
          DateTime? fecha;

          // Usar ultima_actualizacion o ultima_venta para el PDF
          if (entrada['ultima_actualizacion'] != null) {
            fecha = parseFechaCampo(entrada['ultima_actualizacion']);
          } else if (entrada['ultima_venta'] != null) {
            try {
              fecha = DateTime.parse(entrada['ultima_venta'].toString());
            } catch (_) {
              fecha = null;
            }
          }

          String fechaFormateada = '-';
          if (fecha != null) {
            fechaFormateada = fecha.toLocal().toString().split(' ')[0];
          }

          return [
            fechaFormateada,
            '${entrada['referencia'] ?? '-'}',
            '${entrada['nombre'] ?? '-'}',
            '${entrada['cantidad'] ?? 0}',
          ];
        }).toList();

    pdf.addPage(
      buildReporteInventarioPDF(
        titulo: 'Reporte de ${tipo.toUpperCase()}',
        headers: ['Fecha', 'Ref', 'Nombre', 'Cant'],
        dataRows: lista,
        footerText: 'Total registros: ${lista.length}',
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    final tipos = ['fundicion', 'procesos', 'general'];

    return MainDeskLayout(
      child: Column(
        children: [
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Reporte de Inventario',
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

          // ✅ CONTENIDO con fondo blanco
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar nombre o referencia...',
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
                        setState(() {
                          _filtroTexto = value;
                        });
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton.icon(
                        onPressed: () async {
                          DateTimeRange? picked;
                          DateTime? start = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (start != null) {
                            DateTime? end = await showDatePicker(
                              context: context,
                              initialDate: start,
                              firstDate: start,
                              lastDate: DateTime.now(),
                            );
                            if (end != null) {
                              picked = DateTimeRange(start: start, end: end);
                              setState(() {
                                _rangoFechas = picked;
                              });
                            }
                          }
                        },
                        icon: const Icon(
                          Icons.date_range,
                          color: Color(0xFF4682B4),
                        ),
                        label: Text(
                          _rangoFechas == null
                              ? 'Filtrar por fecha'
                              : 'Desde ${_rangoFechas!.start.toLocal().toString().split(' ')[0]} hasta ${_rangoFechas!.end.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(color: Color(0xFF4682B4)),
                        ),
                      ),
                      if (_rangoFechas != null)
                        IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF4682B4),
                          ),
                          onPressed: () {
                            setState(() {
                              _rangoFechas = null;
                            });
                          },
                        ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: TabBar(
                        controller: _tabController,
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
                          Tab(text: 'Fundición'),
                          Tab(text: 'Procesos'),
                          Tab(text: 'General'),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabla('fundicion'),
                        _buildTabla('procesos'),
                        _buildTabla('general'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final tipo = tipos[_tabController.index];
                        _exportarPDF(tipo);
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Exportar a PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
}
