import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReporteTransporteFScreen extends StatefulWidget {
  const ReporteTransporteFScreen({super.key});

  @override
  State<ReporteTransporteFScreen> createState() =>
      _ReporteTransporteFScreenState();
}

class _ReporteTransporteFScreenState extends State<ReporteTransporteFScreen> {
  TimeOfDay? salidaSede;
  TimeOfDay? llegadaFabrica;
  TimeOfDay? salidaFabrica;
  TimeOfDay? llegadaSede;
  Duration? tiempoSedeAFabrica;
  Duration? tiempoFabricaASede;

  String formatHora(TimeOfDay? hora) {
    if (hora == null) return '--:--';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hora.hour, hora.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  void calcularDiferencias() {
    final ahora = DateTime.now();
    if (salidaSede != null && llegadaFabrica != null) {
      final salida = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        salidaSede!.hour,
        salidaSede!.minute,
      );
      DateTime llegada = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        llegadaFabrica!.hour,
        llegadaFabrica!.minute,
      );
      if (llegada.isBefore(salida)) {
        llegada = llegada.add(const Duration(days: 1));
      }
      final diff = llegada.difference(salida);
      setState(() {
        tiempoSedeAFabrica = diff;
      });
    }
    if (salidaFabrica != null && llegadaSede != null) {
      final salida = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        salidaFabrica!.hour,
        salidaFabrica!.minute,
      );
      DateTime llegada = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        llegadaSede!.hour,
        llegadaSede!.minute,
      );
      if (llegada.isBefore(salida)) {
        llegada = llegada.add(const Duration(days: 1));
      }
      final diff = llegada.difference(salida);
      setState(() {
        tiempoFabricaASede = diff;
      });
    }
  }

  Future<void> seleccionarHoraTramo(String tramo) async {
    final TimeOfDay? seleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'Seleccionar hora',
    );

    if (seleccionada != null) {
      setState(() {
        switch (tramo) {
          case 'salidaSede':
            salidaSede = seleccionada;
            break;
          case 'llegadaFabrica':
            llegadaFabrica = seleccionada;
            break;
          case 'salidaFabrica':
            salidaFabrica = seleccionada;
            break;
          case 'llegadaSede':
            llegadaSede = seleccionada;
            break;
        }
        calcularDiferencias();
      });
    }
  }

  ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF4682B4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(horizontal: 20),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tiempoIda =
        tiempoSedeAFabrica != null
            ? '${tiempoSedeAFabrica!.inHours}h ${tiempoSedeAFabrica!.inMinutes.remainder(60)}m'
            : '--';
    final tiempoRegreso =
        tiempoFabricaASede != null
            ? '${tiempoFabricaASede!.inHours}h ${tiempoFabricaASede!.inMinutes.remainder(60)}m'
            : '--';

    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 25),
              alignment: Alignment.center,
              child: const Text(
                'Reporte Transporte',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 25,
                  vertical: 10,
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            // Botones uniformes
                            _buildBoton(
                              icon: Icons.exit_to_app,
                              texto: "Salida Sede: ${formatHora(salidaSede)}",
                              onTap: () => seleccionarHoraTramo('salidaSede'),
                            ),
                            const SizedBox(height: 16),
                            _buildBoton(
                              icon: Icons.factory,
                              texto:
                                  "Llegada Fábrica: ${formatHora(llegadaFabrica)}",
                              onTap:
                                  () => seleccionarHoraTramo('llegadaFabrica'),
                            ),
                            const SizedBox(height: 16),
                            _buildBoton(
                              icon: Icons.exit_to_app,
                              texto:
                                  "Salida Fábrica: ${formatHora(salidaFabrica)}",
                              onTap:
                                  () => seleccionarHoraTramo('salidaFabrica'),
                            ),
                            const SizedBox(height: 16),
                            _buildBoton(
                              icon: Icons.home,
                              texto: "Llegada Sede: ${formatHora(llegadaSede)}",
                              onTap: () => seleccionarHoraTramo('llegadaSede'),
                            ),
                            const SizedBox(height: 30),
                            Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 6,
                              color: Colors.blue.shade50,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 30,
                                  horizontal: 20,
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Tiempo Sede → Fábrica:",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      tiempoIda,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Tiempo Fábrica → Sede:",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      tiempoRegreso,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2C3E50),
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
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed:
                            (salidaSede != null &&
                                    llegadaFabrica != null &&
                                    salidaFabrica != null &&
                                    llegadaSede != null)
                                ? () async {
                                  final firestore = FirebaseFirestore.instance;
                                  await firestore.collection('transporte').add({
                                    'salida_sede': formatHora(salidaSede),
                                    'llegada_fabrica': formatHora(
                                      llegadaFabrica,
                                    ),
                                    'salida_fabrica': formatHora(salidaFabrica),
                                    'llegada_sede': formatHora(llegadaSede),
                                    'tiempo_sede_fabrica': tiempoIda,
                                    'tiempo_fabrica_sede': tiempoRegreso,
                                    'fecha_registro': Timestamp.now(),
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Datos guardados correctamente',
                                      ),
                                    ),
                                  );

                                  setState(() {
                                    salidaSede = null;
                                    llegadaFabrica = null;
                                    salidaFabrica = null;
                                    llegadaSede = null;
                                    tiempoSedeAFabrica = null;
                                    tiempoFabricaASede = null;
                                  });
                                }
                                : null,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: buttonStyle(),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoton({
    required IconData icon,
    required String texto,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          texto,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        onPressed: onTap,
        style: buttonStyle(),
      ),
    );
  }
}
