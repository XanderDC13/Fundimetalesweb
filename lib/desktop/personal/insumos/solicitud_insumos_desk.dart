import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SolicitudInsumosDeskWidget extends StatefulWidget {
  const SolicitudInsumosDeskWidget({super.key});

  @override
  State<SolicitudInsumosDeskWidget> createState() =>
      _SolicitudInsumosDeskWidgetState();
}

class _SolicitudInsumosDeskWidgetState
    extends State<SolicitudInsumosDeskWidget> {
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
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Solicitud de Insumos',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildCard('Empleado', _buildDropdownEmpleados()),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildCard('Insumo', _buildDropdownInsumos()),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildCard('Cantidad', _buildCantidadSelector()),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 240,
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
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Card(
      color: const Color(0xFFF7F5F5),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildCantidadSelector() {
    return Container(
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
                final parsed = int.tryParse(value);
                if (parsed != null && parsed >= 0 && parsed <= maxCantidad) {
                  setState(() => cantidad = parsed);
                } else {
                  setState(() {
                    cantidad = maxCantidad;
                    _cantidadController.text = maxCantidad.toString();
                  });
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
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final empleados = snapshot.data!.docs;

        return Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, // 👈 Fondo de la lista desplegable
          ),
          child: DropdownButtonFormField<String>(
            value: empleadoSeleccionado,
            decoration: _dropdownDecoration('Selecciona un empleado'),
            items:
                empleados.map((doc) {
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      doc['nombre'],
                      style: const TextStyle(
                        color: Colors.black,
                      ), // Texto negro sobre fondo blanco
                    ),
                  );
                }).toList(),
            onChanged: (value) => setState(() => empleadoSeleccionado = value),
          ),
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
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final insumos = snapshot.data!.docs;

        return Theme(
          data: Theme.of(context).copyWith(
            canvasColor: Colors.white, // 👈 Fondo blanco para el menú
          ),
          child: DropdownButtonFormField<String>(
            value: insumoSeleccionado,
            decoration: _dropdownDecoration('Selecciona un insumo'),
            items:
                insumos.map((doc) {
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text(
                      doc['nombre'],
                      style: const TextStyle(
                        color: Colors.black,
                      ), // Texto negro visible
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
                  setState(() {
                    maxCantidad = doc['cantidad'] ?? 0;
                  });
                }
              }
            },
          ),
        );
      },
    );
  }

  InputDecoration _dropdownDecoration(String hint) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
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

    final userDoc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(currentUser.uid)
            .get();
    final nombreUsuario =
        userDoc.data()?['nombre'] ?? currentUser.email ?? '---';

    final empleadoDoc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(empleadoSeleccionado)
            .get();
    final nombreEmpleado =
        empleadoDoc.data()?['nombre'] ?? empleadoSeleccionado;

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

        if (!snapshot.exists) throw Exception('El insumo no existe');

        final stockActual = snapshot['cantidad'] ?? 0;
        if (stockActual < cantidad) {
          throw Exception('Stock insuficiente. Quedan $stockActual unidades.');
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
