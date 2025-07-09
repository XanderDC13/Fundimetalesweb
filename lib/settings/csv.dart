import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImportarProductosScreen extends StatefulWidget {
  const ImportarProductosScreen({super.key});

  @override
  State<ImportarProductosScreen> createState() =>
      _ImportarProductosScreenState();
}

class _ImportarProductosScreenState extends State<ImportarProductosScreen> {
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
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final contenido = await file.readAsString();

        final rowsAsListOfValues = const CsvToListConverter(
          fieldDelimiter: ';',
          eol: '\n',
        ).convert(contenido);

        if (rowsAsListOfValues.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('El archivo CSV está vacío')),
          );
          return;
        }

        setState(() {
          totalFilas = rowsAsListOfValues.length - 1; // Excluye cabecera
          filasProcesadas = 0;
        });

        for (int i = 1; i < rowsAsListOfValues.length; i++) {
          final fila = rowsAsListOfValues[i];
          print('Fila $i: $fila');

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

          print('→ CODIGO: $codigo');
          print('→ REFERENCIA: $referencia');
          print('→ NOMBRE: $nombre');
          print('→ COSTO: $costo');
          print('→ PRECIOS: $precios');
          print('→ CATEGORIA: $categoria');

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

            print(
              '✅ Guardado: $codigo | Ref: $referencia | Categoria: $categoria',
            );
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
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionó ningún archivo')),
        );
      }
    } catch (e) {
      print('❌ ERROR GENERAL: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error al importar CSV')));
    } finally {
      if (mounted) {
        setState(() {
          cargando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: const Center(
                child: Text(
                  'Importar Productos CSV',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
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
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
