import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarCocinasScreen extends StatefulWidget {
  const ImportarCocinasScreen({super.key});

  @override
  State<ImportarCocinasScreen> createState() => _ImportarCocinasScreenState();
}

class _ImportarCocinasScreenState extends State<ImportarCocinasScreen> {
  bool cargando = false;
  int totalFilas = 0;
  int filasProcesadas = 0;

  Future<void> importarCocinasCSV() async {
    setState(() {
      cargando = true;
      totalFilas = 0;
      filasProcesadas = 0;
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
          await _procesarCocinasCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de cocinas', e);
    }
  }

  Future<void> _procesarCocinasCSV(String contenido) async {
    final rowsAsListOfValues = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
    ).convert(contenido);

    if (rowsAsListOfValues.isEmpty) {
      _mostrarMensaje('El archivo CSV está vacío');
      setState(() => cargando = false);
      return;
    }

    // Columnas esperadas (índice):
    // 0: referencia
    // 1: nombre
    // 2: dimensiones
    // 3: pvp

    setState(() {
      totalFilas = rowsAsListOfValues.length - 1;
      filasProcesadas = 0;
    });

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final fila = rowsAsListOfValues[i];

      if (fila.length < 4) {
        print('⚠️ Fila $i incompleta, saltada.');
        continue;
      }

      final referencia = fila[0].toString().trim();
      final nombre = fila[1].toString().trim();
      final dimensiones = fila[2].toString().trim();
      final pvp = double.tryParse(fila[3].toString().trim()) ?? 0.0;

      if (referencia.isEmpty || nombre.isEmpty) {
        print('⚠️ Fila $i inválida (faltan datos obligatorios), saltada.');
        continue;
      }

      try {
        await FirebaseFirestore.instance
            .collection('catalogo')
            .doc('Cocinas')
            .collection('productos')
            .doc()
            .set({
              'referencia': referencia,
              'nombre': nombre,
              'dimensiones': dimensiones,
              'pvp': pvp,
              'fecha': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        print('✅ Cocina guardada: $referencia');
      } catch (e) {
        print('❌ Error fila $i: $e');
      }

      setState(() => filasProcesadas = i);
    }

    if (!mounted) return;
    _mostrarMensaje('Cocinas importadas correctamente');
    setState(() => cargando = false);
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _manejarError(String mensaje, dynamic error) {
    print('❌ $mensaje: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF2C3E50),
            padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Importar CSV - Catálogo de Cocinas',
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
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child:
                    cargando
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFE74C3C),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Importando Cocinas: $filasProcesadas / $totalFilas',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                        : Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE74C3C),
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
                                          Icons.kitchen,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'CATÁLOGO DE COCINAS',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Columnas CSV:\nreferencia ; nombre ; dimensiones ; pvp',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        ElevatedButton.icon(
                                          onPressed: importarCocinasCSV,
                                          icon: const Icon(
                                            Icons.upload_file,
                                            size: 24,
                                          ),
                                          label: const Text(
                                            'SUBIR CSV COCINAS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFFE74C3C,
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 40,
                                              vertical: 24,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
