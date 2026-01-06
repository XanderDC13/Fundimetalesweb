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
  bool esEmpleadoManual = false;
  String nombreEmpleadoManual = '';

  final TextEditingController _cantidadController = TextEditingController(
    text: '0',
  );
  final TextEditingController _nombreEmpleadoController =
      TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    _nombreEmpleadoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
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
                      child: _buildCard('Usuario', _buildSelectorEmpleado()),
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
                      onPressed:
                          guardando || maxCantidad == 0
                              ? null
                              : _guardarSolicitud, // CAMBIO AQUÍ
                      icon: const Icon(Icons.save),
                      label:
                          guardando
                              ? const Text('Guardando...')
                              : maxCantidad == 0
                              ? const Text('Sin stock disponible')
                              : const Text('Guardar Solicitud'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.grey.shade300, // Añadir esta línea
                        disabledForegroundColor:
                            Colors.grey.shade600, // Añadir esta línea
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
      ),
    );
  }

  Widget _buildCard(String title, Widget child) {
    return Card(
      color: const Color(0xFFF0F4F8),
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

  Widget _buildSelectorEmpleado() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final empleados = snapshot.data!.docs;

        return Autocomplete<Map<String, String>>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              // Mostrar todos los empleados + opción manual
              final allOptions =
                  empleados.map((doc) {
                    return {'id': doc.id, 'nombre': doc['nombre'].toString()};
                  }).toList();

              allOptions.add({
                'id': 'MANUAL',
                'nombre': 'Agregar nuevo usuario',
              });
              return allOptions;
            }

            // Filtrar por búsqueda
            final filtered =
                empleados
                    .where((doc) {
                      return doc['nombre'].toString().toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    })
                    .map((doc) {
                      return {'id': doc.id, 'nombre': doc['nombre'].toString()};
                    })
                    .toList();

            filtered.add({'id': 'MANUAL', 'nombre': 'Agregar nuevo usuario'});
            return filtered;
          },
          displayStringForOption:
              (Map<String, String> option) => option['nombre']!,
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Buscar usuario...',
                prefixIcon: const Icon(Icons.person, color: Color(0xFF4682B4)),
                suffixIcon:
                    empleadoSeleccionado != null
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            controller.clear();
                            setState(() {
                              empleadoSeleccionado = null;
                              esEmpleadoManual = false;
                              nombreEmpleadoManual = '';
                              _nombreEmpleadoController.clear();
                            });
                          },
                        )
                        : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF4682B4),
                    width: 2,
                  ),
                ),
              ),
            );
          },
          onSelected: (Map<String, String> selection) {
            setState(() {
              empleadoSeleccionado = selection['id'];
              esEmpleadoManual = selection['id'] == 'MANUAL';
              if (!esEmpleadoManual) {
                nombreEmpleadoManual = '';
                _nombreEmpleadoController.clear();
              }
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isManual = option['id'] == 'MANUAL';

                      return ListTile(
                        leading: Icon(
                          isManual ? Icons.person_add : Icons.person,
                          color: const Color(0xFF4682B4),
                          size: 20,
                        ),
                        title: Text(
                          option['nombre']!,
                          style: TextStyle(
                            color:
                                isManual
                                    ? const Color(0xFF4682B4)
                                    : Colors.black,
                            fontWeight:
                                isManual ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCantidadSelector() {
    return Container(
      height: 50,
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
                contentPadding: EdgeInsets.symmetric(
                  vertical: 8,
                ), // Padding reducido
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
      width: 40, // Reducido de 50 a 40
      height: 40, // Reducido de 50 a 40
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color:
            onPressed != null ? const Color(0xFF4682B4) : Colors.grey.shade300,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18), // Icono más pequeño
        onPressed: onPressed,
        padding: EdgeInsets.zero, // Sin padding extra
      ),
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

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Autocomplete<Map<String, dynamic>>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return insumos.map((doc) {
                      return {
                        'id': doc.id,
                        'nombre': doc['nombre'].toString(),
                        'cantidad': doc['cantidad'] ?? 0,
                      };
                    }).toList();
                  }

                  return insumos
                      .where((doc) {
                        return doc['nombre'].toString().toLowerCase().contains(
                          textEditingValue.text.toLowerCase(),
                        );
                      })
                      .map((doc) {
                        return {
                          'id': doc.id,
                          'nombre': doc['nombre'].toString(),
                          'cantidad': doc['cantidad'] ?? 0,
                        };
                      })
                      .toList();
                },
                displayStringForOption:
                    (Map<String, dynamic> option) => option['nombre']!,
                fieldViewBuilder: (
                  context,
                  controller,
                  focusNode,
                  onFieldSubmitted,
                ) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Buscar insumo...',
                      prefixIcon: const Icon(
                        Icons.inventory_2,
                        color: Color(0xFF4682B4),
                      ),
                      suffixIcon:
                          insumoSeleccionado != null
                              ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  controller.clear();
                                  setState(() {
                                    insumoSeleccionado = null;
                                    cantidad = 0;
                                    maxCantidad = 0;
                                    _cantidadController.text = '0';
                                  });
                                },
                              )
                              : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF4682B4),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
                onSelected: (Map<String, dynamic> selection) {
                  setState(() {
                    insumoSeleccionado = selection['id'];
                    maxCantidad = selection['cantidad'] as int;
                    cantidad = 0;
                    _cantidadController.text = '0';
                  });
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final option = options.elementAt(index);

                            return ListTile(
                              leading: const Icon(
                                Icons.inventory_2,
                                color: Color(0xFF4682B4),
                                size: 20,
                              ),
                              title: Text(option['nombre']!),
                              trailing: Text(
                                'Stock: ${option['cantidad']}',
                                style: TextStyle(
                                  color:
                                      option['cantidad'] == 0
                                          ? Colors.red
                                          : Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              onTap: () => onSelected(option),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            if (insumoSeleccionado != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      maxCantidad == 0
                          ? Colors.red.shade50
                          : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        maxCantidad == 0
                            ? Colors.red.shade200
                            : Colors.green.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      maxCantidad == 0 ? Icons.warning : Icons.inventory,
                      size: 14,
                      color: maxCantidad == 0 ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      maxCantidad == 0
                          ? "Sin stock"
                          : "Disponible: $maxCantidad",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: maxCantidad == 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _guardarSolicitud() async {
    // Validación actualizada para incluir empleado manual
    if ((empleadoSeleccionado == null ||
            (esEmpleadoManual && nombreEmpleadoManual.isEmpty)) ||
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

    // Obtener nombre del empleado según si es manual o de la base de datos
    String nombreEmpleado;
    String empleadoId;

    if (esEmpleadoManual) {
      nombreEmpleado = nombreEmpleadoManual;
      empleadoId =
          'MANUAL_${DateTime.now().millisecondsSinceEpoch}'; // ID único para empleado manual
    } else {
      final empleadoDoc =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(empleadoSeleccionado)
              .get();
      nombreEmpleado = empleadoDoc.data()?['nombre'] ?? empleadoSeleccionado!;
      empleadoId = empleadoSeleccionado!;
    }

    final insumoDoc =
        await FirebaseFirestore.instance
            .collection('inventario_insumos')
            .doc(insumoSeleccionado)
            .get();
    final nombreInsumo = insumoDoc.data()?['nombre'] ?? insumoSeleccionado!;

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
          'empleado_id': empleadoId,
          'empleado_nombre': nombreEmpleado,
          'es_empleado_manual': esEmpleadoManual,
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
              'Usuario: $nombreEmpleado${esEmpleadoManual ? ' (Manual)' : ''}, Insumo: $nombreInsumo, Cantidad: $cantidad',
        });
      });

      setState(() {
        guardando = false;
        empleadoSeleccionado = null;
        insumoSeleccionado = null;
        cantidad = 0;
        esEmpleadoManual = false;
        nombreEmpleadoManual = '';
        _cantidadController.text = '0';
        _nombreEmpleadoController.clear();
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
