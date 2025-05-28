import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditInvProdScreen extends StatefulWidget {
  final dynamic producto;

  const EditInvProdScreen({super.key, required this.producto});

  @override
  State<EditInvProdScreen> createState() => _EditInvProdScreenState();
}

class _EditInvProdScreenState extends State<EditInvProdScreen> {
  final TextEditingController _fundicionController = TextEditingController();
  final TextEditingController _pinturaController = TextEditingController();
  int general = 0;

  @override
  void initState() {
    super.initState();
    _fundicionController.text = '0';
    _pinturaController.text = '0';
    _fundicionController.addListener(_calcularGeneral);
    _pinturaController.addListener(_calcularGeneral);
  }

  void _calcularGeneral() {
    final pintura = int.tryParse(_pinturaController.text) ?? 0;
    setState(() {
      general = pintura;
    });
  }

  Future<void> _guardarDatos() async {
    final fundicion = int.tryParse(_fundicionController.text) ?? 0;
    final pintura = int.tryParse(_pinturaController.text) ?? 0;
    final timestamp = Timestamp.now();
    // Guardar historial en historial_inventario_general
    await FirebaseFirestore.instance
        .collection('historial_inventario_general')
        .add({
          'codigo': widget.producto.codigo,
          'nombre': widget.producto.nombre,
          'cantidad': general,
          'fecha_actualizacion': timestamp,
        });
    final productoData = {
      'codigo': widget.producto.codigo,
      'nombre': widget.producto.nombre,
      'fundicion': fundicion,
      'pintura': pintura,
      'general': general,
      'fecha_actualizacion': timestamp,
    };

    // Guardar en inventario_general (actualiza o crea)
    await FirebaseFirestore.instance
        .collection('inventario_general')
        .doc(widget.producto.codigo)
        .set(productoData, SetOptions(merge: true));

    // Guardar historial en inventario_fundicion
    await FirebaseFirestore.instance.collection('inventario_fundicion').add({
      'codigo': widget.producto.codigo,
      'nombre': widget.producto.nombre,
      'cantidad': fundicion,
      'fecha': timestamp,
    });

    // Guardar historial en inventario_pintura
    await FirebaseFirestore.instance.collection('inventario_pintura').add({
      'codigo': widget.producto.codigo,
      'nombre': widget.producto.nombre,
      'cantidad': pintura,
      'fecha': timestamp,
    });
  }

  @override
  void dispose() {
    _fundicionController.dispose();
    _pinturaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SafeArea(
        child: Column(
          children: [
            // Encabezado
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
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCampoElegante(
                      'Cantidad Fundición',
                      _fundicionController,
                      Icons.factory,
                      Colors.indigo,
                    ),
                    const SizedBox(height: 16),
                    _buildCampoElegante(
                      'Cantidad Pintura',
                      _pinturaController,
                      Icons.format_paint,
                      Colors.deepOrange,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text(
                        'Guardar',
                        style: TextStyle(fontSize: 16),
                      ),
                      onPressed: () async {
                        await _guardarDatos();
                        Navigator.pop(context);
                      },
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

  Widget _buildCampoElegante(
    String label,
    TextEditingController controller,
    IconData icon,
    Color iconColor,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: iconColor),
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        filled: true,
        fillColor: Colors.white,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: iconColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
