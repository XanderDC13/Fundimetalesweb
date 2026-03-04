import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarAlcantarilladoScreen extends StatefulWidget {
  const ImportarAlcantarilladoScreen({super.key});

  @override
  State<ImportarAlcantarilladoScreen> createState() =>
      _ImportarAlcantarilladoScreenState();
}

class _ImportarAlcantarilladoScreenState
    extends State<ImportarAlcantarilladoScreen> {
  bool cargando = false;
  int totalFilas = 0;
  int filasProcesadas = 0;

  Future<void> importarCSV() async {
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
          await _procesarCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de Alcantarillado', e);
    }
  }

  Future<void> _procesarCSV(String contenido) async {
    // Limpiar comillas dobles antes de parsear
    final contenidoLimpio = contenido.replaceAll('"', '');

    final rowsAsListOfValues = const CsvToListConverter(
      fieldDelimiter: ';',
      eol: '\n',
    ).convert(contenidoLimpio);

    if (rowsAsListOfValues.isEmpty) {
      _mostrarMensaje('El archivo CSV está vacío');
      setState(() => cargando = false);
      return;
    }

    // Columnas esperadas (índice):
    // 0: referencia
    // 1: nombre
    // 2: dimensionesTapa
    // 3: dimensionesCerco
    // 4: pesoTapa
    // 5: pesoCerco
    // 6: tapaCerco
    // 7: pvp

    setState(() {
      totalFilas = rowsAsListOfValues.length - 1;
      filasProcesadas = 0;
    });

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final fila = rowsAsListOfValues[i];

      if (fila.length < 8) {
        print('⚠️ Fila $i incompleta (${fila.length} columnas), saltada.');
        continue;
      }

      final referencia = fila[0]
          .toString()
          .trim()
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('-', '');
      final nombre = fila[1].toString().trim().replaceAll('"', '');
      final dimensionesTapa = fila[2].toString().trim().replaceAll('"', '');
      final dimensionesCerco = fila[3].toString().trim().replaceAll('"', '');
      final pesoTapa = double.tryParse(fila[4].toString().trim()) ?? 0.0;
      final pesoCerco = double.tryParse(fila[5].toString().trim()) ?? 0.0;
      final tapaCerco = fila[6].toString().trim().replaceAll('"', '');
      final pvp = double.tryParse(fila[7].toString().trim()) ?? 0.0;

      if (referencia.isEmpty || nombre.isEmpty) {
        print('⚠️ Fila $i inválida (faltan datos obligatorios), saltada.');
        continue;
      }

      try {
        await FirebaseFirestore.instance
            .collection('catalogo')
            .doc('Alcantarillado')
            .collection('productos')
            .doc()
            .set({
              'referencia': referencia,
              'nombre': nombre,
              'dimensionesTapa': dimensionesTapa,
              'dimensionesCerco': dimensionesCerco,
              'pesoTapa': pesoTapa,
              'pesoCerco': pesoCerco,
              'tapaCerco': tapaCerco,
              'pvp': pvp,
              'fecha': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        print('✅ Alcantarillado guardado: $referencia');
      } catch (e) {
        print('❌ Error fila $i: $e');
      }

      setState(() => filasProcesadas = i);
    }

    if (!mounted) return;
    _mostrarMensaje('Alcantarillado importado correctamente');
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
                    'Importar CSV - Catálogo de Alcantarillado',
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
                                Color(0xFF2980B9),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Importando Alcantarillado: $filasProcesadas / $totalFilas',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                        : Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2980B9),
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
                                      Icons.water_damage,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'CATÁLOGO DE ALCANTARILLADO',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Columnas CSV:\nreferencia ; nombre ; dim. tapa ; dim. cerco ; peso tapa ; peso cerco ; tapa-cerco ; pvp',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    ElevatedButton.icon(
                                      onPressed: importarCSV,
                                      icon: const Icon(
                                        Icons.upload_file,
                                        size: 24,
                                      ),
                                      label: const Text(
                                        'SUBIR CSV ALCANTARILLADO',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: const Color(
                                          0xFF2980B9,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 40,
                                          vertical: 24,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 4,
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
          ),
        ],
      ),
    );
  }
}
