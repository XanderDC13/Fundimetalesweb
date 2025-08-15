import 'package:basefundi/desktop/personal/funciones/tareas_finalizadas_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TareasPendientesDeskScreen extends StatelessWidget {
  const TareasPendientesDeskScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA CON TRANSFORM Y TÍTULO
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
                      'Tareas Pendientes',
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

          // ✅ CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('usuarios_activos')
                                .doc(user.uid)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Error al cargar tareas'),
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Center(
                              child: Text('No se encontró usuario'),
                            );
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final List<dynamic> tareas = List.from(
                            data['tareas'] ?? [],
                          );

                          if (tareas.isEmpty) {
                            return const Center(
                              child: Text(
                                'No tienes tareas pendientes',
                                style: TextStyle(color: Color(0xFFB0BEC5)),
                              ),
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ListView.builder(
                                  itemCount: tareas.length,
                                  itemBuilder: (context, index) {
                                    final tarea = tareas[index];

                                    return Card(
                                      color: const Color(0xFFF7F5F5),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 1,
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.task_alt,
                                          color: Color(0xFF1E3A8A),
                                        ),
                                        title: Text(
                                          tarea.toString(),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        trailing: IconButton(
                                          icon: const Icon(
                                            Icons.check,
                                            color: Colors.green,
                                          ),
                                          tooltip: 'Marcar como hecha',
                                          onPressed: () {
                                            final ref = FirebaseFirestore
                                                .instance
                                                .collection('usuarios_activos')
                                                .doc(user.uid);

                                            ref.update({
                                              'tareas': FieldValue.arrayRemove([
                                                tarea,
                                              ]),
                                              'tareas_hechas':
                                                  FieldValue.arrayUnion([
                                                    {
                                                      'descripcion': tarea,
                                                      'fechaTerminada':
                                                          Timestamp.now(),
                                                    },
                                                  ]),
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    navegarConFade(
                                      context,
                                      const TareasTerminadasDeskScreen(),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Ver tareas completadas'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4682B4),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
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
