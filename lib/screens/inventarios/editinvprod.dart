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
  int? cantidadGeneral;

  void _mostrarFormulario(BuildContext context, String tipo) {
    final TextEditingController cantidadController = TextEditingController();
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
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFD6EAF8),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
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
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: cantidadController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Cantidad',
                        labelStyle: const TextStyle(
                          color: Color(0xFF2C3E50),
                          fontWeight: FontWeight.w500,
                        ),
                        prefixIcon: const Icon(
                          Icons.production_quantity_limits,
                          color: Color(0xFF4682B4),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Colors.white,
                            width: 2,
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            puedeGuardar
                                ? () async {
                                  final cantidad =
                                      int.tryParse(cantidadController.text) ??
                                      0;
                                  final timestamp = Timestamp.now();

                                  if (tipo == 'Fundición') {
                                    setState(() {
                                      cantidadFundicion = cantidad;
                                    });
                                    await FirebaseFirestore.instance
                                        .collection('inventario_fundicion')
                                        .add({
                                          'codigo': widget.producto.codigo,
                                          'nombre': widget.producto.nombre,
                                          'cantidad': cantidad,
                                          'fecha': timestamp,
                                        });
                                  } else if (tipo == 'Pintura') {
                                    setState(() {
                                      cantidadPintura = cantidad;
                                    });
                                    await FirebaseFirestore.instance
                                        .collection('inventario_pintura')
                                        .add({
                                          'codigo': widget.producto.codigo,
                                          'nombre': widget.producto.nombre,
                                          'cantidad': cantidad,
                                          'fecha': timestamp,
                                        });
                                  } else if (tipo == 'Inventario General') {
                                    setState(() {
                                      cantidadGeneral = cantidad;
                                    });
                                    await FirebaseFirestore.instance
                                        .collection(
                                          'historial_inventario_general',
                                        )
                                        .add({
                                          'codigo': widget.producto.codigo,
                                          'nombre': widget.producto.nombre,
                                          'cantidad': cantidad,
                                          'fecha_actualizacion': timestamp,
                                        });
                                    await FirebaseFirestore.instance
                                        .collection('inventario_general')
                                        .doc(widget.producto.codigo)
                                        .set({
                                          'codigo': widget.producto.codigo,
                                          'nombre': widget.producto.nombre,
                                          'cantidad': cantidad,
                                          'fecha_actualizacion': timestamp,
                                        }, SetOptions(merge: true));
                                  }

                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                }
                                : null,
                        icon: const Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Guardar entrada',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
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
          Text(
            cantidad?.toString() ?? '--',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
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
                    Row(
                      children: [
                        Expanded(
                          child: _buildBotonEntrada(
                            titulo: 'Fundición',
                            cantidad: cantidadFundicion,
                            color: const Color(0xFF2C3E50),
                            onPressed:
                                () => _mostrarFormulario(context, 'Fundición'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildBotonEntrada(
                            titulo: 'Pintura',
                            cantidad: cantidadPintura,
                            color: const Color(0xFF2C3E50),
                            onPressed:
                                () => _mostrarFormulario(context, 'Pintura'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildBotonEntrada(
                      titulo: 'Inventario General',
                      cantidad: cantidadGeneral,
                      color: const Color(0xFF2C3E50),
                      onPressed:
                          () =>
                              _mostrarFormulario(context, 'Inventario General'),
                    ),
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
