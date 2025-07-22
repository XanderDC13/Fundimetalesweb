import 'package:flutter/material.dart';

class ProformaCompraScreenDesktop extends StatefulWidget {
  const ProformaCompraScreenDesktop({super.key});

  @override
  State<ProformaCompraScreenDesktop> createState() =>
      _ProformaCompraScreenDesktopState();
}

class _ProformaCompraScreenDesktopState
    extends State<ProformaCompraScreenDesktop> {
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
    print('✅ Proforma de compra guardada (desktop)');
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
      const SnackBar(content: Text('✅ Proforma de compra guardada (desktop)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
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
          ),
          title: const Text(
            'Proforma de Compra',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new),
            color: Colors.white,
            onPressed: () => Navigator.of(context).pop(),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(_proveedorController, 'Proveedor'),
                    const SizedBox(height: 16),
                    _buildTextField(_cedulaController, 'Cédula / RUC'),
                    const SizedBox(height: 16),
                    _buildTextField(_telefonoController, 'Teléfono'),
                    const SizedBox(height: 16),
                    _buildTextField(_materialController, 'Material vendido'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _pesoController,
                            'Peso (Kg)',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calcularTotal(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTextField(
                            _precioKgController,
                            'Precio por Kg',
                            keyboardType: TextInputType.number,
                            onChanged: (_) => _calcularTotal(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total a pagar:',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$ ${_total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _guardarProforma,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar Proforma'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4682B4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          textStyle: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
