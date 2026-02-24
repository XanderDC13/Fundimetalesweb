import 'package:basefundi/desktop/reportes/editar_proformascot.dart';
import 'package:basefundi/services/pdfs/copiaproformaventaspdf.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReporteProformasVentasDeskScreen extends StatefulWidget {
  const ReporteProformasVentasDeskScreen({super.key});

  @override
  State<ReporteProformasVentasDeskScreen> createState() =>
      _ReporteProformasVentasDeskScreenState();
}

class _ReporteProformasVentasDeskScreenState
    extends State<ReporteProformasVentasDeskScreen> {
  List<Map<String, dynamic>> _proformas = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _filtroCliente = '';
  String _filtroRuc = '';
  bool _cargando = false;
  double _montoTotal = 0.0;

  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _rucController = TextEditingController();
  String _rolUsuario = '';
  String _uidUsuario = '';

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario().then((_) => _obtenerDatos());
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _rucController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        setState(() {
          _rolUsuario = data['rol'] ?? ''; // ← CAMBIA 'rol' por tu campo
          _uidUsuario = user.uid;
        });
      }
    } catch (e) {
      print('Error cargando usuario: $e');
      setState(() {});
    }
  }

  Future<void> _obtenerDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      final esVendedor = _rolUsuario == 'Vendedor';

      Query query = FirebaseFirestore.instance
          .collection('proformasventas')
          .orderBy('fecha', descending: true);

      // Filtros de fecha solo si están definidos
      if (_fechaInicio != null) {
        query = query.where(
          'fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
        );
      }
      if (_fechaFin != null) {
        query = query.where(
          'fecha',
          isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
        );
      }

      final snapshot = await query.get();

      List<Map<String, dynamic>> proformas = [];
      double montoTotal = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Si es vendedor, filtrar en memoria por usuario_uid
        if (esVendedor) {
          final uidDoc = data['usuario_uid']?.toString() ?? '';
          if (uidDoc.isEmpty || uidDoc != _uidUsuario) continue;
        }

        // Filtros de cliente y RUC
        bool cumpleFiltroCliente =
            _filtroCliente.isEmpty ||
            (data['cliente']?.toString().toLowerCase().contains(
                  _filtroCliente.toLowerCase(),
                ) ??
                false);

        bool cumpleFiltroRuc =
            _filtroRuc.isEmpty ||
            (data['ruc']?.toString().contains(_filtroRuc) ?? false);

        if (cumpleFiltroCliente && cumpleFiltroRuc) {
          data['id'] = doc.id;
          proformas.add(data);

          final totalFinal =
              double.tryParse(data['total_final']?.toString() ?? '0') ?? 0.0;
          montoTotal += totalFinal;
        }
      }

      setState(() {
        _proformas = proformas;
        _montoTotal = montoTotal;
        _cargando = false;
      });
    } catch (e) {
      print('Error al obtener proformas: $e');
      setState(() {
        _cargando = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar proformas: $e')));
    }
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _filtroCliente = '';
      _filtroRuc = '';
      _clienteController.clear();
      _rucController.clear();
    });
    _obtenerDatos();
  }

  void _aplicarFiltroCliente() {
    setState(() {
      _filtroCliente = _clienteController.text;
    });
    _obtenerDatos();
  }

  void _aplicarFiltroRuc() {
    setState(() {
      _filtroRuc = _rucController.text;
    });
    _obtenerDatos();
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
      _obtenerDatos();
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
      _obtenerDatos();
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '—';

    try {
      if (fecha is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
      } else if (fecha is String) {
        return fecha;
      }
      return fecha.toString();
    } catch (e) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // CABECERA
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Reporte Proformas Ventas',
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

          // INDICADORES RESUMEN
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF4682B4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Total Proformas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_proformas.length}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: const Color(0xFF4682B4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.attach_money,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Monto Total',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_montoTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: const Color(0xFF4682B4),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Promedio',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${_proformas.isNotEmpty ? (_montoTotal / _proformas.length).toStringAsFixed(2) : '0.00'}',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

          // CONTENIDO PRINCIPAL
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // FILTROS
                  Column(
                    children: [
                      // Primera fila de filtros - Fechas
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _seleccionarFechaInicio,
                              icon: const Icon(
                                Icons.date_range,
                                color: Colors.white,
                              ),
                              label: Text(
                                _fechaInicio == null
                                    ? 'Desde'
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaInicio!),
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4682B4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _seleccionarFechaFin,
                              icon: const Icon(
                                Icons.date_range,
                                color: Colors.white,
                              ),
                              label: Text(
                                _fechaFin == null
                                    ? 'Hasta'
                                    : DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(_fechaFin!),
                                style: const TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4682B4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          IconButton(
                            onPressed: _limpiarFiltros,
                            icon: const Icon(
                              Icons.clear,
                              color: Color(0xFF4682B4),
                            ),
                            tooltip: 'Limpiar filtros',
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Segunda fila de filtros - Cliente y RUC
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _clienteController,
                                decoration: InputDecoration(
                                  labelText: 'Filtrar por cliente',
                                  prefixIcon: const Icon(Icons.person),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _aplicarFiltroCliente,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (value) => _aplicarFiltroCliente(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _rucController,
                                decoration: InputDecoration(
                                  labelText: 'Buscar por RUC',
                                  prefixIcon: const Icon(Icons.business),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _aplicarFiltroRuc,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (value) => _aplicarFiltroRuc(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // TABLA DE PROFORMAS
                  _cargando
                      ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : _proformas.isEmpty
                      ? const Expanded(
                        child: Center(
                          child: Text(
                            'No hay proformas para mostrar.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                      )
                      : Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Table(
                              border: TableBorder(
                                horizontalInside: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                top: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                              defaultVerticalAlignment:
                                  TableCellVerticalAlignment.middle,
                              columnWidths: const {
                                0: FlexColumnWidth(2.5), // Número
                                1: FlexColumnWidth(3.0), // Cliente
                                2: FlexColumnWidth(2.0), // RUC
                                3: FlexColumnWidth(2.5), // Fecha
                                4: FlexColumnWidth(1.5), // Total
                                5: FlexColumnWidth(1.8), // PDF
                              },
                              children: [
                                // ENCABEZADO
                                const TableRow(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4682B4),
                                  ),
                                  children: [
                                    _TablaHeaderMain('Número'),
                                    _TablaHeaderMain('Cliente'),
                                    _TablaHeaderMain('RUC'),
                                    _TablaHeaderMain('Fecha'),
                                    _TablaHeaderMain('Total'),
                                    _TablaHeaderMain('Acciones'),
                                  ],
                                ),
                                // FILAS DE DATOS
                                ..._proformas.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final proforma = entry.value;
                                  final isEven = index % 2 == 0;

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color:
                                          isEven
                                              ? Colors.grey.shade50
                                              : Colors.white,
                                    ),
                                    children: [
                                      _TablaCellMain(
                                        proforma['numero']?.toString() ?? '—',
                                        false,
                                      ),
                                      _TablaCellMain(
                                        proforma['cliente']?.toString() ?? '—',
                                        false,
                                      ),
                                      _TablaCellMain(
                                        proforma['ruc']?.toString() ?? '—',
                                        false,
                                      ),
                                      _TablaCellMain(
                                        _formatearFecha(proforma['fecha']),
                                        false,
                                      ),
                                      _TablaCellMain(
                                        '\$${proforma['total_final'] ?? '0.00'}',
                                        true,
                                      ),
                                      // Columna PDF
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                await generarProformaVentasPDF(
                                                  proforma,
                                                );
                                              },
                                              icon: const Icon(
                                                Icons.picture_as_pdf,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'PDF',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF4682B4,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: const Size(0, 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                await EditarProformaVentas.mostrar(
                                                  context,
                                                  proforma,
                                                  proforma['id'],
                                                  esMobil: false,
                                                );
                                                _obtenerDatos();
                                              },
                                              icon: const Icon(
                                                Icons.edit,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Editar',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.orange[700],
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                minimumSize: const Size(0, 32),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TablaHeaderMain extends StatelessWidget {
  final String text;
  const _TablaHeaderMain(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _TablaCellMain extends StatelessWidget {
  final String? text;
  final bool isMoneda;

  const _TablaCellMain(this.text, this.isMoneda);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text ?? '—',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isMoneda ? FontWeight.bold : FontWeight.normal,
          color: isMoneda ? Colors.green.shade700 : const Color(0xFF2C3E50),
        ),
        textAlign: isMoneda ? TextAlign.center : TextAlign.left,
      ),
    );
  }
}
