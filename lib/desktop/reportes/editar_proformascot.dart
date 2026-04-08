import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODELO DE ITEM EDITABLE
// ─────────────────────────────────────────────────────────────────────────────
class ItemEditable {
  final TextEditingController codigoController;
  final TextEditingController descripcionController;
  final TextEditingController cantidadController;
  final TextEditingController precioController;
  final TextEditingController totalController;

  ItemEditable({
    String codigo = '',
    String descripcion = '',
    String cantidad = '',
    String precio = '',
    String total = '',
  }) : codigoController = TextEditingController(text: codigo),
       descripcionController = TextEditingController(text: descripcion),
       cantidadController = TextEditingController(text: cantidad),
       precioController = TextEditingController(text: precio),
       totalController = TextEditingController(text: total);

  void dispose() {
    codigoController.dispose();
    descripcionController.dispose();
    cantidadController.dispose();
    precioController.dispose();
    totalController.dispose();
  }

  Map<String, dynamic> toMap() => {
    'codigo': codigoController.text,
    'descripcion': descripcionController.text,
    'cantidad': cantidadController.text,
    'precio': precioController.text,
    'total': totalController.text,
  };
  // En la clase ItemEditable, agregar este método:
  Map<String, dynamic> toMapProformas() => {
    'ref': codigoController.text, // 👈 nombre correcto
    'descripcion': descripcionController.text,
    'cantidad': cantidadController.text,
    'v_unit': precioController.text, // 👈 nombre correcto
    'v_total': totalController.text, // 👈 nombre correcto
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER ESTÁTICO PARA ABRIR EL EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class EditarProformaVentas {
  /// Abre el editor como Dialog (desk/web) o BottomSheet (móvil).
  /// [proforma] debe ser el Map completo del documento Firestore.
  /// [docId] es el ID del documento en Firestore.
  static Future<void> mostrar(
    BuildContext context,
    Map<String, dynamic> proforma,
    String docId, {
    bool esMobil = false,
    bool descontarInventario = true, // 👈 AGREGAR
    String coleccion = 'proformasventas',
  }) async {
    if (esMobil) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (_) => _EditarProformaWidget(
              proforma: proforma,
              docId: docId,
              esMobil: true,
              descontarInventario: descontarInventario, // 👈
              coleccion: coleccion,
            ),
      );
    } else {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: _EditarProformaWidget(
                proforma: proforma,
                docId: docId,
                esMobil: false,
                descontarInventario: descontarInventario, // 👈
                coleccion: coleccion,
              ),
            ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET PRINCIPAL DEL EDITOR
// ─────────────────────────────────────────────────────────────────────────────
class _EditarProformaWidget extends StatefulWidget {
  final Map<String, dynamic> proforma;
  final String docId;
  final bool esMobil;
  final bool descontarInventario; // 👈 AGREGAR
  final String coleccion; // 👈 AGREGAR

  const _EditarProformaWidget({
    required this.proforma,
    required this.docId,
    required this.esMobil,
    required this.descontarInventario, // 👈 AGREGAR
    required this.coleccion, // 👈 AGREGAR
  });

  @override
  State<_EditarProformaWidget> createState() => _EditarProformaWidgetState();
}

class _EditarProformaWidgetState extends State<_EditarProformaWidget> {
  late List<ItemEditable> _items;
  late bool _aplicarIVA;
  bool _guardando = false;
  Timer? _debounceProducto;

  // Controladores de búsqueda de nuevo ítem
  final TextEditingController _newCodigoCtrl = TextEditingController();
  final TextEditingController _newDescCtrl = TextEditingController();
  final TextEditingController _newCantCtrl = TextEditingController();
  final TextEditingController _newPrecioCtrl = TextEditingController();
  final TextEditingController _newTotalCtrl = TextEditingController();
  late List<Map<String, dynamic>> _itemsOriginales;

  @override
  void initState() {
    super.initState();
    _aplicarIVA = widget.proforma['aplicar_iva'] ?? false;

    final rawItems = widget.proforma['items'] as List<dynamic>? ?? [];
    // DESPUÉS
    final esProformas = widget.coleccion == 'proformas';

    _itemsOriginales =
        rawItems
            .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
            .toList();

    _items =
        rawItems.map((e) {
          final m = e as Map<String, dynamic>;
          return ItemEditable(
            codigo:
                esProformas
                    ? m['ref']?.toString() ??
                        '' // 👈 proformas usa 'ref'
                    : m['codigo']?.toString() ?? '',
            descripcion: m['descripcion']?.toString() ?? '',
            cantidad: m['cantidad']?.toString() ?? '',
            precio:
                esProformas
                    ? m['v_unit']?.toString() ??
                        '' // 👈 proformas usa 'v_unit'
                    : m['precio']?.toString() ?? '',
            total:
                esProformas
                    ? m['v_total']?.toString() ??
                        '' // 👈 proformas usa 'v_total'
                    : m['total']?.toString() ?? '',
          );
        }).toList();
  }

  @override
  void dispose() {
    for (final item in _items) {
      item.dispose();
    }
    _newCodigoCtrl.dispose();
    _newDescCtrl.dispose();
    _newCantCtrl.dispose();
    _newPrecioCtrl.dispose();
    _newTotalCtrl.dispose();
    _debounceProducto?.cancel();
    super.dispose();
  }

  // ── Cálculos ────────────────────────────────────────────────────────────────
  void _recalcularItem(int index) {
    final cant = double.tryParse(_items[index].cantidadController.text) ?? 0;
    final precio = double.tryParse(_items[index].precioController.text) ?? 0;
    _items[index].totalController.text = (cant * precio).toStringAsFixed(2);
    setState(() {});
  }

  void _recalcularNuevoItem() {
    final cant = double.tryParse(_newCantCtrl.text) ?? 0;
    final precio = double.tryParse(_newPrecioCtrl.text) ?? 0;
    _newTotalCtrl.text = (cant * precio).toStringAsFixed(2);
    setState(() {});
  }

  double get _subtotal {
    return _items.fold(0, (sum, item) {
      return sum + (double.tryParse(item.totalController.text) ?? 0);
    });
  }

  double get _iva => _aplicarIVA ? _subtotal * 0.15 : 0;
  double get _totalFinal => _subtotal + _iva;

  // ── Búsqueda de producto por referencia ────────────────────────────────────
  Future<void> _buscarProducto(String referencia, {int itemIndex = -1}) async {
    referencia = referencia.trim().toUpperCase();
    if (referencia.isEmpty) return;

    try {
      final snap =
          await FirebaseFirestore.instance
              .collection('productos')
              .where('referencia', isEqualTo: referencia)
              .limit(1)
              .get();

      if (snap.docs.isEmpty) {
        _showSnack('Producto no encontrado', color: Colors.orange);
        return;
      }

      final data = snap.docs.first.data();

      // Recolectar precios disponibles
      final List<double> precios = [];
      final List<String> nombres = [];

      if ((data['precio20'] ?? 0) > 0) {
        precios.add((data['precio20'] as num).toDouble());
        nombres.add('Precio 20%');
      }
      if ((data['pvp'] ?? 0) > 0) {
        precios.add((data['pvp'] as num).toDouble());
        nombres.add('PVP');
      }
      if (precios.isEmpty && (data['precio'] ?? 0) > 0) {
        precios.add((data['precio'] as num).toDouble());
        nombres.add('Precio');
      }

      double? precioElegido;
      if (precios.length >= 2) {
        precioElegido = await _dialogoSeleccionPrecio(
          data['nombre'] ?? '',
          precios,
          nombres,
        );
        if (precioElegido == null) return;
      } else if (precios.isNotEmpty) {
        precioElegido = precios.first;
      } else {
        precioElegido = 0;
      }

      setState(() {
        if (itemIndex == -1) {
          // Nuevo ítem
          _newDescCtrl.text = data['nombre'] ?? '';
          _newPrecioCtrl.text = precioElegido!.toStringAsFixed(2);
          _recalcularNuevoItem();
        } else {
          // Ítem existente
          _items[itemIndex].descripcionController.text = data['nombre'] ?? '';
          _items[itemIndex].precioController.text = precioElegido!
              .toStringAsFixed(2);
          _recalcularItem(itemIndex);
        }
      });
    } catch (e) {
      _showSnack('Error al buscar producto', color: Colors.red);
    }
  }

  Future<double?> _dialogoSeleccionPrecio(
    String nombre,
    List<double> precios,
    List<String> nombres,
  ) async {
    return showDialog<double>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              'Seleccionar Precio',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...List.generate(
                  precios.length,
                  (i) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(precios[i]),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF4682B4)),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nombres[i],
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '\$${precios[i].toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
    );
  }

  // ── Agregar ítem nuevo ──────────────────────────────────────────────────────
  void _agregarItem() {
    if (_newDescCtrl.text.trim().isEmpty &&
        _newCodigoCtrl.text.trim().isEmpty) {
      _showSnack('Ingrese al menos código o descripción', color: Colors.orange);
      return;
    }
    setState(() {
      _items.add(
        ItemEditable(
          codigo: _newCodigoCtrl.text,
          descripcion: _newDescCtrl.text,
          cantidad: _newCantCtrl.text,
          precio: _newPrecioCtrl.text,
          total: _newTotalCtrl.text,
        ),
      );
      _newCodigoCtrl.clear();
      _newDescCtrl.clear();
      _newCantCtrl.clear();
      _newPrecioCtrl.clear();
      _newTotalCtrl.clear();
    });
  }

  Future<void> _actualizarOrden() async {
    try {
      final numeroProforma = widget.proforma['numero']?.toString();
      if (numeroProforma == null || numeroProforma.isEmpty) return;

      // Buscar la orden vinculada a esta proforma
      final snap =
          await FirebaseFirestore.instance
              .collection('ordenes_despacho')
              .where('numero_proforma', isEqualTo: numeroProforma)
              .limit(1)
              .get();

      if (snap.docs.isEmpty) {
        print('⚠️ No se encontró orden para la proforma: $numeroProforma');
        return;
      }

      final docOrden = snap.docs.first;

      // Mapear los items al formato de la orden (ref, descripcion, cantidad)
      final itemsOrden =
          _items
              .map(
                (item) => {
                  'ref': item.codigoController.text,
                  'descripcion': item.descripcionController.text,
                  'cantidad': item.cantidadController.text,
                },
              )
              .toList();

      await docOrden.reference.update({'items': itemsOrden});

      print('✅ Orden ${docOrden['numero']} actualizada correctamente');
    } catch (e) {
      print('Error actualizando orden: $e');
      // No lanzamos el error para que no interrumpa el flujo principal
    }
  }

  // ── Guardar en Firestore ───────────────────────────────────────────────────
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      // 👇 Solo si corresponde
      if (widget.descontarInventario) {
        await _procesarDevolucionesInventario(_itemsOriginales);
      }

      // Para proformas
      if (widget.coleccion == 'proformas') {
        await FirebaseFirestore.instance
            .collection('proformas')
            .doc(widget.docId)
            .update({
              'items': _items.map((i) => i.toMapProformas()).toList(),
              'subtotal': _subtotal.toStringAsFixed(2),
              'iva': _iva.toStringAsFixed(2),
              'total': _totalFinal.toStringAsFixed(2),
            });
        await _actualizarOrden();
        
        // ✅ AGREGADO: cerrar modal y mostrar snackbar
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Cotización actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirebaseFirestore.instance
            .collection('proformasventas')
            .doc(widget.docId)
            .update({
              'items': _items.map((i) => i.toMap()).toList(),
              'subtotal': _subtotal.toStringAsFixed(2),
              'subtotal_0': '0.00',
              'iva': _iva.toStringAsFixed(2),
              'total_final': _totalFinal.toStringAsFixed(2),
              'aplicar_iva': _aplicarIVA,
            });

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Proforma actualizada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      _showSnack('Error al guardar: $e', color: Colors.red);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Procesa las devoluciones al inventario cuando se reducen cantidades
  Future<void> _procesarDevolucionesInventario(
    List<dynamic> itemsAnteriores,
  ) async {
    try {
      // Crear mapa de items anteriores para fácil búsqueda
      Map<String, double> cantidadesAnteriores = {};
      for (var item in itemsAnteriores) {
        final m = item as Map<String, dynamic>;
        final codigo = m['codigo']?.toString() ?? '';
        final cantidad = double.tryParse(m['cantidad']?.toString() ?? '0') ?? 0;
        cantidadesAnteriores[codigo] = cantidad;
      }

      // Comparar con items actuales
      for (var itemActual in _items) {
        final codigo = itemActual.codigoController.text.trim();
        if (codigo.isEmpty) continue;

        final cantidadAnterior = cantidadesAnteriores[codigo] ?? 0;
        final cantidadActual =
            double.tryParse(itemActual.cantidadController.text) ?? 0;

        // Si la cantidad se redujo, devolver la diferencia al inventario
        if (cantidadActual < cantidadAnterior) {
          final cantidadADevolver = cantidadAnterior - cantidadActual;

          print(
            '📦 Devolviendo $cantidadADevolver unidades del código: $codigo',
          );

          // Buscar el producto en inventario
          final snapProducto =
              await FirebaseFirestore.instance
                  .collection('productos')
                  .where('referencia', isEqualTo: codigo)
                  .limit(1)
                  .get();

          if (snapProducto.docs.isNotEmpty) {
            final docProducto = snapProducto.docs.first;
            final dataProducto = docProducto.data();

            // Obtener cantidad actual en inventario
            final cantidadActualInventario =
                double.tryParse(dataProducto['cantidad']?.toString() ?? '0') ??
                0;

            // Sumar la cantidad devuelta
            final cantidadNuevaInventario =
                cantidadActualInventario + cantidadADevolver;

            // Actualizar inventario
            await docProducto.reference.update({
              'cantidad': cantidadNuevaInventario.toString(),
            });

            print(
              '✅ Inventario actualizado: $codigo ahora tiene $cantidadNuevaInventario unidades',
            );
          } else {
            print('⚠️ Producto no encontrado: $codigo');
          }
        }
      }
    } catch (e) {
      print('Error procesando devoluciones: $e');
      // No lanzar error, solo registrar
    }
  }

  void _showSnack(String msg, {Color color = Colors.green}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return widget.esMobil ? _buildMobil() : _buildDesk();
  }

  // ── VERSIÓN MÓVIL ────────────────────────────────────────────────────────
  Widget _buildMobil() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.93,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle + header
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.proforma['numero']?.toString() ??
                            'Editar Proforma',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Contenido scrollable
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Agregar nuevo ítem ────────────────────────────────────
                  _buildSectionHeader(
                    'Agregar Ítem',
                    Icons.add_circle_outline,
                    const Color(0xFF4682B4),
                  ),
                  const SizedBox(height: 12),
                  _buildNuevoItemFormMobil(),
                  const SizedBox(height: 20),

                  // ── Lista de ítems ────────────────────────────────────────
                  _buildSectionHeader(
                    'Ítems (${_items.length})',
                    Icons.list_alt,
                    Colors.grey[700]!,
                  ),
                  const SizedBox(height: 8),
                  ..._items.asMap().entries.map(
                    (e) => _buildItemCardMobil(e.key, e.value),
                  ),
                  const SizedBox(height: 20),

                  // ── Totales ───────────────────────────────────────────────
                  _buildTotalesMobil(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Botones fijos abajo
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildNuevoItemFormMobil() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4682B4).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // Código con búsqueda
          _buildInputField(
            controller: _newCodigoCtrl,
            label: 'Código / REF',
            icon: Icons.qr_code,
            onChanged: (v) {
              final upper = v.toUpperCase();
              if (_newCodigoCtrl.text != upper) {
                _newCodigoCtrl.value = _newCodigoCtrl.value.copyWith(
                  text: upper,
                  selection: TextSelection.collapsed(offset: upper.length),
                );
              }
              _debounceProducto?.cancel();
              _debounceProducto = Timer(const Duration(milliseconds: 600), () {
                _buscarProducto(upper, itemIndex: -1);
              });
            },
          ),
          const SizedBox(height: 10),
          _buildInputField(
            controller: _newDescCtrl,
            label: 'Descripción',
            icon: Icons.description,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _newCantCtrl,
                  label: 'Cant.',
                  icon: Icons.numbers,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalcularNuevoItem(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputField(
                  controller: _newPrecioCtrl,
                  label: 'Precio',
                  icon: Icons.attach_money,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _recalcularNuevoItem(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputField(
                  controller: _newTotalCtrl,
                  label: 'Total',
                  icon: Icons.calculate,
                  readOnly: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _agregarItem,
              icon: const Icon(Icons.add),
              label: const Text('Agregar ítem'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCardMobil(int index, ItemEditable item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: item.codigoController,
                  label: 'Código',
                  icon: Icons.qr_code,
                  onChanged: (v) {
                    final upper = v.toUpperCase();
                    if (item.codigoController.text != upper) {
                      item.codigoController.value = item.codigoController.value
                          .copyWith(
                            text: upper,
                            selection: TextSelection.collapsed(
                              offset: upper.length,
                            ),
                          );
                    }
                    _debounceProducto?.cancel();
                    _debounceProducto = Timer(
                      const Duration(milliseconds: 600),
                      () {
                        _buscarProducto(upper, itemIndex: index);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => setState(() => _items.removeAt(index)),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildInputField(
            controller: item.descripcionController,
            label: 'Descripción',
            icon: Icons.description,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: item.cantidadController,
                  label: 'Cant.',
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _recalcularItem(index),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputField(
                  controller: item.precioController,
                  label: 'Precio',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => _recalcularItem(index),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInputField(
                  controller: item.totalController,
                  label: 'Total',
                  readOnly: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalesMobil() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          _buildTotalRow('Subtotal:', '\$${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          // Toggle IVA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _aplicarIVA ? Colors.green.shade50 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _aplicarIVA ? Colors.green.shade300 : Colors.grey.shade300,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'IVA 15%: \$${_iva.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color:
                        _aplicarIVA
                            ? Colors.green.shade700
                            : Colors.grey.shade600,
                  ),
                ),
                Switch(
                  value: _aplicarIVA,
                  onChanged: (v) => setState(() => _aplicarIVA = v),
                  activeColor: Colors.green,
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${_totalFinal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── VERSIÓN DESK ─────────────────────────────────────────────────────────
  Widget _buildDesk() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      constraints: const BoxConstraints(maxWidth: 1100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.edit, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Editar: ${widget.proforma['numero'] ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Contenido
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Formulario de nuevo ítem ─────────────────────────────
                  _buildSectionHeader(
                    'Agregar Ítem',
                    Icons.add_circle_outline,
                    const Color(0xFF4682B4),
                  ),
                  const SizedBox(height: 12),
                  _buildNuevoItemFormDesk(),
                  const SizedBox(height: 24),

                  // ── Tabla de ítems ───────────────────────────────────────
                  _buildSectionHeader(
                    'Ítems actuales (${_items.length})',
                    Icons.list_alt,
                    Colors.grey.shade700,
                  ),
                  const SizedBox(height: 8),
                  _buildTablaDesk(),
                  const SizedBox(height: 24),

                  // ── Totales ──────────────────────────────────────────────
                  _buildTotalesDesk(),
                ],
              ),
            ),
          ),

          // Botones
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildNuevoItemFormDesk() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4682B4).withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Código
          SizedBox(
            width: 120,
            child: _buildInputField(
              controller: _newCodigoCtrl,
              label: 'Código',
              icon: Icons.qr_code,
              onChanged: (v) {
                final upper = v.toUpperCase();
                if (_newCodigoCtrl.text != upper) {
                  _newCodigoCtrl.value = _newCodigoCtrl.value.copyWith(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
                _debounceProducto?.cancel();
                _debounceProducto = Timer(
                  const Duration(milliseconds: 600),
                  () {
                    _buscarProducto(upper, itemIndex: -1);
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          // Descripción
          Expanded(
            flex: 3,
            child: _buildInputField(
              controller: _newDescCtrl,
              label: 'Descripción',
              icon: Icons.description,
            ),
          ),
          const SizedBox(width: 10),
          // Cantidad
          SizedBox(
            width: 80,
            child: _buildInputField(
              controller: _newCantCtrl,
              label: 'Cant.',
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalcularNuevoItem(),
            ),
          ),
          const SizedBox(width: 10),
          // Precio
          SizedBox(
            width: 100,
            child: _buildInputField(
              controller: _newPrecioCtrl,
              label: 'Precio',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => _recalcularNuevoItem(),
            ),
          ),
          const SizedBox(width: 10),
          // Total (readonly)
          SizedBox(
            width: 100,
            child: _buildInputField(
              controller: _newTotalCtrl,
              label: 'Total',
              readOnly: true,
            ),
          ),
          const SizedBox(width: 12),
          // Botón agregar
          ElevatedButton.icon(
            onPressed: _agregarItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4682B4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaDesk() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(
                    'CÓDIGO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'DESCRIPCIÓN',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'CANT.',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'PRECIO',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'TOTAL',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No hay ítems. Agrega uno arriba.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            )
          else
            ..._items.asMap().entries.map(
              (e) => _buildFilaTablaDesk(e.key, e.value),
            ),
        ],
      ),
    );
  }

  Widget _buildFilaTablaDesk(int index, ItemEditable item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Código editable con búsqueda
          SizedBox(
            width: 110,
            child: _buildInputFieldCompact(
              controller: item.codigoController,
              onChanged: (v) {
                final upper = v.toUpperCase();
                if (item.codigoController.text != upper) {
                  item
                      .codigoController
                      .value = item.codigoController.value.copyWith(
                    text: upper,
                    selection: TextSelection.collapsed(offset: upper.length),
                  );
                }
                _debounceProducto?.cancel();
                _debounceProducto = Timer(
                  const Duration(milliseconds: 600),
                  () {
                    _buscarProducto(upper, itemIndex: index);
                  },
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // Descripción
          Expanded(
            flex: 3,
            child: _buildInputFieldCompact(
              controller: item.descripcionController,
            ),
          ),
          const SizedBox(width: 8),
          // Cantidad
          SizedBox(
            width: 70,
            child: _buildInputFieldCompact(
              controller: item.cantidadController,
              keyboardType: TextInputType.number,
              onChanged: (_) => _recalcularItem(index),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Precio
          SizedBox(
            width: 100,
            child: _buildInputFieldCompact(
              controller: item.precioController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => _recalcularItem(index),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 8),
          // Total (readonly)
          SizedBox(
            width: 100,
            child: Text(
              '\$${item.totalController.text}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
                fontSize: 13,
              ),
            ),
          ),
          // Eliminar
          SizedBox(
            width: 40,
            child: IconButton(
              onPressed: () => setState(() => _items.removeAt(index)),
              icon: Icon(
                Icons.remove_circle_outline,
                color: Colors.red.shade400,
                size: 20,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalesDesk() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          width: 320,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildTotalRow(
                  'Subtotal:',
                  '\$${_subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                // IVA toggle
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _aplicarIVA
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          _aplicarIVA
                              ? Colors.green.shade300
                              : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'IVA 15%: \$${_iva.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color:
                              _aplicarIVA
                                  ? Colors.green.shade700
                                  : Colors.grey.shade600,
                        ),
                      ),
                      Switch(
                        value: _aplicarIVA,
                        onChanged: (v) => setState(() => _aplicarIVA = v),
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${_totalFinal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Widgets compartidos ───────────────────────────────────────────────────
  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey.shade100 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              prefixIcon:
                  icon != null
                      ? Icon(icon, size: 16, color: Colors.grey.shade500)
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: icon != null ? 4 : 10,
                vertical: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputFieldCompact({
    required TextEditingController controller,
    bool readOnly = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    TextAlign textAlign = TextAlign.left,
  }) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: readOnly ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        onChanged: onChanged,
        textAlign: textAlign,
        style: const TextStyle(fontSize: 13),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: Colors.grey.shade400),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _guardando ? null : _guardar,
              icon:
                  _guardando
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save),
              label: Text(_guardando ? 'Guardando...' : 'Guardar cambios'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
