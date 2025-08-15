import 'package:basefundi/settings/navbar_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistorialTareasDeskScreen extends StatefulWidget {
  const HistorialTareasDeskScreen({super.key});

  @override
  State<HistorialTareasDeskScreen> createState() =>
      _HistorialTareasDeskScreenState();
}

class _HistorialTareasDeskScreenState extends State<HistorialTareasDeskScreen> {
  String _searchQuery = '';

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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Historial de Usuarios',
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
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                            decoration: InputDecoration(
                              hintText: 'Buscar usuario...',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF0F4F8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 0,
                                horizontal: 16,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('usuarios_activos')
                                      .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Center(
                                    child: Text('Error al cargar usuarios'),
                                  );
                                }
                                if (!snapshot.hasData) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final usuarios = snapshot.data!.docs;

                                final usuariosFiltrados =
                                    usuarios.where((doc) {
                                      final nombre =
                                          doc['nombre']
                                              ?.toString()
                                              .toLowerCase() ??
                                          '';
                                      return nombre.contains(
                                        _searchQuery.toLowerCase(),
                                      );
                                    }).toList();

                                if (usuariosFiltrados.isEmpty) {
                                  return const Center(
                                    child: Text('No se encontraron usuarios'),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: usuariosFiltrados.length,
                                  itemBuilder: (context, index) {
                                    final userDoc = usuariosFiltrados[index];
                                    final nombre =
                                        userDoc['nombre'] ?? 'Sin nombre';

                                    return Card(
                                      color: const Color(0xFFF7F5F5),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: ListTile(
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 16,
                                            ),
                                        leading: CircleAvatar(
                                          backgroundColor: const Color.fromRGBO(
                                            255,
                                            255,
                                            255,
                                            1,
                                          ).withOpacity(0.15),
                                          child: const Icon(
                                            Icons.person,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        title: Text(
                                          nombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Color(0xFF2C3E50),
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                        onTap: () {
                                          navegarConFade(
                                            context,
                                            HistorialUsuarioDeskScreen(
                                              userId: userDoc.id,
                                              userName: nombre,
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
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
          ),
        ],
      ),
    );
  }
}

// HISTORIAL USUARIO DESKTOP
class HistorialUsuarioDeskScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const HistorialUsuarioDeskScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<HistorialUsuarioDeskScreen> createState() =>
      _HistorialUsuarioDeskScreenState();
}

class _HistorialUsuarioDeskScreenState
    extends State<HistorialUsuarioDeskScreen> {
  DateTime? _fechaSeleccionada;

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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Historial de ${widget.userName}',
                      style: const TextStyle(
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
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final seleccion = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          _fechaSeleccionada ?? DateTime.now(),
                                      firstDate: DateTime(2023),
                                      lastDate: DateTime.now(),
                                    );
                                    if (seleccion != null) {
                                      setState(
                                        () => _fechaSeleccionada = seleccion,
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F4F8),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _fechaSeleccionada == null
                                              ? 'Seleccionar fecha'
                                              : DateFormat(
                                                'dd/MM/yyyy',
                                              ).format(_fechaSeleccionada!),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (_fechaSeleccionada != null) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap:
                                      () => setState(
                                        () => _fechaSeleccionada = null,
                                      ),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.clear,
                                      color: Colors.red,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 32),
                          Expanded(
                            child: StreamBuilder<DocumentSnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('usuarios_activos')
                                      .doc(widget.userId)
                                      .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return const Center(
                                    child: Text('Error al cargar tareas'),
                                  );
                                }
                                if (!snapshot.hasData ||
                                    !snapshot.data!.exists) {
                                  return const Center(
                                    child: Text('Usuario no encontrado'),
                                  );
                                }

                                final data =
                                    snapshot.data!.data()
                                        as Map<String, dynamic>;
                                final List<dynamic> tareasHechas =
                                    data['tareas_hechas'] ?? [];

                                final tareasFiltradas =
                                    tareasHechas.where((item) {
                                      if (item is! Map<String, dynamic>)
                                        return false;
                                      final ts = item['fechaTerminada'];
                                      if (ts is! Timestamp) return false;
                                      final fecha = ts.toDate();

                                      if (_fechaSeleccionada == null)
                                        return true;

                                      final fechaTarea = DateTime(
                                        fecha.year,
                                        fecha.month,
                                        fecha.day,
                                      );
                                      final fechaFiltro = DateTime(
                                        _fechaSeleccionada!.year,
                                        _fechaSeleccionada!.month,
                                        _fechaSeleccionada!.day,
                                      );

                                      return fechaTarea.isAtSameMomentAs(
                                        fechaFiltro,
                                      );
                                    }).toList();

                                if (tareasFiltradas.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.assignment_outlined,
                                          size: 64,
                                          color: Color(0xFFB0BEC5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _fechaSeleccionada == null
                                              ? 'No hay tareas completadas'
                                              : 'No hay tareas para la fecha seleccionada',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: tareasFiltradas.length,
                                  itemBuilder: (context, index) {
                                    final tarea =
                                        tareasFiltradas[index]
                                            as Map<String, dynamic>;
                                    final descripcion =
                                        tarea['descripcion'] ??
                                        'Tarea sin descripción';
                                    final fecha =
                                        (tarea['fechaTerminada'] as Timestamp)
                                            .toDate();
                                    final fechaTexto = DateFormat(
                                      'dd/MM/yyyy HH:mm',
                                    ).format(fecha);

                                    return Card(
                                      color: const Color(0xFFEBE5E5),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(
                                                  0.15,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check,
                                                color: Colors.green,
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
                                                      decoration:
                                                          TextDecoration
                                                              .lineThrough,
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
                                      ),
                                    );
                                  },
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
          ),
        ],
      ),
    );
  }
}
