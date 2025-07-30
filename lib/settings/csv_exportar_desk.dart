import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import 'dart:html' as html;

Future<void> exportarInventarioDesk(BuildContext context) async {
  try {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    // Crear el archivo Excel
    final excel = Excel.createExcel();
    final sheet = excel['Productos'];

    // Eliminar la hoja por defecto si existe
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    // Añadir encabezados con estilo
    final headerStyle = CellStyle(bold: true);

    final headers = [
      'Referencia',
      'Nombre',
      'Categoría',
      'Cantidad General',
      'Cantidad Fundición',
      'Cantidad Pintura',
    ];

    // Añadir encabezados a la fila 0
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Obtener datos de las cuatro colecciones
    final firestore = FirebaseFirestore.instance;

    final generalSnap =
        await firestore
            .collection('historial_inventario_general')
            .orderBy('nombre')
            .get();

    final pinturaSnap = await firestore.collection('inventario_pintura').get();

    final fundicionSnap =
        await firestore.collection('inventario_fundicion').get();

    final inventarioGeneralSnap =
        await firestore.collection('inventario_general').get();

    // Cerrar el indicador de carga
    Navigator.pop(context);

    if (generalSnap.docs.isEmpty &&
        pinturaSnap.docs.isEmpty &&
        fundicionSnap.docs.isEmpty) {
      _mostrarError(
        context,
        'No se encontraron productos en ningún inventario',
      );
      return;
    }

    // Crear mapa de categorías desde inventario_general
    Map<String, String> categoriasMap = {};
    for (final doc in inventarioGeneralSnap.docs) {
      final data = doc.data();
      final referencia = data['referencia']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final key =
          referencia.isNotEmpty
              ? referencia
              : (nombre.isNotEmpty ? nombre : doc.id);
      final categoria = data['categoria']?.toString() ?? '';
      if (categoria.isNotEmpty) {
        categoriasMap[key] = categoria;
      }
    }

    // Crear un mapa para combinar los datos por referencia o nombre
    Map<String, Map<String, dynamic>> productosMap = {};

    // Procesar inventario general - SUMANDO cantidades si hay duplicados
    for (final doc in generalSnap.docs) {
      final data = doc.data();
      final referencia = data['referencia']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final key =
          referencia.isNotEmpty
              ? referencia
              : (nombre.isNotEmpty ? nombre : doc.id);

      if (productosMap.containsKey(key)) {
        // Si ya existe, SUMAR la cantidad
        productosMap[key]!['cantidad_general'] =
            (productosMap[key]!['cantidad_general'] as int) +
            _convertirAEntero(data['cantidad']);
      } else {
        // Si no existe, crear nuevo registro
        productosMap[key] = {
          'referencia': referencia,
          'nombre': nombre,
          'categoria': categoriasMap[key] ?? 'Sin categoría',
          'cantidad_general': _convertirAEntero(data['cantidad']),
          'cantidad_fundicion': 0,
          'cantidad_pintura': 0,
        };
      }
    }

    // Procesar inventario de pintura - SUMANDO cantidades si hay duplicados
    for (final doc in pinturaSnap.docs) {
      final data = doc.data();
      final referencia = data['referencia']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final key =
          referencia.isNotEmpty
              ? referencia
              : (nombre.isNotEmpty ? nombre : doc.id);

      if (productosMap.containsKey(key)) {
        // Si ya existe, SUMAR la cantidad
        productosMap[key]!['cantidad_pintura'] =
            (productosMap[key]!['cantidad_pintura'] as int) +
            _convertirAEntero(data['cantidad']);
      } else {
        // Si no existe, crear nuevo registro
        productosMap[key] = {
          'referencia': referencia,
          'nombre': nombre,
          'categoria': categoriasMap[key] ?? 'Sin categoría',
          'cantidad_general': 0,
          'cantidad_fundicion': 0,
          'cantidad_pintura': _convertirAEntero(data['cantidad']),
        };
      }
    }

    // Procesar inventario de fundición - SUMANDO cantidades si hay duplicados
    for (final doc in fundicionSnap.docs) {
      final data = doc.data();
      final referencia = data['referencia']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final key =
          referencia.isNotEmpty
              ? referencia
              : (nombre.isNotEmpty ? nombre : doc.id);

      if (productosMap.containsKey(key)) {
        // Si ya existe, SUMAR la cantidad
        productosMap[key]!['cantidad_fundicion'] =
            (productosMap[key]!['cantidad_fundicion'] as int) +
            _convertirAEntero(data['cantidad']);
      } else {
        // Si no existe, crear nuevo registro
        productosMap[key] = {
          'referencia': referencia,
          'nombre': nombre,
          'categoria': categoriasMap[key] ?? 'Sin categoría',
          'cantidad_general': 0,
          'cantidad_fundicion': _convertirAEntero(data['cantidad']),
          'cantidad_pintura': 0,
        };
      }
    }

    // Añadir datos de productos al Excel
    int rowIndex = 1;
    final productosOrdenados =
        productosMap.entries.toList()..sort(
          (a, b) => a.value['nombre'].toString().compareTo(
            b.value['nombre'].toString(),
          ),
        );

    for (final entry in productosOrdenados) {
      final data = entry.value;

      final referencia = data['referencia'].toString();
      final nombre = data['nombre'].toString();
      final categoria = data['categoria'].toString();
      final cantGeneral = data['cantidad_general'] as int;
      final cantFundicion = data['cantidad_fundicion'] as int;
      final cantPintura = data['cantidad_pintura'] as int;

      // Añadir fila de datos
      final rowData = [
        referencia,
        nombre,
        categoria,
        cantGeneral,
        cantFundicion,
        cantPintura,
      ];

      for (int i = 0; i < rowData.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: rowIndex),
        );

        // Determinar el tipo de celda apropiado
        final value = rowData[i];
        if (value is int) {
          cell.value = IntCellValue(value);
        } else {
          cell.value = TextCellValue(value.toString());
        }
      }
      rowIndex++;
    }

    // Ajustar ancho de columnas automáticamente
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 15.0);
    }

    // Convertir a bytes
    final List<int>? excelBytes = excel.encode();

    if (excelBytes != null) {
      // Mostrar previsualización
      _mostrarPrevisualizacion(context, productosOrdenados, excelBytes);
    } else {
      _mostrarError(context, 'Error al generar el archivo Excel');
    }
  } catch (e) {
    // Cerrar loading si está abierto
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    _mostrarError(context, 'Error al exportar: ${e.toString()}');
  }
}

