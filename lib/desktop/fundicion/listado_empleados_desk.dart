import 'package:basefundi/desktop/fundicion/rechazos_desk.dart';
import 'package:basefundi/desktop/fundicion/tareasfundi_desk.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/pdfs/reportegeneralfundicion.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

class OperadoresListDeskScreen extends StatefulWidget {
  const OperadoresListDeskScreen({super.key});

  @override
  State<OperadoresListDeskScreen> createState() =>
      _OperadoresListDeskScreenState();
}

class _OperadoresListDeskScreenState extends State<OperadoresListDeskScreen> {
  String _searchOperador = '';
  DateTimeRange? _selectedDateRange; // ✅ AGREGAR
  final TextEditingController _searchController =
      TextEditingController(); // ✅ AGREGAR

  @override
  void dispose() {
    _searchController.dispose(); // ✅ AGREGAR
    super.dispose();
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Control de Operadores',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // ✅ BOTONES A LA DERECHA
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Botón rango de fechas
                        ElevatedButton.icon(
                          onPressed: () async {
                            final picked = await showDialog<DateTimeRange>(
                              context: context,
                              builder:
                                  (ctx) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: SizedBox(
                                      width: 400,
                                      height: 500,
                                      child: DateRangePickerDialog(
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                        initialDateRange: _selectedDateRange,
                                      ),
                                    ),
                                  ),
                            );
                            if (picked != null) {
                              setState(() => _selectedDateRange = picked);
                            }
                          },
                          icon: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            _selectedDateRange == null
                                ? 'Rango de fechas'
                                : '${_selectedDateRange!.start.day}/${_selectedDateRange!.start.month}/${_selectedDateRange!.start.year} - ${_selectedDateRange!.end.day}/${_selectedDateRange!.end.month}/${_selectedDateRange!.end.year}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        if (_selectedDateRange != null) ...[
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed:
                                () => setState(() => _selectedDateRange = null),
                            child: const Text(
                              'Limpiar',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                        const SizedBox(width: 8),
                        // Botón exportar PDF general
                        ElevatedButton.icon(
                          onPressed: () => _exportarPDFGeneral(),
                          icon: const Icon(Icons.picture_as_pdf, size: 16),
                          label: const Text('PDF General'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: _buildFilters(),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('usuarios')
                                    .where('telefono', isEqualTo: '09876543210')
                                    .snapshots(),

                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay operadores activos con ese rol.',
                                  ),
                                );
                              }

                              final allOperadores = snapshot.data!.docs;
                              final filteredOperadores = _filtrarOperadores(
                                allOperadores,
                              );

                              if (filteredOperadores.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay resultados para los filtros seleccionados.',
                                  ),
                                );
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.2,
                                    ),
                                itemCount: filteredOperadores.length,
                                itemBuilder: (context, index) {
                                  final operador = filteredOperadores[index];
                                  return _buildOperadorCard(operador);
                                },
                              );
                            },
                          ),
                        ),
                      ],
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

  List<QueryDocumentSnapshot> _filtrarOperadores(
    List<QueryDocumentSnapshot> operadores,
  ) {
    var filteredByName =
        operadores.where((operador) {
          final nombre = (operador['nombre'] ?? '').toString().toLowerCase();
          final searchLower = _searchOperador.toLowerCase();
          return nombre.contains(searchLower);
        }).toList();

    return filteredByName;
  }

  Widget _buildOperadorCard(QueryDocumentSnapshot operador) {
    final nombre = operador['nombre'] ?? 'Sin nombre';

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('tareas_operador')
              .where('operador_id', isEqualTo: operador.id)
              .where('estado', isEqualTo: 'asignada')
              .snapshots(),
      builder: (context, tareasSnapshot) {
        final tareasPendientes =
            tareasSnapshot.hasData ? tareasSnapshot.data!.docs.length : 0;

        return GestureDetector(
          onTap: () {
            navegarConFade(
              context,
              OperadorControlDeskScreen(
                operadorId: operador.id,
                operadorNombre: nombre,
              ),
            );
          },
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF2C3E50),
                          child: Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'O',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$tareasPendientes tareas',
                          style: TextStyle(
                            color:
                                tareasPendientes > 0
                                    ? Colors.orange
                                    : Colors.grey[600],
                            fontSize: 12,
                            fontWeight:
                                tareasPendientes > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          navegarConFade(
                            context,
                            OperadorControlDeskScreen(
                              operadorId: operador.id,
                              operadorNombre: nombre,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'Ver Control',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Uint8List> _generarPDFIsolate(Map<String, dynamic> params) async {
    final tareas = params['tareas'] as List<Map<String, dynamic>>;
    final nombresOperadores =
        params['nombresOperadores'] as Map<String, String>;
    final tareasExtras = params['tareasExtras'] as List<Map<String, dynamic>>;
    final rangoStart = params['rangoStart'] as int?;
    final rangoEnd = params['rangoEnd'] as int?;
    final logoBytes = params['logoBytes'] as Uint8List; // ← agregar

    DateTimeRange? rango;
    if (rangoStart != null && rangoEnd != null) {
      rango = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(rangoStart),
        end: DateTime.fromMillisecondsSinceEpoch(rangoEnd),
      );
    }

    return ReporteGeneralPdfService.generarReporteGeneral(
      tareas: tareas,
      nombresOperadores: nombresOperadores,
      rango: rango,
      tareasExtras: tareasExtras,
      logoBytes: logoBytes, // ← agregar
    );
  }

  Future<void> _exportarPDFGeneral() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection('usuarios').get(),
        FirebaseFirestore.instance
            .collection('tareas_operador')
            .where('estado', isEqualTo: 'completada')
            .get(),
        FirebaseFirestore.instance.collection('tareas_extras').get(),
      ]);

      final usuariosSnapshot = results[0];
      final tareasSnapshot = results[1];
      final extrasSnapshot = results[2];

      var todasTareas =
          tareasSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

      if (_selectedDateRange != null) {
        todasTareas =
            todasTareas.where((t) {
              final fecha = (t['fecha_completada'] as Timestamp?)?.toDate();
              if (fecha == null) return false;
              return fecha.isAfter(
                    _selectedDateRange!.start.subtract(
                      const Duration(seconds: 1),
                    ),
                  ) &&
                  fecha.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1)),
                  );
            }).toList();
      }

      var tareasExtras =
          extrasSnapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList();

      if (_selectedDateRange != null) {
        tareasExtras =
            tareasExtras.where((t) {
              final fecha = (t['fecha_asignacion'] as Timestamp?)?.toDate();
              if (fecha == null) return false;
              return fecha.isAfter(
                    _selectedDateRange!.start.subtract(
                      const Duration(seconds: 1),
                    ),
                  ) &&
                  fecha.isBefore(
                    _selectedDateRange!.end.add(const Duration(days: 1)),
                  );
            }).toList();
      }

      final Map<String, String> nombresOperadores = {
        for (var u in usuariosSnapshot.docs)
          u.id: (u.data())['nombre'] ?? 'Sin nombre',
      };

      Navigator.of(context).pop();

      if (todasTareas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay tareas completadas en el rango seleccionado'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Cargar logo UNA sola vez en el hilo principal
      final logoBytes = await rootBundle.load('lib/assets/logo.png');

      final pdfBytes = await compute(_generarPDFIsolate, {
        'tareas': todasTareas,
        'nombresOperadores': nombresOperadores,
        'tareasExtras': tareasExtras,
        'rangoStart': _selectedDateRange?.start.millisecondsSinceEpoch,
        'rangoEnd': _selectedDateRange?.end.millisecondsSinceEpoch,
        'logoBytes': logoBytes.buffer.asUint8List(), // ← pasar los bytes
      });

      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name:
            'reporte_general_fundicion_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 300, // ajusta el ancho a tu gusto
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre ...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchOperador = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  // En OperadoresListDeskScreen, botón Rechazos:
                  onPressed:
                      () => navegarConFade(
                        context,
                        const RechazosFundicionDeskScreen(),
                      ),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Rechazos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }
}
