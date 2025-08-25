import 'package:basefundi/services/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmpleadosActivosDeskScreen extends StatefulWidget {
  const EmpleadosActivosDeskScreen({super.key});

  @override
  State<EmpleadosActivosDeskScreen> createState() =>
      _EmpleadosActivosDeskScreenState();
}

class _EmpleadosActivosDeskScreenState
    extends State<EmpleadosActivosDeskScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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
                      'Usuarios Activos',
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
                child: Align(
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
                                    .collection('usuarios_activos')
                                    .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text('Error al cargar empleados'),
                                );
                              }

                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final empleados = snapshot.data!.docs;

                              if (empleados.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay empleados activos.',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFFB0BEC5),
                                    ),
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 32,
                                  headingRowColor: WidgetStateProperty.all(
                                    const Color(0xFF4682B4),
                                  ),
                                  headingTextStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  columns: const [
                                    DataColumn(label: Text('Nombre')),
                                    DataColumn(label: Text('Email')),
                                    DataColumn(label: Text('Sede')),
                                    DataColumn(label: Text('Rol')),
                                    DataColumn(label: Text('Acción')),
                                  ],
                                  rows:
                                      empleados.map((empleado) {
                                        final nombre =
                                            empleado['nombre'] ?? 'Sin nombre';
                                        final email =
                                            empleado['email'] ?? 'Sin email';
                                        final sede =
                                            (empleado.data()
                                                        as Map<String, dynamic>)
                                                    .containsKey('sede')
                                                ? empleado['sede']
                                                : 'Sin sede';
                                        final rol =
                                            empleado['rol'] ?? 'Empleado';
                                        final roles = [
                                          'Administrador General',
                                          'Gerente Sede',
                                          'Vendedor',
                                          'Supervisor Fundición',
                                          'Operador Fundición',
                                          'Supervisor Mecanizado',
                                          'Operador Mecanizado',
                                        ];

                                        final valorRol = roles.firstWhere(
                                          (r) =>
                                              r.toLowerCase() ==
                                              rol.toLowerCase(),
                                          orElse: () => roles.first,
                                        );

                                        return DataRow(
                                          cells: [
                                            DataCell(Text(nombre)),
                                            DataCell(Text(email)),
                                            DataCell(Text(sede)),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      Colors
                                                          .white, // ✅ Fondo blanco
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: DropdownButton<String>(
                                                  value: valorRol,
                                                  underline:
                                                      Container(), // Elimina la línea inferior
                                                  isExpanded:
                                                      true, // ✅ Ocupa todo el ancho disponible
                                                  dropdownColor:
                                                      Colors
                                                          .white, // ✅ También blanco al desplegar
                                                  items:
                                                      roles.map((String value) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: value,
                                                          child: Row(
                                                            children: [
                                                              Icon(
                                                                value ==
                                                                        'Administrador'
                                                                    ? Icons
                                                                        .security
                                                                    : Icons
                                                                        .supervisor_account,
                                                                color:
                                                                    const Color(
                                                                      0xFF2C3E50,
                                                                    ),
                                                                size: 18,
                                                              ),
                                                              const SizedBox(
                                                                width: 8,
                                                              ),
                                                              Text(value),
                                                            ],
                                                          ),
                                                        );
                                                      }).toList(),
                                                  onChanged: (nuevoRol) async {
                                                    if (nuevoRol != null &&
                                                        nuevoRol != rol) {
                                                      // Actualizar el rol en Firestore
                                                      await FirebaseFirestore
                                                          .instance
                                                          .collection(
                                                            'usuarios_activos',
                                                          )
                                                          .doc(empleado.id)
                                                          .update({
                                                            'rol': nuevoRol,
                                                          });

                                                      // Registrar auditoría del cambio de rol
                                                      await _registrarAuditoria(
                                                        accion:
                                                            'Cambiar Rol Usuario',
                                                        detalle:
                                                            'Usuario: $nombre, Rol anterior: $rol, Nuevo rol: $nuevoRol'
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),

                                            DataCell(
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.redAccent,
                                                ),
                                                tooltip: 'Eliminar empleado',
                                                onPressed:
                                                    () => _confirmarEliminacion(
                                                      context,
                                                      empleado.id,
                                                      nombre,
                                                      sede,
                                                      rol,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                ),
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

  Future<void> _confirmarEliminacion(
    BuildContext context,
    String docId,
    String nombre,
    String sede,
    String rol,
  ) async {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 28,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Eliminar Empleado',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Estás seguro de que deseas eliminar a "$nombre"?',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              Navigator.of(context).pop();

                              // Eliminar usuario de Firestore
                              await FirebaseFirestore.instance
                                  .collection('usuarios_activos')
                                  .doc(docId)
                                  .delete();

                              // Registrar auditoría de eliminación
                              await _registrarAuditoria(
                                accion: 'Eliminar Usuario',
                                detalle:
                                    'Usuario: $nombre, Rol: $rol, Sede: $sede',
                              );

                              if (!mounted) return;
                              _scaffoldMessengerKey.currentState?.showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Empleado $nombre eliminado correctamente',
                                  ),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            },
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
  }
}
