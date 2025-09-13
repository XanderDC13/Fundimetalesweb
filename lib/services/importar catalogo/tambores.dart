import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarTamboresScreen extends StatefulWidget {
  const ImportarTamboresScreen({super.key});

  @override
  State<ImportarTamboresScreen> createState() => _ImportarTamboresScreenState();
}

class _ImportarTamboresScreenState extends State<ImportarTamboresScreen> {
  bool cargando = false;
  int totalFilas = 0;
  int filasProcesadas = 0;

  Future<void> importarTamboresCSV() async {
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
          await _procesarTamboresCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de tambores', e);
    }
  }

  Future<void> _procesarTamboresCSV(String contenido) async {
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

      if (fila.length < 11) {
        print('⚠️ Fila $i incompleta, saltada.');
        continue;
      }

      final referencia = fila[0].toString().trim();
      final nombre = fila[1].toString().trim();
      final diametro = fila[2].toString().trim();
      final hueco = fila[3].toString().trim();
      final banda = fila[4].toString().trim();
      final bocin = fila[5].toString().trim();
      final poc = fila[6].toString().trim();
      final observaciones = fila[7].toString().trim();
      final pvp = double.tryParse(fila[8].toString().trim()) ?? 0.0;
      final descuento20 = double.tryParse(fila[9].toString().trim()) ?? 0.0;
      final peso = double.tryParse(fila[10].toString().trim()) ?? 0.0;

      if (referencia.isEmpty || nombre.isEmpty) {
        print('⚠️ Fila $i inválida (faltan datos obligatorios), saltada.');
        continue;
      }

      try {
        final docRef = FirebaseFirestore.instance
            .collection('catalogo')
            .doc('Tambores')
            .collection('productos')
            .doc();

        await docRef.set({
          'referencia': referencia,
          'nombre': nombre,
          'diametro': diametro,
          'hueco': hueco,
          'banda': banda,
          'bocin': bocin,
          'poc': poc,
          'observaciones': observaciones,
          'pvp': pvp,
          'descuento20': descuento20,
          'peso': peso,
          'fecha': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Tambor guardado: $referencia');
      } catch (e) {
        print('❌ Error fila $i: $e');
      }

      setState(() {
        filasProcesadas = i;
      });
    }

    if (!mounted) return;
    _mostrarMensaje('Tambores importados correctamente');
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
                      'Importar CSV - Catálogo de Tambores',
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
                              Color(0xFF8E44AD),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Importando Tambores: $filasProcesadas / $totalFilas',
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
                                    color: const Color(0xFF8E44AD),
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
                                        Icons.radio_button_unchecked,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'CATÁLOGO DE TAMBORES',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Importar tambores a la colección "catalogo"',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton.icon(
                                        onPressed: importarTamboresCSV,
                                        icon: const Icon(Icons.upload_file, size: 24),
                                        label: const Text(
                                          'SUBIR CSV TAMBORES',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(0xFF8E44AD),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 40,
                                            vertical: 24,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
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