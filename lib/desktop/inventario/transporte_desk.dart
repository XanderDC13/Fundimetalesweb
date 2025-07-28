import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/settings/navbar_desk.dart'; // Usa tu MainDeskLayout

class TransporteDeskScreen extends StatefulWidget {
  const TransporteDeskScreen({super.key});

  @override
  State<TransporteDeskScreen> createState() => _TransporteDeskScreenState();
}

class _TransporteDeskScreenState extends State<TransporteDeskScreen>
    with SingleTickerProviderStateMixin {
  TimeOfDay? salidaSede;
  TimeOfDay? llegadaFabrica;
  TimeOfDay? salidaFabrica;
  TimeOfDay? llegadaSede;
  Duration? tiempoSedeAFabrica;
  Duration? tiempoFabricaASede;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

    return MainDeskLayout(
      child: Column(
        children: [
          // CABECERA TIPO DESKTOP
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
                      'Reporte Transporte',
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

          // CONTENIDO CON FADE
          Expanded(
            child: Container(
              color: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 64,
                    vertical: 32,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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
                          onTap: () => seleccionarHoraTramo('llegadaFabrica'),
                        ),
                        const SizedBox(height: 16),
                        _buildBoton(
                          icon: Icons.exit_to_app,
                          texto: "Salida Fábrica: ${formatHora(salidaFabrica)}",
                          onTap: () => seleccionarHoraTramo('salidaFabrica'),
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
                        const SizedBox(height: 30),
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
                                      final firestore =
                                          FirebaseFirestore.instance;
                                      await firestore
                                          .collection('transporte')
                                          .add({
                                            'salida_sede': formatHora(
                                              salidaSede,
                                            ),
                                            'llegada_fabrica': formatHora(
                                              llegadaFabrica,
                                            ),
                                            'salida_fabrica': formatHora(
                                              salidaFabrica,
                                            ),
                                            'llegada_sede': formatHora(
                                              llegadaSede,
                                            ),
                                            'tiempo_sede_fabrica': tiempoIda,
                                            'tiempo_fabrica_sede':
                                                tiempoRegreso,
                                            'fecha_registro': Timestamp.now(),
                                          });

                                      ScaffoldMessenger.of(
                                        // ignore: use_build_context_synchronously
                                        context,
                                      ).showSnackBar(
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
