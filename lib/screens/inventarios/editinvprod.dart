import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditInvProdScreen extends StatefulWidget {
  final dynamic producto;

  const EditInvProdScreen({super.key, required this.producto});

  @override
  State<EditInvProdScreen> createState() => _EditInvProdScreenState();
}

class _EditInvProdScreenState extends State<EditInvProdScreen> {
  int? cantidadFundicion;
  int? cantidadPintura;
  TimeOfDay? horaFundicion;
  TimeOfDay? horaPintura;
  int general = 0;

  // ... (todo tu import original permanece intacto)

  void _mostrarFormulario(BuildContext context, String tipo) {
    final TextEditingController cantidadController = TextEditingController();
    TimeOfDay? horaSeleccionada;
    bool puedeGuardar = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
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
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: cantidadController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: Icon(Icons.production_quantity_limits),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      setModalState(() {
                        puedeGuardar =
                            parsed != null &&
                            parsed > 0 &&
                            horaSeleccionada != null;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 8),
                      const Text('Hora de llegada:'),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final nuevaHora = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (nuevaHora != null) {
                            setModalState(() {
                              horaSeleccionada = nuevaHora;
                              final cantidad = int.tryParse(
                                cantidadController.text,
                              );
                              puedeGuardar = cantidad != null && cantidad > 0;
                            });
                          }
                        },
                        child: Text(
                          horaSeleccionada?.format(context) ?? 'Seleccionar',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          puedeGuardar
                              ? () async {
                                final cantidad =
                                    int.tryParse(cantidadController.text) ?? 0;
                                final now = DateTime.now();
                                final horaExacta = DateTime(
                                  now.year,
                                  now.month,
                                  now.day,
                                  horaSeleccionada!.hour,
                                  horaSeleccionada!.minute,
                                );
                                final timestamp = Timestamp.fromDate(
                                  horaExacta,
                                );
                                final horaSeleccionadaStr = horaSeleccionada!
                                    .format(context);

                                if (tipo == 'Fundición') {
                                  setState(() {
                                    cantidadFundicion = cantidad;
                                    horaFundicion = horaSeleccionada;
                                  });
                                  await FirebaseFirestore.instance
                                      .collection('inventario_fundicion')
                                      .add({
                                        'codigo': widget.producto.codigo,
                                        'nombre': widget.producto.nombre,
                                        'cantidad': cantidad,
                                        'fecha': timestamp,
                                        'hora': horaSeleccionadaStr,
                                      });
                                } else {
                                  setState(() {
                                    cantidadPintura = cantidad;
                                    horaPintura = horaSeleccionada;
                                    general = cantidad; // Solo suma pintura
                                  });

                                  await FirebaseFirestore.instance
                                      .collection('inventario_pintura')
                                      .add({
                                        'codigo': widget.producto.codigo,
                                        'nombre': widget.producto.nombre,
                                        'cantidad': cantidad,
                                        'fecha': timestamp,
                                        'hora': horaSeleccionadaStr,
                                      });

                                  await FirebaseFirestore.instance
                                      .collection(
                                        'historial_inventario_general',
                                      )
                                      .add({
                                        'codigo': widget.producto.codigo,
                                        'nombre': widget.producto.nombre,
                                        'cantidad': general,
                                        'fecha_actualizacion': timestamp,
                                      });

                                  await FirebaseFirestore.instance
                                      .collection('inventario_general')
                                      .doc(widget.producto.codigo)
                                      .set({
                                        'codigo': widget.producto.codigo,
                                        'nombre': widget.producto.nombre,
                                        'fundicion': cantidadFundicion ?? 0,
                                        'pintura': cantidad,
                                        'general': general,
                                        'fecha_actualizacion': timestamp,
                                      }, SetOptions(merge: true));
                                }

                                Navigator.pop(context);
                              }
                              : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
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
    required TimeOfDay? hora,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.factory, color: color),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                cantidad?.toString() ?? '--',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hora != null)
                Text(
                  hora.format(context),
                  style: const TextStyle(color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Text(
                'Editar: ${widget.producto.nombre}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildBotonEntrada(
                      titulo: 'Fundición',
                      cantidad: cantidadFundicion,
                      hora: horaFundicion,
                      color: Colors.indigo,
                      onPressed: () => _mostrarFormulario(context, 'Fundición'),
                    ),
                    const SizedBox(height: 16),
                    _buildBotonEntrada(
                      titulo: 'Pintura',
                      cantidad: cantidadPintura,
                      hora: horaPintura,
                      color: Colors.deepOrange,
                      onPressed: () => _mostrarFormulario(context, 'Pintura'),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.inventory_2, color: Color(0xFF1E3A8A)),
                              SizedBox(width: 8),
                              Text(
                                'Inventario General',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            general.toString(),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
