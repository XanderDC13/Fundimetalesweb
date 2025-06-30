import 'package:flutter/material.dart';
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildDropdownInsumos(),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cantidad:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Botón -
              IconButton(
                icon: const Icon(Icons.remove),
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

              // Campo texto cantidad con validación
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                    errorText:
                        (cantidad > maxCantidad) ? 'Máximo $maxCantidad' : null,
                  ),
                  onChanged: (value) {
                    if (value.isEmpty) {
                      setState(() {
                        cantidad = 0;
                      });
                    } else {
                      final parsed = int.tryParse(value);
                      if (parsed != null &&
                          parsed >= 0 &&
                          parsed <= maxCantidad) {
                        setState(() {
                          cantidad = parsed;
                        });
                      } else {
                        // Si intenta poner más que maxCantidad, ajusta al máximo permitido
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

              // Botón +
              IconButton(
                icon: const Icon(Icons.add),
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
          const SizedBox(height: 40),
          Center(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
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
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Selecciona un empleado',
          ),
          items:
              empleados
                  .map(
                    (doc) => DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['nombre']),
                    ),
                  )
                  .toList(),
          onChanged: (value) {
            setState(() {
              empleadoSeleccionado = value;
            });
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
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Selecciona un insumo',
          ),
          items:
              insumos
                  .map(
                    (doc) => DropdownMenuItem(
                      value: doc.id,
                      child: Text(doc['nombre']),
                    ),
                  )
                  .toList(),
          onChanged: (value) async {
            setState(() {
              insumoSeleccionado = value;
              cantidad = 0;
              _cantidadController.text = '0';
              maxCantidad = 0; // reiniciar mientras carga
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

    setState(() {
      guardando = true;
    });

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

        // Resta la cantidad solicitada al stock
        transaction.update(docInsumoRef, {'cantidad': stockActual - cantidad});

        // Crea la solicitud
        final solicitudRef =
            FirebaseFirestore.instance.collection('solicitudes_insumos').doc();

        transaction.set(solicitudRef, {
          'empleado_id': empleadoSeleccionado,
          'insumo_id': insumoSeleccionado,
          'cantidad': cantidad,
          'fecha': FieldValue.serverTimestamp(),
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
      setState(() {
        guardando = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
