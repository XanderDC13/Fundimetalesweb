import 'package:basefundi/desktop/personal/empleados/empleados_activos_desk.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmpleadosPendientesDeskScreen extends StatefulWidget {
  const EmpleadosPendientesDeskScreen({super.key});

  @override
  State<EmpleadosPendientesDeskScreen> createState() =>
      _EmpleadosPendientesDeskScreenState();
}

class _EmpleadosPendientesDeskScreenState
    extends State<EmpleadosPendientesDeskScreen> {
  final Map<String, String> rolesDisponibles = {
    'Administrador': 'Administrador General',
    'Gerente': 'Gerente',
    'Vendedor': 'Vendedor',
    'SupervisorFundicion': 'Supervisor Fundicion',
    'OperadorFundicion': 'Operador Fundicion',
    'SupervisorMecanizado': 'Supervisor Mecanizado',
    'OperadorMecanizado': 'Operador Mecanizado',
  };

  List<DropdownMenuItem<String>> _buildDropdownItems(
    Map<String, String> rolesDisponibles,
    String rolOriginal,
  ) {
    return rolesDisponibles.entries.map((entry) {
      String value = entry.key;
      String displayName = entry.value;

      return DropdownMenuItem<String>(
        value: value,
        child: Row(
          children: [
            Icon(
              value.contains('Administrador') || value.contains('Gerente')
                  ? Icons.security
                  : value.contains('Supervisor')
                  ? Icons.supervisor_account
                  : Icons.person,
              color: const Color(0xFF2C3E50),
            ),
            const SizedBox(width: 10),
            Text(displayName),
          ],
        ),
      );
    }).toList();
  }

  Future<void> _registrarAuditoria({
    required String accion,
    required String detalle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    String nombreUsuario = 'Administrador';

    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        nombreUsuario = doc['nombre'] ?? nombreUsuario;
      }
    }

    await FirebaseFirestore.instance.collection('auditoria_general').add({
      'fecha': FieldValue.serverTimestamp(),
      'usuario_nombre': nombreUsuario,
      'accion': accion,
      'detalle': detalle,
    });
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
                      'Usuarios Pendientes',
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
                                      final rol = user['rol'] ?? '';
                                      final sede = user['sede'] ?? 'Sin sede';

                                      String? rolValido;
                                      String rolOriginal =
                                          rol?.toString() ?? '';

                                      if (rolOriginal.isNotEmpty &&
                                          rolesDisponibles.containsKey(
                                            rolOriginal,
                                          )) {
                                        rolValido = rolOriginal;
                                      }

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
                                                  Text(
                                                    rolValido != null &&
                                                            rolesDisponibles
                                                                .containsKey(
                                                                  rolValido,
                                                                )
                                                        ? 'Rol: '
                                                        : 'Rol: Sin asignar',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF2C3E50),
                                                    ),
                                                  ),
                                                  DropdownButton<String>(
                                                    value: rolValido,
                                                    underline: Container(),
                                                    dropdownColor: Colors.white,
                                                    hint: const Text(
                                                      'Seleccionar rol',
                                                      style: TextStyle(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    items: _buildDropdownItems(
                                                      rolesDisponibles,
                                                      rolOriginal,
                                                    ),
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
                                                          if (rolValido ==
                                                                  null ||
                                                              rolValido
                                                                  .isEmpty) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Por favor, asigna un rol antes de aprobar al usuario',
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .orange,
                                                              ),
                                                            );
                                                            return;
                                                          }

                                                          if (!rolesDisponibles
                                                              .containsKey(
                                                                rolValido,
                                                              )) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'Por favor, selecciona un rol válido de la lista antes de aprobar',
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .orange,
                                                              ),
                                                            );
                                                            return;
                                                          }

                                                          {
                                                            final pendienteDoc =
                                                                await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'usuarios_pendientes',
                                                                    )
                                                                    .doc(
                                                                      user.id,
                                                                    )
                                                                    .get();

                                                            if (!pendienteDoc
                                                                .exists) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                const SnackBar(
                                                                  content: Text(
                                                                    'Error: Usuario no encontrado',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red,
                                                                ),
                                                              );
                                                              return;
                                                            }

                                                            final data =
                                                                pendienteDoc
                                                                    .data()!;
                                                            data['estado'] =
                                                                'aceptado';
                                                            data['fechaVerificacion'] =
                                                                FieldValue.serverTimestamp();
                                                            data['rol'] =
                                                                rolValido;

                                                            // Crear usuario activo
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'usuarios_activos',
                                                                )
                                                                .doc(user.id)
                                                                .set(data);

                                                            // Eliminar de pendientes
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'usuarios_pendientes',
                                                                )
                                                                .doc(user.id)
                                                                .delete();

                                                            await _registrarAuditoria(
                                                              accion:
                                                                  'Aprobar Usuario',
                                                              detalle:
                                                                  'Usuario: $nombre, Rol: ${rolesDisponibles[rolValido]}, Sede: $sede',
                                                            );
                                                          }
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
                                                          final bool?
                                                          confirm = await showDialog<
                                                            bool
                                                          >(
                                                            context: context,
                                                            builder:
                                                                (
                                                                  context,
                                                                ) => Center(
                                                                  child: ConstrainedBox(
                                                                    constraints:
                                                                        const BoxConstraints(
                                                                          maxWidth:
                                                                              500,
                                                                        ),
                                                                    child: Dialog(
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              20,
                                                                            ),
                                                                      ),
                                                                      elevation:
                                                                          12,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .white,
                                                                      child: Padding(
                                                                        padding: const EdgeInsets.symmetric(
                                                                          vertical:
                                                                              24,
                                                                          horizontal:
                                                                              28,
                                                                        ),
                                                                        child: Column(
                                                                          mainAxisSize:
                                                                              MainAxisSize.min,
                                                                          children: [
                                                                            Icon(
                                                                              Icons.warning_amber_rounded,
                                                                              color:
                                                                                  Colors.redAccent,
                                                                              size:
                                                                                  48,
                                                                            ),
                                                                            const SizedBox(
                                                                              height:
                                                                                  12,
                                                                            ),
                                                                            Text(
                                                                              'Rechazar Usuario',
                                                                              style: Theme.of(
                                                                                context,
                                                                              ).textTheme.titleLarge?.copyWith(
                                                                                fontWeight:
                                                                                    FontWeight.bold,
                                                                                color:
                                                                                    Colors.black87,
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              height:
                                                                                  8,
                                                                            ),
                                                                            Text(
                                                                              '¿Estás seguro de que quieres rechazar a "$nombre"?',
                                                                              style: Theme.of(
                                                                                context,
                                                                              ).textTheme.bodyMedium?.copyWith(
                                                                                color:
                                                                                    Colors.black54,
                                                                              ),
                                                                              textAlign:
                                                                                  TextAlign.center,
                                                                            ),
                                                                            const SizedBox(
                                                                              height:
                                                                                  28,
                                                                            ),
                                                                            Row(
                                                                              mainAxisAlignment:
                                                                                  MainAxisAlignment.end,
                                                                              children: [
                                                                                TextButton(
                                                                                  style: TextButton.styleFrom(
                                                                                    foregroundColor:
                                                                                        Colors.grey[700],
                                                                                  ),
                                                                                  onPressed:
                                                                                      () => Navigator.pop(
                                                                                        context,
                                                                                        false,
                                                                                      ),
                                                                                  child: const Text(
                                                                                    'Cancelar',
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(
                                                                                  width:
                                                                                      12,
                                                                                ),
                                                                                ElevatedButton(
                                                                                  style: ElevatedButton.styleFrom(
                                                                                    backgroundColor:
                                                                                        Colors.redAccent,
                                                                                    shape: RoundedRectangleBorder(
                                                                                      borderRadius: BorderRadius.circular(
                                                                                        12,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  onPressed:
                                                                                      () => Navigator.pop(
                                                                                        context,
                                                                                        true,
                                                                                      ),
                                                                                  child: const Text(
                                                                                    'Rechazar',
                                                                                    style: TextStyle(
                                                                                      color:
                                                                                          Colors.white,
                                                                                      fontWeight:
                                                                                          FontWeight.w600,
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                          );

                                                          if (confirm == true) {
                                                            // Eliminar usuario pendiente (SOLO esto)
                                                            await FirebaseFirestore
                                                                .instance
                                                                .collection(
                                                                  'usuarios_pendientes',
                                                                )
                                                                .doc(user.id)
                                                                .delete();

                                                            // Registrar auditoría
                                                            await _registrarAuditoria(
                                                              accion:
                                                                  'Rechazar Usuario',
                                                              detalle:
                                                                  'Usuario: $nombre, Sede: $sede',
                                                            );

                                                            // Mostrar mensaje
                                                            if (mounted) {
                                                              ScaffoldMessenger.of(
                                                                context,
                                                              ).showSnackBar(
                                                                SnackBar(
                                                                  content: Text(
                                                                    'Usuario $nombre rechazado',
                                                                  ),
                                                                  backgroundColor:
                                                                      Colors
                                                                          .redAccent,
                                                                ),
                                                              );
                                                            }
                                                          }
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
                                  navegarConFade(
                                    context,
                                    const EmpleadosActivosDeskScreen(),
                                  );
                                },
                                icon: const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                ),
                                label: const Text('Ver usuarios activos'),
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
