import 'package:basefundi/desktop/fundicion/tareasfundi_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OperadoresListDeskScreen extends StatefulWidget {
  const OperadoresListDeskScreen({super.key});

  @override
  State<OperadoresListDeskScreen> createState() =>
      _OperadoresListDeskScreenState();
}

class _OperadoresListDeskScreenState extends State<OperadoresListDeskScreen> {
  String _searchOperador = '';

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
                      'Control de Operadores',
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: _buildFilters(),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream:
                                FirebaseFirestore.instance
                                    .collection('usuarios_activos')
                                    .where(
                                      'rol',
                                      whereIn: [
                                        'Supervisor Fundición',
                                        'Operador Fundición',
                                      ],
                                    )
                                    .snapshots(),

                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay operadores activos con ese rol.',
                                  ),
                                );
                              }

                              final allOperadores = snapshot.data!.docs;
                              final filteredOperadores = _filtrarOperadores(
                                allOperadores,
                              );

                              if (filteredOperadores.isEmpty) {
                                return const Center(
                                  child: Text(
                                    'No hay resultados para los filtros seleccionados.',
                                  ),
                                );
                              }

                              return GridView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 16,
                                      mainAxisSpacing: 16,
                                      childAspectRatio: 1.2,
                                    ),
                                itemCount: filteredOperadores.length,
                                itemBuilder: (context, index) {
                                  final operador = filteredOperadores[index];
                                  return _buildOperadorCard(operador);
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
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filtrarOperadores(
    List<QueryDocumentSnapshot> operadores,
  ) {
    var filteredByName =
        operadores.where((operador) {
          final nombre = (operador['nombre'] ?? '').toString().toLowerCase();
          final searchLower = _searchOperador.toLowerCase();
          return nombre.contains(searchLower);
        }).toList();

    return filteredByName;
  }

  Widget _buildOperadorCard(QueryDocumentSnapshot operador) {
    final nombre = operador['nombre'] ?? 'Sin nombre';

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('tareas_operador')
              .where('operador_id', isEqualTo: operador.id)
              .where('estado', isEqualTo: 'asignada')
              .snapshots(),
      builder: (context, tareasSnapshot) {
        final tareasPendientes =
            tareasSnapshot.hasData ? tareasSnapshot.data!.docs.length : 0;

        return GestureDetector(
          onTap: () {
            navegarConFade(
              context,
              OperadorControlDeskScreen(
                operadorId: operador.id,
                operadorNombre: nombre,
              ),
            );
          },
          child: Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFF2C3E50),
                          child: Text(
                            nombre.isNotEmpty ? nombre[0].toUpperCase() : 'O',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.assignment,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$tareasPendientes tareas',
                          style: TextStyle(
                            color:
                                tareasPendientes > 0
                                    ? Colors.orange
                                    : Colors.grey[600],
                            fontSize: 12,
                            fontWeight:
                                tareasPendientes > 0
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          navegarConFade(
                            context,
                            OperadorControlDeskScreen(
                              operadorId: operador.id,
                              operadorNombre: nombre,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C3E50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'Ver Control',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre ...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchOperador = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ],
    );
  }
}
