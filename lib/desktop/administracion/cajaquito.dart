import 'package:basefundi/services/navbar_desk.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CajaScreen extends StatefulWidget {
  const CajaScreen({super.key});

  @override
  State<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends State<CajaScreen> {
  String _sedaSeleccionada = 'Quito';
  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now();

  double _totalVentas = 0.0;
  int _cantidadTransacciones = 0;
  Map<String, double> _productosVendidos = {};
  List<Map<String, dynamic>> _ventasDetalladas = [];
  bool _cargando = true;
  String _mensajeError = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _cargando = true;
      _mensajeError = '';
      _totalVentas = 0.0;
      _cantidadTransacciones = 0;
      _productosVendidos = {};
      _ventasDetalladas = [];
    });

    try {
      print('🔍 Buscando proformas con sede: $_sedaSeleccionada');
      print(
        '📅 Rango: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)} - ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
      );

      final query = FirebaseFirestore.instance
          .collection('proformas')
          .where('sede_origen', isEqualTo: _sedaSeleccionada);

      final snapshotProformas = await query.get();

      print('✅ Documentos encontrados: ${snapshotProformas.docs.length}');

      double totalVentas = 0.0;
      Map<String, double> productosVendidos = {};
      List<Map<String, dynamic>> ventasDetalladas = [];

      final inicioDelDia = DateTime(
        _fechaInicio.year,
        _fechaInicio.month,
        _fechaInicio.day,
      );
      final finDelDia = DateTime(
        _fechaFin.year,
        _fechaFin.month,
        _fechaFin.day,
        23,
        59,
        59,
      );

      for (var doc in snapshotProformas.docs) {
        final data = doc.data();

        final fecha = data['fecha'] as Timestamp?;
        if (fecha == null) continue;

        final fechaDoc = fecha.toDate();

        if (fechaDoc.isBefore(inicioDelDia) || fechaDoc.isAfter(finDelDia)) {
          continue;
        }

        final totalStr =
            (data['total'] ?? '0')
                .toString()
                .replaceAll('\$', '')
                .replaceAll(',', '')
                .trim();
        final total = double.tryParse(totalStr) ?? 0.0;

        print('📄 Proforma ${data['numero']}: \$$total');

        totalVentas += total;

        final numeroProforma = data['numero']?.toString() ?? 'N/A';
        final numeroOrden = data['numero_orden']?.toString() ?? 'N/A';
        final cliente = data['cliente'] ?? 'Sin cliente';

        if (data['items'] != null && data['items'] is List) {
          final items = List.from(data['items']);

          for (var item in items) {
            final ref = item['ref'] ?? 'Sin referencia';

            final cantidadStr =
                (item['cantidad'] ?? '0')
                    .toString()
                    .replaceAll(',', '.')
                    .trim();
            final cantidad = double.tryParse(cantidadStr) ?? 0.0;

            productosVendidos[ref] = (productosVendidos[ref] ?? 0) + cantidad;

            ventasDetalladas.add({
              'referencia': ref,
              'cantidad': cantidad,
              'numeroProforma': numeroProforma,
              'numeroOrden': numeroOrden,
              'cliente': cliente,
              'total': total,
              'descripcion': item['descripcion'] ?? '',
            });
          }
        }
      }

      print('💰 Total calculado: \$$totalVentas');
      print('📊 Productos únicos: ${productosVendidos.length}');
      print('📋 Ventas detalladas: ${ventasDetalladas.length}');

      setState(() {
        _totalVentas = totalVentas;
        _cantidadTransacciones =
            snapshotProformas.docs.where((doc) {
              final fecha = doc['fecha'] as Timestamp?;
              if (fecha == null) return false;
              final fechaDoc = fecha.toDate();
              final inicioDelDia = DateTime(
                _fechaInicio.year,
                _fechaInicio.month,
                _fechaInicio.day,
              );
              final finDelDia = DateTime(
                _fechaFin.year,
                _fechaFin.month,
                _fechaFin.day,
                23,
                59,
                59,
              );
              return !fechaDoc.isBefore(inicioDelDia) &&
                  !fechaDoc.isAfter(finDelDia);
            }).length;
        _productosVendidos = productosVendidos;
        _ventasDetalladas = ventasDetalladas;
        _cargando = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _mensajeError = 'Error: ${e.toString()}';
        _cargando = false;
      });
    }
  }

  void _cambiarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: esInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
      _cargarDatos();
    }
  }

  void _cambiarSede(String nuevaSede) {
    setState(() {
      _sedaSeleccionada = nuevaSede;
    });
    _cargarDatos();
  }

  Widget _buildHeader() {
    return Transform.translate(
      offset: const Offset(
        -0.5,
        0,
      ), // Puedes ajustar el offset según sea necesario
      child: Container(
        width: double.infinity,
        color: const Color(
          0xFF2C3E50,
        ), // Cambié el color de fondo a uno similar al segundo diseño
        padding: const EdgeInsets.symmetric(
          horizontal: 64,
          vertical: 38,
        ), // Ajusté el padding para mayor simetría
        child: Stack(
          children: [
            // Icono de regreso
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            // Título centrado
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Caja', // El texto que deseas mostrar
                style: TextStyle(
                  color: Colors.white,
                  fontSize:
                      24, // Aumenté el tamaño de la fuente para que coincida más con el estilo
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorSede() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _sedaSeleccionada != 'Quito'
                      ? () => _cambiarSede('Quito')
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _sedaSeleccionada == 'Quito'
                        ? const Color(0xFF4682B4)
                        : Colors.grey[300],
                foregroundColor:
                    _sedaSeleccionada == 'Quito' ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Quito'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  _sedaSeleccionada != 'Guayaquil'
                      ? () => _cambiarSede('Guayaquil')
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _sedaSeleccionada == 'Guayaquil'
                        ? const Color(0xFF4682B4)
                        : Colors.grey[300],
                foregroundColor:
                    _sedaSeleccionada == 'Guayaquil'
                        ? Colors.white
                        : Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Guayaquil'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroFechas() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.grey[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _cambiarFecha(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(
                  'Desde: ${DateFormat('dd/MM/yyyy').format(_fechaInicio)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _cambiarFecha(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(
                  'Hasta: ${DateFormat('dd/MM/yyyy').format(_fechaFin)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _cargarDatos,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF4682B4),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    return Transform.translate(
      offset: const Offset(0, 0),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF4682B4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.summarize, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Resumen del Período',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildResumenItem(
                    icon: Icons.attach_money,
                    titulo: 'Total de Ventas',
                    valor: '\$${_totalVentas.toStringAsFixed(2)}',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildResumenItem(
                    icon: Icons.receipt,
                    titulo: 'Cantidad de Proformas',
                    valor: '$_cantidadTransacciones',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildResumenItem(
                    icon: Icons.inventory,
                    titulo: 'Total de Productos Vendidos',
                    valor:
                        '${_productosVendidos.values.fold(0.0, (prev, element) => prev + element).toInt()}',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosVendidosList() {
    if (_productosVendidos.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Sin ventas en este período',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final productosOrdenados =
        _productosVendidos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Transform.translate(
      offset: const Offset(0, 0),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF4682B4),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_cart,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Productos Vendidos (${productosOrdenados.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(color: Colors.grey[100]),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'REFERENCIA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'CANTIDAD',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
            ...productosOrdenados.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == productosOrdenados.length - 1;

              final detallesRef =
                  _ventasDetalladas
                      .where((v) => v['referencia'] == item.key)
                      .toList();

              return GestureDetector(
                onTap: () {
                  _mostrarDetallesProducto(item.key, detallesRef);
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom:
                          isLast
                              ? BorderSide.none
                              : BorderSide(color: Colors.grey[200]!),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.key,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${detallesRef.length} venta${detallesRef.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.value.toInt()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _mostrarDetallesProducto(
    String referencia,
    List<Map<String, dynamic>> detalles,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Referencia: $referencia',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${detalles.length} venta${detalles.length > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: detalles.length,
                  itemBuilder: (context, index) {
                    final detalle = detalles[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Proforma: ${detalle['numeroProforma']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              if (detalle['numeroOrden'] != 'N/A')
                                Text(
                                  'Orden: ${detalle['numeroOrden']}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Cliente: ${detalle['cliente']}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cantidad: ${detalle['cantidad'].toInt()}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue[700],
                                ),
                              ),
                              Text(
                                'Total: \$${detalle['total'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSelectorSede(),
                      const SizedBox(height: 8),
                      _buildFiltroFechas(),
                      const SizedBox(height: 12),
                      _cargando
                          ? const Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(
                              color: Color(0xFF4682B4),
                            ),
                          )
                          : _mensajeError.isNotEmpty
                          ? Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error, color: Colors.red[600]),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _mensajeError,
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Column(
                            children: [
                              _buildResumenCard(),
                              const SizedBox(height: 8),
                              _buildProductosVendidosList(),
                              const SizedBox(height: 24),
                            ],
                          ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
