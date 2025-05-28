import 'package:basefundi/screens/ventas/modificarventas.dart';
import 'package:basefundi/screens/ventas/ventastotales.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/screens/ventas/realizarventa.dart';
import 'package:basefundi/settings/transition.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView(
                    children: [
                      const SizedBox(height: 16),
                      TarjetaAccion(
                        icono: Icons.edit,
                        titulo: 'Ventas Totales',
                        valor: '',
                        onTap: () {
                          navigateWithTransition(
                            context: context,
                            destination: const VentasTotalesScreen(),
                            transition: TransitionType.fade,
                            replace: false,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TarjetaAccion(
                        icono: Icons.edit,
                        titulo: 'Modificar Ventas',
                        valor: '',
                        onTap: () {
                          navigateWithTransition(
                            context: context,
                            destination: const ModificarVentasScreen(),
                            transition: TransitionType.fade,
                            replace: false,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TarjetaAccion(
                        icono: Icons.shopping_cart,
                        titulo: 'Realizar Venta',
                        valor: '',
                        onTap: () {
                          navigateWithTransition(
                            context: context,
                            destination: const VentasDetalleScreen(),
                            transition: TransitionType.fade,
                            replace: false,
                          );
                        },
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1E40AF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Center(
        child: Text(
          'Ventas',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class TarjetaAccion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final VoidCallback? onTap;

  const TarjetaAccion({
    super.key,
    required this.icono,
    required this.titulo,
    required this.valor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
              child: Icon(icono, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  if (valor.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      valor,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
