import 'package:flutter/material.dart';

class ProductoEnCarrito {
  final String codigo;
  final String nombre;
  final double precio;
  int cantidad;

  ProductoEnCarrito({
    required this.codigo,
    required this.nombre,
    required this.precio,
    this.cantidad = 1,
  });

  double get subtotal => precio * cantidad;
}

class CarritoController extends ChangeNotifier {
  final List<ProductoEnCarrito> _items = [];

  List<ProductoEnCarrito> get items => _items;

  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);

  void agregarProducto(ProductoEnCarrito producto) {
    final index = _items.indexWhere((p) => p.codigo == producto.codigo);
    if (index != -1) {
      _items[index].cantidad += 1;
    } else {
      _items.add(producto);
    }
    notifyListeners();
  }

  void actualizarCantidad(String codigo, int nuevaCantidad) {
    final index = _items.indexWhere((p) => p.codigo == codigo);
    if (index != -1) {
      _items[index].cantidad = nuevaCantidad;
      notifyListeners();
    }
  }

  void eliminarProducto(String codigo) {
    _items.removeWhere((p) => p.codigo == codigo);
    notifyListeners();
  }

  void limpiarCarrito() {
    _items.clear();
    notifyListeners();
  }
}
