import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarDualScreen extends StatefulWidget {
  const ImportarDualScreen({super.key});

  @override
  State<ImportarDualScreen> createState() => _ImportarDualScreenState();
}

class _ImportarDualScreenState extends State<ImportarDualScreen> {
  bool cargando = false;
  int totalFilas = 0;
  int filasProcesadas = 0;
  String tipoImportacion = '';

  final List<String> subcoleccionesInventario = [
    'bruto',
    'mecanizado',
    'pintura',
    'bodega'
  ];

  Future<void> importarProductosCSV() async {
    setState(() {
      cargando = true;
      totalFilas = 0;
      filasProcesadas = 0;
      tipoImportacion = 'Productos';
    });

    try {
      final input = html.FileUploadInputElement();
      input.accept = '.csv';
      input.click();

      input.onChange.listen((event) {
        final file = input.files?.first;
        if (file == null) {
          _mostrarMensaje('No se seleccionó ningún archivo');
          setState(() => cargando = false);
          return;
        }

        final reader = html.FileReader();
        reader.readAsText(file);

        reader.onLoadEnd.listen((event) async {
          await _procesarProductosCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de productos', e);
    }
  }

  Future<void> importarInventariosCSV() async {
    setState(() {
      cargando = true;
      totalFilas = 0;
      filasProcesadas = 0;
      tipoImportacion = 'Inventarios';
    });

    try {
      final input = html.FileUploadInputElement();
      input.accept = '.csv';
      input.click();

      input.onChange.listen((event) {
        final file = input.files?.first;
        if (file == null) {
          _mostrarMensaje('No se seleccionó ningún archivo');
          setState(() => cargando = false);
          return;
        }

        final reader = html.FileReader();
        reader.readAsText(file);

        reader.onLoadEnd.listen((event) async {
          await _procesarInventariosCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de inventarios', e);
    }
  }

  Future<void> _procesarProductosCSV(String contenido) async {
    // Usar punto y coma como delimitador
    final rowsAsListOfValues = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
    ).convert(contenido);

    if (rowsAsListOfValues.isEmpty) {
      _mostrarMensaje('El archivo CSV está vacío');
      setState(() => cargando = false);
      return;
    }

    setState(() {
      totalFilas = rowsAsListOfValues.length - 1;
      filasProcesadas = 0;
    });

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final fila = rowsAsListOfValues[i];

      // Ahora esperamos: CODIGO, REF, NOMBRE, P.V.P, 20%, CATEGORIA
      if (fila.length < 6) {
        print('⚠️ Fila $i incompleta, saltada.');
        continue;
      }

      final rawCodigo = fila[0].toString().trim();
      final codigo = rawCodigo.startsWith("'") ? rawCodigo.substring(1) : rawCodigo;
      final referencia = fila[1].toString().trim();
      final nombre = fila[2].toString().trim();
      final pvp = double.tryParse(fila[3].toString().trim()) ?? 0.0;
      final precio20 = double.tryParse(fila[4].toString().trim()) ?? 0.0;
      final categoria = fila[5].toString().trim();

      if (codigo.isEmpty || nombre.isEmpty || categoria.isEmpty) {
        print('⚠️ Fila $i inválida (faltan datos), saltada.');
        continue;
      }

      try {
        final docRef = FirebaseFirestore.instance
            .collection('productos')
            .doc(codigo);

        await docRef.set({
          'codigo': codigo,
          'referencia': referencia,
          'nombre': nombre,
          'pvp': pvp,
          'precio20': precio20,
          'categoria': categoria,
          'fecha': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Producto guardado: $codigo');
      } catch (e) {
        print('❌ Error fila $i: $e');
      }

      setState(() {
        filasProcesadas = i;
      });
    }

    if (!mounted) return;
    _mostrarMensaje('Productos importados correctamente');
    setState(() => cargando = false);
  }

  Future<void> _procesarInventariosCSV(String contenido) async {
    final rowsAsListOfValues = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
    ).convert(contenido);

    if (rowsAsListOfValues.isEmpty) {
      _mostrarMensaje('El archivo CSV está vacío');
      setState(() => cargando = false);
      return;
    }

    setState(() {
      totalFilas = rowsAsListOfValues.length - 1;
      filasProcesadas = 0;
    });

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final fila = rowsAsListOfValues[i];

      if (fila.length < 7) {
        print('⚠️ Fila $i incompleta, saltada.');
        continue;
      }

      final referencia = fila[0].toString().trim();
      
      if (referencia.isEmpty) {
        print('⚠️ Fila $i sin referencia, saltada.');
        continue;
      }

      for (int j = 1; j < fila.length && j <= 6; j++) {
        final cantidad = int.tryParse(fila[j].toString().trim()) ?? 0;
        final subcoleccion = subcoleccionesInventario[j - 1];

        try {
          final docRef = FirebaseFirestore.instance
              .collection('inventarios')
              .doc(subcoleccion)
              .collection('productos')
              .doc(referencia);

          await docRef.set({
            'referencia': referencia,
            'cantidad': cantidad,
            'fecha': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          print('✅ Inventario guardado: $referencia en $subcoleccion ($cantidad)');
        } catch (e) {
          print('❌ Error guardando $referencia en $subcoleccion: $e');
        }
      }

      setState(() {
        filasProcesadas = i;
      });
    }

    if (!mounted) return;
    _mostrarMensaje('Inventarios importados correctamente');
    setState(() => cargando = false);
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  void _manejarError(String mensaje, dynamic error) {
    print('❌ $mensaje: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
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
                      'Importar CSV - Productos e Inventarios',
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
            child: Container(
              color: Colors.white,
              child: Center(
                child: cargando
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF4682B4),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Importando $tipoImportacion: $filasProcesadas / $totalFilas',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // BOTÓN PRODUCTOS
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4682B4),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.inventory,
                                            size: 64,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 20),
                                          const Text(
                                            'PRODUCTOS',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Importar productos a la colección "productos"',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            onPressed: importarProductosCSV,
                                            icon: const Icon(Icons.upload_file, size: 20),
                                            label: const Text(
                                              'SUBIR CSV PRODUCTOS',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF4682B4),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 20,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Formato CSV (separado por punto y coma):',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4682B4),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text('• Código', style: TextStyle(fontSize: 12)),
                                          Text('• Referencia', style: TextStyle(fontSize: 12)),
                                          Text('• Nombre', style: TextStyle(fontSize: 12)),
                                          Text('• P.V.P', style: TextStyle(fontSize: 12)),
                                          Text('• 20%', style: TextStyle(fontSize: 12)),
                                          Text('• Categoría', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // DIVISOR VISUAL
                            Container(
                              width: 2,
                              height: 400,
                              color: Colors.grey.shade300,
                            ),
                            
                            // BOTÓN INVENTARIOS
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E8B57),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.warehouse,
                                            size: 64,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 20),
                                          const Text(
                                            'INVENTARIOS',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Importar inventarios a subcolecciones por ubicación',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          ElevatedButton.icon(
                                            onPressed: importarInventariosCSV,
                                            icon: const Icon(Icons.upload_file, size: 20),
                                            label: const Text(
                                              'SUBIR CSV INVENTARIOS',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: const Color(0xFF2E8B57),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 20,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.green.shade200),
                                      ),
                                      child: const Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Formato CSV:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2E8B57),
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text('• Referencia', style: TextStyle(fontSize: 12)),
                                          Text('• Fundición', style: TextStyle(fontSize: 12)),
                                          Text('• Bruto', style: TextStyle(fontSize: 12)),
                                          Text('• Mecanizado', style: TextStyle(fontSize: 12)),
                                          Text('• Pulido', style: TextStyle(fontSize: 12)),
                                          Text('• Pintura', style: TextStyle(fontSize: 12)),
                                          Text('• Bodega', style: TextStyle(fontSize: 12)),
                                        ],
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
            ),
          ),
        ],
      ),
    );
  }
}