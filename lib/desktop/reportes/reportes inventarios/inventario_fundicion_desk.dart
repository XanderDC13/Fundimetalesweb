import 'package:basefundi/services/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class InventarioFundicionDeskScreen extends StatefulWidget {
  const InventarioFundicionDeskScreen({super.key});

  @override
  State<InventarioFundicionDeskScreen> createState() =>
      _InventarioFundicionDeskScreenState();
}

class _InventarioFundicionDeskScreenState
    extends State<InventarioFundicionDeskScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  DateTimeRange? _rangoFechas;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(-0.5, 0),
              child: Container(
                width: double.infinity,
                color: const Color(0xFF2C3E50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 38,
                ),
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
                        'Inventario Fundición',
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
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildBarraBusqueda(),
                      _buildFiltroFechaYExportarPDF(),
                      const SizedBox(height: 8),
                      Expanded(child: _buildTablaFundicion()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextField(
        onChanged: (value) => setState(() => searchQuery = value.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o referencia...',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF4682B4)),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltroFechaYExportarPDF() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
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
                icon: const Icon(Icons.date_range, color: Color(0xFF4682B4)),
                label: Text(
                  _rangoFechas == null
                      ? 'Filtrar por fecha'
                      : 'Desde ${_rangoFechas!.start.toLocal().toString().split(' ')[0]} hasta ${_rangoFechas!.end.toLocal().toString().split(' ')[0]}',
                  style: const TextStyle(color: Color(0xFF4682B4)),
                ),
              ),
              if (_rangoFechas != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF4682B4)),
                  onPressed: () {
                    setState(() {
                      _rangoFechas = null;
                    });
                  },
                ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: _exportarPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar a PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4682B4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaFundicion() {
    final inventarioStream =
        FirebaseFirestore.instance
            .collection('inventarios')
            .doc('fundicion')
            .collection('productos')
            .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: inventarioStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data!.docs;
        final List<Map<String, dynamic>> productos = [];

        for (var doc in allDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final referencia = doc.id;
          final cantidad =
              int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;

          productos.add({
            'referencia': referencia,
            'cantidad': cantidad,
            'docId': doc.id,
            'ultima_actualizacion': data['ultima_actualizacion'],
          });
        }

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _obtenerProductosConNombres(productos),
          builder: (context, productosSnapshot) {
            if (!productosSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final productosCompletos = productosSnapshot.data!;

            final filtered =
                productosCompletos.where((data) {
                  final nombre = data['nombre'].toString().toLowerCase();
                  final referencia =
                      data['referencia'].toString().toLowerCase();
                  final textoCoincide =
                      searchQuery.isEmpty ||
                      nombre.contains(searchQuery) ||
                      referencia.contains(searchQuery);
                  bool cumpleFiltroFecha = true;
                  if (_rangoFechas != null) {
                    final fecha = parseFechaCampo(data['ultima_actualizacion']);
                    if (fecha != null) {
                      cumpleFiltroFecha =
                          fecha.isAfter(_rangoFechas!.start) &&
                          fecha.isBefore(
                            _rangoFechas!.end.add(const Duration(days: 1)),
                          );
                    } else {
                      cumpleFiltroFecha = false;
                    }
                  }

                  return textoCoincide && cumpleFiltroFecha;
                }).toList();

            if (filtered.isEmpty) {
              return const Center(
                child: Text('No hay registros para mostrar.'),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final double anchoFecha = totalWidth * 0.15;
                final double anchoNombre = totalWidth * 0.25;
                final double anchoReferencia = totalWidth * 0.25;
                final double anchoCantidad = totalWidth * 0.10;
                final double anchoAcciones = totalWidth * 0.15;

                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 0,
                    headingRowColor: MaterialStateProperty.all(
                      const Color(0xFF4682B4),
                    ),
                    headingTextStyle: const TextStyle(color: Colors.white),
                    columns: const [
                      DataColumn(label: Text('Fecha')),
                      DataColumn(label: Text('Nombre')),
                      DataColumn(label: Text('Referencia')),
                      DataColumn(label: Text('Cantidad')),
                      DataColumn(label: Text('Acción')),
                    ],
                    rows:
                        filtered.map((data) {
                          String fechaFormateada = '-';
                          final fecha = parseFechaCampo(
                            data['ultima_actualizacion'],
                          );
                          if (fecha != null) {
                            fechaFormateada =
                                fecha.toLocal().toString().split(' ')[0];
                          }

                          return DataRow(
                            cells: [
                              DataCell(
                                SizedBox(
                                  width: anchoFecha,
                                  child: Text(
                                    fechaFormateada,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: anchoNombre,
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Text(
                                          data['nombre'] ?? 'Sin nombre',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF4682B4),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: anchoReferencia,
                                  child: Align(
                                    alignment: const Alignment(-0.6, 0.0),
                                    child: Text(
                                      data['referencia'],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: anchoCantidad,
                                  child: Text(
                                    data['cantidad'].toString(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              DataCell(
                                SizedBox(
                                  width: anchoAcciones,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit_outlined,
                                          color: Color(0xFF4682B4),
                                        ),
                                        tooltip: 'Editar cantidad',
                                        onPressed: () => _editarCantidad(data),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Eliminar',
                                        onPressed:
                                            () => _eliminarProducto(
                                              data,
                                              context,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _obtenerProductosConNombres(
    List<Map<String, dynamic>> productos,
  ) async {
    final List<Map<String, dynamic>> productosCompletos = [];

    try {
      final Set<String> todasLasReferencias = {};

      for (var producto in productos) {
        todasLasReferencias.add(producto['referencia']);
      }

      final Map<String, String> nombresProductos = {};

      if (todasLasReferencias.isNotEmpty) {
        final lotes = <List<String>>[];
        final listaReferencias = todasLasReferencias.toList();

        for (int i = 0; i < listaReferencias.length; i += 10) {
          final fin =
              (i + 10 < listaReferencias.length)
                  ? i + 10
                  : listaReferencias.length;
          lotes.add(listaReferencias.sublist(i, fin));
        }

        final futuresNombres =
            lotes
                .map(
                  (lote) =>
                      FirebaseFirestore.instance
                          .collection('productos')
                          .where('referencia', whereIn: lote)
                          .get(),
                )
                .toList();

        final resultadosNombres = await Future.wait(futuresNombres);

        for (final snapshot in resultadosNombres) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            nombresProductos[data['referencia']] =
                data['nombre'] ?? 'Sin nombre';
          }
        }
      }

      for (var producto in productos) {
        productosCompletos.add({
          'referencia': producto['referencia'],
          'cantidad': producto['cantidad'],
          'nombre':
              nombresProductos[producto['referencia']] ??
              'Producto no encontrado',
          'docId': producto['docId'],
          'ultima_actualizacion': producto['ultima_actualizacion'],
        });
      }
    } catch (e) {
      print('Error obteniendo productos de fundición optimizado: $e');

      for (var producto in productos) {
        productosCompletos.add({
          'referencia': producto['referencia'],
          'cantidad': producto['cantidad'],
          'nombre': 'Error al cargar',
          'docId': producto['docId'],
          'ultima_actualizacion': producto['ultima_actualizacion'],
        });
      }
    }

    return productosCompletos;
  }

  Future<void> _eliminarProducto(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final confirmar =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 12,
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 28,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                            size: 48,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Eliminar producto',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¿Eliminar "${data['nombre']}" del inventario de Fundición?',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.grey[700],
                                ),
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancelar'),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text(
                                  'Eliminar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        ) ??
        false;

    if (confirmar) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          _mostrarSnackBar('Usuario no autenticado');
          return;
        }

        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(currentUser.uid)
                .get();

        final nombreUsuario =
            userDoc.data()?['nombre'] ?? currentUser.email ?? '---';

        await FirebaseFirestore.instance
            .collection('inventarios')
            .doc('fundicion')
            .collection('productos')
            .doc(data['referencia'])
            .delete();

        await FirebaseFirestore.instance.collection('auditoria_general').add({
          'accion': 'Eliminar Cant Inventario Fundición',
          'detalle':
              'Producto: ${data['nombre']}, Referencia: ${data['referencia']}, Cantidad eliminada: ${data['cantidad']}',
          'fecha': DateTime.now(),
          'usuario_uid': currentUser.uid,
          'usuario_nombre': nombreUsuario,
        });

        _mostrarSnackBar('Producto eliminado correctamente');
      } catch (e) {
        _mostrarSnackBar('Error al eliminar producto: $e');
      }
    }
  }

  Future<void> _editarCantidad(Map<String, dynamic> data) async {
    final TextEditingController cantidadController = TextEditingController(
      text: data['cantidad'].toString(),
    );

    final nuevaCantidad = await showDialog<int>(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Título
                      Text(
                        'Editar cantidad',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtítulo con nombre del producto
                      Text(
                        data['nombre'] ?? 'Producto',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Campo cantidad
                      TextField(
                        controller: cantidadController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nueva cantidad',
                          border: OutlineInputBorder(),
                        ),
                        autofocus: true,
                        onSubmitted: (value) {
                          final cantidad = int.tryParse(value);
                          if (cantidad != null && cantidad >= 0) {
                            Navigator.pop(context, cantidad);
                          }
                        },
                      ),

                      const SizedBox(height: 20),

                      // Botones
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4682B4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              final cantidad = int.tryParse(
                                cantidadController.text,
                              );
                              if (cantidad != null && cantidad >= 0) {
                                Navigator.pop(context, cantidad);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ingrese una cantidad válida (número entero mayor o igual a 0)',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const Text('Guardar'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    if (nuevaCantidad != null && nuevaCantidad != data['cantidad']) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          _mostrarSnackBar('Usuario no autenticado');
          return;
        }

        // Buscar el nombre en la colección usuarios_activos
        final usuarioDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();

        final usuarioNombre =
            usuarioDoc.exists
                ? (usuarioDoc['nombre'] ?? 'Desconocido')
                : 'Desconocido';

        // Actualizar la cantidad en Firestore - RUTA FUNDICIÓN
        await FirebaseFirestore.instance
            .collection('inventarios')
            .doc('fundicion')
            .collection('productos')
            .doc(data['referencia'])
            .update({
              'cantidad': nuevaCantidad,
              'ultima_actualizacion': FieldValue.serverTimestamp(),
            });

        // Registrar en auditoría - MENSAJE FUNDICIÓN
        await FirebaseFirestore.instance.collection('auditoria_general').add({
          'fecha': FieldValue.serverTimestamp(),
          'usuario_nombre': usuarioNombre,
          'usuario_uid': user.uid,
          'accion': 'Edición de cantidad de inventario fundición',
          'detalle':
              'Producto: ${data['nombre']}, Referencia: ${data['referencia']}, Cantidad anterior: ${data['cantidad']}, Cantidad nueva: $nuevaCantidad',
        });

        _mostrarSnackBar('Cantidad actualizada correctamente');
      } catch (e) {
        _mostrarSnackBar('Error al actualizar cantidad: $e');
      }
    }
  }

  Future<void> _exportarPDF() async {
    try {
      _mostrarSnackBar('Preparando reporte PDF...');

      final snapshot =
          await FirebaseFirestore.instance
              .collection('inventarios')
              .doc('fundicion')
              .collection('productos')
              .get();

      final allDocs = snapshot.docs;
      final List<Map<String, dynamic>> productos = [];

      for (var doc in allDocs) {
        final data = doc.data();
        final referencia = doc.id;
        final cantidad = int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;

        productos.add({
          'referencia': referencia,
          'cantidad': cantidad,
          'docId': doc.id,
          'ultima_actualizacion': data['ultima_actualizacion'],
        });
      }

      final productosCompletos = await _obtenerProductosConNombres(productos);

      final filtered =
          productosCompletos.where((data) {
            final nombre = data['nombre'].toString().toLowerCase();
            final referencia = data['referencia'].toString().toLowerCase();
            final textoCoincide =
                searchQuery.isEmpty ||
                nombre.contains(searchQuery) ||
                referencia.contains(searchQuery);

            bool cumpleFiltroFecha = true;
            if (_rangoFechas != null) {
              final fecha = parseFechaCampo(data['ultima_actualizacion']);
              if (fecha != null) {
                cumpleFiltroFecha =
                    fecha.isAfter(_rangoFechas!.start) &&
                    fecha.isBefore(
                      _rangoFechas!.end.add(const Duration(days: 1)),
                    );
              } else {
                cumpleFiltroFecha = false;
              }
            }

            return textoCoincide && cumpleFiltroFecha;
          }).toList();

      if (filtered.isEmpty) {
        _mostrarSnackBar(
          'No hay datos para exportar con los filtros aplicados',
        );
        return;
      }

      const maxRegistrosTotal = 1000;

      if (filtered.length > maxRegistrosTotal) {
        final continuar =
            await showDialog<bool>(
              context: context,
              builder:
                  (_) => AlertDialog(
                    title: const Text('Muchos registros'),
                    content: Text(
                      'Se encontraron ${filtered.length} registros. Para evitar errores, el PDF se limitará a los primeros $maxRegistrosTotal registros. ¿Continuar?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Continuar'),
                      ),
                    ],
                  ),
            ) ??
            false;

        if (!continuar) return;
      }

      final datosParaPDF = filtered.take(maxRegistrosTotal).toList();

      final lista =
          datosParaPDF.map((data) {
            String fechaFormateada = '-';
            final fecha = parseFechaCampo(data['ultima_actualizacion']);
            if (fecha != null) {
              fechaFormateada = fecha.toLocal().toString().split(' ')[0];
            }

            return [
              fechaFormateada,
              '${data['referencia'] ?? '-'}',
              '${data['nombre'] ?? '-'}',
              '${data['cantidad'] ?? 0}',
            ];
          }).toList();

      String titulo = 'Inventario Fundición';
      if (_rangoFechas != null) {
        titulo +=
            ' (${_rangoFechas!.start.toLocal().toString().split(' ')[0]} - ${_rangoFechas!.end.toLocal().toString().split(' ')[0]})';
      }
      if (searchQuery.isNotEmpty) {
        titulo += ' - Filtro: "$searchQuery"';
      }

      final pdf = pw.Document();
      pdf.addPage(
        _buildReporteInventarioPDF(
          titulo: titulo,
          headers: ['Fecha', 'Referencia', 'Nombre', 'Cantidad'],
          dataRows: lista,
          footerText: 'Total de registros: ${datosParaPDF.length}',
        ),
      );

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      _mostrarSnackBar('PDF generado exitosamente');
    } catch (e) {
      print('Error generando PDF: $e');
      _mostrarSnackBar('Error al generar PDF: ${e.toString()}');
    }
  }

  pw.MultiPage _buildReporteInventarioPDF({
    required String titulo,
    required List<String> headers,
    required List<List<String>> dataRows,
    String? footerText,
  }) {
    return pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(20),
      header:
          (context) => pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
            ),
            child: pw.Text(
              titulo,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
          ),
      footer:
          (context) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey400, width: 1),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  footerText ?? '',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.blueGrey700,
                  ),
                ),
                pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.blueGrey700,
                  ),
                ),
              ],
            ),
          ),
      build:
          (context) => [
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              cellAlignment: pw.Alignment.centerLeft,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 9,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.blue800,
              ),
              cellStyle: const pw.TextStyle(fontSize: 8),
              cellPadding: const pw.EdgeInsets.all(3),
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FixedColumnWidth(80),
                3: const pw.FixedColumnWidth(50),
              },
              headers: headers,
              data: dataRows,
            ),
          ],
    );
  }

  void _mostrarSnackBar(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }
}
