import 'package:basefundi/desktop/personal/empleados/empleados_activos_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmpleadosPendientesDeskScreen extends StatefulWidget {
  const EmpleadosPendientesDeskScreen({super.key});

  @override
  State<EmpleadosPendientesDeskScreen> createState() =>
      _EmpleadosPendientesDeskScreenState();
}

void _navegarConFade(BuildContext context, Widget pantalla) {
  Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => pantalla,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 150),
    ),
  );
}

class _EmpleadosPendientesDeskScreenState
    extends State<EmpleadosPendientesDeskScreen> {
  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA con Transform y flecha retroceso
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
                      'Personal - Pendientes',
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

          // ✅ CONTENIDO
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: FutureBuilder<User?>(
                  future: FirebaseAuth.instance.authStateChanges().first,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Center(child: Text('Acceso no autorizado.'));
                    }

                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            Expanded(
                              child: StreamBuilder<QuerySnapshot>(
                                stream:
                                    FirebaseFirestore.instance
                                        .collection('usuarios_pendientes')
                                        .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Center(
                                      child: Text('Error al cargar usuarios'),
                                    );
                                  }

                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final usuarios = snapshot.data!.docs;

                                  if (usuarios.isEmpty) {
                                    return const Center(
                                      child: Text(
                                        'No hay usuarios pendientes',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFFB0BEC5),
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                    ),
                                    itemCount: usuarios.length,
                                    itemBuilder: (context, index) {
                                      final user = usuarios[index];
                                      final nombre =
                                          user['nombre'] ?? 'Sin nombre';
                                      final email =
                                          user['email'] ?? 'Sin email';
                                      final rol = user['rol'] ?? 'Sin rol';
                                      final sede = user['sede'] ?? 'Sin sede';

                                      return Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        elevation: 0,
                                        color: Colors.white,
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor: Color(
                                                      0xFF1E3A8A,
                                                    ),
                                                    child: Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          nombre,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Color(
                                                                  0xFF1E3A8A,
                                                                ),
                                                              ),
                                                        ),
                                                        Text(
                                                          email,
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                        Text(
                                                          'Sede: $sede',
                                                          style:
                                                              const TextStyle(
                                                                color:
                                                                    Colors.grey,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  const Text(
                                                    'Rol:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                  DropdownButton<String>(
                                                    value: rol,
                                                    underline: Container(),
                                                    items: const [
                                                      DropdownMenuItem(
                                                        value: 'Administrador',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons.security,
                                                              color: Color(
                                                                0xFF2C3E50,
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text(
                                                              'Administrador',
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      DropdownMenuItem(
                                                        value: 'Empleado',
                                                        child: Row(
                                                          children: [
                                                            Icon(
                                                              Icons
                                                                  .supervisor_account,
                                                              color: Color(
                                                                0xFF2C3E50,
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            Text('Empleado'),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (nuevoRol) {
                                                      if (nuevoRol != null) {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection(
                                                              'usuarios_pendientes',
                                                            )
                                                            .doc(user.id)
                                                            .update({
                                                              'rol': nuevoRol,
                                                            });
                                                      }
                                                    },
                                                  ),
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.check,
                                                          color: Colors.green,
                                                        ),
                                                        tooltip:
                                                            'Aprobar usuario',
                                                        onPressed: () async {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'usuarios_activos',
                                                              )
                                                              .doc(user.id)
                                                              .set(
                                                                user.data()
                                                                    as Map<
                                                                      String,
                                                                      dynamic
                                                                    >,
                                                              );
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'usuarios_pendientes',
                                                              )
                                                              .doc(user.id)
                                                              .delete();
                                                        },
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.red,
                                                        ),
                                                        tooltip:
                                                            'Rechazar usuario',
                                                        onPressed: () async {
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                'usuarios_pendientes',
                                                              )
                                                              .doc(user.id)
                                                              .delete();
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _navegarConFade(
                                    context,
                                    const EmpleadosActivosDeskScreen(),
                                  );
                                },

                                icon: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                ),
                                label: const Text('Ver empleados activos'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4682B4),
                                  foregroundColor: const Color.fromARGB(
                                    255,
                                    255,
                                    255,
                                    255,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
