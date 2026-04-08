import 'dart:async';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/pdfs/compartirordenpdf_desk.dart';
import 'package:basefundi/services/pdfs/compartirproformapdf_desk.dart';
import 'package:basefundi/services/pdfs/ordendespacho_pdfgenerator_desk.dart';
import 'package:basefundi/services/pdfs/proforma_pdfgenerator_desk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProformaOrdenDespachoDeskScreen extends StatefulWidget {
  const ProformaOrdenDespachoDeskScreen({super.key});

  @override
  _ProformaOrdenDespachoDeskScreenState createState() =>
      _ProformaOrdenDespachoDeskScreenState();
}

class _ProformaOrdenDespachoDeskScreenState
    extends State<ProformaOrdenDespachoDeskScreen> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _ciRucController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _formRefController = TextEditingController();
  final TextEditingController _formDescripcionController =
      TextEditingController();
  final TextEditingController _formCantidadController = TextEditingController();
  final TextEditingController _formPrecioController = TextEditingController();
  final TextEditingController _formTotalController = TextEditingController();
  List<Map<String, dynamic>> _clientesSugeridos = [];
  bool _mostrarSugerencias = false;
  final FocusNode _nombreFocusNode = FocusNode();
  Timer? _debounceNombre;
  String _numeroProforma = '';
  String _numeroOrdenDespacho = '';
  Timer? _debounce;
  Timer? _debounceProducto;
  bool _isSearching = false;
  bool _clienteEncontrado = false;
  String _mensajeBusqueda = '';
  bool _entradaManualHabilitada = false;
  bool _aplicarIVA = false;

  List<ItemOrdenDespacho> items = [];

  bool _efectivo = false;
  bool _dineroElectronico = false;
  bool _tarjetaCredito = false;
  bool _otros = false;

  final TextEditingController _numeroFacturaController =
      TextEditingController();
  final TextEditingController _valorDeclaradoController =
      TextEditingController();
  String sucursalUsuario = '';
  Map<String, int> stockDisponibleBodega = {};

  String? _vendedorSeleccionado;
  List<Map<String, dynamic>> _vendedores = [];
  String? _despachoSeleccionado;

  Future<void> _cargarVendedores() async {
    final cedulasUsuarios = [
      '0401729769',
      '1729711513',
      '0402027924',
      '0402110092',
      '1346798520',
      '2135468790',
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

  Future<void> _cargarSucursalUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          setState(() {
            sucursalUsuario = data['sede'] ?? 'Quito';
          });
        } else {
          setState(() {
            sucursalUsuario = 'Quito';
          });
        }
      }
    } catch (e) {
      print('Error cargando sucursal del usuario: $e');
      setState(() {
        sucursalUsuario = 'Quito';
      });
    }
  }

  void _calcularTotalFormulario() {
    setState(() {
      double cantidad = double.tryParse(_formCantidadController.text) ?? 0;
      double precio = double.tryParse(_formPrecioController.text) ?? 0;
      double subtotal = cantidad * precio;
      _formTotalController.text = subtotal.toStringAsFixed(2);
    });
  }

  void _agregarItemFromForm() {
    if (_formDescripcionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debe ingresar una descripción'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ItemOrdenDespacho nuevoItem = ItemOrdenDespacho();
    nuevoItem.refController.text = _formRefController.text;
    nuevoItem.descripcionController.text = _formDescripcionController.text;
    nuevoItem.cantidadController.text = _formCantidadController.text;
    nuevoItem.vUnitController.text = _formPrecioController.text;
    nuevoItem.vTotalController.text = _formTotalController.text;

    setState(() {
      items.add(nuevoItem);
      _formRefController.clear();
      _formDescripcionController.clear();
      _formCantidadController.clear();
      _formPrecioController.clear();
      _formTotalController.clear();
    });
  }

  void _habilitarEntradaManual() {
    setState(() {
      _entradaManualHabilitada = true;
      _mensajeBusqueda =
          'Modo entrada manual activado. Complete los campos requeridos.';

      if (_telefonoController.text.isEmpty) {
        _telefonoController.text = '09XXXXXXXX';
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = 'sincorreo@fmn.com';
      }
    });
  }

  void _limpiarFormulario() {
    setState(() {
      _ciRucController.clear();
      _clienteController.clear();
      _telefonoController.clear();
      _direccionController.clear();
      _emailController.clear();
      _ciudadController.clear();
      _entradaManualHabilitada = true;
      _clienteEncontrado = false;
      _mensajeBusqueda = '';
    });
  }

  Future<void> _guardarClienteManual() async {
    if (!_validarDatosCliente()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: const Color(0xFF4682B4)),
              SizedBox(height: 16),
              Text('Guardando cliente...'),
            ],
          ),
        );
      },
    );

    try {
      final clienteData = {
        'ruc': _ciRucController.text.trim(),
        'nombre': _clienteController.text.toUpperCase(),
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text.toUpperCase(),
        'correo': _emailController.text.toLowerCase(),
        'ciudad': _ciudadController.text.toUpperCase(),
        'fecha_creacion': Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('clientes').add(clienteData);

      Navigator.pop(context);

      setState(() {
        _clienteEncontrado = true;
        _mensajeBusqueda = 'Cliente guardado y encontrado correctamente.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cliente guardado correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar cliente: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  bool _validarDatosCliente() {
    if (_clienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El nombre del cliente es obligatorio'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_ciRucController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La cédula/RUC es obligatoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (!_telefonoController.text.startsWith('09') ||
        _telefonoController.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El teléfono debe tener formato 09XXXXXXXX'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  void _buscarClientesPorNombreConDebounce(String query) {
    if (_debounceNombre?.isActive ?? false) _debounceNombre!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _clientesSugeridos = [];
        _mostrarSugerencias = false;
      });
      return;
    }

    _debounceNombre = Timer(const Duration(milliseconds: 500), () {
      _buscarClientesPorNombre(query);
    });
  }

  Future<void> _buscarClientesPorNombre(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _clientesSugeridos = [];
        _mostrarSugerencias = false;
      });
      return;
    }

    try {
      final querySnapshot =
          await FirebaseFirestore.instance
              .collection('clientes')
              .where('nombre', isGreaterThanOrEqualTo: query.toUpperCase())
              .where(
                'nombre',
                isLessThanOrEqualTo: '${query.toUpperCase()}\uf8ff',
              )
              .limit(5)
              .get();

      setState(() {
        _clientesSugeridos =
            querySnapshot.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    'nombre': doc['nombre'] ?? '',
                    'ruc': doc['ruc'] ?? '',
                    'telefono': doc['telefono'] ?? '',
                    'direccion': doc['direccion'] ?? '',
                    'correo': doc['correo'] ?? '',
                    'ciudad': doc['ciudad'] ?? '',
                  },
                )
                .toList();
        _mostrarSugerencias = _clientesSugeridos.isNotEmpty;
      });
    } catch (e) {
      print('Error al buscar clientes: $e');
      setState(() {
        _clientesSugeridos = [];
        _mostrarSugerencias = false;
      });
    }
  }

  void _seleccionarCliente(Map<String, dynamic> cliente) {
    setState(() {
      _clienteController.text = cliente['nombre'] ?? '';
      _ciRucController.text = cliente['ruc'] ?? '';
      _telefonoController.text = cliente['telefono'] ?? '';
      _direccionController.text = cliente['direccion'] ?? '';
      _emailController.text = cliente['correo'] ?? '';
      _ciudadController.text = cliente['ciudad'] ?? '';
      _clienteEncontrado = true;
      _mensajeBusqueda = 'Cliente encontrado correctamente.';
      _mostrarSugerencias = false;
      _clientesSugeridos = [];
    });
  }

  void _buscarClienteConDebounce(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _clienteEncontrado = false;
        _mensajeBusqueda = '';
        _isSearching = false;
        _clienteController.clear();
        _telefonoController.clear();
        _direccionController.clear();
        _emailController.clear();
        _ciudadController.clear();
        _entradaManualHabilitada = true;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _buscarCliente(query);
    });
  }

  Future<void> _buscarCliente(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _clienteEncontrado = false;
      _mensajeBusqueda = 'Buscando cliente...';
    });

    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('clientes')
              .where('ruc', isEqualTo: query.trim())
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final DocumentSnapshot doc = querySnapshot.docs.first;
        final Map<String, dynamic> cliente = doc.data() as Map<String, dynamic>;

        setState(() {
          _clienteEncontrado = true;
          _isSearching = false;
          _mensajeBusqueda = 'Cliente encontrado correctamente.';
          _entradaManualHabilitada = true;

          _clienteController.text = cliente['nombre'] ?? '';
          _telefonoController.text = cliente['telefono'] ?? '';
          _direccionController.text = cliente['direccion'] ?? '';
          _emailController.text = cliente['correo'] ?? '';
          _ciudadController.text = cliente['ciudad'] ?? '';
        });
      } else {
        setState(() {
          _clienteEncontrado = false;
          _isSearching = false;
          _mensajeBusqueda =
              'Cliente no encontrado. Puede ingresar datos manualmente.';
          _entradaManualHabilitada = true;

          _clienteController.clear();
          _telefonoController.clear();
          _direccionController.clear();
          _emailController.clear();
          _ciudadController.clear();
        });
      }
    } catch (e) {
      print('Error al buscar cliente: $e');
      setState(() {
        _clienteEncontrado = false;
        _isSearching = false;
        _mensajeBusqueda = 'Error al buscar cliente. Verifique la conexión.';
        _entradaManualHabilitada = true;

        _clienteController.clear();
        _telefonoController.clear();
        _direccionController.clear();
        _emailController.clear();
        _ciudadController.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _inicializarPantalla();
    _cargarVendedores();
  }

  Future<void> _inicializarPantalla() async {
    await _cargarSucursalUsuario();
    await _previsualizarNumeroProforma();
    await _previsualizarNumeroOrdenDespacho();
  }

  Widget _buildSelectorVendedor() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Row(
            children: [
              Icon(Icons.person_pin, color: Colors.grey, size: 20),
              SizedBox(width: 8),
              Text(
                'Seleccionar vendedor',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          value: _vendedorSeleccionado,
          items:
              _vendedores.map((v) {
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
              }).toList(),
          onChanged: (value) {
            setState(() {
              _vendedorSeleccionado = value;
            });
          },
        ),
      ),
    );
  }

  Future<void> _previsualizarNumeroOrdenDespacho() async {
    // FIX: leer la sede desde Firestore para asegurar el docId correcto
    final user = FirebaseAuth.instance.currentUser;
    String sedeReal = sucursalUsuario;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          sedeReal = userDoc['sede'] ?? sucursalUsuario;
        }
      } catch (_) {}
    }

    String docId;
    if (sedeReal == 'Quito') {
      docId = 'orden_Quito';
    } else if (sedeReal == 'Guayaquil') {
      docId = 'orden_Guayaquil';
    } else {
      docId = 'orden';
    }

    final ref = FirebaseFirestore.instance
        .collection('orden_proforma_counter')
        .doc(docId);

    final doc = await ref.get();

    int numero;
    if (doc.exists) {
      numero = (doc['contador'] ?? 0) + 1;
    } else {
      await ref.set({'contador': 0});
      numero = 1;
    }

    setState(() {
      if (sedeReal == 'Quito') {
        _numeroOrdenDespacho = 'Q-$numero';
      } else if (sedeReal == 'Guayaquil') {
        _numeroOrdenDespacho = 'G-$numero';
      } else {
        _numeroOrdenDespacho = numero.toString();
      }
    });
  }

  Future<Map<String, String>> _obtenerDatosUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'uid': 'desconocido',
        'nombre': 'Desconocido',
        'sucursal': sucursalUsuario,
      };
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      final nombre =
          userDoc.exists ? (userDoc['nombre'] ?? 'Desconocido') : 'Desconocido';
      final sucursal =
          userDoc.exists
              ? (userDoc['sede'] ?? sucursalUsuario)
              : sucursalUsuario;

      return {'uid': user.uid, 'nombre': nombre, 'sucursal': sucursal};
    } catch (e) {
      return {
        'uid': user.uid,
        'nombre': 'Usuario',
        'sucursal': sucursalUsuario,
      };
    }
  }

  // FIX: recibe la sede real como parámetro para no depender de sucursalUsuario
  Future<void> _descontarInventario(String sedeReal) async {
    if (sedeReal == 'Tulcán' &&
        (_despachoSeleccionado == 'quito' ||
            _despachoSeleccionado == 'guayaquil')) {
      print('ℹ️ Usuario en Tulcán con despacho externo - No se descuenta');
      return;
    }
    try {
      final usuario = await _obtenerDatosUsuario();
      final timestamp = Timestamp.now();

      for (var item in items) {
        final referencia = item.refController.text.trim();
        if (referencia.isEmpty) continue;

        final cantidadSolicitada =
            int.tryParse(item.cantidadController.text) ?? 0;
        if (cantidadSolicitada <= 0) continue;

        final docInventario = FirebaseFirestore.instance
            .collection('inventarios')
            .doc(sedeReal) // FIX: usar sedeReal en lugar de usuario['sucursal']
            .collection('procesos')
            .doc('bodega')
            .collection('productos')
            .doc(referencia);

        final snapshot = await docInventario.get();
        final cantidadActual =
            snapshot.exists ? (snapshot['cantidad'] ?? 0) : 0;

        if (cantidadActual < cantidadSolicitada) {
          final diferencia = cantidadSolicitada - cantidadActual;

          await docInventario.set({
            'cantidad': cantidadSolicitada,
            'ultima_actualizacion': timestamp,
          }, SetOptions(merge: true));

          await FirebaseFirestore.instance
              .collection('kardex_movimientos')
              .add({
                'referencia': referencia,
                'tipo': 'entrada',
                'cantidad': diferencia,
                'fecha': timestamp,
                'usuario_uid': usuario['uid']!,
                'usuario_nombre': usuario['nombre']!,
                'sucursal': sedeReal,
                'motivo': 'Ajuste de inventario - Proforma N° $_numeroProforma',
              });
        }

        final snapshotActualizado = await docInventario.get();
        final cantidadFinal =
            snapshotActualizado.exists
                ? (snapshotActualizado['cantidad'] ?? 0)
                : 0;

        await docInventario.update({
          'cantidad': cantidadFinal - cantidadSolicitada,
          'ultima_actualizacion': timestamp,
        });

        await FirebaseFirestore.instance.collection('kardex_movimientos').add({
          'referencia': referencia,
          'tipo': 'salida',
          'cantidad': cantidadSolicitada,
          'fecha': timestamp,
          'usuario_uid': usuario['uid']!,
          'usuario_nombre': usuario['nombre']!,
          'sucursal': sedeReal,
          'motivo': 'Proforma N° $_numeroProforma',
        });
      }
    } catch (e) {
      print('Error descontando inventario: $e');
      throw e;
    }
  }

  Future<void> _previsualizarNumeroProforma() async {
    String docId;
    int contadorInicial;

    if (sucursalUsuario == 'Quito') {
      docId = 'proforma_Quito';
      contadorInicial = 0;
    } else if (sucursalUsuario == 'Guayaquil') {
      docId = 'proforma_Guayaquil';
      contadorInicial = 0;
    } else {
      docId = 'proforma';
      contadorInicial = 7400;
    }

    final ref = FirebaseFirestore.instance
        .collection('orden_proforma_counter')
        .doc(docId);

    final doc = await ref.get();

    int numero;
    if (doc.exists) {
      numero = (doc['contador'] ?? contadorInicial) + 1;
    } else {
      await ref.set({'contador': contadorInicial});
      numero = contadorInicial + 1;
    }

    setState(() {
      if (sucursalUsuario == 'Quito') {
        _numeroProforma = 'Q-$numero';
      } else if (sucursalUsuario == 'Guayaquil') {
        _numeroProforma = 'G-$numero';
      } else {
        _numeroProforma = numero.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
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
                  Align(
                    alignment: Alignment.center,
                    // FIX: cabecera adaptada según sede
                    child: _buildTituloCabecera(),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: _buildClienteSection(),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          _buildProductosSection(),
                                          const SizedBox(height: 16),
                                          _buildFacturaSection(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: _buildListaProductosSection(),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          _buildTotalesSection(),
                                          const SizedBox(height: 16),
                                          _buildFormaPagoSection(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: _buildActionBar(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FIX: título de cabecera adaptado según sede
  Widget _buildTituloCabecera() {
    if (sucursalUsuario == 'Tulcán') {
      return Text(
        'ORDEN Nº $_numeroOrdenDespacho / PROFORMA Nº $_numeroProforma',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    // Quito y Guayaquil siempre muestran ambos
    return Text(
      'ORDEN Nº $_numeroOrdenDespacho / PROFORMA Nº $_numeroProforma',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildClienteSection() {
    return _buildSection(
      title: 'Información del Cliente',
      icon: Icons.person_outline,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _ciRucController,
              decoration: InputDecoration(
                labelText: 'Buscar por C.I/RUC',
                hintText: 'Ingrese número de cédula o RUC',
                prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                suffixIcon:
                    _isSearching
                        ? Container(
                          width: 20,
                          height: 20,
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[600]!,
                            ),
                          ),
                        )
                        : _clienteEncontrado
                        ? Icon(Icons.check_circle, color: Colors.green[600])
                        : (_ciRucController.text.isNotEmpty &&
                            !_clienteEncontrado)
                        ? IconButton(
                          icon: Icon(Icons.add_circle, color: Colors.blue[600]),
                          onPressed: _habilitarEntradaManual,
                          tooltip: 'Agregar cliente manualmente',
                        )
                        : null,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                _buscarClienteConDebounce(value.trim());
              },
              keyboardType: TextInputType.number,
            ),
          ),

          if (_mensajeBusqueda.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _clienteEncontrado
                        ? Colors.green[50]
                        : _entradaManualHabilitada
                        ? Colors.blue[50]
                        : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _clienteEncontrado
                          ? Colors.green[200]!
                          : _entradaManualHabilitada
                          ? Colors.blue[200]!
                          : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _clienteEncontrado
                        ? Icons.check_circle
                        : _entradaManualHabilitada
                        ? Icons.edit
                        : Icons.info,
                    size: 16,
                    color:
                        _clienteEncontrado
                            ? Colors.green[600]
                            : _entradaManualHabilitada
                            ? Colors.blue[600]
                            : Colors.orange[600],
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _mensajeBusqueda,
                      style: TextStyle(
                        color:
                            _clienteEncontrado
                                ? Colors.green[700]
                                : _entradaManualHabilitada
                                ? Colors.blue[700]
                                : Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_entradaManualHabilitada)
                    TextButton(
                      onPressed: _limpiarFormulario,
                      child: Text(
                        'Limpiar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red[600],
                        ),
                      ),
                    ),
                ],
              ),
            ),

          SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _clienteController,
                  focusNode: _nombreFocusNode,
                  decoration: InputDecoration(
                    labelText: 'Nombre del Cliente',
                    hintText: 'Escriba el nombre del cliente',
                    prefixIcon: Icon(Icons.person, color: Colors.grey[600]),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    labelStyle: TextStyle(color: Colors.grey[700]),
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  ),
                  onChanged: (value) {
                    _buscarClientesPorNombreConDebounce(value);
                  },
                ),
              ),

              if (_mostrarSugerencias && _clientesSugeridos.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(top: 4),
                  constraints: BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _clientesSugeridos.length,
                    itemBuilder: (context, index) {
                      final cliente = _clientesSugeridos[index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          Icons.person,
                          color: Color(0xFF4682B4),
                          size: 20,
                        ),
                        title: Text(
                          cliente['nombre'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'CI/RUC: ${cliente['ruc'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () => _seleccionarCliente(cliente),
                      );
                    },
                  ),
                ),
            ],
          ),

          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  readOnly: _clienteEncontrado,
                  enabled: _clienteEncontrado || _entradaManualHabilitada,
                  hintText:
                      _entradaManualHabilitada ? 'Ingrese teléfono' : null,
                  keyboardType: TextInputType.phone,
                  onChanged: (value) {},
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _direccionController,
                  label: 'Dirección',
                  icon: Icons.location_on,
                  readOnly: _clienteEncontrado,
                  enabled: _clienteEncontrado || _entradaManualHabilitada,
                  hintText:
                      _entradaManualHabilitada ? 'Ingrese dirección' : null,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),

          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  readOnly: _clienteEncontrado,
                  enabled: _clienteEncontrado || _entradaManualHabilitada,
                  hintText: _entradaManualHabilitada ? 'Ingrese email' : null,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) {},
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _ciudadController,
                  label: 'Ciudad',
                  icon: Icons.location_city,
                  readOnly: _clienteEncontrado,
                  enabled: _clienteEncontrado || _entradaManualHabilitada,
                  hintText: _entradaManualHabilitada ? 'Ingrese ciudad' : null,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSelectorVendedor(),

          const SizedBox(height: 16),
          if (sucursalUsuario == 'Tulcán')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Seleccionar Despacho',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _despachoSeleccionado =
                                  _despachoSeleccionado == 'quito'
                                      ? null
                                      : 'quito';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _despachoSeleccionado == 'quito'
                                    ? const Color(0xFF4682B4)
                                    : Colors.grey[200],
                            foregroundColor:
                                _despachoSeleccionado == 'quito'
                                    ? Colors.white
                                    : Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    _despachoSeleccionado == 'quito'
                                        ? const Color(0xFF4682B4)
                                        : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          child: const Text('Despacho Quito'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _despachoSeleccionado =
                                  _despachoSeleccionado == 'guayaquil'
                                      ? null
                                      : 'guayaquil';
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _despachoSeleccionado == 'guayaquil'
                                    ? const Color(0xFF4682B4)
                                    : Colors.grey[200],
                            foregroundColor:
                                _despachoSeleccionado == 'guayaquil'
                                    ? Colors.white
                                    : Colors.grey[700],
                            padding: EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color:
                                    _despachoSeleccionado == 'guayaquil'
                                        ? const Color(0xFF4682B4)
                                        : Colors.grey[300]!,
                              ),
                            ),
                          ),
                          child: const Text('Despacho Guayaquil'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],
              ),
            ),

          if (_entradaManualHabilitada && !_clienteEncontrado)
            Container(
              margin: EdgeInsets.only(top: 16),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _guardarClienteManual,
                icon: Icon(Icons.save, color: Colors.white),
                label: Text('Guardar Cliente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductosSection() {
    return _buildSection(
      title: 'Agregar Productos',
      icon: Icons.inventory_2_outlined,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          _buildTextField(
            controller: _formRefController,
            label: 'REF',
            icon: Icons.qr_code,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              String upperValue = value.toUpperCase();
              if (_formRefController.text != upperValue) {
                _formRefController.value = _formRefController.value.copyWith(
                  text: upperValue,
                  selection: TextSelection.collapsed(offset: upperValue.length),
                );
              }

              if (_debounceProducto?.isActive ?? false)
                _debounceProducto!.cancel();
              _debounceProducto = Timer(const Duration(milliseconds: 500), () {
                _buscarProductoPorReferenciaFormulario(upperValue.trim());
              });
            },
          ),
          SizedBox(height: 12),

          _buildTextField(
            controller: _formDescripcionController,
            label: 'Descripción',
            icon: Icons.description,
            onChanged: (value) {},
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _formCantidadController,
                  label: 'Cant',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  onChanged: (value) => _calcularTotalFormulario(),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _formPrecioController,
                  label: 'Precio Unit',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _calcularTotalFormulario(),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _formTotalController,
                  label: 'Subtotal',
                  icon: Icons.calculate,
                  readOnly: true,
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _agregarItemFromForm,
              icon: Icon(Icons.add),
              label: Text('Agregar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[700],
                side: BorderSide(color: Colors.grey[400]!),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacturaSection() {
    return _buildSection(
      title: 'Factura',
      icon: Icons.receipt_long,
      color: Colors.grey[800]!,
      child: Row(
        children: [
          Expanded(
            child: _buildTextField(
              controller: _numeroFacturaController,
              label: 'N° Factura',
              icon: Icons.numbers,
              onChanged: (value) {},
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildTextField(
              controller: _valorDeclaradoController,
              label: 'Valor Declarado',
              icon: Icons.attach_money,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaProductosSection() {
    return _buildSection(
      title: 'Lista Productos Agregados',
      icon: Icons.list_alt,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Text(
                    'REF',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'DESCRIPCIÓN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'CANT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'PRECIO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'SUBTOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    '',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),

          if (items.isEmpty)
            Container(
              padding: EdgeInsets.all(32),
              child: Text(
                'No hay productos agregados',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              int index = entry.key;
              ItemOrdenDespacho item = entry.value;
              return _buildProductRowCompact(index, item);
            }),

          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildProductRowCompact(int index, ItemOrdenDespacho item) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              item.refController.text,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              item.descripcionController.text,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.cantidadController.text,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '\$${item.vUnitController.text}',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              item.vTotalController.text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () => _eliminarItem(index),
              icon: Icon(Icons.remove_circle_outline, color: Colors.red[600]),
              iconSize: 18,
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buscarProductoPorReferenciaFormulario(String referencia) async {
    referencia = referencia.toUpperCase();

    if (referencia.isEmpty) {
      setState(() {
        _formDescripcionController.clear();
        _formPrecioController.clear();
        _formTotalController.clear();
      });
      return;
    }

    try {
      final QuerySnapshot querySnapshot =
          await FirebaseFirestore.instance
              .collection('productos')
              .where('referencia', isEqualTo: referencia.trim())
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final DocumentSnapshot doc = querySnapshot.docs.first;
        final Map<String, dynamic> producto =
            doc.data() as Map<String, dynamic>;

        List<double> preciosDisponibles = [];
        List<String> nombrePrecios = [];

        if (producto['precio20'] != null && producto['precio20'] > 0) {
          preciosDisponibles.add((producto['precio20']).toDouble());
          nombrePrecios.add('Precio 20%');
        }

        if (producto['pvp'] != null && producto['pvp'] > 0) {
          preciosDisponibles.add((producto['pvp']).toDouble());
          nombrePrecios.add('PVP');
        }

        if (preciosDisponibles.isEmpty) {
          if (producto['precio'] != null && producto['precio'] > 0) {
            preciosDisponibles.add((producto['precio']).toDouble());
            nombrePrecios.add('Precio');
          } else if (producto['costo'] != null && producto['costo'] > 0) {
            preciosDisponibles.add((producto['costo']).toDouble());
            nombrePrecios.add('Costo');
          }
        }

        if (preciosDisponibles.length >= 2) {
          double? precioSeleccionado = await _mostrarDialogoSeleccionPrecio(
            producto['nombre'] ?? '',
            preciosDisponibles,
            nombrePrecios,
          );

          if (precioSeleccionado != null) {
            _aplicarDatosProductoFormulario(producto, precioSeleccionado);
          } else {
            setState(() {
              _formDescripcionController.clear();
              _formPrecioController.clear();
              _formTotalController.clear();
            });
          }
        } else if (preciosDisponibles.isNotEmpty) {
          _aplicarDatosProductoFormulario(producto, preciosDisponibles[0]);
        } else {
          setState(() {
            _formDescripcionController.text = producto['nombre'] ?? '';
            _formPrecioController.text = '0.00';
            _formTotalController.clear();
          });
        }
      } else {
        setState(() {
          _formDescripcionController.clear();
          _formPrecioController.clear();
          _formTotalController.clear();
        });
      }
    } catch (e) {
      print('Error al buscar producto: $e');
      setState(() {
        _formDescripcionController.clear();
        _formPrecioController.clear();
        _formTotalController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar producto. Verifique la conexión.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<double?> _mostrarDialogoSeleccionPrecio(
    String nombreProducto,
    List<double> precios,
    List<String> nombrePrecios,
  ) async {
    return await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Seleccionar Precio',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreProducto,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Seleccione el precio a usar:',
                style: TextStyle(color: Colors.black),
              ),
              SizedBox(height: 12),
              ...List.generate(precios.length, (index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(precios[index]),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.all(12),
                      side: BorderSide(color: Colors.blue),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${nombrePrecios[index]}:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '\$${precios[index].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        );
      },
    );
  }

  void _aplicarDatosProductoFormulario(
    Map<String, dynamic> producto,
    double precio,
  ) {
    setState(() {
      _formDescripcionController.text = producto['nombre'] ?? '';
      _formPrecioController.text = precio.toStringAsFixed(2);
      if (_formCantidadController.text.isNotEmpty) {
        _calcularTotalFormulario();
      }
    });
  }

  Widget _buildTotalesSection() {
    return _buildSection(
      title: 'Resumen Totales',
      icon: Icons.calculate,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', '\$${_calcularSubtotal()}'),
          SizedBox(height: 12),
          _buildTotalRow('I.V.A. 0%:', '\$0.00'),
          SizedBox(height: 12),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _aplicarIVA ? Colors.green[50] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _aplicarIVA ? Colors.green[300]! : Colors.grey[300]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IVA (15%)',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: _aplicarIVA ? Colors.green[700] : Colors.grey[600],
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '\$${_calcularIVA()}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _aplicarIVA ? Colors.green[700] : Colors.grey[600],
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _aplicarIVA = !_aplicarIVA;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 20,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color:
                              _aplicarIVA
                                  ? Colors.green[400]
                                  : Colors.grey[400],
                        ),
                        child: AnimatedAlign(
                          duration: Duration(milliseconds: 200),
                          alignment:
                              _aplicarIVA
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            width: 18,
                            height: 18,
                            margin: EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(9),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                Text(
                  '\$${_calcularTotalFinal()}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormaPagoSection() {
    return _buildSection(
      title: 'Forma de Pago',
      icon: Icons.payment,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text('EFECTIVO', style: TextStyle(fontSize: 14)),
                  value: _efectivo,
                  onChanged: (bool? value) {
                    setState(() {
                      _efectivo = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: Text(
                    'DINERO ELECTRÓNICO',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _dineroElectronico,
                  onChanged: (bool? value) {
                    setState(() {
                      _dineroElectronico = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: Text(
                    'TARJETA DE CRÉDITO/DÉBITO',
                    style: TextStyle(fontSize: 14),
                  ),
                  value: _tarjetaCredito,
                  onChanged: (bool? value) {
                    setState(() {
                      _tarjetaCredito = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: Text('OTROS', style: TextStyle(fontSize: 14)),
                  value: _otros,
                  onChanged: (bool? value) {
                    setState(() {
                      _otros = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    bool enabled = true,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required void Function(dynamic value) onChanged,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
        ),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        onChanged: (value) {
          if (label == 'Email') {
            if (value != value.toLowerCase()) {
              controller.value = controller.value.copyWith(
                text: value.toLowerCase(),
                selection: TextSelection.collapsed(
                  offset: value.toLowerCase().length,
                ),
              );
            }
          } else if (label != 'Teléfono' && label != 'REF') {
            if (value != value.toUpperCase()) {
              controller.value = controller.value.copyWith(
                text: value.toUpperCase(),
                selection: TextSelection.collapsed(
                  offset: value.toUpperCase().length,
                ),
              );
            }
          }
          onChanged(value);
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          prefixIcon: Icon(
            icon,
            color: enabled ? Colors.grey[600] : Colors.grey[400],
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          labelStyle: TextStyle(
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        ),
        style: TextStyle(color: enabled ? Colors.black87 : Colors.grey[500]),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4682B4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4682B4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _mostrarOpcionesImprimir,
                  child: const Text('Imprimir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4682B4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4682B4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _mostrarOpcionesCompartir,
                  child: const Text('Compartir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4682B4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4682B4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _mostrarOpcionesGuardar,
                  child: const Text('Guardar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIX: diálogo de guardado con opciones para Tulcán, directo para Quito/Guayaquil
  void _mostrarOpcionesGuardar() async {
    if (!_validarDatos()) return;

    if (sucursalUsuario == 'Tulcán') {
      // Tulcán: mostrar opciones de qué guardar
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '¿Qué desea guardar?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Seleccione si desea guardar solo la Orden, solo la Proforma, o ambas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              // Solo Orden
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmarYGuardar(soloOrden: true, soloProforma: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 168, 168, 168),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Solo Orden'),
              ),
              // Solo Proforma
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmarYGuardar(soloOrden: false, soloProforma: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 168, 168, 168),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Solo Proforma'),
              ),
              // Ambas
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmarYGuardar(soloOrden: false, soloProforma: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ambas'),
              ),
            ],
          );
        },
      );
    } else {
      // Quito y Guayaquil: siempre guardan ambas sin preguntar
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              '¿Confirmar guardado?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Se guardarán la Proforma y la Orden de Despacho juntas.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _confirmarYGuardar(soloOrden: false, soloProforma: false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    }
  }

  // FIX: función central de guardado que recibe qué guardar
  void _confirmarYGuardar({
    required bool soloOrden,
    required bool soloProforma,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: const Color(0xFF4682B4)),
              SizedBox(height: 16),
              Text('Guardando documentos y actualizando inventario...'),
            ],
          ),
        );
      },
    );

    try {
      // Obtener sede real desde Firestore una sola vez
      final user = FirebaseAuth.instance.currentUser;
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user?.uid)
              .get();

      final sedeReal =
          usuarioDoc.exists ? (usuarioDoc['sede'] ?? 'Tulcán') : 'Tulcán';
      final usuarioNombre =
          usuarioDoc.exists
              ? (usuarioDoc['nombre'] ?? 'Desconocido')
              : 'Desconocido';

      // Descontar inventario solo si se guarda algo con productos
      await _descontarInventario(sedeReal);

      String detalleAuditoria = '';

      if (soloOrden) {
        await _guardarOrdenDespachoInterno(
          sedeReal,
          incluirNumeroProforma: false,
        );
        detalleAuditoria = 'Orden de Despacho N° $_numeroOrdenDespacho';
      } else if (soloProforma) {
        await _guardarProformaInterno(sedeReal, numeroOrdenCruzado: '');
        detalleAuditoria = 'Proforma N° $_numeroProforma';
      } else {
        // Ambas: se cruzan los números
        await _guardarProformaInterno(
          sedeReal,
          numeroOrdenCruzado: _numeroOrdenDespacho,
        );
        await _guardarOrdenDespachoInterno(
          sedeReal,
          incluirNumeroProforma: true,
        );
        detalleAuditoria =
            'Proforma N° $_numeroProforma | Orden N° $_numeroOrdenDespacho';
      }

      // Auditoría
      final auditoriaRef =
          FirebaseFirestore.instance.collection('auditoria_general').doc();
      await auditoriaRef.set({
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': usuarioNombre,
        'usuario_uid': user?.uid ?? 'uid_desconocido',
        'accion':
            soloOrden
                ? 'Nueva orden de despacho'
                : soloProforma
                ? 'Nueva proforma'
                : 'Nueva proforma y orden de despacho',
        'detalle': detalleAuditoria,
      });

      Navigator.pop(context); // Cerrar diálogo de carga

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Documentos guardados e inventario actualizado correctamente',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _limpiarFormularioCompleto();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar documentos: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // FIX: recibe sedeReal y numeroOrdenCruzado como parámetros
  Future<void> _guardarProformaInterno(
    String sedeReal, {
    required String numeroOrdenCruzado,
  }) async {
    final numeroLimpio = _numeroProforma
        .replaceAll('Q-', '')
        .replaceAll('G-', '');
    final numeroAUsar = int.parse(numeroLimpio);

    final proformaData = {
      'numero': numeroAUsar,
      // Solo agrega numero_orden si no está vacío (cuando se guardan ambas)
      if (numeroOrdenCruzado.isNotEmpty) 'numero_orden': numeroOrdenCruzado,
      'cliente': _clienteController.text,
      'ci_ruc': _ciRucController.text,
      'direccion': _direccionController.text,
      'telefono': _telefonoController.text,
      'vendedor_nombre': _vendedorSeleccionado ?? 'Sin asignar',
      'despacho': _despachoSeleccionado,
      'sede_origen': sedeReal,
      'items':
          items
              .map(
                (item) => {
                  'ref': item.refController.text,
                  'descripcion': item.descripcionController.text,
                  'cantidad': item.cantidadController.text,
                  'v_unit': item.vUnitController.text,
                  'v_total': item.vTotalController.text,
                },
              )
              .toList(),
      'subtotal': _calcularSubtotal(),
      'iva': _calcularIVA(),
      'total': _calcularTotalFinal(),
      'numero_factura': _numeroFacturaController.text.trim(),
      'valor_declarado':
          _valorDeclaradoController.text.trim().isEmpty
              ? '0'
              : _valorDeclaradoController.text.trim(),
      'fecha': Timestamp.now(),
      'estado': '',
    };

    await FirebaseFirestore.instance.collection('proformas').add(proformaData);

    // FIX: usar sedeReal para el docId del contador
    String docIdProforma;
    if (sedeReal == 'Quito') {
      docIdProforma = 'proforma_Quito';
    } else if (sedeReal == 'Guayaquil') {
      docIdProforma = 'proforma_Guayaquil';
    } else {
      docIdProforma = 'proforma';
    }

    // Solo incrementa el contador de proforma
    final ref = FirebaseFirestore.instance
        .collection('orden_proforma_counter')
        .doc(docIdProforma);
    await ref.update({'contador': numeroAUsar});
  }

  // FIX: recibe sedeReal como parámetro, ya no usa sucursalUsuario
  Future<void> _guardarOrdenDespachoInterno(
    String sedeReal, {
    bool incluirNumeroProforma = true,
  }) async {
    final numeroLimpio = _numeroOrdenDespacho
        .replaceAll('Q-', '')
        .replaceAll('G-', '');
    final numeroAUsar = int.parse(numeroLimpio);

    final ordenData = {
      'numero': numeroAUsar,
      if (incluirNumeroProforma) 'numero_proforma': _numeroProforma,
      'cliente': _clienteController.text,
      'ci_ruc': _ciRucController.text,
      'email': _emailController.text,
      'direccion': _direccionController.text,
      'ciudad': _ciudadController.text,
      'telefono': _telefonoController.text,
      'despacho': _despachoSeleccionado,
      'sede_origen': sedeReal,
      'items':
          items
              .map(
                (item) => {
                  'ref': item.refController.text,
                  'descripcion': item.descripcionController.text,
                  'cantidad': item.cantidadController.text,
                },
              )
              .toList(),
      'numero_factura': _numeroFacturaController.text.trim(),
      'valor_declarado':
          _valorDeclaradoController.text.trim().isEmpty
              ? '0'
              : _valorDeclaradoController.text.trim(),
      'fecha': Timestamp.now(),
      'estado': 'Pendiente',
    };

    await FirebaseFirestore.instance
        .collection('ordenes_despacho')
        .add(ordenData);

    // FIX: usar sedeReal para el docId del contador de orden
    String docIdOrden;
    if (sedeReal == 'Quito') {
      docIdOrden = 'orden_Quito';
    } else if (sedeReal == 'Guayaquil') {
      docIdOrden = 'orden_Guayaquil';
    } else {
      docIdOrden = 'orden';
    }

    // Solo incrementa el contador de orden
    final ref = FirebaseFirestore.instance
        .collection('orden_proforma_counter')
        .doc(docIdOrden);
    await ref.update({'contador': numeroAUsar});
  }

  void _mostrarOpcionesCompartir() async {
    if (!_validarDatos()) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccione qué compartir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _compartirProforma(),
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir Proforma'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _compartirOrdenDespacho(),
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir Orden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarOpcionesImprimir() async {
    if (!_validarDatos()) return;

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccione qué imprimir',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _vistasPreviasProforma();
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir Proforma'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _vistaPreviaOrdenDespacho();
                      },
                      icon: const Icon(Icons.print),
                      label: const Text('Imprimir Orden'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _eliminarItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  String _calcularSubtotal() {
    double subtotal = 0;
    for (var item in items) {
      subtotal += double.tryParse(item.vTotalController.text) ?? 0;
    }
    return subtotal.toStringAsFixed(2);
  }

  String _calcularIVA() {
    if (!_aplicarIVA) return '0.00';
    double subtotal = double.tryParse(_calcularSubtotal()) ?? 0;
    double iva = subtotal * 0.15;
    return iva.toStringAsFixed(2);
  }

  String _calcularTotalFinal() {
    double subtotal = double.tryParse(_calcularSubtotal()) ?? 0;
    double iva = double.tryParse(_calcularIVA()) ?? 0;
    double total = subtotal + iva;
    return total.toStringAsFixed(2);
  }

  void _vistasPreviasProforma() async {
    if (!_validarDatos()) return;

    try {
      await ProformaPDFGenerator.showPreview(
        numeroProforma: _numeroProforma,
        cliente: _clienteController.text,
        ciRuc: _ciRucController.text,
        direccion: _direccionController.text,
        telefono: _telefonoController.text,
        items:
            items
                .map(
                  (item) => {
                    'ref': item.refController.text,
                    'descripcion': item.descripcionController.text,
                    'cantidad': item.cantidadController.text,
                    'v_unit': item.vUnitController.text,
                    'v_total': item.vTotalController.text,
                  },
                )
                .toList(),
        subtotal: _calcularSubtotal(),
        iva: _calcularIVA(),
        total: _calcularTotalFinal(),
        efectivo: _efectivo,
        dineroElectronico: _dineroElectronico,
        tarjetaCredito: _tarjetaCredito,
        otros: _otros,
      );
    } catch (e) {
      print('Error al generar proforma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar proforma: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _vistaPreviaOrdenDespacho() async {
    if (!_validarDatos()) return;

    try {
      await OrdenDespachoPDFGenerator.showPreview(
        numeroOrdenDespacho: _numeroOrdenDespacho,
        cliente: _clienteController.text,
        ciRuc: _ciRucController.text,
        email: _emailController.text,
        telefono: _telefonoController.text,
        direccion: _direccionController.text,
        ciudad: _ciudadController.text,
        items:
            items
                .map(
                  (item) => {
                    'ref': item.refController.text,
                    'descripcion': item.descripcionController.text,
                    'cantidad': item.cantidadController.text,
                  },
                )
                .toList(),
      );
    } catch (e) {
      print('Error al generar orden de despacho: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al generar orden de despacho: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _validarDatos() {
    if (_clienteController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('El nombre del cliente es obligatorio'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_ciRucController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('La cédula/RUC es obligatoria'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    bool tieneItems = items.any(
      (item) =>
          item.descripcionController.text.isNotEmpty ||
          item.refController.text.isNotEmpty,
    );

    if (!tieneItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debe agregar al menos un producto'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    if (_vendedorSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un vendedor'),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }

    return true;
  }

  void _compartirProforma() async {
    try {
      await ProformaPDFCompartir.shareDocument(
        numeroOrden: _numeroProforma,
        cliente: _clienteController.text,
        ciRuc: _ciRucController.text,
        direccion: _direccionController.text,
        telefono: _telefonoController.text,
        items:
            items
                .map(
                  (item) => {
                    'ref': item.refController.text,
                    'descripcion': item.descripcionController.text,
                    'cantidad': item.cantidadController.text,
                    'v_unit': item.vUnitController.text,
                    'v_total': item.vTotalController.text,
                  },
                )
                .toList(),
        subtotal: _calcularSubtotal(),
        iva: _calcularIVA(),
        total: _calcularTotalFinal(),
        efectivo: _efectivo,
        dineroElectronico: _dineroElectronico,
        tarjetaCredito: _tarjetaCredito,
        otros: _otros,
      );

      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al compartir proforma: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _compartirOrdenDespacho() async {
    try {
      await OrdenPDFCompartir.shareDocument(
        numeroOrden: _numeroOrdenDespacho,
        cliente: _clienteController.text,
        ciRuc: _ciRucController.text,
        email: _emailController.text,
        direccion: _direccionController.text,
        ciudad: _ciudadController.text,
        items:
            items
                .map(
                  (item) => {
                    'ref': item.refController.text,
                    'descripcion': item.descripcionController.text,
                    'cantidad': item.cantidadController.text,
                  },
                )
                .toList(),
      );

      Navigator.pop(context);
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al compartir orden: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _limpiarFormularioCompleto() {
    setState(() {
      _clienteController.clear();
      _ciRucController.clear();
      _direccionController.clear();
      _telefonoController.clear();
      _emailController.clear();
      _ciudadController.clear();
      _efectivo = false;
      _dineroElectronico = false;
      _tarjetaCredito = false;
      _otros = false;
      _numeroFacturaController.clear();
      _valorDeclaradoController.clear();
      _clienteEncontrado = false;
      _mensajeBusqueda = '';
      _entradaManualHabilitada = true;
      items.clear();
      _despachoSeleccionado = null;
      items.add(ItemOrdenDespacho());
      _vendedorSeleccionado = null;
    });
    _previsualizarNumeroProforma();
    _previsualizarNumeroOrdenDespacho();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _debounceProducto?.cancel();
    _debounceNombre?.cancel();
    _nombreFocusNode.dispose();
    _clienteController.dispose();
    _ciRucController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _ciudadController.dispose();
    _numeroFacturaController.dispose();
    _valorDeclaradoController.dispose();
    for (var item in items) {
      item.dispose();
    }
    super.dispose();
  }
}

class ItemOrdenDespacho {
  final TextEditingController refController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController vUnitController = TextEditingController();
  final TextEditingController vTotalController = TextEditingController();

  void dispose() {
    refController.dispose();
    descripcionController.dispose();
    cantidadController.dispose();
    vUnitController.dispose();
    vTotalController.dispose();
  }
}
