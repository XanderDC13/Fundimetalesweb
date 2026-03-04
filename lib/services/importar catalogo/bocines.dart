import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarBocinesScreen extends StatefulWidget {
  const ImportarBocinesScreen({super.key});

  @override
  State<ImportarBocinesScreen> createState() => _ImportarBocinesScreenState();
}

class _ImportarBocinesScreenState extends State<ImportarBocinesScreen> {
  bool cargando = false;
  int totalFilas = 0;
  int filasProcesadas = 0;

  Future<void> importarBocinesCSV() async {
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
          await _procesarBocinesCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de bocines', e);
    }
  }

  Future<void> _procesarBocinesCSV(String contenido) async {
    // ── Limpiar comillas dobles del contenido antes de parsear ───────────────
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
    // 2: pistainterna
    // 3: pistaexterna
    // 4: pernos
    // 5: eje
    // 6: pvp
    // 7: descuento15
    // 8: peso

    setState(() {
      totalFilas = rowsAsListOfValues.length - 1;
      filasProcesadas = 0;
    });

    for (int i = 1; i < rowsAsListOfValues.length; i++) {
      final fila = rowsAsListOfValues[i];

      if (fila.length < 9) {
        print('⚠️ Fila $i incompleta (${fila.length} columnas), saltada.');
        continue;
      }

      // ── Limpiar REF: quitar comillas y guiones ────────────────────────────
      final referencia = fila[0]
          .toString()
          .trim()
          .replaceAll('"', '')
          .replaceAll("'", '')
          .replaceAll('-', '');

      final nombre       = fila[1].toString().trim().replaceAll('"', '');
      final pistainterna = fila[2].toString().trim().replaceAll('"', '');
      final pistaexterna = fila[3].toString().trim().replaceAll('"', '');
      final pernos       = fila[4].toString().trim().replaceAll('"', '');
      final eje          = fila[5].toString().trim().replaceAll('"', '');
      final pvp          = double.tryParse(fila[6].toString().trim()) ?? 0.0;
      final descuento15  = double.tryParse(fila[7].toString().trim()) ?? 0.0;
      final peso         = double.tryParse(fila[8].toString().trim()) ?? 0.0;

      if (referencia.isEmpty || nombre.isEmpty) {
        print('⚠️ Fila $i inválida (faltan datos obligatorios), saltada.');
        continue;
      }

      try {
        await FirebaseFirestore.instance
            .collection('catalogo')
            .doc('Bocines')
            .collection('productos')
            .doc()
            .set({
              'referencia':   referencia,
              'nombre':       nombre,
              'pistainterna': pistainterna,
              'pistaexterna': pistaexterna,
              'pernos':       pernos,
              'eje':          eje,
              'pvp':          pvp,
              'descuento15':  descuento15,
              'peso':         peso,
              'fecha':        FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        print('✅ Bocín guardado: $referencia');
      } catch (e) {
        print('❌ Error fila $i: $e');
      }

      setState(() => filasProcesadas = i);
    }

    if (!mounted) return;
    _mostrarMensaje('Bocines importados correctamente');
    setState(() => cargando = false);
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _manejarError(String mensaje, dynamic error) {
    print('❌ $mensaje: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensaje)));
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
                    'Importar CSV - Catálogo de Bocines',
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
                child: cargando
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF1ABC9C),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Importando Bocines: $filasProcesadas / $totalFilas',
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
                                    color: const Color(0xFF1ABC9C),
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
                                        Icons.speaker,
                                        size: 80,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(height: 24),
                                      const Text(
                                        'CATÁLOGO DE BOCINES',
                                        style: TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Columnas CSV:\nreferencia ; nombre ; pista interna ; pista externa ; pernos ; eje ; pvp ; 15% ; peso',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      ElevatedButton.icon(
                                        onPressed: importarBocinesCSV,
                                        icon: const Icon(
                                          Icons.upload_file,
                                          size: 24,
                                        ),
                                        label: const Text(
                                          'SUBIR CSV BOCINES',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor:
                                              const Color(0xFF1ABC9C),
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