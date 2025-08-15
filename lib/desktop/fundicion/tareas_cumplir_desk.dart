import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OperadorTareasScreen extends StatefulWidget {
  final String operadorId;
  final String operadorNombre;
  
  const OperadorTareasScreen({
    super.key,
    required this.operadorId,
    required this.operadorNombre,
  });

  @override
  State<OperadorTareasScreen> createState() => _OperadorTareasScreenState();
}

class _OperadorTareasScreenState extends State<OperadorTareasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchTarea = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // HEADER
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
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Mis Tareas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // TABS
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2C3E50),
              labelColor: const Color(0xFF2C3E50),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(
                  icon: Icon(Icons.assignment),
                  text: 'Tareas Pendientes',
                ),
                Tab(
                  icon: Icon(Icons.check_circle),
                  text: 'Completadas',
                ),
              ],
            ),
          ),

          // CONTENIDO
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTareasPendientes(),
                        _buildTareasCompletadas(),
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

  Widget _buildTareasPendientes() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tareas_operador')
                .where('operador_id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                .where('estado', isEqualTo: 'asignada')
                .orderBy('fecha_asignacion', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              print('DEBUG PENDIENTES: operador_id buscado: "${widget.operadorId}"');
              print('DEBUG PENDIENTES: connectionState: ${snapshot.connectionState}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                print('DEBUG PENDIENTES: Cargando tareas para operador: ${widget.operadorId}');
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando mis tareas pendientes...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                print('DEBUG PENDIENTES: Error al cargar tareas: ${snapshot.error}');
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error al cargar tareas: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Verificar si hay datos
              if (!snapshot.hasData) {
                print('DEBUG PENDIENTES: snapshot.hasData = false');
                return _buildEmptyState('Cargando datos...');
              }

              final docs = snapshot.data!.docs;
              print('DEBUG PENDIENTES: Total documentos encontrados: ${docs.length}');
              
              // Debug: mostrar primeros documentos
              for (int i = 0; i < docs.length && i < 3; i++) {
                final data = docs[i].data() as Map<String, dynamic>;
                print('DEBUG PENDIENTES: Doc $i - operador_id: "${data['operador_id']}", referencia: "${data['referencia']}"');
              }

              if (docs.isEmpty) {
                return _buildEmptyState('No tienes tareas pendientes');
              }
              
              // Aplicar filtros
              final tareasFiltradas = _filtrarTareas(docs);
              print('DEBUG PENDIENTES: Tareas después de filtros: ${tareasFiltradas.length}');

              if (tareasFiltradas.isEmpty && (_searchTarea.isNotEmpty || _selectedDate != null)) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildFiltrosBusqueda(),
                      const SizedBox(height: 32),
                      const Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.filter_alt_off,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No hay tareas que coincidan con los filtros',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Separar por prioridad
              final tareasUrgentes = tareasFiltradas.where((t) {
                final prioridad = (t.data() as Map<String, dynamic>)['prioridad']?.toString().toLowerCase() ?? 'normal';
                return prioridad == 'urgente';
              }).toList();
              
              final tareasPrioritarias = tareasFiltradas.where((t) {
                final prioridad = (t.data() as Map<String, dynamic>)['prioridad']?.toString().toLowerCase() ?? 'normal';
                return prioridad == 'prioritario';
              }).toList();
              
              final tareasNormales = tareasFiltradas.where((t) {
                final prioridad = (t.data() as Map<String, dynamic>)['prioridad']?.toString().toLowerCase() ?? 'normal';
                return prioridad == 'normal';
              }).toList();
              
              final tareasBajas = tareasFiltradas.where((t) {
                final prioridad = (t.data() as Map<String, dynamic>)['prioridad']?.toString().toLowerCase() ?? 'normal';
                return prioridad == 'baja';
              }).toList();

              print('DEBUG PENDIENTES: Urgentes: ${tareasUrgentes.length}, Prioritarias: ${tareasPrioritarias.length}, Normales: ${tareasNormales.length}, Bajas: ${tareasBajas.length}');

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FILTROS
                    _buildFiltrosBusqueda(),
                    const SizedBox(height: 16),

                    // ALERTAS DE PRIORIDAD
                    if (tareasUrgentes.isNotEmpty || tareasPrioritarias.isNotEmpty)
                      _buildAlertaPrioridad(tareasUrgentes.length, tareasPrioritarias.length),

                    // TAREAS URGENTES
                    if (tareasUrgentes.isNotEmpty) ...[
                      _buildSeccionTareas('Tareas URGENTES', Colors.red, tareasUrgentes, Icons.priority_high),
                      const SizedBox(height: 24),
                    ],

                    // TAREAS PRIORITARIAS
                    if (tareasPrioritarias.isNotEmpty) ...[
                      _buildSeccionTareas('Tareas PRIORITARIAS', Colors.orange, tareasPrioritarias, Icons.flag),
                      const SizedBox(height: 24),
                    ],

                    // TAREAS NORMALES
                    if (tareasNormales.isNotEmpty) ...[
                      _buildSeccionTareas('Tareas Normales', Colors.blue, tareasNormales, Icons.assignment),
                      const SizedBox(height: 24),
                    ],

                    // TAREAS BAJA PRIORIDAD
                    if (tareasBajas.isNotEmpty) ...[
                      _buildSeccionTareas('Tareas de Baja Prioridad', Colors.green, tareasBajas, Icons.low_priority),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTareasCompletadas() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('tareas_operador')
                .where('operador_id', isEqualTo: widget.operadorId)
                .where('estado', isEqualTo: 'completada')
                .orderBy('fecha_completada', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              print('DEBUG COMPLETADAS: operador_id buscado: "${widget.operadorId}"');
              print('DEBUG COMPLETADAS: connectionState: ${snapshot.connectionState}');
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                print('DEBUG COMPLETADAS: Error: ${snapshot.error}');
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              if (!snapshot.hasData) {
                print('DEBUG COMPLETADAS: No data available');
                return _buildEmptyStateCompletadas('Cargando datos...');
              }

              final docs = snapshot.data!.docs;
              print('DEBUG COMPLETADAS: Total documentos encontrados: ${docs.length}');

              if (docs.isEmpty) {
                return _buildEmptyStateCompletadas('Aún no has completado tareas');
              }

              final tareasFiltradas = _filtrarTareas(docs);
              print('DEBUG COMPLETADAS: Tareas después de filtros: ${tareasFiltradas.length}');

              // Calcular estadísticas
              final tareasCompletadas = tareasFiltradas.length;
              final cantidadTotal = tareasFiltradas.fold<int>(0, (sum, tarea) {
                final data = tarea.data() as Map<String, dynamic>;
                return sum + (data['cantidad'] as int? ?? 0);
              });

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    // FILTROS Y ESTADÍSTICAS
                    _buildFiltrosBusqueda(),
                    const SizedBox(height: 16),
                    
                    _buildEstadisticas(tareasCompletadas, cantidadTotal),
                    const SizedBox(height: 16),

                    // TABLA DE COMPLETADAS
                    if (tareasFiltradas.isNotEmpty)
                      _buildTablaCompletadas(tareasFiltradas)
                    else if (_searchTarea.isNotEmpty || _selectedDate != null)
                      const Center(
                        child: Text('No hay resultados para los filtros seleccionados'),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '¡Excelente trabajo! 🎉',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCompletadas(String mensaje) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            mensaje,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Completa tus primeras tareas para verlas aquí',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertaPrioridad(int urgentes, int prioritarias) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: urgentes > 0 ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: urgentes > 0 ? Colors.red.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            urgentes > 0 ? Icons.warning : Icons.info,
            color: urgentes > 0 ? Colors.red : Colors.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  urgentes > 0 
                      ? 'Atención: Tienes $urgentes tarea(s) URGENTE(S)'
                      : 'Tienes $prioritarias tarea(s) prioritaria(s) pendientes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: urgentes > 0 ? Colors.red[800] : Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  urgentes > 0 
                      ? 'Estas tareas requieren atención inmediata'
                      : 'Te recomendamos completarlas pronto',
                  style: TextStyle(
                    fontSize: 14,
                    color: urgentes > 0 ? Colors.red[600] : Colors.orange[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionTareas(String titulo, Color color, List<QueryDocumentSnapshot> tareas, IconData icono) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de sección
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icono, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tareas.length} ${tareas.length == 1 ? 'tarea' : 'tareas'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Lista de tareas
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tareas.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.2),
            ),
            itemBuilder: (context, index) {
              final tarea = tareas[index];
              return _buildTareaCard(tarea, color);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTareaCard(QueryDocumentSnapshot tarea, Color color) {
    final data = tarea.data() as Map<String, dynamic>;
    final fechaAsignacion = data['fecha_asignacion']?.toDate();
    final referencia = data['referencia'] ?? 'Sin referencia';
    final descripcion = data['descripcion'] ?? 'Sin descripción';
    final cantidad = data['cantidad'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Checkbox para completar
          Checkbox(
            value: false,
            onChanged: (value) {
              if (value == true) {
                _mostrarDialogoCompletar(tarea);
              }
            },
            activeColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          
          // Información de la tarea
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      referencia,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Cantidad: $cantidad',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  descripcion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fechaAsignacion != null
                          ? 'Asignada: ${fechaAsignacion.day.toString().padLeft(2, '0')}/${fechaAsignacion.month.toString().padLeft(2, '0')}/${fechaAsignacion.year}'
                          : 'Sin fecha de asignación',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Botón de detalles
          IconButton(
            icon: Icon(Icons.info_outline, color: Colors.grey[600]),
            onPressed: () => _mostrarDetallesTarea(tarea),
            tooltip: 'Ver detalles',
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticas(int tareasCompletadas, int cantidadTotal) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: Colors.green[600],
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Estadísticas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tareas completadas: $tareasCompletadas | Total fundido: $cantidadTotal',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaCompletadas(List<QueryDocumentSnapshot> tareas) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mis Tareas Completadas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de tareas completadas
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tareas.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey.withOpacity(0.1),
            ),
            itemBuilder: (context, index) {
              final tarea = tareas[index];
              final data = tarea.data() as Map<String, dynamic>;
              final referencia = data['referencia'] ?? 'Sin referencia';
              final descripcion = data['descripcion'] ?? 'Sin descripción';
              final cantidad = data['cantidad'] ?? 0;
              final fechaCompletada = data['fecha_completada']?.toDate();

              return GestureDetector(
                onTap: () => _mostrarDetallesTarea(tarea),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[600],
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  referencia,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'Cantidad: $cantidad',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              descripcion,
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              fechaCompletada != null
                                  ? 'Completada: ${fechaCompletada.day}/${fechaCompletada.month}/${fechaCompletada.year}'
                                  : 'Sin fecha de finalización',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
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
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosBusqueda() {
    return Column(
      children: [
        // Campo de búsqueda
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por referencia o descripción...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchTarea = value;
            });
          },
        ),
        const SizedBox(height: 10),

        // Filtro de fecha
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _selectedDate == null
                    ? 'Filtrar por fecha'
                    : 'Fecha: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            if (_selectedDate != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = null;
                  });
                },
                child: const Text('Limpiar'),
              ),
            ],
          ],
        ),
      ],
    );
  }

  List<QueryDocumentSnapshot> _filtrarTareas(List<QueryDocumentSnapshot> tareas) {
    var filtradas = tareas.where((tarea) {
      final referencia = (tarea['referencia'] ?? '').toString().toLowerCase();
      final descripcion = (tarea['descripcion'] ?? '').toString().toLowerCase();
      final searchLower = _searchTarea.toLowerCase();
      return referencia.contains(searchLower) || descripcion.contains(searchLower);
    }).toList();

    if (_selectedDate != null) {
      filtradas = filtradas.where((tarea) {
        final fecha = tarea['fecha_asignacion']?.toDate();
        return fecha != null &&
            fecha.year == _selectedDate!.year &&
            fecha.month == _selectedDate!.month &&
            fecha.day == _selectedDate!.day;
      }).toList();
    }

    return filtradas;
  }

  void _mostrarDialogoCompletar(QueryDocumentSnapshot tarea) {
    String observaciones = '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600]),
            const SizedBox(width: 8),
            const Text('Completar Tarea'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información de la tarea
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Referencia: ${tarea['referencia'] ?? 'N/A'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Descripción: ${tarea['descripcion'] ?? 'N/A'}'),
                    const SizedBox(height: 4),
                    Text('Cantidad: ${tarea['cantidad'] ?? 0}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo de observaciones
              const Text(
                'Observaciones (opcional):',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Agregar comentarios sobre la tarea completada...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
                maxLines: 3,
                onChanged: (value) => observaciones = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('tareas_operador')
                    .doc(tarea.id)
                    .update({
                  'estado': 'completada',
                  'fecha_completada': DateTime.now(),
                  if (observaciones.isNotEmpty) 'observaciones': observaciones,
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('¡Tarea completada exitosamente!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } catch (e) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al completar la tarea: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Completar Tarea'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesTarea(QueryDocumentSnapshot tarea) {
    final fechaAsignacion = tarea['fecha_asignacion']?.toDate();
    final fechaCompletada = tarea['fecha_completada']?.toDate();
    final prioridad = tarea['prioridad'] ?? 'normal';
    
    // Color según prioridad
    Color prioridadColor = Colors.blue;
    IconData prioridadIcon = Icons.flag;
    switch (prioridad.toLowerCase()) {
      case 'urgente':
        prioridadColor = Colors.red;
        prioridadIcon = Icons.priority_high;
        break;
      case 'prioritario':
        prioridadColor = Colors.orange;
        prioridadIcon = Icons.flag;
        break;
      case 'normal':
        prioridadColor = Colors.blue;
        prioridadIcon = Icons.assignment;
        break;
      case 'baja':
        prioridadColor = Colors.green;
        prioridadIcon = Icons.low_priority;
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(prioridadIcon, color: prioridadColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tarea['referencia'] ?? 'Detalle de Tarea',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Referencia:', tarea['referencia'] ?? 'N/A'),
              _buildDetailRow('Descripción:', tarea['descripcion'] ?? 'N/A'),
              _buildDetailRow('Cantidad:', '${tarea['cantidad'] ?? 0}'),
              
              // Prioridad con color
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 120,
                      child: Text(
                        'Prioridad:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: prioridadColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: prioridadColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        prioridad.toUpperCase(),
                        style: TextStyle(
                          color: prioridadColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              _buildDetailRow('Estado:', tarea['estado'] ?? 'N/A'),
              
              if (fechaAsignacion != null)
                _buildDetailRow('Fecha Asignación:', 
                  '${fechaAsignacion.day.toString().padLeft(2, '0')}/${fechaAsignacion.month.toString().padLeft(2, '0')}/${fechaAsignacion.year} - ${fechaAsignacion.hour.toString().padLeft(2, '0')}:${fechaAsignacion.minute.toString().padLeft(2, '0')}'),
              
              if (fechaCompletada != null)
                _buildDetailRow('Fecha Completada:', 
                  '${fechaCompletada.day.toString().padLeft(2, '0')}/${fechaCompletada.month.toString().padLeft(2, '0')}/${fechaCompletada.year} - ${fechaCompletada.hour.toString().padLeft(2, '0')}:${fechaCompletada.minute.toString().padLeft(2, '0')}'),
              
              if (tarea['observaciones'] != null && tarea['observaciones'].toString().isNotEmpty)
                _buildDetailRow('Observaciones:', tarea['observaciones']),
                
              // Mostrar tiempo transcurrido si está completada
              if (fechaAsignacion != null && fechaCompletada != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer, size: 16, color: Colors.blue[600]),
                          const SizedBox(width: 4),
                          Text(
                            'Tiempo de resolución:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _calcularTiempoTranscurrido(fechaAsignacion, fechaCompletada),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _calcularTiempoTranscurrido(DateTime inicio, DateTime fin) {
    final diferencia = fin.difference(inicio);
    
    if (diferencia.inDays > 0) {
      return '${diferencia.inDays} día(s), ${diferencia.inHours % 24} hora(s)';
    } else if (diferencia.inHours > 0) {
      return '${diferencia.inHours} hora(s), ${diferencia.inMinutes % 60} minuto(s)';
    } else {
      return '${diferencia.inMinutes} minuto(s)';
    }
  }
}