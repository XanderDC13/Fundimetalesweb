import 'package:flutter/material.dart';

class ProductoEnCarrito {
  final String referencia;
  final String nombre;
  final double precio;
  final int disponibles;
  final bool exentoIva; // Para identificar si el producto puede tener IVA
  int cantidad;

  ProductoEnCarrito({
    required this.referencia,
    required this.nombre,
    required this.precio,
    required this.disponibles,
    this.exentoIva = false, // Por defecto no está exento
    this.cantidad = 1,
  });

  // Subtotal sin IVA (precio base)
  double get subtotal => precio * cantidad;

  // Monto de IVA por unidad (solo si no está exento)
  double montoIvaUnitario(bool aplicarIva) {
    if (exentoIva || !aplicarIva) {
      return 0.0; // Sin IVA si está exento o no se aplica IVA
    } else {
      return precio * 0.15; // IVA del 15%
    }
  }

  // Precio unitario con IVA (si aplica)
  double precioConIva(bool aplicarIva) {
    return precio + montoIvaUnitario(aplicarIva);
  }

  // Total con IVA incluido (si aplica)
  double totalConIva(bool aplicarIva) => precioConIva(aplicarIva) * cantidad;

  // Total del IVA para este producto
  double totalIva(bool aplicarIva) => montoIvaUnitario(aplicarIva) * cantidad;
}

class CarritoController extends ChangeNotifier {
  final List<ProductoEnCarrito> _items = [];
  static const double IVA_PORCENTAJE = 0.15; // 15%

  // Estado del IVA - controla si se aplica o no
  bool _ivaActivado = false;

  List<ProductoEnCarrito> get items => _items;

  // Getter y setter para el estado del IVA
  bool get ivaActivado => _ivaActivado;

  void toggleIva() {
    _ivaActivado = !_ivaActivado;
    notifyListeners();
  }

  void activarIva() {
    _ivaActivado = true;
    notifyListeners();
  }

  void desactivarIva() {
    _ivaActivado = false;
    notifyListeners();
  }

  // Total sin IVA (subtotal base)
  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);

  // Total con IVA incluido (depende del estado del botón IVA)
  double get total =>
      _items.fold(0.0, (sum, item) => sum + item.totalConIva(_ivaActivado));

  // Total del IVA (solo se calcula si está activado)
  double get totalIva =>
      _items.fold(0.0, (sum, item) => sum + item.totalIva(_ivaActivado));

  // Subtotal de productos exentos de IVA
  double get subtotalExento {
    return _items
        .where((item) => item.exentoIva)
        .fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // Subtotal de productos que PUEDEN tener IVA (no exentos)
  double get subtotalGravable {
    return _items
        .where((item) => !item.exentoIva)
        .fold(0.0, (sum, item) => sum + item.subtotal);
  }

  // IVA solo de productos gravables (cuando está activado)
  double get ivaProductosGravables {
    if (!_ivaActivado) return 0.0;
    return _items
        .where((item) => !item.exentoIva)
        .fold(0.0, (sum, item) => sum + item.totalIva(_ivaActivado));
  }

  // Verificar si un producto es de transporte
  bool _esProductoTransporte(String referencia, String nombre) {
    // Por referencia específica
    if (referencia == 'TRA001') return true;

    // Por palabras clave en el nombre
    final nombreUpper = nombre.toUpperCase();
    final palabrasTransporte = [
      'TRANSPORTE',
      'EMBALAJE',
      'ENVIO',
      'ENVÍO',
      'FLETE',
      'DELIVERY',
      'SERVICIO DE EMBALAJE',
    ];

    return palabrasTransporte.any((palabra) => nombreUpper.contains(palabra));
  }

  void agregarProducto(ProductoEnCarrito producto) {
    final index = _items.indexWhere((p) => p.referencia == producto.referencia);

    // Verificar si es producto de transporte y aplicar exención de IVA
    final esTransporte = _esProductoTransporte(
      producto.referencia,
      producto.nombre,
    );

    // Crear producto con la configuración correcta de IVA
    final productoFinal = ProductoEnCarrito(
      referencia: producto.referencia,
      nombre: producto.nombre,
      precio: producto.precio,
      disponibles:
          esTransporte
              ? 999999
              : producto.disponibles, // Ilimitado para transporte
      exentoIva: esTransporte, // Exento si es transporte
      cantidad: producto.cantidad,
    );

    if (index != -1) {
      // Si ya existe el producto
      if (esTransporte) {
        // Para transporte, permitir agregar sin límite
        _items[index].cantidad += 1;
      } else {
        // Para productos normales, verificar stock
        if (_items[index].cantidad < _items[index].disponibles) {
          _items[index].cantidad += 1;
        } else {
          throw Exception('No hay suficientes unidades disponibles');
        }
      }
    } else {
      // Si es un producto nuevo
      if (esTransporte) {
        // Para transporte, agregar sin restricciones
        _items.add(productoFinal);
      } else {
        // Para productos normales, verificar stock
        if (producto.cantidad <= producto.disponibles) {
          _items.add(productoFinal);
        } else {
          throw Exception(
            'La cantidad solicitada excede las unidades disponibles',
          );
        }
      }
    }
    notifyListeners();
  }

  void actualizarCantidad(String referencia, int nuevaCantidad) {
    final index = _items.indexWhere((p) => p.referencia == referencia);

    if (index != -1) {
      final producto = _items[index];
      final esTransporte = _esProductoTransporte(
        producto.referencia,
        producto.nombre,
      );

      if (esTransporte) {
        // Para transporte, permitir cualquier cantidad
        _items[index].cantidad = nuevaCantidad;
      } else {
        // Para productos normales, verificar stock
        if (nuevaCantidad <= _items[index].disponibles) {
          _items[index].cantidad = nuevaCantidad;
        } else {
          throw Exception('No tienes unidades disponibles');
        }
      }
      notifyListeners();
    }
  }

  void eliminarProducto(String codigo) {
    _items.removeWhere((p) => p.referencia == codigo);
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
    String nombre = '',
  }) {
    final esTransporte = _esProductoTransporte(codigo, nombre);

    if (esTransporte) {
      return true; // Siempre se puede agregar transporte
    }

    final index = _items.indexWhere((p) => p.referencia == codigo);

    if (index != -1) {
      return (_items[index].cantidad + cantidadDeseada) <=
          _items[index].disponibles;
    } else {
      return cantidadDeseada <= disponibles;
    }
  }

  int cantidadEnCarrito(String codigo) {
    final producto = _items.firstWhere(
      (p) => p.referencia == codigo,
      orElse:
          () => ProductoEnCarrito(
            referencia: codigo,
            nombre: '',
            precio: 0,
            disponibles: 0,
            cantidad: 0,
          ),
    );
    return producto.cantidad;
  }

  // Método para obtener resumen de facturación
  Map<String, dynamic> get resumenFacturacion {
    return {
      'subtotalExento': subtotalExento,
      'subtotalGravable': subtotalGravable,
      'ivaActivado': _ivaActivado,
      'totalIva': totalIva,
      'total': total,
    };
  }

  // Método para verificar si hay productos exentos en el carrito
  bool get tieneProductosExentos {
    return _items.any((item) => item.exentoIva);
  }

  // Método para verificar si hay productos que pueden tener IVA
  bool get tieneProductosGravables {
    return _items.any((item) => !item.exentoIva);
  }
}
