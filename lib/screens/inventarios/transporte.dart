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
  TimeOfDay? horaLlegada;
  TimeOfDay? horaSalida;
  Duration? diferencia;

  String formatHora(TimeOfDay? hora) {
    if (hora == null) return '--:--';
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, hora.hour, hora.minute);
    return DateFormat('hh:mm a').format(dt);
  }

  void calcularDiferencia() {
    if (horaLlegada != null && horaSalida != null) {
      final ahora = DateTime.now();
      final llegada = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        horaLlegada!.hour,
        horaLlegada!.minute,
      );
      final salida = DateTime(
        ahora.year,
        ahora.month,
        ahora.day,
        horaSalida!.hour,
        horaSalida!.minute,
      );
      setState(() {
        diferencia = salida.difference(llegada);
      });
    }
  }

  Future<void> seleccionarHora(bool esLlegada) async {
    final TimeOfDay? seleccionada = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText:
          esLlegada
              ? 'Seleccionar hora de llegada'
              : 'Seleccionar hora de salida',
    );

    if (seleccionada != null) {
      setState(() {
        if (esLlegada) {
          horaLlegada = seleccionada;
        } else {
          horaSalida = seleccionada;
        }
        calcularDiferencia();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiempoDemora =
        diferencia != null
            ? '${diferencia!.inHours}h ${diferencia!.inMinutes.remainder(60)}min'
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
                'Transporte',
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.exit_to_app,
                                  size: 28,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Hora de salida: ${formatHora(horaSalida)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4682B4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 20,
                                  ),
                                ),
                                onPressed: () => seleccionarHora(false),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.login,
                                  size: 28,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  "Hora de llegada: ${formatHora(horaLlegada)}",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4682B4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 20,
                                  ),
                                ),
                                onPressed: () => seleccionarHora(true),
                              ),
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
                                      "Tiempo de demora:",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      tiempoDemora,
                                      style: const TextStyle(
                                        fontSize: 28,
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
                      child: ElevatedButton.icon(
                        onPressed:
                            (horaLlegada != null &&
                                    horaSalida != null &&
                                    diferencia != null)
                                ? () async {
                                  final firestore = FirebaseFirestore.instance;
                                  final tiempo =
                                      '${diferencia!.inHours}h ${diferencia!.inMinutes.remainder(60)} min';

                                  await firestore.collection('transporte').add({
                                    'hora_llegada': formatHora(horaLlegada),
                                    'hora_salida': formatHora(horaSalida),
                                    'tiempo_demora': tiempo,
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
                                    horaLlegada = null;
                                    horaSalida = null;
                                    diferencia = null;
                                  });
                                }
                                : null,
                        icon: const Icon(Icons.save, color: Colors.white),
                        label: const Text(
                          'Guardar',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
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
}