// Función auxiliar para convertir a entero
int _convertirAEntero(dynamic valor) {
  if (valor == null) return 0;
  if (valor is int) return valor;
  if (valor is double) return valor.round();
  if (valor is String) {
    return int.tryParse(valor) ?? 0;
  }
  return 0;
}

// Función para mostrar errores
void _mostrarError(BuildContext context, String mensaje) {
  showDialog(
    context: context,
    builder:
        (_) => AlertDialog(
          title: const Text('Error'),
          content: Text(mensaje),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
  );
}

// Función para mostrar previsualización
void _mostrarPrevisualizacion(
  BuildContext context,
  List<MapEntry<String, Map<String, dynamic>>> productos,
  List<int> excelBytes,
) {
  showDialog(
    context: context,
    builder:
        (_) => Dialog(
          backgroundColor: Colors.white,
          child: Container(
            width: 800,
            height: 600,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              children: [
                // Header del diálogo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFD6EAF8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.preview, color: Color(0xFF4682B4)),
                      const SizedBox(width: 8),
                      Text(
                        'Previsualización - ${productos.length} productos',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                // Contenido del diálogo
                Expanded(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Estadísticas rápidas
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Total Productos',
                                productos.length.toString(),
                                Icons.inventory,
                              ),
                              _buildStatCard(
                                'Total General',
                                productos
                                    .fold<int>(
                                      0,
                                      (sum, producto) =>
                                          sum +
                                          (producto.value['cantidad_general']
                                              as int),
                                    )
                                    .toString(),
                                Icons.storage,
                              ),
                              _buildStatCard(
                                'Total Fundición',
                                productos
                                    .fold<int>(
                                      0,
                                      (sum, producto) =>
                                          sum +
                                          (producto.value['cantidad_fundicion']
                                              as int),
                                    )
                                    .toString(),
                                Icons.fire_truck,
                              ),
                              _buildStatCard(
                                'Total Pintura',
                                productos
                                    .fold<int>(
                                      0,
                                      (sum, producto) =>
                                          sum +
                                          (producto.value['cantidad_pintura']
                                              as int),
                                    )
                                    .toString(),
                                Icons.brush,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tabla de datos
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dataTableTheme: DataTableThemeData(
                                    headingRowColor: MaterialStateProperty.all(
                                      Color(0xFFD6EAF8),
                                    ),
                                    dataRowColor: MaterialStateProperty.all(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                child: DataTable(
                                  columns: const [
                                    DataColumn(
                                      label: Text(
                                        'Referencia',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Nombre',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Categoría',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'General',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Fundición',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Pintura',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      numeric: true,
                                    ),
                                  ],
                                  rows:
                                      productos.take(50).map((producto) {
                                        final data = producto.value;
                                        return DataRow(
                                          color: MaterialStateProperty.all(
                                            Colors.white,
                                          ),
                                          cells: [
                                            DataCell(
                                              Text(
                                                data['referencia'].toString(),
                                              ),
                                            ),
                                            DataCell(
                                              SizedBox(
                                                width: 150,
                                                child: Text(
                                                  data['nombre'].toString(),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                data['categoria'].toString(),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                (data['cantidad_general']
                                                        as int)
                                                    .toString(),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                (data['cantidad_fundicion']
                                                        as int)
                                                    .toString(),
                                              ),
                                            ),
                                            DataCell(
                                              Text(
                                                (data['cantidad_pintura']
                                                        as int)
                                                    .toString(),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),

                        if (productos.length > 50)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Mostrando los primeros 50 productos de ${productos.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Botones de acción
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cerrar'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          _descargarExcel(excelBytes);
                          Navigator.pop(context);

                          // Mostrar mensaje de éxito
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text('Archivo Excel descargado exitosamente'),
                                ],
                              ),
                              backgroundColor: const Color(0xFFD6EAF8),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.download),
                        label: const Text('Descargar Excel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
  );
}

// Widget para mostrar estadísticas
Widget _buildStatCard(String titulo, String valor, IconData icono) {
  return Column(
    children: [
      Icon(icono, size: 24, color: const Color(0xFF4682B4)),
      const SizedBox(height: 4),
      Text(
        valor,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4682B4),
        ),
      ),
      Text(
        titulo,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

// Función para descargar el archivo Excel
void _descargarExcel(List<int> excelBytes) {
  try {
    // Convertir List<int> a Uint8List
    final Uint8List uint8list = Uint8List.fromList(excelBytes);

    // Crear el blob con el tipo MIME correcto
    final blob = html.Blob([
      uint8list,
    ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

    // Crear la URL del objeto
    final url = html.Url.createObjectUrlFromBlob(blob);

    // Crear el elemento anchor para la descarga
    final anchor =
        html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download =
              'inventario_productos_${_formatearFechaPorArchivo()}.xlsx';

    // Añadir al documento, hacer click y remover
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);

    // Limpiar la URL del objeto
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    print('Error al descargar: $e');
  }
}

// Función auxiliar para formatear fecha para nombres de archivo
String _formatearFechaPorArchivo() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
}
