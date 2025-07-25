import 'package:basefundi/desktop/ventas/editar_ventas_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ModificarVentaDeskScreen extends StatefulWidget {
  const ModificarVentaDeskScreen({super.key});

  @override
  State<ModificarVentaDeskScreen> createState() =>
      _ModificarVentaDeskScreenState();
}

class _ModificarVentaDeskScreenState extends State<ModificarVentaDeskScreen>
    with SingleTickerProviderStateMixin {
  bool _esAdmin = false;
  bool _verificado = false;
  String _busquedaCliente = '';
  DateTime? _selectedDate;

  // Añadir controlador de animación
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Inicializar animación
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _verificarPermiso();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verificarPermiso() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final rol = data['rol'];

        if (rol == 'Administrador') {
          setState(() {
            _esAdmin = true;
            _verificado = true;
          });
          // Iniciar animación solo cuando se verifica que es admin
          _controller.forward();
          return;
        }
      }
    }

    // Si no es admin, mostrar error y regresar
    setState(() {
      _verificado = true;
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permisos para modificar ventas.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 3), () {
        Navigator.pop(context);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar la estructura completa desde el inicio pero con contenido condicional
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA SIEMPRE VISIBLE
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
                      'Modificar Ventas',
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

          // ✅ CONTENIDO CONDICIONAL
          Expanded(
            child: Container(color: Colors.white, child: _buildContenido()),
          ),
        ],
      ),
    );
  }

  Widget _buildContenido() {
    if (!_verificado) {
      // Mientras se verifica, mostrar loading centrado
      return const Center(child: CircularProgressIndicator());
    }

    if (!_esAdmin) {
      // Si no es admin, mostrar mensaje centrado
      return const Center(
        child: Text(
          'Verificando permisos...',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // Si es admin, mostrar contenido con animación
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _buildFilters(),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildListaVentas()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Buscar por cliente...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onChanged: (value) {
            setState(() {
              _busquedaCliente = value;
            });
          },
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
              });
            }
          },
          icon: const Icon(Icons.calendar_today),
          label: Text(
            _selectedDate == null
                ? 'Filtrar por fecha'
                : 'Filtrado: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4682B4),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_selectedDate != null)
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDate = null;
              });
            },
            child: const Text('Limpiar filtro de fecha'),
          ),
      ],
    );
  }

  Widget _buildListaVentas() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('ventas')
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar las ventas'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final ventas = snapshot.data?.docs ?? [];

        final ventasFiltradas =
            ventas.where((venta) {
              final data = venta.data() as Map<String, dynamic>;
              final cliente = data['cliente']?.toString().toLowerCase() ?? '';
              final fecha = (data['fecha'] as Timestamp?)?.toDate();

              final coincideCliente = cliente.contains(
                _busquedaCliente.toLowerCase(),
              );

              final coincideFecha =
                  _selectedDate == null ||
                  (fecha != null &&
                      fecha.day == _selectedDate!.day &&
                      fecha.month == _selectedDate!.month &&
                      fecha.year == _selectedDate!.year);

              return coincideCliente && coincideFecha;
            }).toList();

        if (ventasFiltradas.isEmpty) {
          return const Center(
            child: Text('No hay resultados para los filtros seleccionados.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          itemCount: ventasFiltradas.length,
          itemBuilder: (context, index) {
            final venta = ventasFiltradas[index];
            final data = venta.data() as Map<String, dynamic>;

            final cliente = data['cliente'] ?? 'Sin nombre';
            final total = data['total'] ?? 0.0;
            final fecha = (data['fecha'] as Timestamp?)?.toDate();
            final codigoComprobante =
                data['codigo_comprobante'] ?? 'Sin código';

            return Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.receipt_long,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cliente,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$codigoComprobante',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fecha != null
                                ? '${fecha.day}/${fecha.month}/${fecha.year} — ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}'
                                : 'Sin fecha',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '\$${(total as num).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Editar',
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Color(0xFF4682B4),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => EditarVentaDeskScreen(
                                          ventaId: venta.id,
                                          datosVenta: data,
                                        ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: 'Eliminar',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmarEliminacion(venta.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmarEliminacion(String idVenta) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta venta?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error: usuario no autenticado.'),
                      ),
                    );
                    return;
                  }

                  // Obtener datos del usuario actual
                  final userDoc =
                      await FirebaseFirestore.instance
                          .collection('usuarios_activos')
                          .doc(user.uid)
                          .get();

                  final usuarioNombre =
                      userDoc.data()?['nombre'] ?? 'Desconocido';

                  // Obtener datos de la venta eliminada
                  final ventaDoc =
                      await FirebaseFirestore.instance
                          .collection('ventas')
                          .doc(idVenta)
                          .get();

                  final ventaData = ventaDoc.data();

                  if (ventaData != null && ventaData['productos'] != null) {
                    final productos = List<Map<String, dynamic>>.from(
                      ventaData['productos'],
                    );

                    // Extraer cliente y total de ventaData
                    final cliente = ventaData['cliente'] ?? 'Sin nombre';
                    final total = ventaData['total'] ?? 0.0;

                    // ignore: unused_local_variable
                    for (final producto in productos) {
                      final tipoVenta =
                          ventaData['tipo'] ??
                          'Venta'; // Por ejemplo: 'Factura' o 'Nota de Venta'

                      await FirebaseFirestore.instance
                          .collection('auditoria_general')
                          .add({
                            'accion': 'Eliminación de $tipoVenta',
                            'detalle':
                                'Se eliminó una $tipoVenta del cliente: $cliente, Total: \$${(total as num).toStringAsFixed(2)}',
                            'fecha': Timestamp.now(),
                            'usuario_nombre': usuarioNombre,
                            'usuario_uid': user.uid,
                          });
                    }
                  }

                  // Eliminar la venta
                  await FirebaseFirestore.instance
                      .collection('ventas')
                      .doc(idVenta)
                      .delete();

                  Navigator.pop(context);
                },
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
