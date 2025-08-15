import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OperadorControlDeskScreen extends StatefulWidget {
  final String operadorId;
  final String operadorNombre;

  const OperadorControlDeskScreen({
    super.key,
    required this.operadorId,
    required this.operadorNombre,
  });

  @override
  State<OperadorControlDeskScreen> createState() =>
      _OperadorControlDeskScreenState();
}

class _OperadorControlDeskScreenState extends State<OperadorControlDeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchTarea = '';
  DateTime? _selectedDate;

  // ✅ Agregar estos controladores
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchHistorialController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
void dispose() {
  _tabController.dispose();
  _searchController.dispose();
  _searchHistorialController.dispose(); // ✅ Agregar esta línea
  super.dispose();
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
                  Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Control de Actividades',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Operador: ${widget.operadorNombre}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 8),
                        // Botón original
                        ElevatedButton.icon(
                          onPressed: () => _mostrarAgregarTarea(),
                          icon: const Icon(Icons.add_task, size: 18),
                          label: const Text('Nueva Tarea'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ✅ TABS
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2C3E50),
              labelColor: const Color(0xFF2C3E50),
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(icon: Icon(Icons.assignment), text: 'Tareas Asignadas'),
                Tab(icon: Icon(Icons.history), text: 'Historial'),
              ],
            ),
          ),

          // ✅ CONTENIDO CON FONDO BLANCO
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
                      children: [_buildTareasAsignadas(), _buildHistorial()],
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

  Widget _buildTareasAsignadas() {
    return Column(
      children: [
        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('tareas_operador')
                    .where('operador_id', isEqualTo: widget.operadorId)
                    .where('estado', isEqualTo: 'asignada')
                    .orderBy('fecha_asignacion', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Cargando tareas asignadas...'),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
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

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No hay tareas asignadas',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Las nuevas tareas aparecerán aquí',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              // Aplicar filtros adicionales
              final todasTareas = _filtrarTareas(docs);

              // Separar por prioridad
              final tareasUrgentes =
                  todasTareas
                      .where(
                        (t) =>
                            t['prioridad']?.toString().toLowerCase() ==
                            'urgente',
                      )
                      .toList();
              final tareasPrioritarias =
                  todasTareas
                      .where(
                        (t) =>
                            t['prioridad']?.toString().toLowerCase() ==
                            'prioritario',
                      )
                      .toList();
              final tareasNormales =
                  todasTareas
                      .where(
                        (t) =>
                            t['prioridad']?.toString().toLowerCase() ==
                            'normal',
                      )
                      .toList();
              final tareasBajas =
                  todasTareas
                      .where(
                        (t) =>
                            t['prioridad']?.toString().toLowerCase() == 'baja',
                      )
                      .toList();

              if (todasTareas.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.filter_alt_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay resultados para los filtros seleccionados',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FILTROS SIN CONTADOR (solo para tareas asignadas)
                    _buildFiltersAsignadas(),
                    const SizedBox(height: 16),

                    // Tabla de Tareas Urgentes
                    if (tareasUrgentes.isNotEmpty) ...[
                      _buildTableHeader(
                        'Tareas de Carácter Urgente',
                        Colors.red,
                        tareasUrgentes.length,
                      ),
                      const SizedBox(height: 8),
                      _buildTareasTable(tareasUrgentes, Colors.red),
                      const SizedBox(height: 24),
                    ],

                    // Tabla de Tareas Prioritarias
                    if (tareasPrioritarias.isNotEmpty) ...[
                      _buildTableHeader(
                        'Tareas de Carácter Prioritario',
                        Colors.orange,
                        tareasPrioritarias.length,
                      ),
                      const SizedBox(height: 8),
                      _buildTareasTable(tareasPrioritarias, Colors.orange),
                      const SizedBox(height: 24),
                    ],

                    // Tabla de Tareas Normales
                    if (tareasNormales.isNotEmpty) ...[
                      _buildTableHeader(
                        'Tareas Normales',
                        Colors.blue,
                        tareasNormales.length,
                      ),
                      const SizedBox(height: 8),
                      _buildTareasTable(tareasNormales, Colors.blue),
                      const SizedBox(height: 24),
                    ],

                    // Tabla de Tareas de Baja Prioridad
                    if (tareasBajas.isNotEmpty) ...[
                      _buildTableHeader(
                        'Tareas de Baja Prioridad',
                        Colors.green,
                        tareasBajas.length,
                      ),
                      const SizedBox(height: 8),
                      _buildTareasTable(tareasBajas, Colors.green),
                      const SizedBox(height: 24),
                    ],
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

  Widget _buildTableHeader(String title, Color color, int count) {
    return Container(
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
          Icon(Icons.priority_high, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
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
              '$count tareas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareasTable(
    List<QueryDocumentSnapshot> tareas,
    Color themeColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        border: Border.all(color: themeColor.withOpacity(0.3)),
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
          // Header de la tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: themeColor.withOpacity(0.2)),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Fecha Asignación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Referencia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Cantidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Cumplida',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Filas de la tabla
          ...tareas.asMap().entries.map((entry) {
            final index = entry.key;
            final tarea = entry.value;
            final fechaAsignacion = tarea['fecha_asignacion']?.toDate();
            final referencia = tarea['referencia'] ?? 'Sin referencia';
            final cantidad = tarea['cantidad'] ?? 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    index % 2 == 0
                        ? Colors.white
                        : Colors.grey.withOpacity(0.02),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Fecha de asignación
                  Expanded(
                    flex: 2,
                    child: Text(
                      fechaAsignacion != null
                          ? '${fechaAsignacion.day.toString().padLeft(2, '0')}/${fechaAsignacion.month.toString().padLeft(2, '0')}/${fechaAsignacion.year}'
                          : 'Sin fecha',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Referencia
                  Expanded(
                    flex: 2,
                    child: Text(
                      referencia,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  // Cantidad
                  Expanded(
                    flex: 1,
                    child: Text(
                      cantidad.toString(),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Checkbox para marcar como cumplida
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Checkbox(
                        value:
                            false, // Siempre false porque estas son tareas asignadas
                        onChanged: (value) {
                          if (value == true) {
                            _completarTareaRapido(tarea);
                          }
                        },
                        activeColor: themeColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildHistorial() {
    return Column(
      children: [
        const SizedBox(height: 20),

        // Contenido dinámico con StreamBuilder
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('tareas_operador')
                    .where('operador_id', isEqualTo: widget.operadorId)
                    .where('estado', isEqualTo: 'completada')
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
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
                        'Error al cargar historial: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay historial de tareas completadas',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              var docs = snapshot.data!.docs;

              // Ordenar por fecha_completada (más recientes primero)
              docs.sort((a, b) {
                final fechaA =
                    a['fecha_completada']?.toDate() ?? DateTime.now();
                final fechaB =
                    b['fecha_completada']?.toDate() ?? DateTime.now();
                return fechaB.compareTo(fechaA);
              });

              // Convertir a Map para el contador y filtros
              final allTareas =
                  docs
                      .map((doc) => doc.data() as Map<String, dynamic>)
                      .toList();

              // Aplicar filtros adicionales (búsqueda, fecha, etc.)
              final tareas = _filtrarTareas(docs);

              if (tareas.isEmpty &&
                  (_searchTarea.isNotEmpty || _selectedDate != null)) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      _buildFiltersHistorial(allTareas),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'No hay resultados para los filtros seleccionados.',
                        ),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // FILTROS Y CONTADOR (solo en historial)
                    _buildFiltersHistorial(allTareas),
                    const SizedBox(height: 16),

                    // TABLA DE HISTORIAL
                    if (tareas.isNotEmpty) _buildHistorialTable(tareas),
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

  Widget _buildHistorialTable(List<QueryDocumentSnapshot> tareas) {
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
          // Header de la tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.green.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Historial de Tareas Completadas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),

          // Cabeceras de columnas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: Colors.green.withOpacity(0.2)),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Referencia',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Descripción',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Cantidad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'Prioridad',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Fecha Asignación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Fecha Completada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Filas de datos
          ...tareas.asMap().entries.map((entry) {
            final index = entry.key;
            final tarea = entry.value;
            final referencia = tarea['referencia'] ?? 'Sin referencia';
            final descripcion = tarea['descripcion'] ?? 'Sin descripción';
            final cantidad = tarea['cantidad'] ?? 0;
            final prioridad = tarea['prioridad'] ?? 'normal';
            final fechaAsignacion = tarea['fecha_asignacion']?.toDate();
            final fechaCompletada = tarea['fecha_completada']?.toDate();

            // Color de prioridad
            Color prioridadColor = Colors.blue;
            switch (prioridad.toLowerCase()) {
              case 'urgente':
                prioridadColor = Colors.red;
                break;
              case 'prioritario':
                prioridadColor = Colors.orange;
                break;
              case 'normal':
                prioridadColor = Colors.blue;
                break;
              case 'baja':
                prioridadColor = Colors.green;
                break;
            }

            return GestureDetector(
              onTap: () => _mostrarDetalleTarea(tarea),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color:
                      index % 2 == 0
                          ? Colors.white
                          : Colors.grey.withOpacity(0.02),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.1),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Referencia
                    Expanded(
                      flex: 2,
                      child: Text(
                        referencia,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Descripción
                    Expanded(
                      flex: 3,
                      child: Text(
                        descripcion,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Cantidad
                    Expanded(
                      flex: 1,
                      child: Text(
                        cantidad.toString(),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Prioridad
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: prioridadColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: prioridadColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            prioridad.toUpperCase(),
                            style: TextStyle(
                              color: prioridadColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Fecha Asignación
                    Expanded(
                      flex: 2,
                      child: Text(
                        fechaAsignacion != null
                            ? '${fechaAsignacion.day.toString().padLeft(2, '0')}/${fechaAsignacion.month.toString().padLeft(2, '0')}/${fechaAsignacion.year}\n${fechaAsignacion.hour.toString().padLeft(2, '0')}:${fechaAsignacion.minute.toString().padLeft(2, '0')}'
                            : 'Sin fecha',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Fecha Completada
                    Expanded(
                      flex: 2,
                      child: Text(
                        fechaCompletada != null
                            ? '${fechaCompletada.day.toString().padLeft(2, '0')}/${fechaCompletada.month.toString().padLeft(2, '0')}/${fechaCompletada.year}\n${fechaCompletada.hour.toString().padLeft(2, '0')}:${fechaCompletada.minute.toString().padLeft(2, '0')}'
                            : 'Sin fecha',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  List<QueryDocumentSnapshot> _filtrarTareas(
    List<QueryDocumentSnapshot> tareas,
  ) {
    var filteredByTarea =
        tareas.where((tarea) {
          final referencia =
              (tarea['referencia'] ?? '').toString().toLowerCase();
          final descripcion =
              (tarea['descripcion'] ?? '').toString().toLowerCase();
          final searchLower = _searchTarea.toLowerCase();
          return referencia.contains(searchLower) ||
              descripcion.contains(searchLower);
        }).toList();

    if (_selectedDate != null) {
      filteredByTarea =
          filteredByTarea.where((tarea) {
            final fecha = tarea['fecha_asignacion']?.toDate();
            return fecha != null &&
                fecha.year == _selectedDate!.year &&
                fecha.month == _selectedDate!.month &&
                fecha.day == _selectedDate!.day;
          }).toList();
    }

    return filteredByTarea;
  }

Widget _buildFiltersAsignadas() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Campo de búsqueda con controlador
      TextField(
        controller: _searchHistorialController,
        decoration: InputDecoration(
          hintText: 'Buscar por referencia o descripción...',
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
          suffixIcon: _searchHistorialController.text.isNotEmpty 
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchTarea = '';
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchTarea = value;
          });
        },
      ),
      const SizedBox(height: 10),

      // Filtro de fecha en Row
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
                  : 'Filtrado: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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

  // Filtros para historial (con contador y suma de cantidades)
  Widget _buildFiltersHistorial(List<Map<String, dynamic>> allTareas) {
    // Filtrar tareas según fecha seleccionada y búsqueda
    var tareasFiltradas = allTareas;

    // Aplicar filtro de fecha
    if (_selectedDate != null) {
      tareasFiltradas =
          tareasFiltradas.where((t) {
            final fecha = (t['fecha_completada'] as Timestamp?)?.toDate();
            return fecha != null &&
                fecha.year == _selectedDate!.year &&
                fecha.month == _selectedDate!.month &&
                fecha.day == _selectedDate!.day;
          }).toList();
    }

    // Aplicar filtro de búsqueda
    if (_searchTarea.isNotEmpty) {
      final searchLower = _searchTarea.toLowerCase();
      tareasFiltradas =
          tareasFiltradas.where((t) {
            final referencia = (t['referencia'] ?? '').toString().toLowerCase();
            final descripcion =
                (t['descripcion'] ?? '').toString().toLowerCase();
            return referencia.contains(searchLower) ||
                descripcion.contains(searchLower);
          }).toList();
    }

    // Calcular totales
    final tareasCompletadas = tareasFiltradas.length;
    final cantidadTotal = tareasFiltradas.fold<int>(
      0,
      (sum, tarea) => sum + (tarea['cantidad'] as int? ?? 0),
    );

    return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Campo de búsqueda
      TextField(
        controller: _searchHistorialController, // ✅ Agregar controlador
        decoration: InputDecoration(
          hintText: 'Buscar por referencia o descripción...',
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
            _searchTarea = value;
          });
        },
      ),
        const SizedBox(height: 10),

        // Row con resumen + botón de filtro
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Resumen de tareas completadas y cantidad total
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completadas: $tareasCompletadas | Total fundido: $cantidadTotal',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green[800],
                            ),
                          ),
                          if (_selectedDate != null || _searchTarea.isNotEmpty)
                            Text(
                              'Resultado de filtros aplicados',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green[600],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Botón filtro de fecha
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
                    : 'Filtrado: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
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

  void _mostrarDetalleTarea(QueryDocumentSnapshot tarea) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(tarea['referencia'] ?? 'Detalle de Tarea'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Referencia:', tarea['referencia'] ?? 'N/A'),
                _buildDetailRow('Descripción:', tarea['descripcion'] ?? 'N/A'),
                _buildDetailRow('Cantidad:', '${tarea['cantidad'] ?? 0}'),
                _buildDetailRow('Prioridad:', tarea['prioridad'] ?? 'N/A'),
                _buildDetailRow('Estado:', tarea['estado'] ?? 'N/A'),
                if (tarea['fecha_asignacion'] != null)
                  _buildDetailRow(
                    'Fecha Asignación:',
                    '${tarea['fecha_asignacion'].toDate().day}/${tarea['fecha_asignacion'].toDate().month}/${tarea['fecha_asignacion'].toDate().year}',
                  ),
                if (tarea['fecha_completada'] != null)
                  _buildDetailRow(
                    'Fecha Completada:',
                    '${tarea['fecha_completada'].toDate().day}/${tarea['fecha_completada'].toDate().month}/${tarea['fecha_completada'].toDate().year}',
                  ),
                if (tarea['observaciones'] != null)
                  _buildDetailRow('Observaciones:', tarea['observaciones']),
              ],
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _completarTareaRapido(QueryDocumentSnapshot tarea) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Completar: ${tarea['referencia']}'),
            content: const Text('¿Marcar esta tarea como completada?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('tareas_operador')
                      .doc(tarea.id)
                      .update({
                        'estado': 'completada',
                        'fecha_completada': DateTime.now(),
                      });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarea completada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Completar'),
              ),
            ],
          ),
    );
  }

  void _mostrarAgregarTarea() {
    String referencia = '';
    String descripcion = '';
    int cantidad = 0;
    String prioridad = 'prioritario';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.white, // 🔹 Fondo blanco puro
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // 🔹 Bordes redondeados
            ),
            title: Text(
              'Agregar Tarea - ${widget.operadorNombre}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF333333),
              ),
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Referencia (ej: 635TD)',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ), // 🔹 Borde blanco
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ), // 🔹 Borde blanco
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 2,
                          ), // 🔹 Borde blanco al enfocar
                        ),
                        filled: true,
                        fillColor: Colors.white, // 🔹 Fondo blanco
                      ),
                      onChanged: (value) => referencia = value,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Descripción de la tarea',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 2,
                      onChanged: (value) => descripcion = value,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => cantidad = int.tryParse(value) ?? 0,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: prioridad,
                      decoration: InputDecoration(
                        labelText: 'Prioridad',
                        labelStyle: const TextStyle(color: Colors.black87),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          // 🔹 Evita borde rojo en error
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          // 🔹 Evita borde rojo al enfocar en error
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFC0C0C0),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white, // 🔹 Fuerza fondo blanco
                        errorStyle: const TextStyle(
                          height: 0,
                        ), // 🔹 Oculta mensaje de error
                      ),
                      dropdownColor:
                          Colors
                              .white, // 🔹 Fondo blanco en el menú desplegable
                      items: const [
                        DropdownMenuItem(
                          value: 'urgente',
                          child: Text('Urgente'),
                        ),
                        DropdownMenuItem(
                          value: 'prioritario',
                          child: Text('Prioritario'),
                        ),
                        DropdownMenuItem(
                          value: 'normal',
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(value: 'baja', child: Text('Baja')),
                      ],
                      onChanged: (value) => prioridad = value ?? 'prioritario',
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4), // 🔹 Azul elegante
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: () async {
                  if (referencia.isNotEmpty && descripcion.isNotEmpty) {
                    await FirebaseFirestore.instance
                        .collection('tareas_operador')
                        .add({
                          'operador_id': widget.operadorId,
                          'referencia': referencia,
                          'descripcion': descripcion,
                          'cantidad': cantidad,
                          'prioridad': prioridad,
                          'estado': 'asignada',
                          'fecha_asignacion': DateTime.now(),
                        });
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tarea asignada exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                },
                child: const Text(
                  'Asignar Tarea',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
            ],
          ),
    );
  }
}
