import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class TareasTerminadasScreen extends StatefulWidget {
  const TareasTerminadasScreen({super.key});

  @override
  State<TareasTerminadasScreen> createState() => _TareasTerminadasScreenState();
}

class _TareasTerminadasScreenState extends State<TareasTerminadasScreen> {
  DateTime? _fechaSeleccionada;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Column(
        children: [
          SafeArea(child: _buildHeader()),
          _buildSelectorFecha(),
          Expanded(
            child:
                user == null
                    ? const Center(child: Text('Usuario no autenticado'))
                    : StreamBuilder<DocumentSnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('usuarios_activos')
                              .doc(user.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text('Error al cargar datos'),
                          );
                        }
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Center(
                            child: Text('No se encontró usuario'),
                          );
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final List<dynamic> tareasHechas = List.from(
                          data['tareas_hechas'] ?? [],
                        );

                        final tareasFiltradas =
                            tareasHechas.where((tarea) {
                              if (tarea is! Map<String, dynamic>) return false;
                              final ts = tarea['fechaTerminada'];
                              if (ts is! Timestamp) return false;

                              final fecha = ts.toDate();
                              if (_fechaSeleccionada == null) return true;

                              return fecha.year == _fechaSeleccionada!.year &&
                                  fecha.month == _fechaSeleccionada!.month &&
                                  fecha.day == _fechaSeleccionada!.day;
                            }).toList();

                        if (tareasFiltradas.isEmpty) {
                          return const Center(
                            child: Text('No hay tareas completadas'),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tareasFiltradas.length,
                          itemBuilder: (context, index) {
                            final tarea = tareasFiltradas[index];
                            final descripcion =
                                tarea['descripcion'] ?? 'Tarea sin descripción';
                            final fecha =
                                (tarea['fechaTerminada'] as Timestamp).toDate();
                            final fechaTexto = DateFormat(
                              'dd/MM/yyyy HH:mm',
                            ).format(fecha);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          descripcion,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w600,
                                            decoration:
                                                TextDecoration.lineThrough,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Terminada el: $fechaTexto',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: const Center(
        child: Text(
          'Tareas Completadas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorFecha() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final seleccion = await showDatePicker(
                  context: context,
                  initialDate: _fechaSeleccionada ?? DateTime.now(),
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2100),
                );
                if (seleccion != null) {
                  setState(() => _fechaSeleccionada = seleccion);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _fechaSeleccionada == null
                          ? 'Seleccionar fecha'
                          : DateFormat(
                            'dd/MM/yyyy',
                          ).format(_fechaSeleccionada!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_fechaSeleccionada != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Quitar filtro',
              onPressed: () => setState(() => _fechaSeleccionada = null),
            ),
          ],
        ],
      ),
    );
  }
}
