import 'dart:async';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/pdfs/proformaventaspdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProformaVentasDeskScreen extends StatefulWidget {
  const ProformaVentasDeskScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProformaVentasDeskScreenState createState() =>
      _ProformaVentasDeskScreenState();
}

class _ProformaVentasDeskScreenState extends State<ProformaVentasDeskScreen> {
  final TextEditingController _clienteController = TextEditingController();
  final TextEditingController _nombreComercialController =
      TextEditingController();
  final TextEditingController _rucController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _subtotalCeroController = TextEditingController(
    text: '0.00',
  );
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();

  // AGREGAR ESTOS CONTROLADORES SEPARADOS PARA EL FORMULARIO
  final TextEditingController _formCodigoController = TextEditingController();
  final TextEditingController _formDescripcionController =
      TextEditingController();
  final TextEditingController _formCantidadController = TextEditingController();
  final TextEditingController _formPrecioController = TextEditingController();
  final TextEditingController _formTotalController = TextEditingController();
  String _numeroProforma = '';
  Timer? _debounce;
  final List<bool> _isSearchingProduct = [];
  final List<bool> _productoEncontrado = [];
  final List<String> _mensajeBusquedaProducto = [];
  List<Map<String, dynamic>> _clientesSugeridos = [];
  bool _mostrarSugerencias = false;
  final FocusNode _nombreFocusNode = FocusNode();
  Timer? _debounceNombre;
  Timer? _debounceProducto;

