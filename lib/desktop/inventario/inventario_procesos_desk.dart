import 'package:basefundi/desktop/inventario/tablas/tablainv_procesos_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:basefundi/settings/transition.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class InventarioProcesoDeskScreen extends StatefulWidget {
  const InventarioProcesoDeskScreen({super.key});

  @override
  State<InventarioProcesoDeskScreen> createState() =>
      _InventarioProcesoDeskScreenState();
}

class _InventarioProcesoDeskScreenState
    extends State<InventarioProcesoDeskScreen>
    with SingleTickerProviderStateMixin {
  String searchQuery = '';
  String procesoSeleccionado = 'todos';

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  // ✅ Lista de procesos disponibles
  final List<Map<String, String>> procesos = [
    {'value': 'todos', 'label': 'Todos los procesos'},
    {'value': 'bruto', 'label': 'Bruto'},
    {'value': 'mecanizado', 'label': 'Mecanizado'},
    {'value': 'pintura', 'label': 'Pintura'},
    {'value': 'pulido', 'label': 'Pulido'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Transform.translate(
              offset: const Offset(-0.5, 0),
              child: Container(
                width: double.infinity,
                color: const Color(0xFF2C3E50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 38,
                ),
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
                        'Inventario por Procesos',
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
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildBarraBusquedaYFiltro(), // ✅ Nueva barra con filtro
                      const SizedBox(height: 8),
                      Expanded(child: _buildTablaProcesos()),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NUEVA BARRA CON BÚSQUEDA Y FILTRO
  Widget _buildBarraBusquedaYFiltro() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Campo de búsqueda
          Expanded(
            flex: 2,
            child: TextField(
              onChanged:
                  (value) => setState(() => searchQuery = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o referencia...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4682B4)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filtro de procesos
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<String>(
              value: procesoSeleccionado,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white, // Fuerza fondo blanco
                prefixIcon: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF4682B4),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.grey.shade400,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              dropdownColor: Colors.white, // Menú blanco
              items:
                  procesos.map((proceso) {
                    return DropdownMenuItem<String>(
                      value: proceso['value'],
                      child: Text(
                        proceso['label']!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
              onChanged: (value) {
                setState(() {
                  procesoSeleccionado = value!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ TABLA QUE MUESTRA TODOS LOS PROCESOS
  Widget _buildTablaProcesos() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _obtenerProductosDeTodosLosProcesos(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final todosLosProductos = snapshot.data!;

        // ✅ Aplicar filtros
        final filtered =
            todosLosProductos.where((data) {
              final nombre = data['nombre'].toString().toLowerCase();
              final referencia = data['referencia'].toString().toLowerCase();
              final proceso = data['proceso'].toString();

              // Filtro por búsqueda
              final cumpleBusqueda =
                  searchQuery.isEmpty ||
                  nombre.contains(searchQuery) ||
                  referencia.contains(searchQuery);

              // Filtro por proceso
              final cumpleProceso =
                  procesoSeleccionado == 'todos' ||
                  proceso == procesoSeleccionado;

              return cumpleBusqueda && cumpleProceso;
            }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No hay registros para mostrar.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final double anchoNombre = totalWidth * 0.30;
            final double anchoReferencia = totalWidth * 0.25;
            // ✅ NO definir anchoProceso fijo, se ajustará automáticamente
            final double anchoCantidad = totalWidth * 0.15;
            final double anchoAcciones = totalWidth * 0.15;
            // El 15% restante se distribuye automáticamente

            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: DataTable(
                columnSpacing: 8,
                headingRowColor: MaterialStateProperty.all(
                  const Color(0xFF4682B4),
                ),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(fontSize: 10),
                columns: const [
                  DataColumn(label: Text('Nombre')),
                  DataColumn(label: Text('Referencia')),
                  DataColumn(
                    label: Text('Proceso', textAlign: TextAlign.center),
                  ),
                  DataColumn(label: Text('Cantidad')),
                  DataColumn(label: Text('Acción')),
                ],
                rows:
                    filtered.map((data) {
                      return DataRow(
                        cells: [
                          DataCell(
                            SizedBox(
                              width: anchoNombre,
                              child: GestureDetector(
                                onTap: () {
                                  navegarConFade(
                                    context,
                                    TablaInvPinturaDeskScreen(
                                      referencia: data['referencia'],
                                      nombre: data['nombre'],
                                    ),
                                  );
                                },
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Text(
                                    data['nombre'] ?? 'Sin nombre',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF4682B4),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: anchoReferencia,
                              child: Text(
                                data['referencia'],
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),

                          // ✅ CELDA DE PROCESO CON ANCHO AUTOMÁTICO
                          DataCell(
                            IntrinsicWidth(
                              // ✅ Esto ajusta el ancho al contenido
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, // ✅ Padding normal
                                  vertical: 4, // ✅ Padding normal
                                ),
                                decoration: BoxDecoration(
                                  color: _getColorProceso(data['proceso']),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  data['proceso']
                                      .toUpperCase(), // ✅ Texto completo
                                  style: const TextStyle(
                                    fontSize: 9, // ✅ Tamaño normal
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          DataCell(
                            SizedBox(
                              width: anchoCantidad,
                              child: Text(
                                data['cantidad'].toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: anchoAcciones,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'Eliminar',
                                onPressed:
                                    () => _eliminarProducto(data, context),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  // ✅ OBTENER PRODUCTOS DE TODOS LOS PROCESOS
  Future<List<Map<String, dynamic>>>
  _obtenerProductosDeTodosLosProcesos() async {
    final List<Map<String, dynamic>> todosLosProductos = [];
    final List<String> procesosInventario = [
      'bruto',
      'mecanizado',
      'pintura',
      'pulido',
    ];

    try {
      // ✅ 1. EJECUTAR TODAS LAS CONSULTAS DE INVENTARIO EN PARALELO
      final futures =
          procesosInventario
              .map(
                (proceso) => FirebaseFirestore.instance
                    .collection('inventarios')
                    .doc(proceso)
                    .collection('productos')
                    .get()
                    .then(
                      (snapshot) => {'proceso': proceso, 'snapshot': snapshot},
                    ),
              )
              .toList();

      final resultados = await Future.wait(futures);

      // ✅ 2. RECOPILAR TODAS LAS REFERENCIAS ÚNICAS
      final Set<String> todasLasReferencias = {};
      final List<Map<String, dynamic>> productosConProceso = [];

      for (final resultado in resultados) {
        final proceso = resultado['proceso'] as String;
        final snapshot = resultado['snapshot'] as QuerySnapshot;

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final referencia = doc.id;
          final cantidad =
              int.tryParse(data['cantidad']?.toString() ?? '0') ?? 0;

          todasLasReferencias.add(referencia);
          productosConProceso.add({
            'referencia': referencia,
            'proceso': proceso,
            'cantidad': cantidad,
          });
        }
      }

      // ✅ 3. OBTENER TODOS LOS NOMBRES EN UNA SOLA CONSULTA BATCH
      final Map<String, String> nombresProductos = {};

      if (todasLasReferencias.isNotEmpty) {
        // Dividir en lotes de 10 (límite de Firestore para consultas 'in')
        final lotes = <List<String>>[];
        final listaReferencias = todasLasReferencias.toList();

        for (int i = 0; i < listaReferencias.length; i += 10) {
          final fin =
              (i + 10 < listaReferencias.length)
                  ? i + 10
                  : listaReferencias.length;
          lotes.add(listaReferencias.sublist(i, fin));
        }

        // Ejecutar consultas de lotes en paralelo
        final futuresNombres =
            lotes
                .map(
                  (lote) =>
                      FirebaseFirestore.instance
                          .collection('productos')
                          .where('referencia', whereIn: lote)
                          .get(),
                )
                .toList();

        final resultadosNombres = await Future.wait(futuresNombres);

        for (final snapshot in resultadosNombres) {
          for (final doc in snapshot.docs) {
            final data = doc.data();
            nombresProductos[data['referencia']] =
                data['nombre'] ?? 'Sin nombre';
          }
        }
      }

      // ✅ 4. COMBINAR DATOS
      for (final producto in productosConProceso) {
        todosLosProductos.add({
          'referencia': producto['referencia'],
          'nombre':
              nombresProductos[producto['referencia']] ??
              'Producto no encontrado',
          'proceso': producto['proceso'],
          'cantidad': producto['cantidad'],
        });
      }
    } catch (e) {
      print('Error obteniendo inventarios optimizado: $e');
    }

    return todosLosProductos;
  }

  // ✅ COLOR SEGÚN EL PROCESO
  Color _getColorProceso(String proceso) {
    switch (proceso.toLowerCase()) {
      case 'bruto':
        return Colors.brown;
      case 'mecanizado':
        return Colors.blue;
      case 'pintura':
        return Colors.green;
      case 'pulido':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // ✅ ELIMINAR PRODUCTO
  Future<void> _eliminarProducto(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final confirmar =
        await showDialog<bool>(
          context: context,
          builder:
              (_) => AlertDialog(
                title: const Text('Confirmar eliminación'),
                content: Text(
                  '¿Eliminar "${data['nombre']}" del proceso ${data['proceso'].toUpperCase()}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
        ) ??
        false;

    if (confirmar) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
        return;
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(currentUser.uid)
              .get();

      final nombreUsuario =
          userDoc.data()?['nombre'] ?? currentUser.email ?? '---';

      // ✅ ELIMINAR DE LA ESTRUCTURA CORRECTA
      await FirebaseFirestore.instance
          .collection('inventarios')
          .doc(data['proceso'])
          .collection('productos')
          .doc(data['referencia'])
          .delete();

      // ✅ Registrar en auditoría
      await FirebaseFirestore.instance.collection('auditoria_general').add({
        'accion': 'Eliminación de Inventario ${data['proceso'].toUpperCase()}',
        'detalle':
            'Producto: ${data['nombre']}, Referencia: ${data['referencia']}, Cantidad eliminada: ${data['cantidad']}',
        'fecha': DateTime.now(),
        'usuario_uid': currentUser.uid,
        'usuario_nombre': nombreUsuario,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado correctamente.')),
      );

      // ✅ Refrescar la vista
      setState(() {});
    }
  }
}
