import 'package:basefundi/desktop/personal/funciones/tareas_historial_desk.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FuncionesDeskScreen extends StatefulWidget {
  const FuncionesDeskScreen({super.key});

  @override
  State<FuncionesDeskScreen> createState() => _FuncionesDeskScreenState();
}

class _FuncionesDeskScreenState extends State<FuncionesDeskScreen> {
  String _searchText = '';
  final Set<String> _expandedCards =
      {}; // Para rastrear qué tarjetas están expandidas

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
                      'Gestión de Tareas',
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
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: FutureBuilder<DocumentSnapshot>(
                        future:
                            FirebaseFirestore.instance
                                .collection('usuarios_activos')
                                .doc(user.uid)
                                .get(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return const Center(
                              child: Text('Error al cargar datos'),
                            );
                          }
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Center(
                              child: Text('Datos no encontrados'),
                            );
                          }

                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          final rol = data['rol'] ?? 'empleado';

                          if (rol == 'Administrador General') {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.search),
                                    hintText: 'Buscar usuario por nombre',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    fillColor: const Color(0xFFF0F4F8),
                                    filled: true,
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _searchText = value.trim().toLowerCase();
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      navegarConFade(
                                        context,
                                        const HistorialTareasDeskScreen(),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4682B4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.history,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      'Ver Historial de Tareas',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
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
                  ),
                ),
              ),
            ),
          ),
        ],
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
              final data = doc.data() as Map<String, dynamic>;
              final nombre = (data['nombre'] ?? '').toString().toLowerCase();
              return nombre.contains(_searchText);
            }).toList();

        if (empleados.isEmpty) {
          return const Center(child: Text('No se encontraron usuarios'));
        }

        return ListView.builder(
          itemCount: empleados.length,
          itemBuilder: (context, index) {
            final empleado = empleados[index];
            final nombre = empleado['nombre'] ?? 'Sin nombre';
            final data = empleado.data() as Map<String, dynamic>;
            final List tareas =
                data.containsKey('tareas') ? List.from(data['tareas']) : [];
            final tareasController = TextEditingController();
            final isExpanded = _expandedCards.contains(empleado.id);

            return Card(
              color: const Color.fromARGB(255, 239, 247, 253),
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // LÍNEA PRINCIPAL COMPACTA
                    Row(
                      children: [
                        // Nombre y rol
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                data['rol'] ?? 'Sin rol',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Campo nueva tarea
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: tareasController,
                            decoration: InputDecoration(
                              hintText: 'Nueva tarea',
                              filled: true,
                              fillColor: const Color.fromARGB(255, 255, 255, 255),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Botón Agregar
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
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            minimumSize: const Size(0, 32),
                          ),
                          child: const Text(
                            'Agregar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Botón expandir/contraer
                        InkWell(
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedCards.remove(empleado.id);
                              } else {
                                _expandedCards.add(empleado.id);
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${tareas.length}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // SECCIÓN EXPANDIBLE DE TAREAS
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Tareas asignadas:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (tareas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Sin tareas asignadas',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        )
                      else
                        ...tareas.map<Widget>((tarea) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_box_outlined,
                                  size: 16,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tarea.toString(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  onPressed:
                                      () => _showEditarTareaDialog(
                                        empleado.id,
                                        tarea,
                                      ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                  padding: const EdgeInsets.all(2),
                                  constraints: const BoxConstraints(
                                    minWidth: 24,
                                    minHeight: 24,
                                  ),
                                  onPressed:
                                      () => _eliminarTarea(empleado.id, tarea),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombre,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tus tareas:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        if (tareas.isEmpty)
          const Text(
            'No tienes tareas asignadas',
            style: TextStyle(color: Colors.grey),
          )
        else
          ...tareas.map((tarea) {
            return Row(
              children: [
                const Icon(Icons.check_box_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(tarea.toString())),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange),
                  onPressed: () => _showEditarTareaDialog(uid, tarea),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarTarea(uid, tarea),
                ),
              ],
            );
          }).toList(),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: tareasController,
                decoration: InputDecoration(
                  hintText: 'Nueva tarea',
                  filled: true,
                  fillColor: const Color.fromARGB(255, 255, 255, 255),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
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
                      .doc(uid)
                      .update({
                        'tareas': FieldValue.arrayUnion([nuevaTarea]),
                      });
                  tareasController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Agregar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showEditarTareaDialog(String uid, dynamic tareaOriginal) {
    final editController = TextEditingController(
      text: tareaOriginal.toString(),
    );
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Editar tarea'),
          content: TextField(controller: editController),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nuevo = editController.text.trim();
                if (nuevo.isNotEmpty) {
                  final docRef = FirebaseFirestore.instance
                      .collection('usuarios_activos')
                      .doc(uid);
                  await docRef.update({
                    'tareas': FieldValue.arrayRemove([tareaOriginal]),
                  });
                  await docRef.update({
                    'tareas': FieldValue.arrayUnion([nuevo]),
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarTarea(String uid, dynamic tarea) {
    FirebaseFirestore.instance.collection('usuarios_activos').doc(uid).update({
      'tareas': FieldValue.arrayRemove([tarea]),
    });
  }
}
