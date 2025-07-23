import 'dart:async';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ProformaVentasDeskScreen extends StatefulWidget {
  @override
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
  String _numeroProforma = '';

  Timer? _debounce;

  void _buscarClienteConDebounce(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    setState(() {
      _isSearching = true;
      _clienteEncontrado = false;
      _mensajeBusqueda = '';
    });
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      // Simulación de búsqueda en Firestore
      if (value.isEmpty) {
        setState(() {
          _isSearching = false;
          _clienteEncontrado = false;
          _mensajeBusqueda = '';
          _nombreComercialController.clear();
          _rucController.clear();
          _telefonoController.clear();
        });
        return;
      }
      try {
        var snapshot =
            await FirebaseFirestore.instance
                .collection('clientes')
                .where('nombre', isEqualTo: value)
                .limit(1)
                .get();
        if (snapshot.docs.isNotEmpty) {
          var data = snapshot.docs.first.data();
          setState(() {
            _isSearching = false;
            _clienteEncontrado = true;
            _mensajeBusqueda = 'Cliente encontrado';
            _nombreComercialController.text = data['empresa'] ?? '';
            _rucController.text = data['ruc'] ?? '';
            _telefonoController.text = data['telefono'] ?? '';
          });
        } else {
          setState(() {
            _isSearching = false;
            _clienteEncontrado = false;
            _mensajeBusqueda = 'Cliente no encontrado';
            _nombreComercialController.clear();
            _rucController.clear();
            _telefonoController.clear();
          });
        }
      } catch (e) {
        setState(() {
          _isSearching = false;
          _clienteEncontrado = false;
          _mensajeBusqueda = 'Error al buscar cliente';
          _nombreComercialController.clear();
          _rucController.clear();
          _telefonoController.clear();
        });
      }
    });
  }

  // Controladores para información de envío
  final TextEditingController _transporteController = TextEditingController();
  final TextEditingController _destinoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _transportistaController =
      TextEditingController();

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

  // Imagen del transporte
  File? _transportImage;
  final ImagePicker _picker = ImagePicker();

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
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Proforma de Ventas',
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

          // ✅ CONTENIDO CON FONDO BLANCO
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
                                _buildMobileClienteSection(),
                                const SizedBox(height: 16),
                                _buildMobileEnvioSection(),
                                const SizedBox(height: 16),
                                _buildMobileItemsSection(),
                                const SizedBox(height: 16),
                                _buildMobileTotalesSection(),
                                const SizedBox(height: 16),
                                _buildMobileCondicionesSection(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                        // Action bar dentro del contenido
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: _buildMobileActionBar(),
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
          _numeroProforma,
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

  @override
  void initState() {
    super.initState();
    _previsualizarNumeroProforma();
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
      numero = counterDoc['contador'] + 1; // SOLO LEE, NO ACTUALIZA
    }

    setState(() {
      _numeroProforma = "PROFORMA N-$fechaFormateada-$numero";
    });
  }

  Widget _buildMobileClienteSection() {
    return _buildMobileSection(
      title: 'Cliente',
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
              controller: _clienteController,
              decoration: InputDecoration(
                labelText: 'Buscar Cliente',
                hintText: 'Ingrese el nombre del cliente',
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
          _buildMobileTextField(
            controller: _nombreComercialController,
            label: 'Nombre Comercial',
            icon: Icons.business,
            readOnly: true,
            enabled: _clienteEncontrado,
            fillColor: Colors.grey[50],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMobileTextField(
                  controller: _rucController,
                  label: 'RUC',
                  icon: Icons.receipt_long,
                  readOnly: true,
                  enabled: _clienteEncontrado,
                  fillColor: Colors.grey[50],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMobileTextField(
                  controller: _telefonoController,
                  label: 'Teléfono',
                  icon: Icons.phone,
                  readOnly: true,
                  enabled: _clienteEncontrado,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileEnvioSection() {
    return _buildMobileSection(
      title: 'Envío',
      icon: Icons.local_shipping_outlined,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        'Transporte',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _transporteController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.directions_car,
                            color: Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        'Destino',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _destinoController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        'Fecha de Envío',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _fechaController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate:
                                _fechaController.text.isNotEmpty
                                    ? DateTime.tryParse(
                                          _fechaController.text,
                                        ) ??
                                        DateTime.now()
                                    : DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            _fechaController.text = DateFormat(
                              'yyyy-MM-dd',
                            ).format(pickedDate);
                            setState(() {});
                          }
                        },
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6, left: 4),
                      child: Text(
                        'Transportista',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                    ),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _transportistaController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.person,
                            color: Colors.grey[600],
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          isDense: true,
                        ),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildMobileImageUpload(),
        ],
      ),
    );
  }

  Widget _buildMobileImageUpload() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          if (_transportImage == null) ...[
            Icon(Icons.upload_file, size: 48, color: Colors.grey[400]),
            SizedBox(height: 8),
            Text(
              'Imagen del Transporte',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: Icon(Icons.add_photo_alternate),
              label: Text('Subir Imagen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: FileImage(_transportImage!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                SizedBox(width: 4),
                Text(
                  'Imagen cargada',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _transportImage = null;
                });
              },
              icon: Icon(Icons.delete, size: 16),
              label: Text('Eliminar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileItemsSection() {
    return _buildMobileSection(
      title: 'Items (${items.length})',
      icon: Icons.list_alt,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Productos y servicios',
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
            ItemProforma item = entry.value;
            return _buildMobileItemCard(index, item);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMobileItemCard(int index, ItemProforma item) {
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
          // Header del item
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

          // Contenido del item
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                // Código y Descripción
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: _buildItemInputField(
                        controller: item.codigoController,
                        label: 'Código',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: _buildItemInputField(
                        controller: item.descripcionController,
                        label: 'Descripción',
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                // Cantidad, Precio y Total
                Row(
                  children: [
                    Expanded(
                      child: _buildItemInputField(
                        controller: item.cantidadController,
                        label: 'Cant.',
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _calcularTotal(index),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildItemInputField(
                        controller: item.precioController,
                        label: 'Precio',
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (value) => _calcularTotal(index),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildItemInputField(
                        controller: item.totalController,
                        label: 'Total',
                        readOnly: true,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
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

  Widget _buildItemInputField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    TextStyle? style,
    Function(String)? onChanged,
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

  Widget _buildMobileTotalesSection() {
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

          // Subtotal (calculado automáticamente de los items)
          _buildTotalRow('Subtotal:', '\$${_calcularSubtotal()}', large: false),
          SizedBox(height: 12),

          // Subtotal 0% (editable por el usuario)
          _buildSubtotalCeroField(),
          SizedBox(height: 12),

          // IVA (15% SOLO del subtotal, no del subtotal 0%)
          _buildTotalRow('IVA (15%):', '\$${_calcularIVA()}', large: false),
          Divider(height: 1, color: Colors.grey[300]),

          // Total final
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: _buildTotalRow(
              'TOTAL FINAL:',
              '\$${_calcularTotalFinal()}',
              bold: true,
              large: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCondicionesSection() {
    return _buildMobileSection(
      title: 'Condiciones',
      icon: Icons.assignment_outlined,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          _buildStyledTextField(
            controller: _validezController,
            label: 'Validez de la Oferta',
            icon: Icons.schedule,
          ),
          SizedBox(height: 12),
          _buildStyledTextField(
            controller: _saldoController,
            label: 'Forma de Pago',
            icon: Icons.payment,
            maxLines: 2,
          ),
          SizedBox(height: 12),
          _buildStyledTextField(
            controller: _entregaController,
            label: 'Plazo de Entrega',
            icon: Icons.delivery_dining,
          ),
          SizedBox(height: 12),
          _buildStyledTextField(
            controller: _lugarController,
            label: 'Lugar de Entrega',
            icon: Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 6),
        Container(
          height: maxLines == 1 ? 48 : null,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              prefixIcon:
                  icon != null ? Icon(icon, color: Colors.grey[600]) : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionBar() {
    return Padding(
      padding: const EdgeInsets.all(
        16,
      ), // Margen para que no pegue a los bordes
      child: SafeArea(
        child: Row(
          children: [
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
                  onPressed: _vistaPrevia,
                  child: const Text('Vista previa'),
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
                  child: const Text('Opciones'),
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

  Widget _buildMobileSection({
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

  Widget _buildMobileTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    bool enabled = true,
    bool compact = false,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextStyle? style,
    Function(String)? onChanged,
    Color? fillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compact) ...[
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: enabled ? Colors.grey[700] : Colors.grey[400],
            ),
          ),
          SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style:
                style ??
                TextStyle(
                  fontSize: compact ? 12 : 14,
                  color: enabled ? Colors.black : Colors.grey[500],
                ),
            onChanged: onChanged,
            decoration: InputDecoration(
              labelText: compact ? label : null,
              labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
              prefixIcon:
                  icon != null
                      ? Icon(icon, size: 18, color: Colors.grey[600])
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: icon != null ? 8 : 12,
                vertical: compact ? 10 : 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(
    String label,
    String value, {
    bool bold = false,
    required bool large,
  }) {
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

  void _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _transportImage = File(image.path);
      });
    }
  }

  void _agregarItem() {
    setState(() {
      items.add(ItemProforma());
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
      double precio = double.tryParse(items[index].precioController.text) ?? 0;
      double total = cantidad * precio;
      items[index].totalController.text = total.toStringAsFixed(2);
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
    // El IVA se calcula SOLO del subtotal (items), NO del subtotal 0%
    double subtotal = double.tryParse(_calcularSubtotal()) ?? 0;
    double iva = subtotal * 0.15;
    return iva.toStringAsFixed(2);
  }

  String _calcularTotalFinal() {
    double subtotal = double.tryParse(_calcularSubtotal()) ?? 0;
    double subtotalCero = double.tryParse(_subtotalCeroController.text) ?? 0;
    double iva = double.tryParse(_calcularIVA()) ?? 0;

    // Total = Subtotal + Subtotal 0% + IVA (donde IVA = 15% del subtotal únicamente)
    double total = subtotal + subtotalCero + iva;
    return total.toStringAsFixed(2);
  }

  void _actualizarTotales() {
    setState(() {});
  }

  Widget _buildSubtotalCeroField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subtotal 0%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextField(
            controller: _subtotalCeroController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              // Actualiza los totales cuando cambia el subtotal 0%
              _actualizarTotales();
            },
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.edit, color: Colors.grey[600]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: '0.00',
              hintStyle: TextStyle(color: Colors.grey[400]),
            ),
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }

  void _vistaPrevia() async {
    // Generar el PDF y mostrarlo en vista previa
    final pdf = await _generarPDF();
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  Future<pw.Document> _generarPDF() async {
    final pdf = pw.Document();

    // Convertir imagen del transporte a formato PDF si existe
    pw.ImageProvider? transportImageProvider;
    if (_transportImage != null) {
      final imageBytes = await _transportImage!.readAsBytes();
      transportImageProvider = pw.MemoryImage(imageBytes);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPDFHeader(),
                    pw.SizedBox(height: 10),
                    _buildPDFClienteInfo(),
                    pw.SizedBox(height: 10),
                    _buildPDFEnvioInfo(),
                    pw.SizedBox(height: 10),
                    _buildPDFItemsTable(),
                    pw.SizedBox(height: 10),
                    _buildPDFTotales(),
                    pw.SizedBox(height: 10),
                    _buildPDFCondiciones(),
                  ],
                ),
              ),

              // Imagen del comprobante SIEMPRE al final
              if (transportImageProvider != null) ...[
                pw.SizedBox(height: 20),
                pw.Text(
                  'COMPROBANTE',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildPDFComprobante(transportImageProvider),
              ],
            ],
          );
        },
      ),
    );

    return pdf;
  }

  pw.Widget _buildPDFHeader() {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(8), // antes 12
            color: PdfColor.fromHex('#4682B4'),
            child: pw.Text(
              'COTIZACIÓN',
              style: pw.TextStyle(
                color: PdfColors.white,
                fontSize: 14, // antes 18
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.all(6), // antes 8
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Column(
              children: [
                pw.Text(
                  'FUNDIMETALES DEL NORTE',
                  style: pw.TextStyle(
                    fontSize: 10, // antes 14
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2), // antes 4
                pw.Text(_numeroProforma, style: pw.TextStyle(fontSize: 8)),
                pw.Text(
                  'Dirección: Av Brasil y Panamá - (Tulcán Ecuador) - telf: 2962017',
                  style: pw.TextStyle(fontSize: 7), // antes 9
                ),
                pw.Text(
                  'Fecha: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: pw.TextStyle(fontSize: 7), // antes 9
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFClienteInfo() {
    return pw.Container(
      padding: pw.EdgeInsets.all(6), // antes 8
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DEL CLIENTE',
            style: pw.TextStyle(
              fontSize: 7, // antes 12
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3), // antes 5
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Cliente: ${_clienteController.text}',
                      style: pw.TextStyle(fontSize: 7), // antes 9
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'RUC: ${_rucController.text}',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Nombre Comercial: ${_nombreComercialController.text}',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Teléfono: ${_telefonoController.text}',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFEnvioInfo() {
    return pw.Container(
      padding: pw.EdgeInsets.all(6), // antes 8
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMACIÓN DE ENVÍO',
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 3),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Transporte: ${_transporteController.text}',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Fecha de Envío: ${_fechaController.text}',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Destino: ${_destinoController.text}',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Transportista: ${_transportistaController.text}',
                      style: pw.TextStyle(fontSize: 7),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPDFItemsTable() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.all(4), // antes 6
            color: PdfColor.fromHex('#f8f9fa'),
            child: pw.Row(
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'CÓDIGO',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    'DESCRIPCIÓN',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'CANT.',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'P. UNIT',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    'TOTAL',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...items.map(
            (item) => pw.Container(
              padding: pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300),
                ),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.codigoController.text,
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 4,
                    child: pw.Text(
                      item.descripcionController.text,
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      item.cantidadController.text,
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.precioController.text}',
                      style: pw.TextStyle(fontSize: 6),
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      '\$${item.totalController.text}',
                      style: pw.TextStyle(fontSize: 6),
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

  pw.Widget _buildPDFTotales() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 140, // más estrecho aún
          padding: pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(
                    '\$${_calcularSubtotal()}',
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal 0%:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text('\$5.00', style: pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('(+) 15% IVA:', style: pw.TextStyle(fontSize: 7)),
                  pw.Text(
                    '\$${_calcularIVA()}',
                    style: pw.TextStyle(fontSize: 7),
                  ),
                ],
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                padding: pw.EdgeInsets.symmetric(vertical: 2),
                color: PdfColor.fromHex('#fff3cd'),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL:',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '\$${_calcularTotalFinal()}',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPDFCondiciones() {
    return pw.Center(
      child: pw.Container(
        padding: pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        width: 350,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              'CONDICIONES GENERALES DE LA OFERTA',
              style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Validez de la oferta: ${_validezController.text}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Forma de pago: ${_saldoController.text}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Plazo de entrega: ${_entregaController.text}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Lugar de entrega: ${_lugarController.text}',
                        style: pw.TextStyle(fontSize: 7),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPDFComprobante(pw.ImageProvider? transportImageProvider) {
    if (transportImageProvider == null) {
      return pw.Container();
    }
    return pw.Center(
      child: pw.Container(
        width: double.infinity,
        height: 250,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Image(
          transportImageProvider,
          fit: pw.BoxFit.contain,
          alignment: pw.Alignment.center,
        ),
      ),
    );
  }

  void _mostrarOpcionesGuardar() async {
    // Generar el PDF una sola vez
    final pdf = await _generarPDF();
    final pdfBytes = await pdf.save();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Qué deseas hacer?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        // 👉 1. Generar y reservar número real de proforma (incrementar contador aquí)
                        final fechaHoy = DateTime.now();
                        final fechaFormateada =
                            "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

                        final counterRef = FirebaseFirestore.instance
                            .collection('proformas_counters')
                            .doc(fechaFormateada);

                        final counterDoc = await counterRef.get();

                        int numero = 1;
                        if (counterDoc.exists) {
                          numero = counterDoc['contador'] + 1;
                          await counterRef.update({'contador': numero});
                        } else {
                          await counterRef.set({'contador': numero});
                        }

                        final numeroProformaFinal =
                            "PROFORMA N-$fechaFormateada-$numero";

                        print(
                          '✅ Número de proforma reservado: $numeroProformaFinal',
                        );

                        // 👉 2. Preparar datos SIN PDF
                        final proformaData = {
                          'numero': numeroProformaFinal,
                          'cliente': _clienteController.text,
                          'ruc': _rucController.text,
                          'telefono': _telefonoController.text,
                          'items':
                              items
                                  .map(
                                    (item) => {
                                      'codigo': item.codigoController.text,
                                      'descripcion':
                                          item.descripcionController.text,
                                      'cantidad': item.cantidadController.text,
                                      'precio': item.precioController.text,
                                      'total': item.totalController.text,
                                    },
                                  )
                                  .toList(),
                          'fecha': Timestamp.now(),
                        };

                        // 👉 3. Guardar en Firestore
                        await FirebaseFirestore.instance
                            .collection('proformas')
                            .add(proformaData);

                        print(
                          '✅ Proforma guardada en Firestore: $numeroProformaFinal',
                        );

                        // 👉 4. Limpiar campos
                        _clienteController.clear();
                        _rucController.clear();
                        _telefonoController.clear();
                        _validezController.clear();
                        _saldoController.clear();
                        _entregaController.clear();
                        _lugarController.clear();
                        items.clear();

                        setState(() {});

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Proforma guardada correctamente'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        print('❌ Error al guardar proforma: $e');
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '❌ Error al guardar: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    },

                    icon: const Icon(Icons.save),
                    label: const Text('Guardar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4682B4),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      await Printing.sharePdf(
                        bytes: pdfBytes,
                        filename:
                            'proforma_${DateTime.now().millisecondsSinceEpoch}.pdf',
                      );
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Compartir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4682B4),
                      foregroundColor: Colors.white,
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
}

class ItemProforma {
  final TextEditingController codigoController = TextEditingController();
  final TextEditingController descripcionController = TextEditingController();
  final TextEditingController cantidadController = TextEditingController();
  final TextEditingController precioController = TextEditingController();
  final TextEditingController totalController = TextEditingController();

  void dispose() {
    codigoController.dispose();
    descripcionController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    totalController.dispose();
  }
}
