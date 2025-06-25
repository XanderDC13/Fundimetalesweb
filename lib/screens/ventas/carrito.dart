import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'carrito_controller.dart';

class VerCarritoScreen extends StatefulWidget {
  const VerCarritoScreen({super.key});

  @override
  State<VerCarritoScreen> createState() => _VerCarritoScreenState();
}

class _VerCarritoScreenState extends State<VerCarritoScreen> {
  final TextEditingController _clienteController = TextEditingController();

  @override
  void dispose() {
    _clienteController.dispose();
    super.dispose();
  }

  String metodoSeleccionado = 'Efectivo';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          children: [
            // ENCABEZADO
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              width: double.infinity,
              child: const Center(
                child: Text(
                  'Ver Carrito',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // CONTENIDO PRINCIPAL
            Expanded(
              child: Consumer<CarritoController>(
                builder: (context, carrito, _) {
                  final items = carrito.items;
                  final total = carrito.total;

                  return Column(
                    children: [
                      Expanded(
                        child:
                            items.isEmpty
                                ? const Center(
                                  child: Text('El carrito está vacío'),
                                )
                                : ListView.builder(
                                  itemCount: items.length,
                                  itemBuilder: (context, index) {
                                    final producto = items[index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Card(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const CircleAvatar(
                                                    backgroundColor:
                                                        Colors.grey,
                                                    child: Icon(
                                                      Icons.inventory_2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      producto.nombre,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '\$${producto.precio.toStringAsFixed(2)}',
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .remove_circle_outline,
                                                        ),
                                                        onPressed: () {
                                                          if (producto
                                                                  .cantidad >
                                                              1) {
                                                            carrito.actualizarCantidad(
                                                              producto.codigo,
                                                              producto.cantidad -
                                                                  1,
                                                            );
                                                          } else {
                                                            carrito
                                                                .eliminarProducto(
                                                                  producto
                                                                      .codigo,
                                                                );
                                                          }
                                                        },
                                                      ),
                                                      Text(
                                                        '${producto.cantidad}',
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .add_circle_outline,
                                                        ),
                                                        onPressed:
                                                            producto.cantidad <
                                                                    producto
                                                                        .disponibles
                                                                ? () {
                                                                  carrito.actualizarCantidad(
                                                                    producto
                                                                        .codigo,
                                                                    producto.cantidad +
                                                                        1,
                                                                  );
                                                                }
                                                                : null,
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    '= \$${producto.subtotal.toStringAsFixed(2)}',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                      ),

                      // CAMPO PARA CLIENTE Y TOTAL
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _clienteController,
                              style: TextStyle(
                                color: Color(0xFF2C3E50),
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: const InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(
                                  Icons.person,
                                  color: Color(0xFF2C3E50),
                                ),

                                labelText: 'Nombre del cliente (opcional)',
                                labelStyle: TextStyle(color: Color(0xFF2C3E50)),
                                border: OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '\$${total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      // BOTÓN CONFIRMAR VENTA
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'CONFIRMAR VENTA',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4682B4),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              _mostrarSeleccionMetodoPago(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSeleccionMetodoPago(BuildContext context) {
    final carrito = Provider.of<CarritoController>(context, listen: false);
    final cliente = _clienteController.text.trim();
    final total = carrito.total;
    final productos = carrito.items;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Selecciona el método de pago',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _opcionPago(setState, 'Efectivo', Icons.attach_money),
                      _opcionPago(setState, 'Tarjeta', Icons.credit_card),
                      _opcionPago(
                        setState,
                        'Transferencia bancaria',
                        Icons.account_balance,
                      ),
                      _opcionPago(setState, 'Otro', Icons.more_horiz),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4), // Azul
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed:
                          productos.isEmpty
                              ? null
                              : () async {
                                await _guardarVentaEnFirebase(
                                  productos,
                                  total,
                                  cliente,
                                  metodoSeleccionado,
                                );
                                carrito.limpiarCarrito();
                                Navigator.pop(context); // Cierra modal
                                Navigator.pop(context); // Vuelve atrás
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Venta registrada con éxito'),
                                  ),
                                );
                              },
                      child: const Text(
                        'CREAR VENTA',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _opcionPago(Function setState, String metodo, IconData icono) {
    final bool activo = metodoSeleccionado == metodo;
    return GestureDetector(
      onTap: () {
        setState(() {
          metodoSeleccionado = metodo;
        });
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFFD6E4FF) : Colors.grey[100],
          border: Border.all(
            color: activo ? const Color(0xFF1E40AF) : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icono, color: activo ? const Color(0xFF1E40AF) : Colors.grey),
            const SizedBox(height: 6),
            Text(
              metodo,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: activo ? const Color(0xFF1E40AF) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarVentaEnFirebase(
    List productos,
    double total,
    String cliente,
    String metodoPago,
  ) async {
    final venta = {
      'cliente': cliente.isNotEmpty ? cliente : null,
      'total': total,
      'metodoPago': metodoPago,
      'fecha': Timestamp.now(),
      'productos':
          productos
              .map(
                (p) => {
                  'codigo': p.codigo,
                  'nombre': p.nombre,
                  'cantidad': p.cantidad,
                  'precio': p.precio,
                  'subtotal': p.subtotal,
                },
              )
              .toList(),
    };

    await FirebaseFirestore.instance.collection('ventas').add(venta);
  }
}
