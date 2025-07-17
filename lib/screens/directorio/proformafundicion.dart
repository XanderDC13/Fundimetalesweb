import 'package:flutter/material.dart';

class ProformaCompraScreen extends StatefulWidget {
  const ProformaCompraScreen({super.key});

  @override
  State<ProformaCompraScreen> createState() => _ProformaCompraScreenState();
}

class _ProformaCompraScreenState extends State<ProformaCompraScreen> {
  final TextEditingController _proveedorController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _precioKgController = TextEditingController();

  double _total = 0.0;

  void _calcularTotal() {
    final peso = double.tryParse(_pesoController.text) ?? 0.0;
    final precioKg = double.tryParse(_precioKgController.text) ?? 0.0;
    setState(() {
      _total = peso * precioKg;
    });
  }

  void _guardarProforma() {
    print('✅ Proforma de compra guardada');
    print('Proveedor: ${_proveedorController.text}');
    print('Cédula: ${_cedulaController.text}');
    print('Teléfono: ${_telefonoController.text}');
    print('Material: ${_materialController.text}');
    print('Peso: ${_pesoController.text} Kg');
    print('Precio x Kg: ${_precioKgController.text}');
    print('TOTAL: $_total');

    _proveedorController.clear();
    _cedulaController.clear();
    _telefonoController.clear();
    _materialController.clear();
    _pesoController.clear();
    _precioKgController.clear();
    setState(() {
      _total = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Proforma de compra guardada')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTextField(_proveedorController, 'Proveedor'),
                      const SizedBox(height: 12),
                      _buildTextField(_cedulaController, 'Cédula / RUC'),
                      const SizedBox(height: 12),
                      _buildTextField(_telefonoController, 'Teléfono'),
                      const SizedBox(height: 12),
                      _buildTextField(_materialController, 'Material vendido'),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _pesoController,
                        'Peso (Kg)',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calcularTotal(),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _precioKgController,
                        'Precio por Kg',
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _calcularTotal(),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total a pagar:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$ ${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _guardarProforma,
                          icon: const Icon(Icons.save),
                          label: const Text('Guardar Proforma'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Center(
        child: Text(
          'Proforma de Compra',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
