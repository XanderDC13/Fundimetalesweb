import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditInvProdDeskScreen extends StatefulWidget {
  final dynamic producto;

  const EditInvProdDeskScreen({super.key, required this.producto});

  @override
  State<EditInvProdDeskScreen> createState() => _EditInvProdDeskScreenState();
}

class _EditInvProdDeskScreenState extends State<EditInvProdDeskScreen> {
  Map<String, int> cantidadesPorProceso = {};
  List<Proceso> procesos = [];
  bool cargando = true;

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarProcesos();
    await _cargarSaldos();
  }

  Future<void> _cargarProcesos() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('procesos')
              .orderBy('orden')
              .get();

      setState(() {
        procesos =
            snapshot.docs
                .map((doc) => Proceso.fromMap(doc.id, doc.data()))
                .toList();
      });
    } catch (e) {
      print('Error cargando procesos: $e');
    }
  }

  Future<void> _cargarSaldos() async {
    Map<String, int> nuevasCantidades = {};

    for (var proceso in procesos) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('inventarios')
                .doc(proceso.id)
                .collection('productos')
                .doc(widget.producto.referencia)
                .get();

        nuevasCantidades[proceso.id] = doc.exists ? (doc['cantidad'] ?? 0) : 0;
      } catch (e) {
        print('Error cargando saldo para ${proceso.id}: $e');
        nuevasCantidades[proceso.id] = 0;
      }
    }

    if (!mounted) return;

    setState(() {
      cantidadesPorProceso = nuevasCantidades;
      cargando = false;
    });
  }

  Future<Map<String, String>> _obtenerDatosUsuario() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'uid': 'desconocido', 'nombre': 'Desconocido'};
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      final nombre =
          userDoc.exists ? (userDoc['nombre'] ?? 'Desconocido') : 'Desconocido';
      return {'uid': user.uid, 'nombre': nombre};
    } catch (e) {
      return {'uid': user.uid, 'nombre': 'Usuario'};
    }
  }

  Future<void> _guardarAuditoria({
    required String accion,
    required String detalle,
    required String uid,
    required String nombreUsuario,
    required Timestamp fecha,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('auditoria_general').add({
        'accion': accion,
        'detalle': detalle,
        'fecha': fecha,
        'usuario_nombre': nombreUsuario,
        'usuario_uid': uid,
      });
    } catch (e) {
      print('Error guardando auditoría: $e');
    }
  }

  Future<void> _registrarMovimiento({
    required String procesoOrigen,
    required String procesoDestino,
    required int cantidad,
    required String usuarioUid,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('movimientos').add({
        'producto_referencia': widget.producto.referencia,
        'proceso_origen': procesoOrigen,
        'proceso_destino': procesoDestino,
        'cantidad': cantidad,
        'fecha': Timestamp.now(),
        'usuario': usuarioUid,
      });
    } catch (e) {
      print('Error registrando movimiento: $e');
    }
  }

  void _mostrarFormularioEntradaDirecta(BuildContext context, Proceso proceso) {
    final TextEditingController cantidadController = TextEditingController();
    bool puedeGuardar = false;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          color: const Color(0xFF4682B4),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Entrada directa a ${proceso.nombre}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Entrada directa sin descontar de proceso anterior',
                              style: TextStyle(
                                color: Colors.amber.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad a ingresar',
                        prefixIcon: const Icon(
                          Icons.production_quantity_limits,
                          color: Color(0xFF4682B4),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE9ECEF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4682B4),
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        final parsed = int.tryParse(value);
                        setModalState(() {
                          puedeGuardar = parsed != null && parsed > 0;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed:
                              puedeGuardar
                                  ? () async {
                                    final cantidad =
                                        int.tryParse(cantidadController.text) ??
                                        0;
                                    await _procesarEntradaDirecta(
                                      proceso,
                                      cantidad,
                                    );
                                    if (mounted) Navigator.pop(context);
                                  }
                                  : null,
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Agregar entrada',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

  void _mostrarFormularioMovimiento(
    BuildContext context,
    Proceso procesoActual,
  ) {
    final TextEditingController cantidadController = TextEditingController();
    Proceso? procesoDestino;
    bool puedeGuardar = false;
    final cantidadDisponible = cantidadesPorProceso[procesoActual.id] ?? 0;

    // Filtrar procesos disponibles para mover (siguiente en la cadena)
    final procesosDisponibles =
        procesos.where((p) => p.orden > procesoActual.orden).toList();

    // Función para validar el formulario
    void validarFormulario() {
      final cantidad = int.tryParse(cantidadController.text) ?? 0;
      puedeGuardar =
          procesoDestino != null &&
          cantidad > 0 &&
          cantidad <= cantidadDisponible;
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width:
                    MediaQuery.of(context).size.width *
                    0.5,
                constraints: const BoxConstraints(
                  maxWidth: 1200,
                ),

                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.transfer_within_a_station,
                          color: const Color(0xFF27AE60),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Mover desde ${procesoActual.nombre}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Disponible en ${procesoActual.nombre}: $cantidadDisponible unidades',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown para seleccionar proceso destino
                    DropdownButtonFormField<Proceso>(
                      decoration: InputDecoration(
                        labelText: 'Proceso destino',
                        prefixIcon: const Icon(
                          Icons.arrow_forward,
                          color: Color(0xFF4682B4),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE9ECEF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4682B4),
                          ),
                        ),
                      ),
                      items:
                          procesosDisponibles.map((proceso) {
                            return DropdownMenuItem<Proceso>(
                              value: proceso,
                              child: Text(proceso.nombre),
                            );
                          }).toList(),
                      onChanged: (Proceso? selected) {
                        setModalState(() {
                          procesoDestino = selected;
                          validarFormulario();
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo cantidad
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad a mover',
                        hintText: 'Máximo: $cantidadDisponible',
                        prefixIcon: const Icon(
                          Icons.production_quantity_limits,
                          color: Color(0xFF4682B4),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE9ECEF),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4682B4),
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          validarFormulario();
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed:
                              puedeGuardar
                                  ? () async {
                                    final cantidad =
                                        int.tryParse(cantidadController.text) ??
                                        0;
                                    await _procesarMovimiento(
                                      procesoActual,
                                      procesoDestino!,
                                      cantidad,
                                    );
                                    if (mounted) Navigator.pop(context);
                                  }
                                  : null,
                          icon: const Icon(Icons.transfer_within_a_station),
                          label: const Text(
                            'Realizar movimiento',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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

  Future<void> _procesarEntradaDirecta(Proceso proceso, int cantidad) async {
    try {
      final timestamp = Timestamp.now();
      final usuario = await _obtenerDatosUsuario();

      // Actualizar inventario del proceso
      final docInventario = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(proceso.id)
          .collection('productos')
          .doc(widget.producto.referencia);

      final snapshot = await docInventario.get();
      final cantidadActual = snapshot.exists ? (snapshot['cantidad'] ?? 0) : 0;

      await docInventario.set({
        'cantidad': cantidadActual + cantidad,
        'ultima_actualizacion': timestamp,
      }, SetOptions(merge: true));

      // Registrar auditoría
      await _guardarAuditoria(
        accion: 'Entrada directa de inventario',
        detalle:
            'Producto: ${widget.producto.nombre} (${widget.producto.referencia}), '
            'Proceso: ${proceso.nombre}, Cantidad: $cantidad',
        uid: usuario['uid']!,
        nombreUsuario: usuario['nombre']!,
        fecha: timestamp,
      );

      await _cargarSaldos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entrada registrada: $cantidad unidades a ${proceso.nombre}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error procesando entrada directa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la entrada'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _procesarMovimiento(
    Proceso origen,
    Proceso destino,
    int cantidad,
  ) async {
    try {
      final timestamp = Timestamp.now();
      final usuario = await _obtenerDatosUsuario();

      // Reducir cantidad en proceso origen
      final docOrigen = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(origen.id)
          .collection('productos')
          .doc(widget.producto.referencia);

      final snapshotOrigen = await docOrigen.get();
      final cantidadOrigen =
          snapshotOrigen.exists ? (snapshotOrigen['cantidad'] ?? 0) : 0;

      await docOrigen.update({
        'cantidad': cantidadOrigen - cantidad,
        'ultima_actualizacion': timestamp,
      });

      // Aumentar cantidad en proceso destino
      final docDestino = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(destino.id)
          .collection('productos')
          .doc(widget.producto.referencia);

      final snapshotDestino = await docDestino.get();
      final cantidadDestino =
          snapshotDestino.exists ? (snapshotDestino['cantidad'] ?? 0) : 0;

      await docDestino.set({
        'cantidad': cantidadDestino + cantidad,
        'ultima_actualizacion': timestamp,
      }, SetOptions(merge: true));

      // Registrar movimiento
      await _registrarMovimiento(
        procesoOrigen: origen.id,
        procesoDestino: destino.id,
        cantidad: cantidad,
        usuarioUid: usuario['uid']!,
      );

      // Registrar auditoría
      await _guardarAuditoria(
        accion: 'Movimiento entre procesos',
        detalle:
            'Producto: ${widget.producto.nombre} (${widget.producto.referencia}), '
            'De: ${origen.nombre} a ${destino.nombre}, Cantidad: $cantidad',
        uid: usuario['uid']!,
        nombreUsuario: usuario['nombre']!,
        fecha: timestamp,
      );

      await _cargarSaldos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Movimiento realizado: $cantidad unidades de ${origen.nombre} a ${destino.nombre}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error procesando movimiento: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al realizar el movimiento'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 🎯 NUEVO MÉTODO: Construir fila horizontal de proceso (COMPACTO)
  Widget _buildFilaProceso(Proceso proceso) {
    final cantidad = cantidadesPorProceso[proceso.id] ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          // Nombre del proceso (más pequeño)
          SizedBox(
            width: 110,
            child: Text(
              proceso.nombre.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Botón ENTRADA (más pequeño)
          SizedBox(
            width: 60,
            height: 28,
            child: ElevatedButton(
              onPressed: () => _mostrarFormularioEntradaDirecta(context, proceso),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'ENTRADA',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(width: 6),
          
          // Botón MOVER (más pequeño)
          SizedBox(
            width: 50,
            height: 28,
            child: ElevatedButton(
              onPressed: cantidad > 0
                  ? () => _mostrarFormularioMovimiento(context, proceso)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(3),
                ),
                minimumSize: Size.zero,
              ),
              child: const Text(
                'MOVER',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // CANTIDAD (más compacta)
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cantidad <= 0
                  ? Colors.red.shade50
                  : cantidad < 5
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: cantidad <= 0
                    ? Colors.red.shade200
                    : cantidad < 5
                        ? Colors.orange.shade200
                        : Colors.green.shade200,
                width: 0.5,
              ),
            ),
            child: Text(
              'CANT: $cantidad',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: cantidad <= 0
                    ? Colors.red.shade700
                    : cantidad < 5
                        ? Colors.orange.shade700
                        : Colors.green.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.95, // 95% del ancho
      constraints: const BoxConstraints(
        maxWidth: 1000,  // Reducido para ser más compacto
      ),
      padding: const EdgeInsets.all(16), // Menos padding
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 244, 250, 255),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header más compacto
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.producto.nombre,
                  style: const TextStyle(
                    fontSize: 18, // Más pequeño
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
              ),
            ],
          ),

          const SizedBox(height: 25), // Menos espacio
          
            // 🎯 NUEVA VISTA: Lista vertical compacta
            Container(
              constraints: const BoxConstraints(maxHeight: 300), // Altura máxima
              child: SingleChildScrollView( // Por si hay muchos procesos
                child: Column(
                  children: procesos.map((proceso) => _buildFilaProceso(proceso)).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Proceso {
  String id;
  String nombre;
  int orden;

  Proceso({required this.id, required this.nombre, required this.orden});

  static Proceso fromMap(String id, Map<String, dynamic> map) {
    return Proceso(
      id: id,
      nombre: map['nombre'] ?? '',
      orden: map['orden'] ?? 0,
    );
  }
}