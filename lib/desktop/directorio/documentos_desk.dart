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

  String _numeroOrden = '';
  Timer? _debounce;

  // Estados para la búsqueda
  bool _isSearching = false;
  bool _clienteEncontrado = false;
  String _mensajeBusqueda = '';
  bool _entradaManualHabilitada = false;

  // Lista de items
  List<ItemOrdenDespacho> items = [ItemOrdenDespacho()];

  // Formas de pago
  bool _efectivo = false;
  bool _dineroElectronico = false;
  bool _tarjetaCredito = false;
  bool _otros = false;

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

  // Método para limpiar el formulario y volver al modo búsqueda
  void _limpiarFormulario() {
    setState(() {
      _ciRucController.clear();
      _clienteController.clear();
      _telefonoController.clear();
      _direccionController.clear();
      _emailController.clear();
      _ciudadController.clear();
      _entradaManualHabilitada = false;
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

      Navigator.pop(context); // Cerrar diálogo de carga

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
      Navigator.pop(context); // Cerrar diálogo de carga

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

  void _buscarClienteConDebounce(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    if (query.isEmpty) {
      setState(() {
        _entradaManualHabilitada = false;
        _clienteEncontrado = false;
        _mensajeBusqueda = '';
        _isSearching = false;
        _clienteController.clear();
        _telefonoController.clear();
        _direccionController.clear();
        _emailController.clear();
        _ciudadController.clear();
      });
      return;
    }

    if (_entradaManualHabilitada) {
      setState(() {
        _entradaManualHabilitada = false;
      });
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
    _previsualizarNumeroOrden();
  }

  Future<void> _previsualizarNumeroOrden() async {
    final fechaHoy = DateTime.now();
    final fechaFormateada =
        "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

    final counterRef = FirebaseFirestore.instance
        .collection('orden_despacho_counter')
        .doc(fechaFormateada);

    final counterDoc = await counterRef.get();

    int numero = 1;

    if (counterDoc.exists) {
      numero = counterDoc['contador'] + 1;
    } else {
      await counterRef.set({'contador': 0});
    }

    setState(() {
      _numeroOrden = numero.toString().padLeft(7, '0');
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // Cabecera
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
                      'Proforma & Orden de Despacho',
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

          // Contenido
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
                                _buildCompactHeader(),
                                const SizedBox(height: 16),
                                _buildClienteSection(),
                                const SizedBox(height: 16),
                                _buildItemsSection(),
                                const SizedBox(height: 16),
                                _buildTotalesSection(),
                                const SizedBox(height: 16),
                                _buildFormaPagoSection(),
                                const SizedBox(height: 16),
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

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(
          'DOCUMENTO Nº $_numeroOrden',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
            letterSpacing: 1,
          ),
        ),
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
          // CAMPO DE CÉDULA PRIMERO
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

          // MENSAJE DE ESTADO
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

          _buildTextField(
            controller: _clienteController,
            label: 'Nombre del Cliente',
            icon: Icons.person,
            readOnly: _clienteEncontrado,
            enabled: _clienteEncontrado || _entradaManualHabilitada,
            hintText:
                _entradaManualHabilitada ? 'Ingrese nombre del cliente' : null,
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
                ),
              ),
            ],
          ),

          // NUEVOS CAMPOS PARA ORDEN DE DESPACHO
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
                ),
              ),
            ],
          ),

          // BOTÓN GUARDAR CLIENTE (solo visible en modo manual)
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

  Widget _buildItemsSection() {
    return _buildSection(
      title: 'Productos y Servicios (${items.length})',
      icon: Icons.list_alt,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lista de productos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _agregarItem,
                  icon: Icon(Icons.add, color: Colors.white),
                  iconSize: 20,
                  constraints: BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...items.asMap().entries.map((entry) {
            int index = entry.key;
            ItemOrdenDespacho item = entry.value;
            return _buildItemCard(index, item);
          }),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index, ItemOrdenDespacho item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Producto ${index + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                if (items.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: IconButton(
                      onPressed: () => _eliminarItem(index),
                      icon: Icon(Icons.close, color: Colors.red[600]),
                      iconSize: 18,
                      constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildItemInputField(
                        controller: item.refController,
                        label: 'REF.',
                        onChanged:
                            (value) =>
                                _buscarProductoPorReferencia(value, index),
                        onEditingComplete:
                            () => _buscarProductoPorReferencia(
                              item.refController.text,
                              index,
                            ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: _buildItemInputField(
                        controller: item.descripcionController,
                        label: 'Descripción',
                        onEditingComplete: () {
                          return Future.value();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildItemInputField(
                        controller: item.cantidadController,
                        label: 'Cantidad',
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calcularTotal(index),
                        onEditingComplete: () {
                          return Future.value();
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildItemInputField(
                        controller: item.vUnitController,
                        label: 'V. UNIT.',
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => _calcularTotal(index),
                        onEditingComplete: () {
                          return Future.value();
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildItemInputField(
                        controller: item.vTotalController,
                        label: 'V. TOTAL',
                        readOnly: true,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                        onEditingComplete: () {
                          return Future.value();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buscarProductoPorReferencia(
    String referencia,
    int index,
  ) async {
    // Si la referencia está vacía, limpiar campos relacionados
    if (referencia.isEmpty) {
      setState(() {
        items[index].descripcionController.clear();
        items[index].vUnitController.clear();
        if (items[index].cantidadController.text.isNotEmpty) {
          _calcularTotal(index); // Recalcular para mostrar 0.00
        }
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

        setState(() {
          items[index].descripcionController.text = producto['nombre'] ?? '';

          if (producto['precios'] != null && producto['precios'].isNotEmpty) {
            double precio = producto['precios'][0].toDouble();
            items[index].vUnitController.text = precio.toStringAsFixed(2);
          } else if (producto['costo'] != null && producto['costo'] > 0) {
            double precio = producto['costo'].toDouble();
            items[index].vUnitController.text = precio.toStringAsFixed(2);
          }

          if (items[index].cantidadController.text.isNotEmpty) {
            _calcularTotal(index);
          }
        });
      } else {
        // Si no encuentra el producto, limpiar descripción y precio
        setState(() {
          items[index].descripcionController.clear();
          items[index].vUnitController.clear();
          if (items[index].cantidadController.text.isNotEmpty) {
            _calcularTotal(index); // Recalcular para mostrar 0.00
          }
        });
      }
    } catch (e) {
      print('Error al buscar producto: $e');

      // En caso de error, también limpiar los campos
      setState(() {
        items[index].descripcionController.clear();
        items[index].vUnitController.clear();
        if (items[index].cantidadController.text.isNotEmpty) {
          _calcularTotal(index);
        }
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

  Widget _buildItemInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    TextStyle? style,
    Function(String)? onChanged,
    required Future<void> Function() onEditingComplete,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onChanged: onChanged,
        style: style ?? TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey[700],
          ),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildTotalesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calculate, color: Colors.grey[800], size: 20),
              SizedBox(width: 8),
              Text(
                'Resumen de Totales',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTotalRow('Sub-Total:', '\$${_calcularSubtotal()}'),
          SizedBox(height: 8),
          _buildTotalRow('I.V.A. 0%:', '\$0.00'),
          SizedBox(height: 8),
          _buildTotalRow('I.V.A. 15%:', '\$${_calcularIVA()}'),
          SizedBox(height: 8),
          Divider(color: Colors.grey[300]),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildTotalRow(
              'TOTAL \$',
              _calcularTotalFinal(),
              bold: true,
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
  }) {
    return Container(
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
        onChanged: (value) {
          // Formatear texto según el tipo de campo
          if (label == 'Email') {
            // Para email, mantener en minúsculas
            if (value != value.toLowerCase()) {
              controller.value = controller.value.copyWith(
                text: value.toLowerCase(),
                selection: TextSelection.collapsed(
                  offset: value.toLowerCase().length,
                ),
              );
            }
          } else if (label != 'Teléfono') {
            // Para todos los campos excepto teléfono y email, convertir a mayúsculas
            if (value != value.toUpperCase()) {
              controller.value = controller.value.copyWith(
                text: value.toUpperCase(),
                selection: TextSelection.collapsed(
                  offset: value.toUpperCase().length,
                ),
              );
            }
          }
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

  Widget _buildTotalRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
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
            // Botón Imprimir
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
            // Botón Compartir
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
            // Botón Guardar (guarda ambos)
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
                  onPressed: _guardarAmbosDocumentos,
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

  void _guardarAmbosDocumentos() async {
    if (!_validarDatos()) return;

    // Mostrar diálogo de carga
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
              Text('Guardando documentos...'),
            ],
          ),
        );
      },
    );

    try {
      // Guardar Proforma
      await _guardarProformaInterno();

      // Guardar Orden de Despacho
      await _guardarOrdenDespachoInterno();

      final user = FirebaseAuth.instance.currentUser;

      // Buscar el nombre en la colección usuarios_activos
      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user?.uid)
              .get();

      final usuarioNombre =
          usuarioDoc.exists
              ? (usuarioDoc['nombre'] ?? 'Desconocido')
              : 'Desconocido';

      final auditoriaRef =
          FirebaseFirestore.instance.collection('auditoria_general').doc();

      await auditoriaRef.set({
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': usuarioNombre,
        'usuario_uid': user?.uid ?? 'uid_desconocido',
        'accion': 'Nueva proforma y orden de despacho',
        'detalle': 'Número de documento: $_numeroOrden',
      });

      // Cerrar diálogo de carga
      Navigator.pop(context);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Proforma y Orden de Despacho guardadas correctamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      _limpiarFormularioCompleto();
    } catch (e) {
      // Cerrar diálogo de carga
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

  // FUNCIÓN INTERNA PARA GUARDAR PROFORMA
  Future<void> _guardarProformaInterno() async {
    final fechaHoy = DateTime.now();
    final fechaFormateada =
        "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

    final counterRef = FirebaseFirestore.instance
        .collection('proforma_counter')
        .doc(fechaFormateada);

    final counterDoc = await counterRef.get();

    int numero = 1;
    if (counterDoc.exists) {
      numero = counterDoc['contador'] + 1;
      await counterRef.update({'contador': numero});
    } else {
      await counterRef.set({'contador': numero});
    }

    final numeroFinal = numero.toString().padLeft(7, '0');

    final proformaData = {
      'numero': numeroFinal,
      'cliente': _clienteController.text,
      'ci_ruc': _ciRucController.text,
      'direccion': _direccionController.text,
      'telefono': _telefonoController.text,
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
      'fecha': Timestamp.now(),
      'efectivo': _efectivo,
      'dinero_electronico': _dineroElectronico,
      'tarjeta_credito': _tarjetaCredito,
      'otros': _otros,
      'subtotal': _calcularSubtotal(),
      'iva': _calcularIVA(),
      'total': _calcularTotalFinal(),
    };

    await FirebaseFirestore.instance.collection('proformas').add(proformaData);
  }

  // FUNCIÓN INTERNA PARA GUARDAR ORDEN DE DESPACHO (sin UI)
  Future<void> _guardarOrdenDespachoInterno() async {
    final fechaHoy = DateTime.now();
    final fechaFormateada =
        "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

    final counterRef = FirebaseFirestore.instance
        .collection('orden_despacho_counter')
        .doc(fechaFormateada);

    final counterDoc = await counterRef.get();

    int numero = 1;
    if (counterDoc.exists) {
      numero = counterDoc['contador'] + 1;
      await counterRef.update({'contador': numero});
    } else {
      await counterRef.set({'contador': numero});
    }

    final numeroFinal = numero.toString().padLeft(7, '0');

    final ordenData = {
      'numero': numeroFinal,
      'cliente': _clienteController.text,
      'ci_ruc': _ciRucController.text,
      'correo': _emailController.text,
      'direccion': _direccionController.text,
      'ciudad': _ciudadController.text,
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
      'fecha': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('ordenes_despacho')
        .add(ordenData);
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

  // NUEVA FUNCIÓN PARA MOSTRAR OPCIONES DE IMPRESIÓN
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

  void _agregarItem() {
    setState(() {
      items.add(ItemOrdenDespacho());
    });
  }

  void _eliminarItem(int index) {
    if (items.length > 1) {
      setState(() {
        items.removeAt(index);
      });
    }
  }

  void _calcularTotal(int index) {
    setState(() {
      double cantidad =
          double.tryParse(items[index].cantidadController.text) ?? 0;
      double precio = double.tryParse(items[index].vUnitController.text) ?? 0;
      double total = cantidad * precio;
      items[index].vTotalController.text = total.toStringAsFixed(2);
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

  // NUEVAS FUNCIONES PARA LLAMAR A LOS PDF GENERATORS

  void _vistasPreviasProforma() async {
    // Validar datos antes de generar
    if (!_validarDatos()) return;

    try {
      // Llamar al ProformaPDFGenerator
      await ProformaPDFGenerator.showPreview(
        numeroOrden: _numeroOrden,
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
    // Validar datos antes de generar
    if (!_validarDatos()) return;

    try {
      // Llamar al OrdenDespachoPDFGenerator
      await OrdenDespachoPDFGenerator.showPreview(
        numeroOrden: _numeroOrden,
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

    // Verificar que al menos un item tenga datos
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

    return true;
  }

  void _compartirProforma() async {
    try {
      await ProformaPDFCompartir.shareDocument(
        numeroOrden: _numeroOrden,
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
        numeroOrden: _numeroOrden,
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
      _clienteEncontrado = false;
      _mensajeBusqueda = '';
      _entradaManualHabilitada = false;
      items.clear();
      items.add(ItemOrdenDespacho());
    });
    _previsualizarNumeroOrden();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _clienteController.dispose();
    _ciRucController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _ciudadController.dispose();
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