  void _buscarClientesPorNombreConDebounce(String query) {
    if (_debounceNombre?.isActive ?? false) _debounceNombre!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _clientesSugeridos = [];
        _mostrarSugerencias = false;
      });
      return;
    }

    _debounceNombre = Timer(const Duration(milliseconds: 500), () async {
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
        print('Error al buscar clientes por nombre: $e');
      }
    });
  }

  void _seleccionarCliente(Map<String, dynamic> cliente) {
    setState(() {
      _clienteController.text = cliente['nombre'] ?? '';
      _rucController.text = cliente['ruc'] ?? '';
      _telefonoController.text = cliente['telefono'] ?? '';
      _direccionController.text = cliente['direccion'] ?? '';
      _correoController.text = cliente['correo'] ?? '';
      _ciudadController.text = cliente['ciudad'] ?? '';
      _clienteEncontrado = true;
      _mensajeBusqueda = 'Cliente encontrado correctamente.';
      _mostrarSugerencias = false;
      _clientesSugeridos = [];
    });
  }

  void _buscarClienteConDebounce(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {
      _isSearching = true;
      _clienteEncontrado = false;
      _mensajeBusqueda = '';
    });
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (value.isEmpty) {
        setState(() {
          _isSearching = false;
          _clienteEncontrado = false;
          _mensajeBusqueda = '';
          // NO limpiar campos, solo el estado de búsqueda
        });
        return;
      }
      try {
        var snapshot =
            await FirebaseFirestore.instance
                .collection('clientes')
                .where('ruc', isEqualTo: value)
                .limit(1)
                .get();
        if (snapshot.docs.isNotEmpty) {
          var data = snapshot.docs.first.data();
          setState(() {
            _isSearching = false;
            _clienteEncontrado = true;
            _mensajeBusqueda = 'Cliente encontrado';
            // Llenar campos pero mantenerlos editables
            _clienteController.text = data['nombre'] ?? '';
            _nombreComercialController.text = data['empresa'] ?? '';
            _telefonoController.text = data['telefono'] ?? '';
            _ciudadController.text = data['ciudad'] ?? '';
            _direccionController.text = data['direccion'] ?? '';
            _correoController.text = data['correo'] ?? '';
          });
        } else {
          setState(() {
            _isSearching = false;
            _clienteEncontrado = false;
            _mensajeBusqueda = 'Cliente no encontrado';
            // NO limpiar campos, mantener lo que el usuario haya escrito
          });
        }
      } catch (e) {
        setState(() {
          _isSearching = false;
          _clienteEncontrado = false;
          _mensajeBusqueda = 'Error al buscar cliente';
        });
      }
    });
  }

  // Controladores para condiciones
  final TextEditingController _validezController = TextEditingController(
    text: '30 DÍAS',
  );
  final TextEditingController _saldoController = TextEditingController(
    text: '50% PREVIA LA ENTREGA DE LOS PRODUCTOS',
  );
  final TextEditingController _entregaController = TextEditingController(
    text: 'SE ACUERDA CON EL COMPRADOR',
  );
  final TextEditingController _lugarController = TextEditingController(
    text: 'EN FÁBRICA FUNDIMETALES DEL NORTE',
  );

  // Lista de items
  List<ItemProforma> items = [ItemProforma()];

  // Estados para la búsqueda
  bool _isSearching = false;
  bool _clienteEncontrado = false;
  String _mensajeBusqueda = '';

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA CON TRANSFORM
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
                    child: Text(
                      _numeroProforma,
                      style: const TextStyle(
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

          // ✅ CONTENIDO CON NUEVO LAYOUT BASADO EN LA IMAGEN
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
                                // FILA SUPERIOR: Cliente + Productos
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // CLIENTE (lado izquierdo)
                                    Expanded(
                                      flex: 1,
                                      child: _buildClienteSection(),
                                    ),
                                    const SizedBox(width: 16),
                                    // PRODUCTOS (lado derecho, más pequeño)
                                    Expanded(
                                      flex: 1,
                                      child: _buildProductosSection(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // FILA MEDIA: Lista de Productos + Totales
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // LISTA DE PRODUCTOS AGREGADOS (lado izquierdo)
                                    Expanded(
                                      flex: 2,
                                      child: _buildListaProductosSection(),
                                    ),
                                    const SizedBox(width: 16),
                                    // TOTALES (lado derecho)
                                    Expanded(
                                      flex: 1,
                                      child: _buildTotalesSection(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // FILA INFERIOR: Condiciones (ancho completo)
                                _buildCondicionesSection(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        // Action bar dentro del contenido
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

  @override
  void initState() {
    super.initState();
    _previsualizarNumeroProforma();
    items = [];
  }

  Future<void> _previsualizarNumeroProforma() async {
    final fechaHoy = DateTime.now();
    final fechaFormateada =
        "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

    final counterRef = FirebaseFirestore.instance
        .collection('proformas_ventas_counter')
        .doc(fechaFormateada);

    final counterDoc = await counterRef.get();

    int numero = 1;

    if (counterDoc.exists) {
      numero = counterDoc['contador'] + 1;
    } else {
      await counterRef.set({'contador': 0});
    }

    setState(() {
      _numeroProforma = "COTIZACION N-$fechaFormateada-$numero";
    });
  }

  bool _aplicarIVA = false;

  // SECCIÓN CLIENTE (basada en la imagen)
  Widget _buildClienteSection() {
    return _buildSection(
      title: 'Cliente',
      icon: Icons.person_outline,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          // Campo de búsqueda por RUC
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: TextField(
              controller: _rucController,
              decoration: InputDecoration(
                labelText: 'RUC',
                hintText: 'Ingrese el RUC del cliente',
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
            ),
          ),

          // Mensaje de búsqueda
          if (_mensajeBusqueda.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 8),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _clienteEncontrado ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color:
                      _clienteEncontrado
                          ? Colors.green[200]!
                          : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _clienteEncontrado ? Icons.check_circle : Icons.info,
                    size: 16,
                    color:
                        _clienteEncontrado
                            ? Colors.green[600]
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
                                : Colors.orange[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 16),

          // Campos organizados como en la imagen
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
                          'RUC: ${cliente['ruc'] ?? ''}',
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
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _ciudadController,
                  label: 'Ciudad',
                  icon: Icons.location_city,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _direccionController,
                  label: 'Dirección',
                  icon: Icons.home,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          _buildTextField(
            controller: _correoController,
            label: 'Correo',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  // SECCIÓN PRODUCTOS (más compacta, lado derecho superior)
  Widget _buildProductosSection() {
    return _buildSection(
      title: 'Productos',
      icon: Icons.inventory_2_outlined,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          // Campo REF
          _buildTextField(
            controller: _formCodigoController,
            label: 'REF',
            icon: Icons.qr_code,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              String upperValue = value.toUpperCase();
              if (_formCodigoController.text != upperValue) {
                _formCodigoController
                    .value = _formCodigoController.value.copyWith(
                  text: upperValue,
                  selection: TextSelection.collapsed(offset: upperValue.length),
                );
              }
              // 👇 DEBOUNCE igual que ProformaOrdenDespachoDeskScreen
              if (_debounceProducto?.isActive ?? false)
                _debounceProducto!.cancel();
              _debounceProducto = Timer(const Duration(milliseconds: 500), () {
                _buscarProductoPorReferencia(upperValue.trim(), -1);
              });
            },
          ),
          SizedBox(height: 12),

          // Campo Descripción
          _buildTextField(
            controller: _formDescripcionController, // CAMBIAR
            label: 'Descripción',
            icon: Icons.description,
          ),
          SizedBox(height: 12),

          // Fila con Cant, Precio Unit, Subtotal
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _formCantidadController, // CAMBIAR
                  label: 'Cant',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  onChanged:
                      (value) => _calcularTotalFormulario(), // Nueva función
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _formPrecioController, // CAMBIAR
                  label: 'Precio Unit',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged:
                      (value) => _calcularTotalFormulario(), // Nueva función
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildTextField(
                  controller: _formTotalController, // CAMBIAR
                  label: 'Subtotal',
                  icon: Icons.calculate,
                  readOnly: true,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Botón Agregar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _agregarItem,
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

  void _calcularTotalFormulario() {
    setState(() {
      double cantidad = double.tryParse(_formCantidadController.text) ?? 0;
      double precio = double.tryParse(_formPrecioController.text) ?? 0;
      double subtotal = cantidad * precio;
      _formTotalController.text = subtotal.toStringAsFixed(2);
    });
  }

  // SECCIÓN LISTA DE PRODUCTOS AGREGADOS
  Widget _buildListaProductosSection() {
    return _buildSection(
      title: 'Lista Productos Agregados',
      icon: Icons.list_alt,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          // Header de la tabla
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

          // AGREGAR ESTA CONDICIÓN:
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
            // Lista de productos (solo si hay items)
            ...items.asMap().entries.map((entry) {
              int index = entry.key;
              ItemProforma item = entry.value;
              return _buildProductRow(index, item);
            }),

          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildProductRow(int index, ItemProforma item) {
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
          // REF
          Expanded(
            flex: 1, // CAMBIAR DE 2 A 1
            child: Text(
              item.codigoController.text,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // DESCRIPCIÓN
          Expanded(
            flex: 4, // CAMBIAR DE 3 A 4
            child: Text(
              item.descripcionController.text,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // CANTIDAD
          Expanded(
            flex: 1, // MANTENER EN 1
            child: Text(
              item.cantidadController.text,
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          // PRECIO
          Expanded(
            flex: 1, // CAMBIAR DE 2 A 1
            child: Text(
              '\$${item.precioController.text}',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.right,
            ),
          ),
          // SUBTOTAL
          Expanded(
            flex: 1, // CAMBIAR DE 1 A 1 (mantener)
            child: Text(
              item.totalController.text, // Sin símbolo $
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
              textAlign: TextAlign.right,
            ),
          ),
          // Botón eliminar - SIEMPRE VISIBLE
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () => _eliminarItem(index),
              icon: Icon(
                Icons.remove_circle_outline,
                color: Colors.red[600], // SIEMPRE rojo, sin condiciones
              ),
              iconSize: 18,
              constraints: BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  // SECCIÓN TOTALES (lado derecho)
  Widget _buildTotalesSection() {
    return _buildSection(
      title: 'Resumen Totales',
      icon: Icons.calculate,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', '\$${_calcularSubtotal()}'),
          SizedBox(height: 12),

          // Campo editable Subtotal 0%
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Subtotal 0%',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 6),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  controller: _subtotalCeroController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  onChanged: (value) => _actualizarTotales(),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.edit,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintText: '0.00',
                  ),
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),

          // Switch para IVA
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

          // Total final
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

  // SECCIÓN CONDICIONES (ancho completo en la parte inferior)
  Widget _buildCondicionesSection() {
    return _buildSection(
      title: 'Condiciones',
      icon: Icons.assignment_outlined,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _validezController,
                  label: 'Validez de la oferta',
                  icon: Icons.schedule,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _saldoController,
                  label: 'Forma de pago',
                  icon: Icons.payment,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _entregaController,
                  label: 'Plazo de entrega',
                  icon: Icons.delivery_dining,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _lugarController,
                  label: 'Lugar de Entrega',
                  icon: Icons.location_on,
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
    IconData? icon,
    bool readOnly = false,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextStyle? style,
    Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        SizedBox(height: 6),
        Container(
          height: maxLines == 1 ? 40 : null,
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[50] : Colors.white,
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
            style:
                style ??
                TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.black : Colors.grey[500],
                ),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon:
                  icon != null
                      ? Icon(icon, size: 18, color: Colors.grey[600])
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: icon != null ? 8 : 12,
                vertical: maxLines == 1 ? 8 : 12,
              ),
            ),
          ),
        ),
      ],
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

  bool _vistaPrevia = false;

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            // Botón Cancelar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide.none,
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

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
                  onPressed: _soloImprimir,
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
            const SizedBox(width: 12),

            // Botón Guardar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _vistaPrevia ? const Color(0xFF4682B4) : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_vistaPrevia
                              ? const Color(0xFF4682B4)
                              : Colors.grey[400]!)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _vistaPrevia ? _guardarEnBaseDatos : null,
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

  Future<void> _buscarProductoPorReferencia(
    String referencia,
    int index,
  ) async {
    referencia = referencia.toUpperCase();

    if (index != -1) {
      while (_isSearchingProduct.length <= index) {
        _isSearchingProduct.add(false);
      }
      while (_productoEncontrado.length <= index) {
        _productoEncontrado.add(false);
      }
      while (_mensajeBusquedaProducto.length <= index) {
        _mensajeBusquedaProducto.add('');
      }
    }

    if (referencia.isEmpty) {
      setState(() {
        if (index == -1) {
          // Es el formulario de entrada
          _formDescripcionController.clear();
          _formPrecioController.clear();
          if (_formCantidadController.text.isNotEmpty) {
            _calcularTotalFormulario();
          }
        } else {
          // Es un item existente en la lista
          _isSearchingProduct[index] = false;
          _productoEncontrado[index] = false;
          _mensajeBusquedaProducto[index] = '';
          items[index].descripcionController.clear();
          items[index].precioController.clear();
          if (items[index].cantidadController.text.isNotEmpty) {
            _calcularTotal(index);
          }
        }
      });
      return;
    }

    setState(() {
      if (index != -1) {
        _isSearchingProduct[index] = true;
        _productoEncontrado[index] = false;
        _mensajeBusquedaProducto[index] = '';
      }
    });

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

        // Leer precio20 y pvp directamente
        if (producto['precio20'] != null && producto['precio20'] > 0) {
          preciosDisponibles.add((producto['precio20']).toDouble());
          nombrePrecios.add('Precio 20%');
        }

        if (producto['pvp'] != null && producto['pvp'] > 0) {
          preciosDisponibles.add((producto['pvp']).toDouble());
          nombrePrecios.add('PVP');
        }

        // Si no tiene ninguno de estos precios, usar precio o costo como fallback
        if (preciosDisponibles.isEmpty) {
          if (producto['precio'] != null && producto['precio'] > 0) {
            preciosDisponibles.add((producto['precio']).toDouble());
            nombrePrecios.add('Precio');
          } else if (producto['costo'] != null && producto['costo'] > 0) {
            preciosDisponibles.add((producto['costo']).toDouble());
            nombrePrecios.add('Costo');
          }
        }

        // Si tiene múltiples precios, mostrar diálogo de selección
        if (preciosDisponibles.length >= 2) {
          double? precioSeleccionado = await _mostrarDialogoSeleccionPrecio(
            producto['nombre'] ?? '',
            preciosDisponibles,
            nombrePrecios,
          );

          if (precioSeleccionado != null) {
            _aplicarDatosProducto(index, producto, precioSeleccionado);
          } else {
            // Si canceló el diálogo, limpiar estado de búsqueda
            setState(() {
              if (index != -1) {
                _isSearchingProduct[index] = false;
                _productoEncontrado[index] = false;
                _mensajeBusquedaProducto[index] = '';
              }
            });
          }
        } else if (preciosDisponibles.isNotEmpty) {
          // Si solo tiene un precio, usarlo directamente
          _aplicarDatosProducto(index, producto, preciosDisponibles[0]);
        } else {
          // Si no tiene ningún precio
          setState(() {
            if (index == -1) {
              _formDescripcionController.text = producto['nombre'] ?? '';
              _formPrecioController.text = '0.00';
            } else {
              _isSearchingProduct[index] = false;
              _productoEncontrado[index] = true;
              _mensajeBusquedaProducto[index] =
                  'Producto encontrado - Sin precio';
              items[index].descripcionController.text =
                  producto['nombre'] ?? '';
              items[index].precioController.text = '0.00';
            }
          });
        }
      } else {
        setState(() {
          if (index == -1) {
            // Es el formulario de entrada
            _formDescripcionController.clear();
            _formPrecioController.clear();
            _formTotalController.clear();
          } else {
            // Es un item existente en la lista
            _isSearchingProduct[index] = false;
            _productoEncontrado[index] = false;
            _mensajeBusquedaProducto[index] = 'Producto no encontrado';

            items[index].descripcionController.clear();
            items[index].precioController.clear();
            items[index].totalController.clear();
          }
        });
      }
    } catch (e) {
      print('Error al buscar producto: $e');
      setState(() {
        if (index == -1) {
          _formDescripcionController.clear();
          _formPrecioController.clear();
          _formTotalController.clear();
        } else {
          _isSearchingProduct[index] = false;
          _productoEncontrado[index] = false;
          _mensajeBusquedaProducto[index] =
              'Error al buscar producto. Verifique la conexión.';

          items[index].descripcionController.clear();
          items[index].precioController.clear();
          items[index].totalController.clear();
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

  Future<double?> _mostrarDialogoSeleccionPrecio(
    String nombreProducto,
    List<double> precios,
    List<String> nombrePrecios,
  ) async {
    return await showDialog<double>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white, // 🔹 Fondo blanco forzado
          title: Text(
            'Seleccionar Precio',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black, // 🔹 Negro
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombreProducto,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // 🔹 Negro
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Seleccione el precio a usar:',
                style: TextStyle(color: Colors.black), // 🔹 Negro
              ),
              SizedBox(height: 12),
              ...List.generate(precios.length, (index) {
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(precios[index]),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white, // 🔹 Fondo blanco
                      foregroundColor: Colors.black, // 🔹 Texto negro
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
                            color: Colors.black, // 🔹 Negro
                          ),
                        ),
                        Text(
                          '\$${precios[index].toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black, // 🔹 Negro
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
                style: TextStyle(color: Colors.grey[700]), // 🔹 Gris
              ),
            ),
          ],
        );
      },
    );
  }

  void _aplicarDatosProducto(
    int index,
    Map<String, dynamic> producto,
    double precio,
  ) {
    setState(() {
      if (index == -1) {
        // Es el formulario de entrada
        _formDescripcionController.text = producto['nombre'] ?? '';
        _formPrecioController.text = precio.toStringAsFixed(2);
        if (_formCantidadController.text.isNotEmpty) {
          _calcularTotalFormulario();
        }
      } else {
        // Es un item existente en la lista
        _isSearchingProduct[index] = false;
        _productoEncontrado[index] = true;
        _mensajeBusquedaProducto[index] = 'Producto encontrado';

        items[index].descripcionController.text = producto['nombre'] ?? '';
        items[index].precioController.text = precio.toStringAsFixed(2);

        if (items[index].cantidadController.text.isNotEmpty) {
          _calcularTotal(index);
        }
      }
    });
  }

  void _agregarItem() {
    // Crear nuevo item con los datos del formulario
    ItemProforma nuevoItem = ItemProforma();
    nuevoItem.codigoController.text = _formCodigoController.text;
    nuevoItem.descripcionController.text = _formDescripcionController.text;
    nuevoItem.cantidadController.text = _formCantidadController.text;
    nuevoItem.precioController.text = _formPrecioController.text;
    nuevoItem.totalController.text = _formTotalController.text;

    setState(() {
      items.add(nuevoItem);
      _isSearchingProduct.add(false);
      _productoEncontrado.add(false);
      _mensajeBusquedaProducto.add('');

      // Limpiar SOLO el formulario
      _formCodigoController.clear();
      _formDescripcionController.clear();
      _formCantidadController.clear();
      _formPrecioController.clear();
      _formTotalController.clear();
    });
  }

  void _eliminarItem(int index) {
    setState(() {
      items.removeAt(index);
      _isSearchingProduct.removeAt(index);
      _productoEncontrado.removeAt(index);
      _mensajeBusquedaProducto.removeAt(index);
    });
  }

  void _calcularTotal(int index) {
    setState(() {
      double cantidad =
          double.tryParse(items[index].cantidadController.text) ?? 0;
      double precio = double.tryParse(items[index].precioController.text) ?? 0;
      double subtotal = (cantidad * precio);
      items[index].totalController.text = subtotal.toStringAsFixed(2);
    });
  }

  String _calcularSubtotal() {
    double subtotal = 0;
    for (var item in items) {
      subtotal += double.tryParse(item.totalController.text) ?? 0;
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
    double subtotalCero = double.tryParse(_subtotalCeroController.text) ?? 0;
    double iva = _aplicarIVA ? double.tryParse(_calcularIVA()) ?? 0 : 0;
    double total = subtotal + subtotalCero + iva;
    return total.toStringAsFixed(2);
  }

  void _actualizarTotales() {
    setState(() {});
  }

  void _soloImprimir() async {
    try {
      final fechaHoy = DateTime.now();
      final fechaFormateada =
          "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

      final counterRef = FirebaseFirestore.instance
          .collection('proformas_ventas_counter')
          .doc(fechaFormateada);

      final counterDoc = await counterRef.get();
      int numero = 1;
      if (counterDoc.exists) {
        numero = counterDoc['contador'] + 1;
      }

      final numeroProformaTemporal = "PROFORMA N-$fechaFormateada-$numero";

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Preparando vista previa para imprimir...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      await PDFGenerator.vistaPrevia(
        numeroProforma: numeroProformaTemporal,
        cliente: _clienteController.text,
        direccion: _direccionController.text,
        ciudad: _ciudadController.text,
        correo: _correoController.text,
        ruc: _rucController.text,
        telefono: _telefonoController.text,
        items: items,
        subtotalCero: _subtotalCeroController.text,
        aplicarIVA: _aplicarIVA,
        validez: _validezController.text,
        saldo: _saldoController.text,
        entrega: _entregaController.text,
        lugar: _lugarController.text, nombreComercial: '',
      );

      // AQUÍ ES DONDE CAMBIA - después de que se cierre la vista previa
      setState(() {
        _vistaPrevia = true;
        _numeroProforma = numeroProformaTemporal;
      });

      // El mensaje aparece DESPUÉS de que el usuario cierre la vista previa
      _mostrarMensajeFlotante();
    } catch (e) {
      print('❌ Error al generar vista previa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al imprimir: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _mostrarMensajeFlotante() {
    // Pequeño delay para asegurar que la vista previa se haya cerrado completamente
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _vistaPrevia) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '⚠️ No olvides de GUARDAR la proforma',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  void _guardarEnBaseDatos() async {
    try {
      // ← MOVER AQUÍ ARRIBA, ANTES DE USARLOS
      final user = FirebaseAuth.instance.currentUser;

      final usuarioDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user?.uid)
              .get();

      final usuarioNombre =
          usuarioDoc.exists
              ? (usuarioDoc['nombre'] ?? 'Desconocido')
              : 'Desconocido';

      final fechaHoy = DateTime.now();
      final fechaFormateada =
          "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

      final counterRef = FirebaseFirestore.instance
          .collection('proformas_ventas_counter')
          .doc(fechaFormateada);

      final counterDoc = await counterRef.get();
      int numero = 1;
      if (counterDoc.exists) {
        numero = counterDoc['contador'] + 1;
        await counterRef.update({'contador': numero});
      } else {
        await counterRef.set({'contador': numero});
      }

      final proformaData = {
        'numero': _numeroProforma,
        'usuario_uid': user?.uid ?? '', // ← ahora sí está declarado
        'usuario_nombre': usuarioNombre, // ← ahora sí está declarado
        'cliente': _clienteController.text,
        'empresa': _nombreComercialController.text,
        'ciudad': _ciudadController.text,
        'direccion': _direccionController.text,
        'correo': _correoController.text,
        'ruc': _rucController.text,
        'telefono': _telefonoController.text,
        'aplicar_iva': _aplicarIVA,
        'items':
            items
                .map(
                  (item) => {
                    'codigo': item.codigoController.text,
                    'descripcion': item.descripcionController.text,
                    'cantidad': item.cantidadController.text,
                    'precio': item.precioController.text,
                    'total': item.totalController.text,
                  },
                )
                .toList(),
        'fecha': Timestamp.now(),
        'subtotal_0': _subtotalCeroController.text,
        'subtotal': _calcularSubtotal(),
        'iva': _calcularIVA(),
        'total_final': _calcularTotalFinal(),
      };

      await FirebaseFirestore.instance
          .collection('proformasventas')
          .add(proformaData);

      final auditoriaRef =
          FirebaseFirestore.instance.collection('auditoria_general').doc();
      await auditoriaRef.set({
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': usuarioNombre,
        'usuario_uid': user?.uid ?? 'uid_desconocido',
        'accion': 'Nueva proforma ventas',
        'detalle': 'Número de proforma: $_numeroProforma',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Proforma guardada correctamente en la base de datos',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    } catch (e) {
      print('❌ Error al guardar proforma: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _debounceNombre?.cancel();
    _debounceProducto?.cancel();
    _nombreFocusNode.dispose();
    super.dispose();
  }
}