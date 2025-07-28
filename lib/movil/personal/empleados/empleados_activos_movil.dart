import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmpleadosActivosScreen extends StatefulWidget {
  const EmpleadosActivosScreen({super.key});

  @override
  State<EmpleadosActivosScreen> createState() => _EmpleadosActivosScreenState();
}

class _EmpleadosActivosScreenState extends State<EmpleadosActivosScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
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
                      columnSpacing: 24,
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
                            final nombre = empleado['nombre'] ?? 'Sin nombre';
                            final email = empleado['email'] ?? 'Sin email';
                            final sede =
                                (empleado.data() as Map<String, dynamic>)
                                        .containsKey('sede')
                                    ? empleado['sede']
                                    : 'S/R';
                            final rol = empleado['rol'] ?? 'Empleado';
                            final roles = ['Administrador', 'Empleado'];

                            final valorRol = roles.firstWhere(
                              (r) => r.toLowerCase() == rol.toLowerCase(),
                              orElse: () => roles.first,
                            );

                            return DataRow(
                              cells: [
                                DataCell(Text(nombre)),
                                DataCell(Text(email)),
                                DataCell(Text(sede)),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white, // ✅ Fondo blanco
                                      borderRadius: BorderRadius.circular(8),
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
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    value == 'Administrador'
                                                        ? Icons.security
                                                        : Icons
                                                            .supervisor_account,
                                                    color: const Color(
                                                      0xFF2C3E50,
                                                    ),
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(value),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                      onChanged: (nuevoRol) {
                                        if (nuevoRol != null) {
                                          FirebaseFirestore.instance
                                              .collection('usuarios_activos')
                                              .doc(empleado.id)
                                              .update({'rol': nuevoRol});
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Center(
        child: Text(
          'Empleados Activos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
