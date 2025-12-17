import 'package:universal_html/html.dart' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ImportarContactosScreen extends StatefulWidget {
  const ImportarContactosScreen({super.key});

  @override
  State<ImportarContactosScreen> createState() =>
      _ImportarContactosScreenState();
}

class _ImportarContactosScreenState extends State<ImportarContactosScreen> {
  bool cargando = false;
  int totalFilas = 0;
  int filasProcesadas = 0;

  // ✅ AGREGAR ESTA FUNCIÓN AQUÍ (después de las variables)
  String _procesarRuc(String rawRuc) {
    String ruc = rawRuc.trim();

    // Remover comilla simple si existe
    if (ruc.startsWith("'")) {
      ruc = ruc.substring(1);
    }

    // Remover espacios y caracteres no numéricos (por si acaso)
    ruc = ruc.replaceAll(RegExp(r'[^0-9]'), '');

    // Si está vacío, retornar vacío
    if (ruc.isEmpty) return '';

    // Si tiene menos de 13 dígitos, completar con ceros a la izquierda
    if (ruc.length < 13) {
      String rucOriginal = ruc;
      ruc = ruc.padLeft(13, '0');
      print('🔧 RUC completado: $rawRuc ($rucOriginal) -> $ruc');
    }

    // Si tiene exactamente 13 dígitos, está bien
    if (ruc.length == 13) {
      print('✅ RUC correcto: $rawRuc -> $ruc');
      return ruc;
    }

    // Si tiene más de 13 dígitos (caso raro), tomar solo los primeros 13
    if (ruc.length > 13) {
      ruc = ruc.substring(0, 13);
      print('⚠️ RUC truncado: $rawRuc -> $ruc');
    }

    return ruc;
  }

  Future<void> importarContactosCSV() async {
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
          await _procesarContactosCSV(reader.result as String);
        });
      });
    } catch (e) {
      _manejarError('Error al importar CSV de contactos', e);
    }
  }

  Future<void> _procesarContactosCSV(String contenido) async {
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

      if (fila.length < 6) {
        print('⚠️ Fila $i incompleta, saltada.');
        continue;
      }

      final ruc = _procesarRuc(fila[0].toString());

      final nombre = fila[1].toString().trim();
      final ciudad = fila[2].toString().trim();
      final direccion = fila[3].toString().trim();
      final telefono = fila[4].toString().trim();
      final email = fila[5].toString().trim();

      // Validaciones básicas
      if (ruc.isEmpty || nombre.isEmpty) {
        print('⚠️ Fila $i inválida (falta RUC o nombre), saltada.');
        continue;
      }

      // Validar formato de email básico si no está vacío
      String emailFinal = email.isEmpty ? 'sincorreo@fmn.com' : email;
      if (emailFinal != 'sincorreo@fmn.com' && !emailFinal.contains('@')) {
        print('⚠️ Fila $i: Email inválido, usando email por defecto.');
        emailFinal = 'sincorreo@fmn.com';
      }

      try {
        // Usar el RUC como ID del documento
        final docRef = FirebaseFirestore.instance
            .collection('clientes')
            .doc(ruc);

        await docRef.set({
          'ruc': ruc,
          'nombre': nombre,
          'ciudad': ciudad.isEmpty ? 'SIN CIUDAD' : ciudad.toUpperCase(),
          'direccion':
              direccion.isEmpty ? 'SIN DIRECCIÓN' : direccion.toUpperCase(),
          'telefono': telefono.isEmpty ? 'SIN TELÉFONO' : telefono,
          'correo': emailFinal,
          'fecha': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('✅ Cliente guardado: $ruc - $nombre');
      } catch (e) {
        print('❌ Error fila $i: $e');
      }

      setState(() {
        filasProcesadas = i;
      });

      // Pequeña pausa para no saturar Firestore
      if (i % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (!mounted) return;
    _mostrarMensaje(
      'Contactos importados correctamente: $filasProcesadas registros',
    );
    setState(() => cargando = false);
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), duration: const Duration(seconds: 3)),
    );
  }

  void _manejarError(String mensaje, dynamic error) {
    print('❌ $mensaje: $error');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
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
                      'Importar CSV - Contactos/Clientes',
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
                                Color(0xFF9B59B6),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Importando Contactos: $filasProcesadas / $totalFilas',
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Por favor, espere...',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        )
                        : Padding(
                          padding: const EdgeInsets.all(40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // CONTENEDOR PRINCIPAL
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                padding: const EdgeInsets.all(40),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C3E50),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.contacts,
                                      size: 80,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'IMPORTAR CONTACTOS',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Sube un archivo CSV para importar contactos y clientes a la base de datos',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    ElevatedButton.icon(
                                      onPressed: importarContactosCSV,
                                      icon: const Icon(
                                        Icons.upload_file,
                                        size: 24,
                                      ),
                                      label: const Text(
                                        'SELECCIONAR ARCHIVO CSV',
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
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),
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
