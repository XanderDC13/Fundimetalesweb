import 'package:basefundi/services/pdfs/copiaordenpdf_desk.dart';
import 'package:basefundi/services/pdfs/copiaproformapdf_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ReporteDocumentosDeskScreen extends StatefulWidget {
  const ReporteDocumentosDeskScreen({super.key});

  @override
  State<ReporteDocumentosDeskScreen> createState() =>
      _ReporteDocumentosDeskScreenState();
}

class _ReporteDocumentosDeskScreenState
    extends State<ReporteDocumentosDeskScreen> {
  List<Map<String, dynamic>> _documentos = [];
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _filtroCliente = '';
  String _filtroCedula = '';
  bool _cargando = false;
  int _tabActual = 0;
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _cedulaController = TextEditingController();
  final TextEditingController _motivoAnulacionController =
      TextEditingController();
  String _filtroVendedor = '';
  List<Map<String, dynamic>> _vendedores = [];
  // Calcular total en dinero
  double get totalDinero => _documentosFiltrados.fold(0.0, (sum, doc) {
    final proforma = doc['proforma'] as Map<String, dynamic>?;
    final total = double.tryParse(proforma?['total']?.toString() ?? '0') ?? 0.0;
    return sum + total;
  });
  @override
  void initState() {
    super.initState();
    _cargarVendedores();
    _obtenerDatos();
  }

  @override
  void dispose() {
    _clienteController.dispose();
    _cedulaController.dispose();
    _motivoAnulacionController.dispose();
    super.dispose();
  }

  Future<void> _cargarVendedores() async {
    final cedulasUsuarios = [
      '0401729769',
      '1729711513',
      '0402027924',
      '0402110092',
    ];

    List<Map<String, dynamic>> lista = [];

    for (String cedula in cedulasUsuarios) {
      final snap =
          await FirebaseFirestore.instance
              .collection('usuarios')
              .where('cedula', isEqualTo: cedula)
              .limit(1)
              .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        lista.add({'nombre': data['nombre'] ?? cedula, 'ci_ruc': cedula});
      } else {
        lista.add({'nombre': cedula, 'ci_ruc': cedula});
      }
    }

    final snapCliente =
        await FirebaseFirestore.instance
            .collection('clientes')
            .where('ruc', isEqualTo: '0000000002')
            .limit(1)
            .get();

    if (snapCliente.docs.isNotEmpty) {
      final data = snapCliente.docs.first.data();
      lista.add({
        'nombre': data['nombre'] ?? 'Mostrador',
        'ci_ruc': '0000000002',
      });
    } else {
      lista.add({'nombre': 'Mostrador', 'ci_ruc': '0000000002'});
    }

    setState(() {
      _vendedores = lista;
    });
  }

  Future<void> _obtenerDatos() async {
    setState(() {
      _cargando = true;
    });

    try {
      // Obtener proformas
      Query queryProformas = FirebaseFirestore.instance
          .collection('proformas')
          .orderBy('fecha', descending: true);

      if (_fechaInicio != null) {
        queryProformas = queryProformas.where(
          'fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
        );
      }
      if (_fechaFin != null) {
        queryProformas = queryProformas.where(
          'fecha',
          isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
        );
      }

      final snapshotProformas = await queryProformas.get();

      // Obtener órdenes de despacho
      Query queryOrdenes = FirebaseFirestore.instance
          .collection('ordenes_despacho')
          .orderBy('fecha', descending: true);

      if (_fechaInicio != null) {
        queryOrdenes = queryOrdenes.where(
          'fecha',
          isGreaterThanOrEqualTo: Timestamp.fromDate(_fechaInicio!),
        );
      }
      if (_fechaFin != null) {
        queryOrdenes = queryOrdenes.where(
          'fecha',
          isLessThanOrEqualTo: Timestamp.fromDate(_fechaFin!),
        );
      }

      final snapshotOrdenes = await queryOrdenes.get();

      // Crear mapa para organizar documentos por cédula + número
      Map<String, Map<String, dynamic>> documentosPorClave = {};

      // Procesar proformas
      for (var doc in snapshotProformas.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final numeroProforma = data['numero']?.toString() ?? '';
        final numeroOrden = data['numero_orden']?.toString() ?? '';
        final cliente = data['cliente']?.toString() ?? '';
        final ciRuc = data['ci_ruc']?.toString() ?? '';

        // Crear clave única: cedula + numero_proforma
        final clave = '$ciRuc-P$numeroProforma';

        documentosPorClave[clave] = {
          'numero_proforma': numeroProforma,
          'numero_orden': numeroOrden,
          'cliente': cliente,
          'ci_ruc': ciRuc,
          'proforma': data,
          'orden': null,
          'fechaProforma': (data['fecha'] as Timestamp?)?.toDate(),
          'fechaOrden': null,
        };
      }

      // Procesar órdenes de despacho
      for (var doc in snapshotOrdenes.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final numeroOrden = data['numero']?.toString() ?? '';
        final numeroProforma = data['numero_proforma']?.toString() ?? '';
        final cliente = data['cliente']?.toString() ?? '';
        final ciRuc = data['ci_ruc']?.toString() ?? '';

        // Buscar si existe una proforma con el mismo cliente y número de proforma
        String? claveExistente;
        if (numeroProforma.isNotEmpty) {
          claveExistente = '$ciRuc-P$numeroProforma';
        }

        if (claveExistente != null &&
            documentosPorClave.containsKey(claveExistente)) {
          // Ya existe la proforma, agregar la orden
          documentosPorClave[claveExistente]!['orden'] = data;
          documentosPorClave[claveExistente]!['numero_orden'] = numeroOrden;
          documentosPorClave[claveExistente]!['fechaOrden'] =
              (data['fecha'] as Timestamp?)?.toDate();
        } else {
          // No existe proforma asociada, crear nueva entrada solo con orden
          final clave = '$ciRuc-O$numeroOrden';
          documentosPorClave[clave] = {
            'numero_proforma': numeroProforma,
            'numero_orden': numeroOrden,
            'cliente': cliente,
            'ci_ruc': ciRuc,
            'proforma': null,
            'orden': data,
            'fechaProforma': null,
            'fechaOrden': (data['fecha'] as Timestamp?)?.toDate(),
          };
        }
      }

      // Convertir a lista y aplicar filtros adicionales
      List<Map<String, dynamic>> documentos =
          documentosPorClave.values.toList();

      // Filtrar por cliente
      if (_filtroCliente.isNotEmpty) {
        documentos =
            documentos.where((doc) {
              final cliente = doc['cliente']?.toString().toLowerCase() ?? '';
              return cliente.contains(_filtroCliente.toLowerCase());
            }).toList();
      }

      // Filtrar por cédula
      if (_filtroCedula.isNotEmpty) {
        documentos =
            documentos.where((doc) {
              final ciRuc = doc['ci_ruc']?.toString() ?? '';
              return ciRuc.contains(_filtroCedula);
            }).toList();
      }
      // Filtrar por vendedor
      if (_filtroVendedor.isNotEmpty) {
        documentos =
            documentos.where((doc) {
              final proforma = doc['proforma'] as Map<String, dynamic>?;
              final vendedor = proforma?['vendedor_nombre']?.toString() ?? '';
              return vendedor == _filtroVendedor;
            }).toList();
      }
      // Ordenar por fecha más reciente (proforma o orden)
      documentos.sort((a, b) {
        final fechaA = a['fechaProforma'] ?? a['fechaOrden'];
        final fechaB = b['fechaProforma'] ?? b['fechaOrden'];
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        return fechaB.compareTo(fechaA);
      });

      setState(() {
        _documentos = documentos;
        _cargando = false;
      });
    } catch (e) {
      print('Error al obtener documentos: $e');
      setState(() {
        _cargando = false;
      });
    }
  }

  List<Map<String, dynamic>> get _documentosFiltrados {
    if (_tabActual == 0) {
      // Tab de Activos - mostrar solo NO anulados
      return _documentos.where((doc) {
        final proformaData = doc['proforma'] as Map<String, dynamic>?;
        final ordenData = doc['orden'] as Map<String, dynamic>?;

        // Si no existe el campo 'anulado' o es false, se considera activo
        final proformaAnulada =
            proformaData?.containsKey('anulado') == true
                ? (proformaData!['anulado'] == true)
                : false;

        final ordenAnulada =
            ordenData?.containsKey('anulado') == true
                ? (ordenData!['anulado'] == true)
                : false;

        final isAnulado = proformaAnulada || ordenAnulada;
        return !isAnulado;
      }).toList();
    } else {
      // Tab de Anulados - mostrar solo anulados
      return _documentos.where((doc) {
        final proformaData = doc['proforma'] as Map<String, dynamic>?;
        final ordenData = doc['orden'] as Map<String, dynamic>?;

        final proformaAnulada =
            proformaData?.containsKey('anulado') == true
                ? (proformaData!['anulado'] == true)
                : false;

        final ordenAnulada =
            ordenData?.containsKey('anulado') == true
                ? (ordenData!['anulado'] == true)
                : false;

        final isAnulado = proformaAnulada || ordenAnulada;
        return isAnulado;
      }).toList();
    }
  }

  Widget _buildFiltroVendedor() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Row(
            children: [
              Icon(Icons.person_pin, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Filtrar por vendedor',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          value: _filtroVendedor.isEmpty ? null : _filtroVendedor,
          items: [
            // Opción para mostrar todos
            const DropdownMenuItem<String>(
              value: '',
              child: Row(
                children: [
                  Icon(Icons.people, color: Color(0xFF4682B4), size: 20),
                  SizedBox(width: 8),
                  Text('Todos los vendedores'),
                ],
              ),
            ),
            ..._vendedores.map((v) {
              return DropdownMenuItem<String>(
                value: v['nombre'],
                child: Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF4682B4),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(v['nombre'], style: const TextStyle(fontSize: 14)),
                  ],
                ),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _filtroVendedor = value ?? '';
            });
            _obtenerDatos();
          },
        ),
      ),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _fechaInicio = null;
      _fechaFin = null;
      _filtroCliente = '';
      _filtroCedula = '';
      _filtroVendedor = '';
      _clienteController.clear();
      _cedulaController.clear();
    });
    _obtenerDatos();
  }

  void _aplicarFiltroCliente() {
    setState(() {
      _filtroCliente = _clienteController.text;
    });
    _obtenerDatos();
  }

  void _aplicarFiltroCedula() {
    setState(() {
      _filtroCedula = _cedulaController.text;
    });
    _obtenerDatos();
  }

  String _construirTextoNumeros(Map<String, dynamic> documento) {
    final List<String> partes = [];

    // Solo mostrar ORDEN si realmente tiene documento de orden
    if (documento['orden'] != null) {
      final numeroOrden = documento['numero_orden']?.toString();
      if (numeroOrden != null && numeroOrden.isNotEmpty) {
        partes.add('ORDEN: $numeroOrden');
      }
    }

    // ⭐ CAMBIO: solo mostrar PROFORMA si realmente existe el documento de proforma
    if (documento['proforma'] != null) {
      final numeroProforma = documento['numero_proforma']?.toString();
      if (numeroProforma != null && numeroProforma.isNotEmpty) {
        partes.add('PROFORMA: $numeroProforma');
      }
    }

    return partes.isEmpty ? '—' : partes.join(' | ');
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

  Future<void> _anularDocumento(Map<String, dynamic> documento) async {
    _motivoAnulacionController.clear();

    final confirmar = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Anular Documento'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('¿Está seguro que desea anular este documento?'),
                const SizedBox(height: 16),
                TextField(
                  controller: _motivoAnulacionController,
                  decoration: const InputDecoration(
                    labelText: 'Motivo de anulación (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Anular'),
              ),
            ],
          ),
    );

    if (confirmar == true) {
      try {
        final motivo = _motivoAnulacionController.text.trim();
        final ahora = Timestamp.now();

        // Anular proforma si existe
        if (documento['proforma'] != null) {
          // Convertir numero a int para la búsqueda
          final numeroProforma = documento['numero_proforma']?.toString() ?? '';
          final numeroInt = int.tryParse(numeroProforma);

          print(
            '🔍 Buscando proforma: numero=$numeroInt, ci_ruc=${documento['ci_ruc']}',
          );

          if (numeroInt != null) {
            final snapshotProforma =
                await FirebaseFirestore.instance
                    .collection('proformas')
                    .where(
                      'numero',
                      isEqualTo: numeroInt,
                    ) // Usar int, no string
                    .where('ci_ruc', isEqualTo: documento['ci_ruc'])
                    .get();

            print('📄 Proformas encontradas: ${snapshotProforma.docs.length}');

            for (var doc in snapshotProforma.docs) {
              await doc.reference.update({
                'anulado': true,
                'motivo_anulacion': motivo.isEmpty ? null : motivo,
                'fecha_anulacion': ahora,
              });
              print('✅ Proforma anulada: ${doc.id}');
            }
          }
        }

        // Anular orden si existe
        if (documento['orden'] != null) {
          // Convertir numero a int para la búsqueda
          final numeroOrden = documento['numero_orden']?.toString() ?? '';
          final numeroInt = int.tryParse(numeroOrden);

          print(
            '🔍 Buscando orden: numero=$numeroInt, ci_ruc=${documento['ci_ruc']}',
          );

          if (numeroInt != null) {
            final snapshotOrden =
                await FirebaseFirestore.instance
                    .collection('ordenes_despacho')
                    .where(
                      'numero',
                      isEqualTo: numeroInt,
                    ) // Usar int, no string
                    .where('ci_ruc', isEqualTo: documento['ci_ruc'])
                    .get();

            print('📦 Órdenes encontradas: ${snapshotOrden.docs.length}');

            for (var doc in snapshotOrden.docs) {
              await doc.reference.update({
                'anulado': true,
                'motivo_anulacion': motivo.isEmpty ? null : motivo,
                'fecha_anulacion': ahora,
              });
              print('✅ Orden anulada: ${doc.id}');
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Documento anulado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Recargar datos
        await _obtenerDatos();
      } catch (e) {
        print('❌ Error al anular: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al anular: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                      'Reporte de Documentos',
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
                            Icons.description,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Total Documentos',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_documentosFiltrados.length}',
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
                            'Total en Ventas',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '\$${totalDinero.toStringAsFixed(2)}',
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

          // CONTENIDO principal
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

                      // Segunda fila de filtros - Cliente y Cédula
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
                                  border: InputBorder.none, // 👈 sin bordes
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
                                controller: _cedulaController,
                                decoration: InputDecoration(
                                  labelText: 'Buscar por cédula',
                                  prefixIcon: const Icon(Icons.credit_card),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.search),
                                    onPressed: _aplicarFiltroCedula,
                                  ),
                                  border: InputBorder.none, // 👈 sin bordes
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                onSubmitted: (value) => _aplicarFiltroCedula(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Tercera fila: filtro por vendedor
                      _buildFiltroVendedor(),
                    ],
                  ),

                  const SizedBox(height: 16),
                  // TABS
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _tabActual = 0;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    _tabActual == 0
                                        ? const Color(0xFF4682B4)
                                        : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color:
                                        _tabActual == 0
                                            ? Colors.white
                                            : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Documentos Activos',
                                    style: TextStyle(
                                      color:
                                          _tabActual == 0
                                              ? Colors.white
                                              : Colors.grey,
                                      fontWeight:
                                          _tabActual == 0
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.shade300,
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _tabActual = 1;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    _tabActual == 1
                                        ? const Color(0xFF4682B4)
                                        : Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel,
                                    color:
                                        _tabActual == 1
                                            ? Colors.white
                                            : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Documentos Anulados',
                                    style: TextStyle(
                                      color:
                                          _tabActual == 1
                                              ? Colors.white
                                              : Colors.grey,
                                      fontWeight:
                                          _tabActual == 1
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                      fontSize: 14,
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

                  const SizedBox(height: 16),
                  // TABLA DE DOCUMENTOS
                  _cargando
                      ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : _documentosFiltrados.isEmpty
                      ? const Expanded(
                        child: Center(
                          child: Text(
                            'No hay documentos para mostrar.',
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
                                0: FlexColumnWidth(1.5), // N°
                                1: FlexColumnWidth(3.0), // Cliente
                                2: FlexColumnWidth(2.0), // Proforma
                                3: FlexColumnWidth(2.0), // Orden
                                4: FlexColumnWidth(1.5), // Anular
                              },
                              children: [
                                // ENCABEZADO
                                const TableRow(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF4682B4),
                                  ),
                                  children: [
                                    _TablaHeaderMain('N°'),
                                    _TablaHeaderMain('Cliente'),
                                    _TablaHeaderMain('Proforma'),
                                    _TablaHeaderMain('Orden'),
                                    _TablaHeaderMain('Anular'),
                                  ],
                                ),
                                // FILAS DE DATOS
                                ..._documentosFiltrados.asMap().entries.map((
                                  entry,
                                ) {
                                  final index = entry.key;
                                  final documento = entry.value;
                                  final isEven = index % 2 == 0;

                                  // Verificar si está anulado
                                  final proformaData =
                                      documento['proforma']
                                          as Map<String, dynamic>?;
                                  final ordenData =
                                      documento['orden']
                                          as Map<String, dynamic>?;

                                  final proformaAnulada =
                                      proformaData?.containsKey('anulado') ==
                                              true
                                          ? (proformaData!['anulado'] == true)
                                          : false;

                                  final ordenAnulada =
                                      ordenData?.containsKey('anulado') == true
                                          ? (ordenData!['anulado'] == true)
                                          : false;

                                  final isAnulado =
                                      proformaAnulada || ordenAnulada;

                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color:
                                          isAnulado
                                              ? Colors
                                                  .red
                                                  .shade100 // MODIFICAR: color rojo si está anulado
                                              : (isEven
                                                  ? Colors.grey.shade50
                                                  : Colors.white),
                                    ),
                                    children: [
                                      _TablaCellMain(
                                        _construirTextoNumeros(documento),
                                        false,
                                      ),
                                      _TablaCellMain(
                                        documento['cliente']?.toString() ?? '—',
                                        false,
                                      ),
                                      // Columna Proforma
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Center(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                (documento['proforma'] !=
                                                            null &&
                                                        !isAnulado) // MODIFICAR
                                                    ? () => generarProformaPDF(
                                                      documento['numero_proforma']
                                                              ?.toString() ??
                                                          '',
                                                      documento['ci_ruc']
                                                          ?.toString(),
                                                    )
                                                    : null,
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'PDF',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  (documento['proforma'] !=
                                                              null &&
                                                          !isAnulado) // MODIFICAR
                                                      ? const Color(0xFF4682B4)
                                                      : Colors.grey,
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
                                        ),
                                      ),
                                      // Columna Orden
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Center(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                (documento['orden'] != null &&
                                                        !isAnulado) // MODIFICAR
                                                    ? () => generarOrdenPDF(
                                                      documento['numero_orden']
                                                              ?.toString() ??
                                                          '',
                                                      documento['ci_ruc']
                                                          ?.toString(),
                                                    )
                                                    : null,
                                            icon: const Icon(
                                              Icons.picture_as_pdf,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'PDF',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  (documento['orden'] != null &&
                                                          !isAnulado) // MODIFICAR
                                                      ? const Color(0xFF4682B4)
                                                      : Colors.grey,
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
                                        ),
                                      ),
                                      // AGREGAR ESTA COLUMNA COMPLETA:
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Center(
                                          child: ElevatedButton.icon(
                                            onPressed:
                                                !isAnulado
                                                    ? () => _anularDocumento(
                                                      documento,
                                                    )
                                                    : null,
                                            icon: const Icon(
                                              Icons.cancel,
                                              size: 16,
                                            ),
                                            label: Text(
                                              isAnulado ? 'ANULADO' : 'Anular',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  isAnulado
                                                      ? Colors.grey
                                                      : Colors.red,
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
