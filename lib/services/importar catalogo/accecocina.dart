import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarAccesoriosScreen extends StatefulWidget {
  const ImportarAccesoriosScreen({super.key});

  @override
  State<ImportarAccesoriosScreen> createState() =>
      _ImportarAccesoriosScreenState();
}

class _ImportarAccesoriosScreenState extends State<ImportarAccesoriosScreen> {
  bool cargando = false;
  int totalFilas = 0;
  int filasProcesadas = 0;

  Future<void> importarAccesoriosCSV() async {
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
          await _procesarAccesoriosCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de Accesorios', e);
    }
  }

  Future<void> _procesarAccesoriosCSV(String contenido) async {
    print(
      contenido.substring(0, contenido.length > 500 ? 500 : contenido.length),
    );

    // Detectar automáticamente el delimitador
    String delimitador = _detectarDelimitador(contenido);

    final rowsAsListOfValues = CsvToListConverter(
      fieldDelimiter: delimitador,
      eol: '\n',
      allowInvalid: true, // Permite procesar CSVs con formato inconsistente
    ).convert(contenido);

    if (rowsAsListOfValues.isEmpty) {
      _mostrarMensaje('El archivo CSV está vacío');
      setState(() => cargando = false);
      return;
    }


    // Verificar si la primera fila son headers
    final primeraFila = rowsAsListOfValues[0];
    bool tieneHeaders = _esFilaDeHeaders(primeraFila);
    if (tieneHeaders) {
    }

    int inicioFilas = tieneHeaders ? 1 : 0;

    setState(() {
      totalFilas = rowsAsListOfValues.length - inicioFilas;
      filasProcesadas = 0;
    });

    int productosImportados = 0;
    int errores = 0;

    for (int i = inicioFilas; i < rowsAsListOfValues.length; i++) {
      final fila = rowsAsListOfValues[i];

      // Si solo hay un campo pero contiene delimitadores, separar manualmente
      List<String> campos = _procesarFila(fila, delimitador);


      // Asegurar que tenemos exactamente 5 campos
      while (campos.length < 5) {
        campos.add('');
      }

      final referencia = campos[0].toString().trim();
      final nombre = campos[1].toString().trim();
      final dimensiones = campos[2].toString().trim();
      final pesoStr = campos[3].toString().trim();
      final pvpStr = campos[4].toString().trim();

      // Validar que la referencia no esté vacía (campo obligatorio)
      if (referencia.isEmpty) {
        errores++;
        setState(() => filasProcesadas++);
        continue;
      }

      // Convertir valores numéricos
      double peso = _convertirANumero(pesoStr);
      double pvp = _convertirANumero(pvpStr);

      try {
        Map<String, dynamic> datosProducto = {
          'referencia': referencia,
          'nombre': nombre.isEmpty ? '' : nombre,
          'dimensiones': dimensiones.isEmpty ? '' : dimensiones,
          'peso': peso,
          'pvp': pvp,
          'fecha': FieldValue.serverTimestamp(),
        };

        final docRef =
            FirebaseFirestore.instance
                .collection('catalogo')
                .doc('Accesorios')
                .collection('productos')
                .doc();

        await docRef.set(datosProducto);

        productosImportados++;
      } catch (e) {
        print('❌ Error fila $i (REF: $referencia): $e');
        errores++;
      }

      setState(() => filasProcesadas++);
    }

    if (!mounted) return;

    String mensaje =
        'Importación completada:\n'
        '✅ $productosImportados accesorios importados\n'
        '❌ $errores errores';

    _mostrarMensaje(mensaje);
    setState(() => cargando = false);
  }

  // Método para detectar automáticamente el delimitador
  String _detectarDelimitador(String contenido) {
    final primeraLinea = contenido.split('\n')[0];

    // Contar ocurrencias de diferentes delimitadores
    final delimitadores = [';', '\t', ',', '|'];
    String mejorDelimitador = '\t';
    int maxOcurrencias = 0;

    for (String delim in delimitadores) {
      int ocurrencias = delim.allMatches(primeraLinea).length;
      if (ocurrencias > maxOcurrencias) {
        maxOcurrencias = ocurrencias;
        mejorDelimitador = delim;
      }
    }

    return mejorDelimitador;
  }

  // Método para verificar si una fila contiene headers
  bool _esFilaDeHeaders(List<dynamic> fila) {
    final textoCompleto = fila.join(' ').toUpperCase();
    final palabrasClave = [
      'REF',
      'NOMBRE',
      'DIMENSIONES',
      'PESO',
      'PVP',
      'REFERENCIA',
    ];

    return palabrasClave.any((palabra) => textoCompleto.contains(palabra));
  }

  // Método para procesar una fila y asegurar la correcta separación
  List<String> _procesarFila(List<dynamic> fila, String delimitador) {
    if (fila.length == 1) {
      // Si solo hay un campo, probablemente necesita separación manual
      String contenido = fila[0].toString();
      if (contenido.contains(delimitador)) {
        return contenido.split(delimitador);
      }
    }

    // Convertir todos los elementos a String
    return fila.map((e) => e.toString()).toList();
  }

  // Método para convertir strings a números de manera robusta
  double _convertirANumero(String valor) {
    if (valor.isEmpty) return 0.0;

    // Limpiar el string: remover espacios y reemplazar comas por puntos
    String limpio = valor.trim().replaceAll(',', '.');

    // Intentar conversión
    return double.tryParse(limpio) ?? 0.0;
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        duration: const Duration(seconds: 4),
        backgroundColor: const Color(0xFF2C3E50),
      ),
    );
  }

  void _manejarError(String mensaje, dynamic error) {
    print('❌ $mensaje: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$mensaje\nError: ${error.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
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
                      'Importar CSV - Catálogo de Accesorios',
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
                child:
                    cargando
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Importando Accesorios: $filasProcesadas / $totalFilas',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Por favor espera...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                        : Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Center(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 700),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(40),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2C3E50),
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
                                          Icons.view_module,
                                          size: 80,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 24),
                                        const Text(
                                          'CATÁLOGO DE ACCESORIOS',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        const Text(
                                          'Importar accesorios al catálogo\nLos campos vacíos serán procesados correctamente\nSoporta delimitadores: ; , | TAB',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        ElevatedButton.icon(
                                          onPressed: importarAccesoriosCSV,
                                          icon: const Icon(
                                            Icons.upload_file,
                                            size: 24,
                                          ),
                                          label: const Text(
                                            'SUBIR CSV ACCESORIOS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: const Color(
                                              0xFF2C3E50,
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
                                  const SizedBox(height: 24),
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
