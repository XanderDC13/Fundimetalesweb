import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'dart:typed_data';
import 'dart:html' as html;

Future<void> exportarInventarioDesk(BuildContext context) async {
  try {
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
      'Bodega',
      'Bruto',
      'Fundición',
      'Mecanizado',
      'Pintura',
      'Pulido',
      'Total',
    ];

    // Añadir encabezados a la fila 0
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // Obtener datos de Firestore
    final firestore = FirebaseFirestore.instance;

    // Obtener datos de la colección productos (para referencia, nombre, categoría)
    final productosSnap = await firestore
        .collection('productos')
        .orderBy('nombre')
        .get();

    // Obtener datos de cada subcolección de inventarios (para cantidades)
    final bodegaSnap = await firestore
        .collection('inventarios')
        .doc('bodega')
        .collection('productos')
        .get();

    final brutoSnap = await firestore
        .collection('inventarios')
        .doc('bruto')
        .collection('productos')
        .get();

    final fundicionSnap = await firestore
        .collection('inventarios')
        .doc('fundicion')
        .collection('productos')
        .get();

    final mecanizadoSnap = await firestore
        .collection('inventarios')
        .doc('mecanizado')
        .collection('productos')
        .get();

    final pinturaSnap = await firestore
        .collection('inventarios')
        .doc('pintura')
        .collection('productos')
        .get();

    final pulidoSnap = await firestore
        .collection('inventarios')
        .doc('pulido')
        .collection('productos')
        .get();

    // Cerrar el indicador de carga
    Navigator.pop(context);

    // Verificar que hay datos
    if (productosSnap.docs.isEmpty) {
      _mostrarError(
        context,
        'No se encontraron productos en la colección productos',
      );
      return;
    }

    // Crear mapa principal de productos
    Map<String, Map<String, dynamic>> productosMap = {};

    // Primero, crear todos los productos con datos base de la colección productos
    for (final doc in productosSnap.docs) {
      final data = doc.data();
      final referencia = data['referencia']?.toString() ?? '';
      final nombre = data['nombre']?.toString() ?? '';
      final categoria = data['categoria']?.toString() ?? 'Sin categoría';
      
      final key = referencia.isNotEmpty 
          ? referencia 
          : (nombre.isNotEmpty ? nombre : doc.id);

      productosMap[key] = {
        'referencia': referencia,
        'nombre': nombre,
        'categoria': categoria,
        'cantidad_bodega': 0,
        'cantidad_bruto': 0,
        'cantidad_fundicion': 0,
        'cantidad_mecanizado': 0,
        'cantidad_pintura': 0,
        'cantidad_pulido': 0,
      };
    }

    // Función auxiliar para procesar cada subcolección de inventarios (solo cantidades)
    void procesarSubcoleccion(QuerySnapshot snap, String campo) {
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final referencia = data['referencia']?.toString() ?? '';
        final nombre = data['nombre']?.toString() ?? '';
        
        final key = referencia.isNotEmpty 
            ? referencia 
            : (nombre.isNotEmpty ? nombre : doc.id);

        if (productosMap.containsKey(key)) {
          // Si existe en productos, SUMAR la cantidad
          productosMap[key]![campo] = 
              (productosMap[key]![campo] as int) + _convertirAEntero(data['cantidad']);
        }
        // Si no existe en productos, se ignora (no debería pasar si los datos están bien)
      }
    }

    // Procesar cada subcolección
    procesarSubcoleccion(bodegaSnap, 'cantidad_bodega');
    procesarSubcoleccion(brutoSnap, 'cantidad_bruto');
    procesarSubcoleccion(fundicionSnap, 'cantidad_fundicion');
    procesarSubcoleccion(mecanizadoSnap, 'cantidad_mecanizado');
    procesarSubcoleccion(pinturaSnap, 'cantidad_pintura');
    procesarSubcoleccion(pulidoSnap, 'cantidad_pulido');

    // Añadir datos de productos al Excel
    int rowIndex = 1;
    final productosOrdenados = productosMap.entries.toList()
      ..sort((a, b) => a.value['nombre'].toString().compareTo(
            b.value['nombre'].toString(),
          ));

    for (final entry in productosOrdenados) {
      final data = entry.value;

      final referencia = data['referencia'].toString();
      final nombre = data['nombre'].toString();
      final categoria = data['categoria'].toString();
      final cantBodega = data['cantidad_bodega'] as int;
      final cantBruto = data['cantidad_bruto'] as int;
      final cantFundicion = data['cantidad_fundicion'] as int;
      final cantMecanizado = data['cantidad_mecanizado'] as int;
      final cantPintura = data['cantidad_pintura'] as int;
      final cantPulido = data['cantidad_pulido'] as int;
      
      // Calcular total
      final total = cantBodega + cantBruto + cantFundicion + cantMecanizado + cantPintura + cantPulido;

      // Añadir fila de datos
      final rowData = [
        referencia,
        nombre,
        categoria,
        cantBodega,
        cantBruto,
        cantFundicion,
        cantMecanizado,
        cantPintura,
        cantPulido,
        total,
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
    builder: (_) => AlertDialog(
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
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      child: Container(
        width: 1000, // Aumenté el ancho para las nuevas columnas
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
                    // Tabla de datos
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
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
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Nombre',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Categoría',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Bodega',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Bruto',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Fundición',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Mecanizado',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Pintura',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Pulido',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                  DataColumn(
                                    label: Text(
                                      'Total',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    numeric: true,
                                  ),
                                ],
                                rows: productos.take(50).map((producto) {
                                  final data = producto.value;
                                  final total = (data['cantidad_bodega'] as int) +
                                      (data['cantidad_bruto'] as int) +
                                      (data['cantidad_fundicion'] as int) +
                                      (data['cantidad_mecanizado'] as int) +
                                      (data['cantidad_pintura'] as int) +
                                      (data['cantidad_pulido'] as int);
                                      
                                  return DataRow(
                                    color: MaterialStateProperty.all(Colors.white),
                                    cells: [
                                      DataCell(Text(data['referencia'].toString())),
                                      DataCell(
                                        SizedBox(
                                          width: 150,
                                          child: Text(
                                            data['nombre'].toString(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(data['categoria'].toString())),
                                      DataCell(Text((data['cantidad_bodega'] as int).toString())),
                                      DataCell(Text((data['cantidad_bruto'] as int).toString())),
                                      DataCell(Text((data['cantidad_fundicion'] as int).toString())),
                                      DataCell(Text((data['cantidad_mecanizado'] as int).toString())),
                                      DataCell(Text((data['cantidad_pintura'] as int).toString())),
                                      DataCell(Text((data['cantidad_pulido'] as int).toString())),
                                      DataCell(
                                        Text(
                                          total.toString(),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _descargarExcel(excelBytes);
                      Navigator.pop(context);

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

// Función para descargar el archivo Excel
void _descargarExcel(List<int> excelBytes) {
  try {
    final Uint8List uint8list = Uint8List.fromList(excelBytes);
    final blob = html.Blob(
      [uint8list],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = 'inventario_productos_${_formatearFechaPorArchivo()}.xlsx';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);

    html.Url.revokeObjectUrl(url);
  } catch (e) {
    print('Error al descargar: $e');
  }
}

String _formatearFechaPorArchivo() {
  final now = DateTime.now();
  return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
}