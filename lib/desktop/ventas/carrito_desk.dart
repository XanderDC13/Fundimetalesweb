import 'package:basefundi/desktop/ventas/carrito_controller_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerCarritoDeskScreen extends StatefulWidget {
  const VerCarritoDeskScreen({super.key});

  @override
  State<VerCarritoDeskScreen> createState() => _VerCarritoScreenState();
}

class _VerCarritoScreenState extends State<VerCarritoDeskScreen> {
  final TextEditingController _clienteController = TextEditingController();
  String metodoSeleccionado = 'Efectivo';

  @override
  void dispose() {
    _clienteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Container(
        color: const Color(0xFFFFFFFF),
        child: Column(
          children: [
            // CABECERA CON Transform.translate
            Transform.translate(
              offset: const Offset(-0.5, 0),
              child: Container(
                width: double.infinity,
                color: const Color(0xFF2C3E50),
                padding: const EdgeInsets.symmetric(
                  horizontal: 64,
                  vertical: 38,
                ),
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
                        'Carrito',
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
            Expanded(
              child: Consumer<CarritoController>(
                builder: (context, carrito, _) {
                  final items = carrito.items;

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
                                    final TextEditingController
                                    cantidadController = TextEditingController(
                                      text: producto.cantidad.toString(),
                                    );

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      child: Card(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 0,
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
                                                  CircleAvatar(
                                                    backgroundColor:
                                                        producto.exentoIva
                                                            ? Colors.green
                                                            : Colors.grey,
                                                    child: Icon(
                                                      producto.exentoIva
                                                          ? Icons.local_shipping
                                                          : Icons.inventory_2,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          producto.nombre,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        ),
                                                        if (producto.exentoIva)
                                                          Container(
                                                            margin:
                                                                const EdgeInsets.only(
                                                                  top: 2,
                                                                ),
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  Colors
                                                                      .green
                                                                      .shade100,
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    4,
                                                                  ),
                                                            ),
                                                            child: const Text(
                                                              'EXENTO IVA',
                                                              style: TextStyle(
                                                                fontSize: 10,
                                                                color:
                                                                    Colors
                                                                        .green,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
                                                    children: [
                                                      Text(
                                                        '\$${producto.precio.toStringAsFixed(2)}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      if (!producto.exentoIva &&
                                                          carrito.ivaActivado)
                                                        Text(
                                                          '+ IVA: \$${producto.montoIvaUnitario(carrito.ivaActivado).toStringAsFixed(2)}',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 11,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                        ),
                                                    ],
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
                                                        onPressed:
                                                            producto.cantidad >
                                                                    1
                                                                ? () {
                                                                  carrito.actualizarCantidad(
                                                                    producto
                                                                        .referencia,
                                                                    producto.cantidad -
                                                                        1,
                                                                  );
                                                                }
                                                                : () {
                                                                  carrito.eliminarProducto(
                                                                    producto
                                                                        .referencia,
                                                                  );
                                                                },
                                                      ),
                                                      SizedBox(
                                                        width: 45,
                                                        child: TextField(
                                                          controller:
                                                              cantidadController,
                                                          keyboardType:
                                                              TextInputType
                                                                  .number,
                                                          textAlign:
                                                              TextAlign.center,
                                                          onSubmitted: (value) {
                                                            final parsed =
                                                                int.tryParse(
                                                                  value,
                                                                );
                                                            if (parsed !=
                                                                    null &&
                                                                parsed >= 1) {
                                                              // Para productos de transporte, permitir cualquier cantidad
                                                              if (producto
                                                                  .exentoIva) {
                                                                carrito.actualizarCantidad(
                                                                  producto
                                                                      .referencia,
                                                                  parsed,
                                                                );
                                                              } else {
                                                                // Para productos normales, respetar disponibles
                                                                if (parsed <=
                                                                    producto
                                                                        .disponibles) {
                                                                  carrito.actualizarCantidad(
                                                                    producto
                                                                        .referencia,
                                                                    parsed,
                                                                  );
                                                                } else {
                                                                  carrito.actualizarCantidad(
                                                                    producto
                                                                        .referencia,
                                                                    producto
                                                                        .disponibles,
                                                                  );
                                                                }
                                                              }
                                                            } else {
                                                              carrito.actualizarCantidad(
                                                                producto
                                                                    .referencia,
                                                                1,
                                                              );
                                                            }
                                                          },
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .add_circle_outline,
                                                        ),
                                                        onPressed:
                                                            producto.exentoIva ||
                                                                    producto.cantidad <
                                                                        producto
                                                                            .disponibles
                                                                ? () {
                                                                  carrito.actualizarCantidad(
                                                                    producto
                                                                        .referencia,
                                                                    producto.cantidad +
                                                                        1,
                                                                  );
                                                                }
                                                                : null,
                                                      ),
                                                    ],
                                                  ),
                                                  Text(
                                                    '= \$${producto.totalConIva(carrito.ivaActivado).toStringAsFixed(2)}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF2C3E50),
                                                    ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _clienteController,
                              style: const TextStyle(
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

                            // NUEVO: Resumen detallado de totales
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  // Subtotal productos exentos
                                  if (carrito.tieneProductosExentos)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Subtotal (Exento IVA):'),
                                        Text(
                                          '\$${carrito.subtotalExento.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),

                                  // Subtotal productos gravables
                                  if (carrito.tieneProductosGravables)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Subtotal (Gravable):'),
                                        Text(
                                          '\$${carrito.subtotalGravable.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),

                                  // IVA (solo si está activado y hay productos gravables)
                                  if (carrito.ivaActivado &&
                                      carrito.totalIva > 0) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('IVA (15%):'),
                                        Text(
                                          '\$${carrito.totalIva.toStringAsFixed(2)}',
                                        ),
                                      ],
                                    ),
                                  ],

                                  const Divider(height: 16),

                                  // Botón de IVA y total
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            'Total:',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap:
                                                carrito.tieneProductosGravables
                                                    ? () {
                                                      carrito.toggleIva();
                                                    }
                                                    : null,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    carrito.ivaActivado
                                                        ? const Color(
                                                          0xFF4682B4,
                                                        )
                                                        : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color:
                                                      carrito.tieneProductosGravables
                                                          ? const Color(
                                                            0xFF4682B4,
                                                          )
                                                          : Colors.grey,
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                carrito.ivaActivado
                                                    ? 'IVA ✓'
                                                    : 'IVA',
                                                style: TextStyle(
                                                  color:
                                                      carrito.ivaActivado
                                                          ? Colors.white
                                                          : carrito
                                                              .tieneProductosGravables
                                                          ? const Color(
                                                            0xFF4682B4,
                                                          )
                                                          : Colors.grey,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (!carrito.tieneProductosGravables)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Text(
                                                '(Solo productos exentos)',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        '\$${carrito.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
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
                              _mostrarSeleccionMetodoPago(context, carrito);
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

  void _mostrarSeleccionMetodoPago(
    BuildContext context,
    CarritoController carrito,
  ) {
    final cliente = _clienteController.text.trim();
    final productos = carrito.items;
    final usuario = FirebaseAuth.instance.currentUser;

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

                  // Resumen de la venta
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        if (carrito.tieneProductosExentos)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Exento IVA:'),
                              Text(
                                '\$${carrito.subtotalExento.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        if (carrito.tieneProductosGravables)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Gravable:'),
                              Text(
                                '\$${carrito.subtotalGravable.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        if (carrito.ivaActivado && carrito.totalIva > 0)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('IVA (15%):'),
                              Text('\$${carrito.totalIva.toStringAsFixed(2)}'),
                            ],
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TOTAL:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '\$${carrito.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// 🔑 Mostrar vendedor autenticado
                  FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('usuarios_activos')
                            .doc(usuario?.uid)
                            .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const Text(
                          'Vendedor: No disponible',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        );
                      }

                      final nombreVendedor =
                          snapshot.data!.get('nombre') ?? '---';

                      return Text(
                        'Vendedor: $nombreVendedor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4682B4),
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
                                  carrito,
                                  cliente,
                                  metodoSeleccionado,
                                );
                                carrito.limpiarCarrito();
                                Navigator.pop(context);
                                Navigator.pop(context);
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
    CarritoController carrito,
    String cliente,
    String metodoPago,
  ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('No hay usuario autenticado');
    }

    final userDoc =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(currentUser.uid)
            .get();

    final nombreUsuario =
        userDoc.data()?['nombre'] ?? currentUser.email ?? '---';

    // Determinar tipo de comprobante basado en si hay IVA
    final conIva = carrito.ivaActivado && carrito.totalIva > 0;
    final tipoComprobante = conIva ? 'Factura' : 'Nota de Venta';
    final prefijo = conIva ? 'FAC' : 'NV';
    final tipoClave = conIva ? 'factura' : 'nota_venta';

    // Transacción para obtener y actualizar el contador
    final firestore = FirebaseFirestore.instance;
    final contadorRef = firestore
        .collection('contadores_comprobantes')
        .doc(tipoClave);

    String codigoComprobante = '';

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(contadorRef);

      int ultimoNumero = 0;
      if (snapshot.exists) {
        ultimoNumero = snapshot.get('ultimo_numero') ?? 0;
      }

      final nuevoNumero = ultimoNumero + 1;
      final numeroFormateado = nuevoNumero.toString().padLeft(5, '0');
      codigoComprobante = '$prefijo-$numeroFormateado';

      transaction.set(contadorRef, {'ultimo_numero': nuevoNumero});
    });

    final venta = {
      'codigo_comprobante': codigoComprobante,
      'cliente': cliente.isNotEmpty ? cliente : null,
      'subtotal_exento': carrito.subtotalExento,
      'subtotal_gravable': carrito.subtotalGravable,
      'total_iva': carrito.totalIva,
      'total': carrito.total,
      'metodoPago': metodoPago,
      'tipoComprobante': tipoComprobante,
      'conIva': conIva,
      'fecha': Timestamp.now(),
      'usuario_uid': currentUser.uid,
      'usuario_nombre': nombreUsuario,
      'productos':
          productos
              .map(
                (p) => {
                  'referencia': p.referencia,
                  'nombre': p.nombre,
                  'cantidad': p.cantidad,
                  'precio': p.precio,
                  'subtotal': p.subtotal,
                  'exento_iva': p.exentoIva,
                  'precio_con_iva': p.precioConIva(carrito.ivaActivado),
                  'total_con_iva': p.totalConIva(carrito.ivaActivado),
                  'iva_unitario': p.montoIvaUnitario(carrito.ivaActivado),
                  'total_iva': p.totalIva(carrito.ivaActivado),
                },
              )
              .toList(),
    };

    final ventaRef = await FirebaseFirestore.instance
        .collection('ventas')
        .add(venta);

    await FirebaseFirestore.instance.collection('auditoria_general').add({
      'accion': 'Registro de Venta',
      'detalle':
          'Comprobante: $codigoComprobante | Total: \$${carrito.total.toStringAsFixed(2)} | Método: $metodoPago | IVA: ${conIva ? 'Sí (\$${carrito.totalIva.toStringAsFixed(2)})' : 'No'} | Tipo: $tipoComprobante',
      'fecha': DateTime.now(),
      'referencia_venta': ventaRef.id,
      'usuario_uid': currentUser.uid,
      'usuario_nombre': nombreUsuario,
    });
  }
}
