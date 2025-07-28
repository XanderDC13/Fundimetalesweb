import 'package:basefundi/settings/navbar_desk.dart';
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
  int? cantidadFundicion;
  int? cantidadPintura;
  int? cantidadGeneral;

  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _cargarSaldos();
  }

  Future<void> _cargarSaldos() async {
    final docFundicion =
        await FirebaseFirestore.instance
            .collection('stock_fundicion')
            .doc(widget.producto.referencia)
            .get();
    final docPintura =
        await FirebaseFirestore.instance
            .collection('stock_pintura')
            .doc(widget.producto.referencia)
            .get();
    final docGeneral =
        await FirebaseFirestore.instance
            .collection('stock_general')
            .doc(widget.producto.referencia)
            .get();

    if (!mounted) return;

    setState(() {
      cantidadFundicion = docFundicion.exists ? docFundicion['cantidad'] : 0;
      cantidadPintura = docPintura.exists ? docPintura['cantidad'] : 0;
      cantidadGeneral = docGeneral.exists ? docGeneral['cantidad'] : 0;
    });
  }

  Future<Map<String, String>> _obtenerDatosUsuario() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {'uid': 'desconocido', 'nombre': 'Desconocido'};
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user.uid)
            .get();

    final nombre =
        userDoc.exists ? (userDoc['nombre'] ?? 'Desconocido') : 'Desconocido';

    return {'uid': user.uid, 'nombre': nombre};
  }

  Future<void> _guardarAuditoria({
    required String tipo,
    required int cantidad,
    required String uid,
    required String nombreUsuario,
    required Timestamp fecha,
  }) async {
    final detalle =
        'Producto: ${widget.producto.nombre}, Referencia: ${widget.producto.referencia}, Cantidad: $cantidad, Movimiento: $tipo';

    await FirebaseFirestore.instance.collection('auditoria_general').add({
      'accion': 'Entrada de inventario',
      'detalle': detalle,
      'fecha': fecha,
      'usuario_nombre': nombreUsuario,
      'usuario_uid': uid,
    });
  }

  void _mostrarFormulario(BuildContext context, String tipo) {
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
                    Text(
                      'Entrada a $tipo',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
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
                                    final timestamp = Timestamp.now();

                                    final usuario =
                                        await _obtenerDatosUsuario();

                                    if (tipo == 'Fundición') {
                                      await FirebaseFirestore.instance
                                          .collection('inventario_fundicion')
                                          .add({
                                            'referencia':
                                                widget.producto.referencia,
                                            'nombre': widget.producto.nombre,
                                            'cantidad': cantidad,
                                            'fecha': timestamp,
                                            'usuario_uid': usuario['uid'],
                                            'usuario_nombre': usuario['nombre'],
                                          });

                                      final docStock = FirebaseFirestore
                                          .instance
                                          .collection('stock_fundicion')
                                          .doc(widget.producto.referencia);
                                      final snapshot = await docStock.get();
                                      if (snapshot.exists) {
                                        final saldo = snapshot['cantidad'] ?? 0;
                                        await docStock.update({
                                          'cantidad': saldo + cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      } else {
                                        await docStock.set({
                                          'referencia':
                                              widget.producto.referencia,
                                          'nombre': widget.producto.nombre,
                                          'cantidad': cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      }
                                    } else if (tipo == 'Pintura') {
                                      await FirebaseFirestore.instance
                                          .collection('inventario_pintura')
                                          .add({
                                            'referencia':
                                                widget.producto.referencia,
                                            'nombre': widget.producto.nombre,
                                            'cantidad': cantidad,
                                            'fecha': timestamp,
                                            'usuario_uid': usuario['uid'],
                                            'usuario_nombre': usuario['nombre'],
                                          });

                                      final docFundicion = FirebaseFirestore
                                          .instance
                                          .collection('stock_fundicion')
                                          .doc(widget.producto.referencia);
                                      final snapFundicion =
                                          await docFundicion.get();
                                      if (snapFundicion.exists) {
                                        final saldoF =
                                            snapFundicion['cantidad'];
                                        await docFundicion.update({
                                          'cantidad':
                                              (saldoF - cantidad) < 0
                                                  ? 0
                                                  : saldoF - cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      }

                                      final docPintura = FirebaseFirestore
                                          .instance
                                          .collection('stock_pintura')
                                          .doc(widget.producto.referencia);
                                      final snapPintura =
                                          await docPintura.get();
                                      if (snapPintura.exists) {
                                        final saldoP = snapPintura['cantidad'];
                                        await docPintura.update({
                                          'cantidad': saldoP + cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      } else {
                                        await docPintura.set({
                                          'referencia':
                                              widget.producto.referencia,
                                          'nombre': widget.producto.nombre,
                                          'cantidad': cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      }
                                    } else if (tipo == 'Inventario General') {
                                      await FirebaseFirestore.instance
                                          .collection(
                                            'historial_inventario_general',
                                          )
                                          .add({
                                            'referencia':
                                                widget.producto.referencia,
                                            'nombre': widget.producto.nombre,
                                            'cantidad': cantidad,
                                            'fecha_actualizacion': timestamp,
                                            'usuario_uid': usuario['uid'],
                                            'usuario_nombre': usuario['nombre'],
                                          });

                                      final docPintura = FirebaseFirestore
                                          .instance
                                          .collection('stock_pintura')
                                          .doc(widget.producto.referencia);
                                      final snapPintura =
                                          await docPintura.get();
                                      if (snapPintura.exists) {
                                        final saldoP = snapPintura['cantidad'];
                                        await docPintura.update({
                                          'cantidad':
                                              (saldoP - cantidad) < 0
                                                  ? 0
                                                  : saldoP - cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      }

                                      final docGeneral = FirebaseFirestore
                                          .instance
                                          .collection('stock_general')
                                          .doc(widget.producto.referencia);
                                      final snapGeneral =
                                          await docGeneral.get();
                                      if (snapGeneral.exists) {
                                        final saldoG = snapGeneral['cantidad'];
                                        await docGeneral.update({
                                          'cantidad': saldoG + cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      } else {
                                        await docGeneral.set({
                                          'referencia':
                                              widget.producto.referencia,
                                          'nombre': widget.producto.nombre,
                                          'cantidad': cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                      }
                                    }

                                    // 🔴 GUARDAR EN AUDITORÍA GENERAL
                                    await _guardarAuditoria(
                                      tipo: tipo,
                                      cantidad: cantidad,
                                      uid: usuario['uid']!,
                                      nombreUsuario: usuario['nombre']!,
                                      fecha: timestamp,
                                    );

                                    await _cargarSaldos();
                                    if (mounted) Navigator.pop(context);
                                  }
                                  : null,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Guardar entrada',
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

  Widget _buildBotonEntrada({
    required String titulo,
    required int? cantidad,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.factory, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4682B4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  cantidad?.toString() ?? '--',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4682B4),
                  ),
                ),
              ),
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
          // ✅ CABECERA UNIDA Y CENTRADA
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
                    child: Text(
                      'Editar: ${widget.producto.nombre}',
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

          // ✅ CONTENIDO CON FONDO BLANCO
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 40,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Información del producto
                          Card(
                            color: const Color(0xFFF8F9FA),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Información del Producto',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text(
                                        'Referencia: ',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      Text(
                                        widget.producto.referencia ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botones de entrada en grid
                          Row(
                            children: [
                              Expanded(
                                child: _buildBotonEntrada(
                                  titulo: 'Fundición',
                                  cantidad: cantidadFundicion,
                                  color: const Color(0xFF2C3E50),
                                  onPressed:
                                      () => _mostrarFormulario(
                                        context,
                                        'Fundición',
                                      ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildBotonEntrada(
                                  titulo: 'Pintura',
                                  cantidad: cantidadPintura,
                                  color: const Color(0xFF2C3E50),
                                  onPressed:
                                      () => _mostrarFormulario(
                                        context,
                                        'Pintura',
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildBotonEntrada(
                            titulo: 'Inventario General',
                            cantidad: cantidadGeneral,
                            color: const Color(0xFF2C3E50),
                            onPressed:
                                () => _mostrarFormulario(
                                  context,
                                  'Inventario General',
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
