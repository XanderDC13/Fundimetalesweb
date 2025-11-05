import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:basefundi/services/navbar_desk.dart';

class TareasExtrasScreen extends StatefulWidget {
  const TareasExtrasScreen({super.key});

  @override
  State<TareasExtrasScreen> createState() => _TareasExtrasScreenState();
}

class _TareasExtrasScreenState extends State<TareasExtrasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _tareasExtras = [];
  List<Map<String, dynamic>> _retirosMercaderia = [];
  Map<String, String> _nombresOperadores = {};
  bool _cargando = false;

  final List<String> _tiposTareas = [
    'Descargar camioneta',
    'Cargar camioneta',
    'Bajar viruta',
    'Limpiar hornos',
    'Mantenimiento de equipos',
    'Limpieza general',
    'Organizar material',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _obtenerDatos();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> _obtenerNombreOperador(String operadorId) async {
    if (_nombresOperadores.containsKey(operadorId)) {
      return _nombresOperadores[operadorId]!;
    }

    try {
      final operadorDoc = await FirebaseFirestore.instance
          .collection('usuarios_activos')
          .doc(operadorId)
          .get();

      if (operadorDoc.exists) {
        final data = operadorDoc.data();
        String nombre = data?['nombre'] ?? 'Sin nombre';
        _nombresOperadores[operadorId] = nombre;
        return nombre;
      }
    } catch (e) {
      print('Error al obtener operador $operadorId: $e');
    }

    return 'Operador desconocido';
  }

  Future<void> _obtenerDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      // Obtener tareas extras
      final tareasSnapshot = await FirebaseFirestore.instance
          .collection('tareas_extras')
          .orderBy('fecha_asignacion', descending: true)
          .get();

      List<Map<String, dynamic>> tareas = [];

      for (var doc in tareasSnapshot.docs) {
        final data = doc.data();

        String operadorNombre = 'Sin operador';
        if (data['operador_id'] != null &&
            data['operador_id'].toString().isNotEmpty) {
          operadorNombre = await _obtenerNombreOperador(
            data['operador_id'].toString(),
          );
        }

        tareas.add({
          'id': doc.id,
          'operador': operadorNombre,
          'tipo_tarea': data['tipo_tarea'] ?? 'Sin especificar',
          'descripcion': data['descripcion'] ?? '',
          'fecha': data['fecha_asignacion'],
          'estado': data['estado']?.toString() ?? 'pendiente',
        });
      }

      // Obtener retiros de mercadería
      final retirosSnapshot = await FirebaseFirestore.instance
          .collection('retiros_mercaderia')
          .orderBy('fecha_retiro', descending: true)
          .get();

      List<Map<String, dynamic>> retiros = [];

      for (var doc in retirosSnapshot.docs) {
        final data = doc.data();

        String personaRetiro = data['persona_retiro'] ?? 'Sin especificar';

        retiros.add({
          'id': doc.id,
          'persona_retiro': personaRetiro,
          'sucursal_origen': data['sucursal_origen'] ?? 'Fundición',
          'sucursal_destino': data['sucursal_destino'] ?? 'Mecanizado',
          'descripcion_material': data['descripcion_material'] ?? '',
          'cantidad': data['cantidad'] ?? 0,
          'fecha': data['fecha_retiro'],
        });
      }

      setState(() {
        _tareasExtras = tareas;
        _retirosMercaderia = retiros;
        _cargando = false;
      });
    } catch (e) {
      print('Error al obtener datos: $e');
      setState(() {
        _cargando = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      if (fecha is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
      } else if (fecha is String) {
        return fecha;
      }
      return fecha.toString();
    } catch (e) {
      return '—';
    }
  }

  void _mostrarDialogoNuevaTarea() {
    final TextEditingController descripcionController = TextEditingController();
    String tipoTareaSeleccionado = _tiposTareas[0];
    String? operadorSeleccionado;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Nueva Tarea Extra'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: tipoTareaSeleccionado,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de tarea',
                    border: OutlineInputBorder(),
                  ),
                  items: _tiposTareas.map((tipo) {
                    return DropdownMenuItem(value: tipo, child: Text(tipo));
                  }).toList(),
                  onChanged: (value) {
                    setStateDialog(() {
                      tipoTareaSeleccionado = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios_activos')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final operadores = snapshot.data!.docs;

                    return DropdownButtonFormField<String>(
                      value: operadorSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Asignar a operador',
                        border: OutlineInputBorder(),
                      ),
                      items: operadores.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return DropdownMenuItem(
                          value: doc.id,
                          child: Text(data['nombre'] ?? 'Sin nombre'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          operadorSeleccionado = value;
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (operadorSeleccionado == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debe seleccionar un operador'),
                    ),
                  );
                  return;
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('tareas_extras')
                      .add({
                    'tipo_tarea': tipoTareaSeleccionado,
                    'operador_id': operadorSeleccionado,
                    'descripcion': descripcionController.text,
                    'fecha_asignacion': Timestamp.now(),
                    'estado': 'pendiente',
                  });

                  Navigator.pop(context);
                  _obtenerDatos();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tarea creada exitosamente'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al crear tarea: $e')),
                  );
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoNuevoRetiro() {
    final TextEditingController personaController = TextEditingController();
    final TextEditingController descripcionController = TextEditingController();
    final TextEditingController cantidadController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Registrar Retiro de Mercadería'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: personaController,
                decoration: const InputDecoration(
                  labelText: 'Persona que retira',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción del material',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: cantidadController,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (personaController.text.isEmpty ||
                  descripcionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debe completar todos los campos'),
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('retiros_mercaderia')
                    .add({
                  'persona_retiro': personaController.text,
                  'sucursal_origen': 'Fundición',
                  'sucursal_destino': 'Mecanizado',
                  'descripcion_material': descripcionController.text,
                  'cantidad': int.tryParse(cantidadController.text) ?? 0,
                  'fecha_retiro': Timestamp.now(),
                });

                Navigator.pop(context);
                _obtenerDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Retiro registrado exitosamente'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al registrar retiro: $e')),
                );
              }
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaTareasExtras() {
    if (_cargando) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_tareasExtras.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No hay tareas extras registradas.',
            style: TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
          ),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2.5),
              2: FlexColumnWidth(3.0),
              3: FlexColumnWidth(2.5),
              4: FlexColumnWidth(1.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFF4682B4)),
                children: [
                  _TablaHeader('Operador'),
                  _TablaHeader('Tipo de Tarea'),
                  _TablaHeader('Descripción'),
                  _TablaHeader('Fecha'),
                  _TablaHeader('Estado'),
                ],
              ),
              ..._tareasExtras.asMap().entries.map((entry) {
                final index = entry.key;
                final tarea = entry.value;
                final isEven = index % 2 == 0;

                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.grey.shade50 : Colors.white,
                  ),
                  children: [
                    _TablaCell(tarea['operador']?.toString() ?? '—'),
                    _TablaCell(tarea['tipo_tarea']?.toString() ?? '—'),
                    _TablaCell(
                      tarea['descripcion']?.toString().isEmpty ?? true
                          ? '—'
                          : tarea['descripcion'].toString(),
                    ),
                    _TablaCell(_formatearFecha(tarea['fecha'])),
                    _TablaCellEstado(tarea['estado']?.toString() ?? 'pendiente'),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTablaRetiros() {
    if (_cargando) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_retirosMercaderia.isEmpty) {
      return const Expanded(
        child: Center(
          child: Text(
            'No hay retiros de mercadería registrados.',
            style: TextStyle(fontSize: 14, color: Color(0xFF2C3E50)),
          ),
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Table(
            border: TableBorder(
              horizontalInside: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              top: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(2.0),
              2: FlexColumnWidth(2.0),
              3: FlexColumnWidth(3.0),
              4: FlexColumnWidth(1.5),
              5: FlexColumnWidth(2.5),
            },
            children: [
              const TableRow(
                decoration: BoxDecoration(color: Color(0xFF4682B4)),
                children: [
                  _TablaHeader('Persona'),
                  _TablaHeader('Origen'),
                  _TablaHeader('Destino'),
                  _TablaHeader('Material'),
                  _TablaHeader('Cantidad'),
                  _TablaHeader('Fecha'),
                ],
              ),
              ..._retirosMercaderia.asMap().entries.map((entry) {
                final index = entry.key;
                final retiro = entry.value;
                final isEven = index % 2 == 0;

                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven ? Colors.grey.shade50 : Colors.white,
                  ),
                  children: [
                    _TablaCell(retiro['persona_retiro']?.toString() ?? '—'),
                    _TablaCell(retiro['sucursal_origen']?.toString() ?? '—'),
                    _TablaCell(retiro['sucursal_destino']?.toString() ?? '—'),
                    _TablaCell(
                      retiro['descripcion_material']?.toString() ?? '—',
                    ),
                    _TablaCell(
                      retiro['cantidad']?.toString() ?? '0',
                      isNumero: true,
                    ),
                    _TablaCell(_formatearFecha(retiro['fecha'])),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Tareas Extras y Retiros',
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
          Container(
            color: const Color(0xFF2C3E50),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: const [
                Tab(text: 'Tareas Extras'),
                Tab(text: 'Retiros de Mercadería'),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _tabController.index == 0
                            ? _mostrarDialogoNuevaTarea
                            : _mostrarDialogoNuevoRetiro,
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: Text(
                          _tabController.index == 0
                              ? 'Nueva Tarea'
                              : 'Registrar Retiro',
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _tabController.index == 0
                      ? _buildTablaTareasExtras()
                      : _buildTablaRetiros(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TablaHeader extends StatelessWidget {
  final String text;
  const _TablaHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TablaCell extends StatelessWidget {
  final String text;
  final bool isNumero;

  const _TablaCell(this.text, {this.isNumero = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isNumero ? FontWeight.bold : FontWeight.normal,
          color: isNumero ? Colors.blue.shade700 : const Color(0xFF2C3E50),
        ),
        textAlign: isNumero ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}

class _TablaCellEstado extends StatelessWidget {
  final String estado;

  const _TablaCellEstado(this.estado);

  @override
  Widget build(BuildContext context) {
    Color color;
    String texto;

    switch (estado.toLowerCase()) {
      case 'terminado':
      case 'terminada':
      case 'completada':
        color = Colors.green;
        texto = 'Terminado';
        break;
      case 'pendiente':
        color = Colors.orange;
        texto = 'Pendiente';
        break;
      default:
        color = Colors.grey;
        texto = estado;
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color),
          ),
          child: Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}