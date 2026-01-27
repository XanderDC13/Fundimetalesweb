import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ClienteDetalleDeskScreen extends StatefulWidget {
  final Map<String, dynamic> clienteData;

  const ClienteDetalleDeskScreen({super.key, required this.clienteData});

  @override
  State<ClienteDetalleDeskScreen> createState() =>
      _ClienteDetalleDeskScreenState();
}

class _ClienteDetalleDeskScreenState extends State<ClienteDetalleDeskScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // Control de selección
  Set<String> _proformasSeleccionadas = {};

  // Controladores para Mesa de Cobros
  final TextEditingController _fechaPagoController = TextEditingController();
  final TextEditingController _formaPagoController = TextEditingController(
    text: 'EFECTIVO',
  );
  String _formaPagoSeleccionada = 'Efectivo';
  String _comoCobraSeleccionado = 'Banco';
  final TextEditingController _numeroDocumentoController =
      TextEditingController();
  final TextEditingController _detallePagoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Fecha de hoy por defecto
    final hoy = DateTime.now();
    _fechaPagoController.text = '${hoy.day}/${hoy.month}/${hoy.year}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _fechaPagoController.dispose();
    _formaPagoController.dispose();
    _numeroDocumentoController.dispose();
    _detallePagoController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ================= HEADER =================
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Detalle del Cliente',
                      style: TextStyle(
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

          // ================= CONTENT =================
          Expanded(
            child: Container(
              color: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildClienteCard(),
                      const SizedBox(height: 16),
                      // TODO EN UNA SOLA FILA SIN SCROLL
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // TABLA DE FACTURAS (60% del ancho)
                            Expanded(flex: 6, child: _buildProformasTable()),
                            const SizedBox(width: 16),
                            // MESA DE COBROS (40% del ancho)
                            Expanded(
                              flex: 4,
                              child: _buildMesaCobrosCompacta(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClienteCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('proformas')
              .where('ci_ruc', isEqualTo: widget.clienteData['ruc'])
              .snapshots(),
      builder: (context, snapshot) {
        double totalFacturado = 0.0;
        double pagoFacturado = 0.0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Priorizar valor_declarado sobre total
            double total;
            final valorDeclarado =
                double.tryParse(data['valor_declarado']?.toString() ?? '0') ??
                0.0;
            if (valorDeclarado > 0) {
              total = valorDeclarado;
            } else {
              total = double.tryParse(data['total'].toString()) ?? 0.0;
            }

            totalFacturado += total;

            if (data['estado'] == 'Cobrado') {
              pagoFacturado += total;
            }
          }
        }

        final saldoFacturado = totalFacturado - pagoFacturado;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              // NOMBRE DEL CLIENTE - MÁS PEQUEÑO
              Text(
                widget.clienteData['nombre'] ?? 'Sin nombre',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),

              const Spacer(),

              // TOTALES EN FILA
              Row(
                children: [
                  _buildCompactTotal(
                    label: 'TOTAL FACT:',
                    value: totalFacturado.toStringAsFixed(2),
                  ),
                  const SizedBox(width: 24),
                  _buildCompactTotal(
                    label: 'SALDO FACT:',
                    value: saldoFacturado.toStringAsFixed(2),
                  ),
                  const SizedBox(width: 24),
                  _buildCompactTotal(
                    label: 'PAGOS FACT:',
                    value: pagoFacturado.toStringAsFixed(2),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // Nuevo widget para totales compactos
  Widget _buildCompactTotal({required String label, required String value}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value USD\$',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
      ],
    );
  }

  // ================= TABLA PROFORMAS =================
  Widget _buildProformasTable() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('proformas')
              .where('ci_ruc', isEqualTo: widget.clienteData['ruc'])
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final proformas = snapshot.data!.docs;

        if (proformas.isEmpty) {
          return const Center(child: Text('Este cliente no tiene proformas'));
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // HEADER
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 40), // Espacio para checkbox
                    _HeaderCell(text: 'Orden', flex: 2),
                    _HeaderCell(text: 'Prof', flex: 2),
                    _HeaderCell(text: 'Fact', flex: 2),
                    _HeaderCell(text: 'Tipo', flex: 1),
                    _HeaderCell(text: 'Valor USD\$', flex: 2),
                    _HeaderCell(text: 'Fecha', flex: 2),
                    _HeaderCell(text: 'Estado', flex: 2),
                    const SizedBox(width: 40), // Espacio para botón editar
                  ],
                ),
              ),

              // LISTA
              Expanded(
                child: ListView.builder(
                  itemCount: proformas.length,
                  itemBuilder: (_, i) {
                    final doc = proformas[i];
                    final proformaId = doc.id;
                    final data = doc.data() as Map<String, dynamic>;
                    double valorMostrar;
                    final valorDeclarado =
                        double.tryParse(
                          data['valor_declarado']?.toString() ?? '0',
                        ) ??
                        0.0;
                    if (valorDeclarado > 0) {
                      valorMostrar = valorDeclarado;
                    } else {
                      valorMostrar =
                          double.tryParse(data['total'].toString()) ?? 0.0;
                    }

                    return _tableRow(
                      proformaId: proformaId,
                      data: {
                        'numero_orden': data['numero_orden'] ?? '-', 
                        'factura': data['numero'].toString(),
                        'tipo': 'FAC',
                        'valor': valorMostrar,
                        'fecha': _formatFecha(data['fecha']),
                        'estado': data['estado'] ?? '',
                        'numero_factura': data['numero_factura'] ?? '',
                        'valor_declarado': data['valor_declarado'] ?? '0',
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatFecha(Timestamp ts) {
    final date = ts.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _tableRow({
    required String proformaId,
    required Map<String, dynamic> data,
  }) {
    final bool cobrado = data['estado'] == 'Cobrado';
    final bool seleccionada = _proformasSeleccionadas.contains(proformaId);

    return InkWell(
      onLongPress:
          cobrado
              ? null
              : () => _mostrarDialogoEditarFactura(context, proformaId, data),
      onTap:
          cobrado
              ? null
              : () {
                setState(() {
                  if (seleccionada) {
                    _proformasSeleccionadas.remove(proformaId);
                  } else {
                    _proformasSeleccionadas.add(proformaId);
                  }
                });
              },
      child: Container(
        color: seleccionada ? Colors.blue.withOpacity(0.1) : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // CHECKBOX
            SizedBox(
              width: 40,
              child:
                  cobrado
                      ? const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      )
                      : Checkbox(
                        value: seleccionada,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _proformasSeleccionadas.add(proformaId);
                            } else {
                              _proformasSeleccionadas.remove(proformaId);
                            }
                          });
                        },
                        activeColor: const Color(0xFF2C3E50),
                      ),
            ),
            _Cell(
              text: data['numero_orden'] ?? '-',
              flex: 2,
            ), // 👈 MODIFICAR ESTA LÍNEA
            _Cell(text: data['factura'], flex: 2), // PROFORMA
            _Cell(
              text:
                  data['numero_factura'].isEmpty ? '-' : data['numero_factura'],
              flex: 2,
            ), // FACTURA
            _Cell(text: data['tipo'], flex: 1),
            _Cell(text: '\$${data['valor'].toStringAsFixed(2)}', flex: 2),
            _Cell(text: data['fecha'], flex: 2),
            _Cell(
              text: data['estado'],
              flex: 2,
              color: cobrado ? Colors.green : Colors.transparent,
              bold: cobrado,
            ),
            // Botón editar (solo visible si NO está cobrado)
            SizedBox(
              width: 40,
              child:
                  !cobrado
                      ? IconButton(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed:
                            () => _mostrarDialogoEditarFactura(
                              context,
                              proformaId,
                              data,
                            ),
                        color: Colors.blue,
                        tooltip: 'Editar factura',
                      )
                      : const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMesaCobrosCompacta() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TÍTULO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              'Mesa de Cobros',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),

          // CONTENIDO SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // TABLA DE SELECCIONADAS
                  _buildTablaSeleccionadas(),
                  const SizedBox(height: 12),

                  // TOTALES
                  _buildTotalesCompactos(),
                  const SizedBox(height: 12),

                  // FORMULARIO COMPACTO
                  _buildFormularioCompacto(),
                  const SizedBox(height: 12),

                  // BOTONES
                  _buildBotones(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaSeleccionadas() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          // ================= HEADER =================
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Factura No.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Cuota',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'USD\$ Cobro',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ================= LISTA =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('proformas')
                      .where('ci_ruc', isEqualTo: widget.clienteData['ruc'])
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final proformasData =
                    snapshot.data!.docs
                        .where(
                          (doc) => _proformasSeleccionadas.contains(doc.id),
                        )
                        .toList();

                if (proformasData.isEmpty) {
                  return Center(
                    child: Text(
                      'Seleccione facturas para cobrar',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: proformasData.length,
                  itemBuilder: (_, i) {
                    final data =
                        proformasData[i].data() as Map<String, dynamic>;

                    // Priorizar valor_declarado sobre total
                    double total;
                    final valorDeclarado =
                        double.tryParse(
                          data['valor_declarado']?.toString() ?? '0',
                        ) ??
                        0.0;
                    if (valorDeclarado > 0) {
                      total = valorDeclarado;
                    } else {
                      total = double.tryParse(data['total'].toString()) ?? 0.0;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[200]!),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Center(
                              child: Text(
                                data['numero'].toString(),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: const Center(
                              child: Text('', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: const Center(
                              child: Text('', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                total.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                total.toStringAsFixed(2),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: const Center(
                              child: Text('', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalesCompactos() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('proformas')
              .where('ci_ruc', isEqualTo: widget.clienteData['ruc'])
              .snapshots(),
      builder: (context, snapshot) {
        double totalSeleccionado = 0.0;

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            if (_proformasSeleccionadas.contains(doc.id)) {
              final data = doc.data() as Map<String, dynamic>;

              // Priorizar valor_declarado sobre total
              double total;
              final valorDeclarado =
                  double.tryParse(data['valor_declarado']?.toString() ?? '0') ??
                  0.0;
              if (valorDeclarado > 0) {
                total = valorDeclarado;
              } else {
                total = double.tryParse(data['total'].toString()) ?? 0.0;
              }

              totalSeleccionado += total;
            }
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTALES USD\$',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                'X Cobrar ${totalSeleccionado.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text('0.00', style: TextStyle(fontSize: 11)),
              const Text('0.00', style: TextStyle(fontSize: 11)),
            ],
          ),
        );
      },
    );
  }

  Future<void> _seleccionarFechaPago() async {
    final DateTime? fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4682B4), // color del calendario
            ),
          ),
          child: child!,
        );
      },
    );

    if (fecha != null) {
      _fechaPagoController.text =
          '${fecha.day.toString().padLeft(2, '0')}/'
          '${fecha.month.toString().padLeft(2, '0')}/'
          '${fecha.year}';
    }
  }

  Widget _buildFormularioCompacto() {
    return Column(
      children: [
        _buildCompactField(
          controller: _fechaPagoController,
          label: 'Fecha del Pago',
          readOnly: true,
          onTap: _seleccionarFechaPago,
        ),

        const SizedBox(height: 8),
        _buildCompactDropdown(
          value: _formaPagoSeleccionada,
          label: 'Forma para el SRI',
          items: [
            'Efectivo',
            'Tarjeta débito',
            'Dinero electrónico',
            'Tarjeta prepago',
            'Tarjeta de crédito',
            'Rol de pagos',
            'Otros',
          ],
          onChanged: (val) => setState(() => _formaPagoSeleccionada = val!),
        ),
        const SizedBox(height: 8),
        _buildCompactField(
          controller: _numeroDocumentoController,
          label: 'No. Documento',
        ),
        const SizedBox(height: 8),
        _buildCompactDropdown(
          value: _comoCobraSeleccionado,
          label: 'Como Cobra',
          items: ['Banco', 'Caja'],
          onChanged: (val) => setState(() => _comoCobraSeleccionado = val!),
        ),
        const SizedBox(height: 8),
        _buildCompactField(
          controller: TextEditingController(),
          label: 'Institución F',
        ),
        const SizedBox(height: 8),
        _buildCompactField(
          controller: _detallePagoController,
          label: 'Detalle su Pago',
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildCompactField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    int maxLines = 1,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      onTap: onTap,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        suffixIcon:
            readOnly ? const Icon(Icons.calendar_today, size: 16) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String value,
    required String label,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 11),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 12, color: Colors.black),
      items:
          items
              .map((val) => DropdownMenuItem(value: val, child: Text(val)))
              .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBotones() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    _proformasSeleccionadas.isEmpty ? null : _cobrarProformas,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text('Cobrar', style: TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Cerrar', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= COBRAR PROFORMAS =================
  Future<void> _cobrarProformas() async {
    if (_proformasSeleccionadas.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF2C3E50)),
                SizedBox(height: 16),
                Text('Procesando cobro...'),
              ],
            ),
          ),
    );

    try {
      // Actualizar cada proforma seleccionada
      for (String proformaId in _proformasSeleccionadas) {
        await FirebaseFirestore.instance
            .collection('proformas')
            .doc(proformaId)
            .update({
              'estado': 'Cobrado',
              'fecha_cobro': Timestamp.now(),
              'forma_pago': _formaPagoController.text,
              'numero_documento': _numeroDocumentoController.text,
              'detalle_pago': _detallePagoController.text,
            });
      }

      Navigator.pop(context); // Cerrar diálogo

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Proformas cobradas correctamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpiar selección
      setState(() {
        _proformasSeleccionadas.clear();
        _numeroDocumentoController.clear();
        _detallePagoController.clear();
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al cobrar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ================= EDITAR FACTURA EXISTENTE =================
Future<void> _mostrarDialogoEditarFactura(
  BuildContext context,
  String proformaId,
  Map<String, dynamic> data,
) async {
  final TextEditingController numeroFacturaController = TextEditingController(
    text: data['numero_factura'] ?? '',
  );
  final TextEditingController valorDeclaradoController = TextEditingController(
    text: data['valor_declarado'] ?? '0',
  );

  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: Color(0xFF2C3E50)),
            SizedBox(width: 8),
            Text(
              'Editar Factura ${data['factura']}',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numeroFacturaController,
                decoration: InputDecoration(
                  labelText: 'Número de Factura',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.receipt),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: valorDeclaradoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Valor Declarado',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: 'Dejar en 0 para usar total calculado',
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Si valor declarado es 0, se usará el total calculado: \$${data['valor']}',
                        style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              numeroFacturaController.dispose();
              valorDeclaradoController.dispose();
              Navigator.pop(context);
            },
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('proformas')
                    .doc(proformaId)
                    .update({
                      'numero_factura': numeroFacturaController.text.trim(),
                      'valor_declarado':
                          valorDeclaradoController.text.trim().isEmpty
                              ? '0'
                              : valorDeclaradoController.text.trim(),
                    });

                numeroFacturaController.dispose();
                valorDeclaradoController.dispose();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Factura actualizada correctamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Error al actualizar: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2C3E50)),
            child: Text('Guardar'),
          ),
        ],
      );
    },
  );
}

// ================= CELDAS =================
class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell({required this.text, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final Color? color;

  const _Cell({
    required this.text,
    required this.flex,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}
