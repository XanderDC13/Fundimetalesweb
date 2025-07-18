import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialTareasScreen extends StatefulWidget {
  const HistorialTareasScreen({super.key});

  @override
  State<HistorialTareasScreen> createState() => _HistorialTareasScreenState();
}

class _HistorialTareasScreenState extends State<HistorialTareasScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Column(
        children: [
          SafeArea(child: _buildHeader()),
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('usuarios_activos')
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar usuarios'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final usuarios = snapshot.data!.docs;

                final usuariosFiltrados =
                    usuarios.where((doc) {
                      final nombre =
                          doc['nombre']?.toString().toLowerCase() ?? '';
                      return nombre.contains(_searchQuery.toLowerCase());
                    }).toList();

                if (usuariosFiltrados.isEmpty) {
                  return const Center(
                    child: Text('No se encontraron usuarios'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: usuariosFiltrados.length,
                  itemBuilder: (context, index) {
                    final userDoc = usuariosFiltrados[index];
                    final nombre = userDoc['nombre'] ?? 'Sin nombre';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (_) => HistorialUsuarioScreen(
                                    userId: userDoc.id,
                                    userName: nombre,
                                  ),
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
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Text(
          'Historial de Usuarios',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        decoration: InputDecoration(
          hintText: 'Buscar usuario...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class HistorialUsuarioScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const HistorialUsuarioScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<HistorialUsuarioScreen> createState() => _HistorialUsuarioScreenState();
}

class _HistorialUsuarioScreenState extends State<HistorialUsuarioScreen> {
  DateTime? _fechaSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Column(
        children: [
          SafeArea(child: _buildHeader(widget.userName)),
          _buildSelectorFecha(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('usuarios_activos')
                      .doc(widget.userId)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar tareas'));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text('Usuario no encontrado'));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;
                final List<dynamic> tareasHechas = data['tareas_hechas'] ?? [];

                // Filtrar tareas por fecha seleccionada
                final tareasFiltradas =
                    tareasHechas.where((item) {
                      if (item is! Map<String, dynamic>) return false;
                      final ts = item['fechaTerminada'];
                      if (ts is! Timestamp) return false;
                      final fecha = ts.toDate();

                      // Si no hay fecha seleccionada, mostrar todas las tareas
                      if (_fechaSeleccionada == null) return true;

                      // Comparar solo la fecha (sin hora)
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

                      return fechaTarea.isAtSameMomentAs(fechaFiltro);
                    }).toList();

                if (tareasFiltradas.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                  padding: const EdgeInsets.all(16),
                  itemCount: tareasFiltradas.length,
                  itemBuilder: (context, index) {
                    final tarea =
                        tareasFiltradas[index] as Map<String, dynamic>;
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.green),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  descripcion,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
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

  Widget _buildHeader(String nombre) {
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Historial de $nombre',
          style: const TextStyle(
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
                  lastDate: DateTime.now(),
                );
                if (seleccion != null) {
                  setState(() => _fechaSeleccionada = seleccion);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      color: const Color(0xFF2C3E50),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _fechaSeleccionada == null
                          ? 'Seleccionar fecha'
                          : DateFormat(
                            'dd/MM/yyyy',
                          ).format(_fechaSeleccionada!),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_fechaSeleccionada != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                setState(() => _fechaSeleccionada = null);
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.clear, color: Colors.red, size: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
