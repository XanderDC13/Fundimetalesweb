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
  Map<String, Map<String, int>> cantidadesPorSucursalProceso = {};
  List<Proceso> procesos = [];
  bool cargando = true;
  String sucursalUsuario = '';
  String sucursalSeleccionada = '';

  final _auth = FirebaseAuth.instance;
  final List<String> sucursales = ['Quito', 'Guayaquil', 'Tulcán'];

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await _cargarSucursalUsuario();
    await _cargarProcesos();
    await _cargarSaldos();
    await _cargarSaldosTodasSucursales();
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

  void _mostrarFormularioSalidaDirecta(BuildContext context, Proceso proceso) {
    final TextEditingController cantidadController = TextEditingController();
      bool puedeGuardar = false;
    bool procesandoSalida = false;
    final cantidadDisponible = cantidadesPorProceso[proceso.id] ?? 0;

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
                          Icons.remove_circle_outline,
                          color: Colors.red.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Salida directa de ${proceso.nombre}',
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
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Disponible en ${proceso.nombre}: $cantidadDisponible unidades',
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
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
                        labelText: 'Cantidad a descontar',
                        hintText: 'Máximo: $cantidadDisponible',
                        prefixIcon: Icon(
                          Icons.remove,
                          color: Colors.red.shade700,
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
                          borderSide: BorderSide(color: Colors.red.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        final cantidad = int.tryParse(value) ?? 0;
                        setModalState(() {
                          puedeGuardar =
                              cantidad > 0 && cantidad <= cantidadDisponible;
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
                              (puedeGuardar && !procesandoSalida)
                                  ? () async {
                                    setModalState(() {
                                      procesandoSalida = true;
                                    });

                                    try {
                                      final cantidad =
                                          int.tryParse(
                                            cantidadController.text,
                                          ) ??
                                          0;

                                      await _procesarSalidaDirecta(
                                        proceso,
                                        cantidad,
                                        'Salida manual', // Motivo por defecto
                                      );
                                      if (mounted) Navigator.pop(context);
                                    } catch (e) {
                                      setModalState(() {
                                        procesandoSalida = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error al procesar salida: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                  : null,
                          icon:
                              procesandoSalida
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.remove_circle),
                          label: Text(
                            procesandoSalida
                                ? 'Procesando...'
                                : 'Registrar salida',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                procesandoSalida
                                    ? Colors.grey
                                    : Colors.red.shade700,
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

  Future<void> _procesarSalidaDirecta(
    Proceso proceso,
    int cantidad,
    String motivo,
  ) async {
    try {
      final timestamp = Timestamp.now();
      final usuario = await _obtenerDatosUsuario();

      // Reducir cantidad en proceso actual de la sucursal
      final docInventario = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(usuario['sucursal']!)
          .collection('procesos')
          .doc(proceso.id)
          .collection('productos')
          .doc(widget.producto.referencia);

      final snapshot = await docInventario.get();
      final cantidadActual = snapshot.exists ? (snapshot['cantidad'] ?? 0) : 0;

      await docInventario.update({
        'cantidad': cantidadActual - cantidad,
        'ultima_actualizacion': timestamp,
      });

      // Registrar en colección de salidas
      await FirebaseFirestore.instance.collection('salidas_manuales').add({
        'producto_referencia': widget.producto.referencia,
        'producto_nombre': widget.producto.nombre,
        'proceso_id': proceso.id,
        'proceso_nombre': proceso.nombre,
        'cantidad': cantidad,
        'motivo': motivo,
        'fecha': timestamp,
        'usuario_uid': usuario['uid']!,
        'usuario_nombre': usuario['nombre']!,
        'sucursal': usuario['sucursal']!,
      });

      // Registrar auditoría
      await _guardarAuditoria(
        accion: 'Salida Manual de Producto',
        detalle:
            'Producto: ${widget.producto.nombre} (${widget.producto.referencia}), '
            'Proceso: ${proceso.nombre}, Cantidad: $cantidad, Motivo: $motivo, Sucursal: ${usuario['sucursal']}',
        uid: usuario['uid']!,
        nombreUsuario: usuario['nombre']!,
        sucursal: usuario['sucursal']!,
        fecha: timestamp,
      );

      await _cargarSaldos();
      await _cargarSaldosTodasSucursales();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Salida registrada: $cantidad unidades de ${proceso.nombre} (${usuario['sucursal']})',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error procesando salida directa: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar la salida'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cargarSaldos() async {
    Map<String, int> nuevasCantidades = {};

    for (var proceso in procesos) {
      try {
        final doc =
            await FirebaseFirestore.instance
                .collection('inventarios')
                .doc(sucursalUsuario) // MODIFICADO: Usar sucursal del usuario
                .collection('procesos')
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
      return {
        'uid': 'desconocido',
        'nombre': 'Desconocido',
        'sucursal': sucursalUsuario,
      };
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      final nombre =
          userDoc.exists ? (userDoc['nombre'] ?? 'Desconocido') : 'Desconocido';
      // Cambiar 'sucursal' por 'sede'
      final sucursal =
          userDoc.exists
              ? (userDoc['sede'] ?? sucursalUsuario)
              : sucursalUsuario;

      return {'uid': user.uid, 'nombre': nombre, 'sucursal': sucursal};
    } catch (e) {
      return {
        'uid': user.uid,
        'nombre': 'Usuario',
        'sucursal': sucursalUsuario,
      };
    }
  }

  Future<void> _cargarSucursalUsuario() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          // Cambiar 'sucursal' por 'sede'
          sucursalUsuario = data['sede'] ?? 'QUITO';
          sucursalSeleccionada = sucursalUsuario;
        } else {
          sucursalUsuario = 'QUITO';
          sucursalSeleccionada = 'QUITO';
        }
      }
    } catch (e) {
      print('Error cargando sucursal del usuario: $e');
      sucursalUsuario = 'QUITO';
      sucursalSeleccionada = 'QUITO';
    }
  }

  Future<void> _cargarSaldosTodasSucursales() async {
    Map<String, Map<String, int>> nuevasCantidadesSucursales = {};

    for (String sucursal in sucursales) {
      nuevasCantidadesSucursales[sucursal] = {};

      for (var proceso in procesos) {
        try {
          final doc =
              await FirebaseFirestore.instance
                  .collection('inventarios')
                  .doc(sucursal)
                  .collection('procesos')
                  .doc(proceso.id)
                  .collection('productos')
                  .doc(widget.producto.referencia)
                  .get();

          nuevasCantidadesSucursales[sucursal]![proceso.id] =
              doc.exists ? (doc['cantidad'] ?? 0) : 0;
        } catch (e) {
          print('Error cargando saldo para $sucursal-${proceso.id}: $e');
          nuevasCantidadesSucursales[sucursal]![proceso.id] = 0;
        }
      }
    }

    if (!mounted) return;

    setState(() {
      cantidadesPorSucursalProceso = nuevasCantidadesSucursales;
    });
  }

  Future<void> _guardarAuditoria({
    required String accion,
    required String detalle,
    required String uid,
    required String nombreUsuario,
    required String sucursal, // NUEVO: Parámetro sucursal
    required Timestamp fecha,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('auditoria_general').add({
        'accion': accion,
        'detalle': detalle,
        'fecha': fecha,
        'usuario_nombre': nombreUsuario,
        'usuario_uid': uid,
        'sucursal': sucursal, // NUEVO: Guardar sucursal en auditoría
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
    required String sucursal, // NUEVO: Parámetro sucursal
  }) async {
    try {
      await FirebaseFirestore.instance.collection('movimientos').add({
        'producto_referencia': widget.producto.referencia,
        'proceso_origen': procesoOrigen,
        'proceso_destino': procesoDestino,
        'cantidad': cantidad,
        'fecha': Timestamp.now(),
        'usuario': usuarioUid,
        'sucursal': sucursal, // NUEVO: Guardar sucursal en movimientos
      });
    } catch (e) {
      print('Error registrando movimiento: $e');
    }
  }

  void _mostrarFormularioEntradaDirecta(BuildContext context, Proceso proceso) {
    final TextEditingController cantidadController = TextEditingController();
    bool puedeGuardar = false;
    bool procesandoEntrada = false;

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
                              (puedeGuardar && !procesandoEntrada)
                                  ? () async {
                                    setModalState(() {
                                      procesandoEntrada = true;
                                    });

                                    try {
                                      final cantidad =
                                          int.tryParse(
                                            cantidadController.text,
                                          ) ??
                                          0;
                                      await _procesarEntradaDirecta(
                                        proceso,
                                        cantidad,
                                      );
                                      if (mounted) Navigator.pop(context);
                                    } catch (e) {
                                      setModalState(() {
                                        procesandoEntrada = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error al procesar entrada: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                  : null,
                          icon:
                              procesandoEntrada
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.add),
                          label: Text(
                            procesandoEntrada
                                ? 'Procesando...'
                                : 'Agregar entrada',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                procesandoEntrada
                                    ? Colors.grey
                                    : const Color(0xFF4682B4),
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

  void _mostrarFormularioRechazo(BuildContext context, Proceso proceso) {
    final TextEditingController cantidadController = TextEditingController();
    final TextEditingController motivoController = TextEditingController();
    bool puedeGuardar = false;
    bool procesandoRechazo = false;
    final cantidadDisponible = cantidadesPorProceso[proceso.id] ?? 0;

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
                          Icons.report_problem,
                          color: Colors.orange.shade700,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Rechazar desde ${proceso.nombre}',
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
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Disponible en ${proceso.nombre}: $cantidadDisponible unidades',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo cantidad a rechazar
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad a rechazar',
                        hintText: 'Máximo: $cantidadDisponible',
                        prefixIcon: Icon(
                          Icons.remove_circle_outline,
                          color: Colors.orange.shade700,
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
                          borderSide: BorderSide(color: Colors.orange.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        final cantidad = int.tryParse(value) ?? 0;
                        final motivo = motivoController.text.trim();
                        setModalState(() {
                          puedeGuardar =
                              cantidad > 0 &&
                              cantidad <= cantidadDisponible &&
                              motivo.isNotEmpty;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo motivo del rechazo
                    TextField(
                      controller: motivoController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Motivo del rechazo',
                        hintText: 'Describe el motivo del rechazo...',
                        prefixIcon: Icon(
                          Icons.description,
                          color: Colors.orange.shade700,
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
                          borderSide: BorderSide(color: Colors.orange.shade700),
                        ),
                      ),
                      onChanged: (value) {
                        final cantidad =
                            int.tryParse(cantidadController.text) ?? 0;
                        final motivo = value.trim();
                        setModalState(() {
                          puedeGuardar =
                              cantidad > 0 &&
                              cantidad <= cantidadDisponible &&
                              motivo.isNotEmpty;
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
                              (puedeGuardar && !procesandoRechazo)
                                  ? () async {
                                    setModalState(() {
                                      procesandoRechazo = true;
                                    });

                                    try {
                                      final cantidad =
                                          int.tryParse(
                                            cantidadController.text,
                                          ) ??
                                          0;
                                      final motivo =
                                          motivoController.text.trim();
                                      await _procesarRechazo(
                                        proceso,
                                        cantidad,
                                        motivo,
                                      );
                                      if (mounted) Navigator.pop(context);
                                    } catch (e) {
                                      setModalState(() {
                                        procesandoRechazo = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error al procesar rechazo: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                  : null,
                          icon:
                              procesandoRechazo
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Icon(Icons.report_problem),
                          label: Text(
                            procesandoRechazo
                                ? 'Procesando...'
                                : 'Registrar rechazo',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                procesandoRechazo
                                    ? Colors.grey
                                    : Colors.orange.shade700,
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

  Future<void> _procesarRechazo(
    Proceso proceso,
    int cantidad,
    String motivo,
  ) async {
    try {
      final timestamp = Timestamp.now();
      final usuario = await _obtenerDatosUsuario();

      // MODIFICADO: Reducir cantidad en proceso actual de la sucursal
      final docInventario = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(usuario['sucursal']!)
          .collection('procesos')
          .doc(proceso.id)
          .collection('productos')
          .doc(widget.producto.referencia);

      final snapshot = await docInventario.get();
      final cantidadActual = snapshot.exists ? (snapshot['cantidad'] ?? 0) : 0;

      await docInventario.update({
        'cantidad': cantidadActual - cantidad,
        'ultima_actualizacion': timestamp,
      });

      // Registrar en colección de rechazos
      await FirebaseFirestore.instance.collection('rechazos').add({
        'producto_referencia': widget.producto.referencia,
        'producto_nombre': widget.producto.nombre,
        'proceso_id': proceso.id,
        'proceso_nombre': proceso.nombre,
        'cantidad': cantidad,
        'motivo': motivo,
        'fecha': timestamp,
        'usuario_uid': usuario['uid']!,
        'usuario_nombre': usuario['nombre']!,
        'sucursal': usuario['sucursal']!, // NUEVO: Guardar sucursal en rechazos
      });

      // Registrar auditoría
      await _guardarAuditoria(
        accion: 'Rechazo de Producto',
        detalle:
            'Producto: ${widget.producto.nombre} (${widget.producto.referencia}), '
            'Proceso: ${proceso.nombre}, Cantidad: $cantidad, Motivo: $motivo, Sucursal: ${usuario['sucursal']}',
        uid: usuario['uid']!,
        nombreUsuario: usuario['nombre']!,
        sucursal: usuario['sucursal']!,
        fecha: timestamp,
      );

      await _cargarSaldos();
      await _cargarSaldosTodasSucursales(); // NUEVO: Recargar todas las sucursales

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rechazo registrado: $cantidad unidades de ${proceso.nombre} (${usuario['sucursal']})',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error procesando rechazo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al procesar el rechazo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                          Icons.transfer_within_a_station,
                          color: const Color(0xFF4682B4),
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

      // MODIFICADO: Actualizar inventario de la sucursal del usuario
      final docInventario = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(usuario['sucursal']!) // MODIFICADO: Usar sucursal del usuario
          .collection('procesos')
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
        accion: 'Agregar Cantidad Inventario',
        detalle:
            'Producto: ${widget.producto.nombre} (${widget.producto.referencia}), '
            'Proceso: ${proceso.nombre}, Cantidad: $cantidad, Sucursal: ${usuario['sucursal']}',
        uid: usuario['uid']!,
        nombreUsuario: usuario['nombre']!,
        sucursal: usuario['sucursal']!,
        fecha: timestamp,
      );

      await _cargarSaldos();
      await _cargarSaldosTodasSucursales(); // NUEVO: Recargar todas las sucursales

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entrada registrada: $cantidad unidades a ${proceso.nombre} (${usuario['sucursal']})',
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

      // MODIFICADO: Reducir cantidad en proceso origen de la sucursal
      final docOrigen = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(usuario['sucursal']!)
          .collection('procesos')
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

      // MODIFICADO: Aumentar cantidad en proceso destino de la sucursal
      final docDestino = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(usuario['sucursal']!)
          .collection('procesos')
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
        sucursal: usuario['sucursal']!,
      );

      // Registrar auditoría
      await _guardarAuditoria(
        accion: 'Movimiento Cantidad Procesos',
        detalle:
            'Producto: ${widget.producto.nombre} (${widget.producto.referencia}), '
            'De: ${origen.nombre} a ${destino.nombre}, Cantidad: $cantidad, Sucursal: ${usuario['sucursal']}',
        uid: usuario['uid']!,
        nombreUsuario: usuario['nombre']!,
        sucursal: usuario['sucursal']!,
        fecha: timestamp,
      );

      await _cargarSaldos();
      await _cargarSaldosTodasSucursales(); // NUEVO: Recargar todas las sucursales

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Movimiento realizado: $cantidad unidades de ${origen.nombre} a ${destino.nombre} (${usuario['sucursal']})',
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

  Widget _buildResumenSucursales() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'INVENTARIO POR SUCURSALES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              // Dropdown para seleccionar sucursal a visualizar
              // Dropdown para seleccionar sucursal a visualizar
              DropdownButton<String>(
                value:
                    sucursalSeleccionada.isEmpty
                        ? null
                        : sucursalSeleccionada, // CAMBIO AQUÍ
                items:
                    sucursales.map((sucursal) {
                      return DropdownMenuItem<String>(
                        value: sucursal,
                        child: Text(
                          sucursal,
                          style: const TextStyle(fontSize: 12),
                        ),
                      );
                    }).toList(),
                onChanged: (String? nueva) {
                  if (nueva != null) {
                    setState(() {
                      sucursalSeleccionada = nueva;
                      if (cantidadesPorSucursalProceso.containsKey(nueva)) {
                        cantidadesPorProceso = Map<String, int>.from(
                          cantidadesPorSucursalProceso[nueva]!,
                        );
                      }
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Mostrar totales por sucursal
          ...sucursales.map((sucursal) {
            final totalSucursal =
                cantidadesPorSucursalProceso[sucursal]?.values.fold<int>(
                  0,
                  (sum, cantidad) => sum + cantidad,
                ) ??
                0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$sucursal:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          sucursal == sucursalUsuario
                              ? FontWeight.bold
                              : FontWeight.normal,
                      color:
                          sucursal == sucursalUsuario
                              ? Colors.blue.shade700
                              : Colors.grey.shade600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color:
                          sucursal == sucursalUsuario
                              ? Colors.blue.shade100
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$totalSucursal unidades',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            sucursal == sucursalUsuario
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const Divider(height: 16),

          // Total general
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL GENERAL:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  '${cantidadesPorSucursalProceso.values.expand((sucursal) => sucursal.values).fold<int>(0, (sum, cantidad) => sum + cantidad)} unidades',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilaProceso(Proceso proceso) {
    final cantidad = cantidadesPorProceso[proceso.id] ?? 0;

    return Container(
      width: 420,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          // Nombre del proceso
          SizedBox(
            width: 120,
            child: Text(
              '${proceso.nombre.toUpperCase()} ($sucursalSeleccionada)',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Solo mostrar botones si es la sucursal del usuario actual
          if (sucursalSeleccionada == sucursalUsuario) ...[
            // Botón ENTRADA
            SizedBox(
              width: 27,
              height: 28,
              child: ElevatedButton(
                onPressed:
                    () => _mostrarFormularioEntradaDirecta(context, proceso),
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
                  '+',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(width: 6),
            // Botón SALIDA
            SizedBox(
              width: 27,
              height: 28,
              child: ElevatedButton(
                onPressed:
                    cantidad > 0
                        ? () =>
                            _mostrarFormularioSalidaDirecta(context, proceso)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  '-',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(width: 6),
            // Botón MOVER
            SizedBox(
              width: 45,
              height: 28,
              child: ElevatedButton(
                onPressed:
                    cantidad > 0
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

            const SizedBox(width: 6),

            // Botón RECHAZO
            SizedBox(
              width: 45,
              height: 28,
              child: ElevatedButton(
                onPressed:
                    cantidad > 0
                        ? () => _mostrarFormularioRechazo(context, proceso)
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3),
                  ),
                  minimumSize: Size.zero,
                ),
                child: const Text(
                  'RECHAZO',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(width: 8),
          ] else ...[
            // Espacio vacío para mantener alineación cuando solo se visualiza
            const SizedBox(width: 197),
          ],

          // CANTIDAD
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  cantidad <= 0
                      ? Colors.red.shade50
                      : cantidad < 5
                      ? Colors.orange.shade50
                      : Colors.green.shade50,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color:
                    cantidad <= 0
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
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color:
                    cantidad <= 0
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
      width: MediaQuery.of(context).size.width * 0.98,
      constraints: const BoxConstraints(maxWidth: 1000),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 244, 250, 255),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.producto.nombre,
                  style: const TextStyle(
                    fontSize: 18,
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

          const SizedBox(height: 16),

          // NUEVO: Resumen por sucursales
          _buildResumenSucursales(),

          // Lista de procesos
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              child: Column(
                children:
                    procesos
                        .map((proceso) => _buildFilaProceso(proceso))
                        .toList(),
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
