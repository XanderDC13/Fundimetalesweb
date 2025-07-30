import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class ImportarProductosDeskScreen extends StatefulWidget {
  const ImportarProductosDeskScreen({super.key});

  @override
  State<ImportarProductosDeskScreen> createState() =>
      _ImportarProductosDeskScreenState();
}

class _ImportarProductosDeskScreenState
    extends State<ImportarProductosDeskScreen> {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se seleccionó ningún archivo')),
          );
          setState(() => cargando = false);
          return;
        }

        final reader = html.FileReader();
        reader.readAsText(file);

        reader.onLoadEnd.listen((event) async {
          final contenido = reader.result as String;
          final rowsAsListOfValues = const CsvToListConverter(
            fieldDelimiter: ';',
            eol: '\n',
          ).convert(contenido);

          if (rowsAsListOfValues.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('El archivo CSV está vacío')),
            );
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

            final rawCodigo = fila[0].toString().trim();
            final codigo =
                rawCodigo.startsWith("'") ? rawCodigo.substring(1) : rawCodigo;

            final referencia = fila[1].toString().trim();
            final nombre = fila[2].toString().trim();
            final costo = double.tryParse(fila[3].toString().trim()) ?? 0.0;

            List<double> precios = [];
            for (int j = 4; j <= 9; j++) {
              final precio = double.tryParse(fila[j].toString().trim()) ?? 0.0;
              if (precio > 0) {
                precios.add(precio);
              }
            }

            final categoria = fila[10].toString().trim();

            if (codigo.isEmpty || nombre.isEmpty || categoria.isEmpty) {
              print('⚠️ Fila $i inválida (faltan datos), saltada.');
              continue;
            }

            try {
              final docRef = FirebaseFirestore.instance
                  .collection('inventario_general')
                  .doc(codigo);

              await docRef.set({
                'codigo': codigo,
                'referencia': referencia,
                'nombre': nombre,
                'costo': costo,
                'precios': precios,
                'categoria': categoria,
                'fecha': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

              print('✅ Guardado: $codigo');
            } catch (e) {
              print('❌ Error fila $i: $e');
            }

            setState(() {
              filasProcesadas = i;
            });
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Productos importados correctamente')),
          );
          setState(() => cargando = false);
        });
      });
    } catch (e) {
      print('❌ ERROR GENERAL: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al importar CSV')));
      setState(() => cargando = false);
    }
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
                      'Importar Productos CSV',
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
                                Color(0xFF4682B4),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Importando: $filasProcesadas / $totalFilas',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        )
                        : ElevatedButton.icon(
                          onPressed: importarCSV,
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Subir CSV y Guardar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
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
