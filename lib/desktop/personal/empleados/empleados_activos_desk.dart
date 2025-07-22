import 'package:basefundi/settings/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA ESCRITORIO
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
                      'Empleados Activos',
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

          // ✅ CONTENIDO TABLA
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
                                  headingRowColor: MaterialStateProperty.all(
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
                                          'Administrador',
                                          'Empleado',
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
                                              DropdownButton<String>(
                                                value: valorRol,
                                                underline: Container(),
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
                                                onChanged: (nuevoRol) {
                                                  if (nuevoRol != null) {
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                          'usuarios_activos',
                                                        )
                                                        .doc(empleado.id)
                                                        .update({
                                                          'rol': nuevoRol,
                                                        });
                                                  }
                                                },
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

  void _confirmarEliminacion(
    BuildContext context,
    String docId,
    String nombre,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFFF5F6FA),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 48,
                    color: Color(0xFF1E40AF),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¿Eliminar empleado?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Estás seguro de que deseas eliminar a "$nombre"? Esta acción no se puede deshacer.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[300],
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await FirebaseFirestore.instance
                              .collection('usuarios_activos')
                              .doc(docId)
                              .delete();
                          if (!mounted) return;
                          _scaffoldMessengerKey.currentState?.showSnackBar(
                            const SnackBar(
                              content: Text('Empleado eliminado correctamente'),
                            ),
                          );
                        },
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
