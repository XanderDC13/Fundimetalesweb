import 'package:basefundi/movil/personal/funciones/tareas_historial_movil.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FuncionesScreen extends StatefulWidget {
  const FuncionesScreen({super.key});

  @override
  State<FuncionesScreen> createState() => _FuncionesScreenState();
}

class _FuncionesScreenState extends State<FuncionesScreen> {
  String _searchText = '';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuario no autenticado')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('usuarios_activos')
                        .doc(user.uid)
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error al cargar datos'));
                  }
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(child: Text('Datos no encontrados'));
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final rol = (data['rol'] ?? 'empleado').toString();

                  if (rol.toLowerCase() == 'administrador') {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 0,
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.search),
                              hintText: 'Buscar usuario por nombre',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              fillColor: Colors.white,
                              filled: true,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchText = value.trim().toLowerCase();
                              });
                            },
                          ),
                        ),
                        Expanded(child: _buildListaEmpleados()),
                      ],
                    );
                  } else {
                    return _buildTareasIndividual(
                      user.uid,
                      data['nombre'] ?? 'Sin nombre',
                      data['tareas'] ?? [],
                    );
                  }
                },
              ),
            ),
            // Botón movido a la parte inferior
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.history, color: Colors.white),
                label: const Text(
                  'Historial de Tareas',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HistorialTareasScreen(),
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

  Widget _buildListaEmpleados() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('usuarios_activos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar empleados'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final empleados =
            snapshot.data!.docs.where((doc) {
              final nombre = (doc['nombre'] ?? '').toString().toLowerCase();
              return nombre.contains(_searchText);
            }).toList();

        if (empleados.isEmpty) {
          return const Center(child: Text('No se encontraron usuarios'));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: empleados.length,
          itemBuilder: (context, index) {
            final empleado = empleados[index];
            final nombre = empleado['nombre'] ?? 'Sin nombre';
            final data = empleado.data() as Map<String, dynamic>;
            final List tareas =
                data.containsKey('tareas') ? List.from(data['tareas']) : [];

            final tareasController = TextEditingController();

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 20),
              color: Colors.white,
              shadowColor: Colors.blueAccent.withOpacity(0.2),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Tareas asignadas:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (tareas.isEmpty)
                      const Text(
                        'Sin tareas asignadas',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...tareas.map<Widget>((tarea) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_box_outlined,
                                size: 20,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tarea.toString(),
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.orange,
                                ),
                                tooltip: 'Editar tarea',
                                onPressed: () {
                                  _showEditarTareaDialog(empleado.id, tarea);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Eliminar tarea',
                                onPressed: () {
                                  _eliminarTarea(empleado.id, tarea);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tareasController,
                            decoration: InputDecoration(
                              hintText: 'Nueva tarea',
                              hintStyle: const TextStyle(
                                color: Color(0xFFB0BEC5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0F4F8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            final nuevaTarea = tareasController.text.trim();
                            if (nuevaTarea.isNotEmpty) {
                              FirebaseFirestore.instance
                                  .collection('usuarios_activos')
                                  .doc(empleado.id)
                                  .update({
                                    'tareas': FieldValue.arrayUnion([
                                      nuevaTarea,
                                    ]),
                                  });
                              tareasController.clear();
                              FocusScope.of(context).unfocus();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4682B4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                            shadowColor: Color(0xFF4682B4),
                          ),
                          child: const Text(
                            'Agregar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
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
    );
  }

  Widget _buildTareasIndividual(String uid, String nombre, List tareas) {
    final tareasController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 6,
        shadowColor: Colors.blueAccent.withOpacity(0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tus Tareas:',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              if (tareas.isEmpty)
                const Text(
                  'No tienes tareas asignadas.',
                  style: TextStyle(color: Colors.grey),
                )
              else
                ...tareas.map<Widget>((tarea) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_box_outlined, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            tarea.toString(),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          tooltip: 'Editar tarea',
                          onPressed: () {
                            _showEditarTareaDialog(uid, tarea);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Eliminar tarea',
                          onPressed: () {
                            _eliminarTarea(uid, tarea);
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tareasController,
                      decoration: InputDecoration(
                        hintText: 'Nueva tarea',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: () {
                      final nuevaTarea = tareasController.text.trim();
                      if (nuevaTarea.isNotEmpty) {
                        FirebaseFirestore.instance
                            .collection('usuarios_activos')
                            .doc(uid)
                            .update({
                              'tareas': FieldValue.arrayUnion([nuevaTarea]),
                            });
                        tareasController.clear();
                        FocusScope.of(context).unfocus();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E40AF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                      shadowColor: Colors.blueAccent,
                    ),
                    child: const Text(
                      'Agregar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditarTareaDialog(String uid, dynamic tareaOriginal) {
    final editController = TextEditingController(
      text: tareaOriginal.toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar tarea'),
          content: TextField(
            controller: editController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Modificar tarea'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevoTexto = editController.text.trim();
                if (nuevoTexto.isNotEmpty) {
                  final docRef = FirebaseFirestore.instance
                      .collection('usuarios_activos')
                      .doc(uid);

                  // Primero removemos la tarea original
                  await docRef.update({
                    'tareas': FieldValue.arrayRemove([tareaOriginal]),
                  });

                  // Luego agregamos la tarea modificada
                  await docRef.update({
                    'tareas': FieldValue.arrayUnion([nuevoTexto]),
                  });

                  Navigator.of(context).pop();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarTarea(String uid, dynamic tarea) async {
    final docRef = FirebaseFirestore.instance
        .collection('usuarios_activos')
        .doc(uid);

    await docRef.update({
      'tareas': FieldValue.arrayRemove([tarea]),
    });
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
          'Gestión de Tareas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

extension on Object? {}
