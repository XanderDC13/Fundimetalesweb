import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudInsumosWidget extends StatefulWidget {
  const SolicitudInsumosWidget({super.key});

  @override
  State<SolicitudInsumosWidget> createState() => _SolicitudInsumosWidgetState();
}

class _SolicitudInsumosWidgetState extends State<SolicitudInsumosWidget> {
  String? empleadoSeleccionado;
  String? insumoSeleccionado;
  int cantidad = 0;
  bool guardando = false;
  int maxCantidad = 0;

  final TextEditingController _cantidadController = TextEditingController(
    text: '0',
  );

  @override
  void dispose() {
    _cantidadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Empleado:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildDropdownEmpleados(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Insumo:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: _buildDropdownInsumos(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cantidad:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD6EAF8)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildRoundButton(
                  icon: Icons.remove,
                  onPressed:
                      cantidad > 0
                          ? () {
                            setState(() {
                              cantidad--;
                              _cantidadController.text = cantidad.toString();
                            });
                          }
                          : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _cantidadController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                        setState(() => cantidad = 0);
                      } else {
                        final parsed = int.tryParse(value);
                        if (parsed != null &&
                            parsed >= 0 &&
                            parsed <= maxCantidad) {
                          setState(() => cantidad = parsed);
                        } else {
                          setState(() {
                            cantidad = maxCantidad;
                            _cantidadController.text = maxCantidad.toString();
                          });
                        }
                      }
                    },
                    onEditingComplete: () {
                      if (_cantidadController.text.isEmpty) {
                        setState(() {
                          cantidad = 0;
                          _cantidadController.text = '0';
                        });
                      }
                    },
                  ),
                ),
                _buildRoundButton(
                  icon: Icons.add,
                  onPressed:
                      cantidad < maxCantidad
                          ? () {
                            setState(() {
                              cantidad++;
                              _cantidadController.text = cantidad.toString();
                            });
                          }
                          : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: guardando ? null : _guardarSolicitud,
              icon: const Icon(Icons.save),
              label:
                  guardando
                      ? const Text('Guardando...')
                      : const Text('Guardar Solicitud'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color:
            onPressed != null ? const Color(0xFF4682B4) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildDropdownEmpleados() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('usuarios_activos').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final empleados = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: empleadoSeleccionado,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Selecciona un empleado',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items:
              empleados.map((doc) {
                return DropdownMenuItem(
                  value: doc.id,
                  child: SizedBox(
                    width: 250,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person,
                          size: 20,
                          color: Color(0xFF4682B4),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc['nombre'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() => empleadoSeleccionado = value);
          },
        );
      },
    );
  }

  Widget _buildDropdownInsumos() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('inventario_insumos')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final insumos = snapshot.data!.docs;

        return DropdownButtonFormField<String>(
          value: insumoSeleccionado,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'Selecciona un insumo',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items:
              insumos.map((doc) {
                return DropdownMenuItem(
                  value: doc.id,
                  child: SizedBox(
                    width: 250,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 20,
                          color: Color(0xFF4682B4),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            doc['nombre'],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
          onChanged: (value) async {
            setState(() {
              insumoSeleccionado = value;
              cantidad = 0;
              _cantidadController.text = '0';
              maxCantidad = 0;
            });

            if (value != null) {
              final doc =
                  await FirebaseFirestore.instance
                      .collection('inventario_insumos')
                      .doc(value)
                      .get();

              if (doc.exists) {
                final stock = (doc.data()?['cantidad'] ?? 0) as int;
                setState(() {
                  maxCantidad = stock;
                });
              }
            }
          },
        );
      },
    );
  }

  Future<void> _guardarSolicitud() async {
    if (empleadoSeleccionado == null ||
        insumoSeleccionado == null ||
        cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completa todos los campos')),
      );
      return;
    }

    setState(() => guardando = true);

    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
      return;
    }

    // Traer nombre real del usuario logueado
    final userDoc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(currentUser.uid)
            .get();

    final nombreUsuario =
        userDoc.data()?['nombre'] ?? currentUser.email ?? '---';

    // Traer nombre del empleado seleccionado
    final empleadoDoc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(empleadoSeleccionado)
            .get();
    final nombreEmpleado =
        empleadoDoc.data()?['nombre'] ?? empleadoSeleccionado;

    // Traer nombre del insumo seleccionado
    final insumoDoc =
        await FirebaseFirestore.instance
            .collection('inventario_insumos')
            .doc(insumoSeleccionado)
            .get();
    final nombreInsumo = insumoDoc.data()?['nombre'] ?? insumoSeleccionado;

    final docInsumoRef = FirebaseFirestore.instance
        .collection('inventario_insumos')
        .doc(insumoSeleccionado);

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docInsumoRef);

        if (!snapshot.exists) {
          throw Exception('El insumo seleccionado no existe');
        }

        final stockActual = (snapshot['cantidad'] ?? 0) as int;
        if (stockActual < cantidad) {
          throw Exception(
            'Stock insuficiente. Solo quedan $stockActual unidades.',
          );
        }

        transaction.update(docInsumoRef, {'cantidad': stockActual - cantidad});

        final solicitudRef =
            FirebaseFirestore.instance.collection('solicitudes_insumos').doc();

        transaction.set(solicitudRef, {
          'empleado_id': empleadoSeleccionado,
          'insumo_id': insumoSeleccionado,
          'cantidad': cantidad,
          'fecha': FieldValue.serverTimestamp(),
          'solicitado_por_uid': currentUser.uid,
          'solicitado_por_nombre': nombreUsuario,
        });

        // Auditoría: ahora guarda los nombres legibles
        final auditoriaRef =
            FirebaseFirestore.instance.collection('auditoria_general').doc();

        transaction.set(auditoriaRef, {
          'fecha': FieldValue.serverTimestamp(),
          'usuario_nombre': nombreUsuario,
          'accion': 'Solicitud de Insumos',
          'detalle':
              'Empleado: $nombreEmpleado, Insumo: $nombreInsumo, Cantidad: $cantidad',
        });
      });

      setState(() {
        guardando = false;
        empleadoSeleccionado = null;
        insumoSeleccionado = null;
        cantidad = 0;
        _cantidadController.text = '0';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud guardada correctamente')),
      );
    } catch (e) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
