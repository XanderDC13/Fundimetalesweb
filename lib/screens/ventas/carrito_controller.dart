import 'package:flutter/material.dart';

class ProductoEnCarrito {
  final String codigo;
  final String nombre;
  final double precio;
  final int disponibles;
  int cantidad;

  ProductoEnCarrito({
    required this.codigo,
    required this.nombre,
    required this.precio,
    required this.disponibles,
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
      if (_items[index].cantidad < _items[index].disponibles) {
        _items[index].cantidad += 1;
      } else {
        throw Exception('No hay suficientes unidades disponibles');
      }
    } else {
      if (producto.cantidad <= producto.disponibles) {
        _items.add(producto);
      } else {
        throw Exception(
          'La cantidad solicitada excede las unidades disponibles',
        );
      }
    }
    notifyListeners();
  }

  void actualizarCantidad(String codigo, int nuevaCantidad) {
    final index = _items.indexWhere((p) => p.codigo == codigo);

    if (index != -1) {
      if (nuevaCantidad <= _items[index].disponibles) {
        _items[index].cantidad = nuevaCantidad;
      } else {
        throw Exception('No tienes unidades disponibles');
      }
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

  bool puedeAgregar(
    String codigo,
    int cantidadDeseada, {
    required int disponibles,
  }) {
    final index = _items.indexWhere((p) => p.codigo == codigo);

    if (index != -1) {
      return (_items[index].cantidad + cantidadDeseada) <=
          _items[index].disponibles;
    } else {
      return cantidadDeseada <= disponibles;
    }
  }

  int cantidadEnCarrito(String codigo) {
    final producto = _items.firstWhere(
      (p) => p.codigo == codigo,
      orElse:
          () => ProductoEnCarrito(
            codigo: codigo,
            nombre: '',
            precio: 0,
            disponibles: 0,
            cantidad: 0,
          ),
    );
    return producto.cantidad;
  }
}
