import 'package:basefundi/screens/insumos/historialinsumos.dart';
import 'package:basefundi/screens/insumos/inventarioinsumos.dart';
import 'package:basefundi/screens/insumos/solicitud.dart';
import 'package:flutter/material.dart';

class InsumosScreen extends StatefulWidget {
  const InsumosScreen({super.key});

  @override
  State<InsumosScreen> createState() => _InsumosScreenState();
}

class _InsumosScreenState extends State<InsumosScreen> {
  int _selectedIndex = 0;

  void _onTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4682B4), Color(0xFF4682B4)],
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
                  'Gestión de Insumos',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Botones de navegación
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildBoton('Solicitud', Icons.assignment, 0),
                  _buildBoton('Inventario', Icons.inventory, 1),
                  _buildBoton('Historial', Icons.history, 2),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Contenido dinámico
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const [
                  SolicitudInsumosWidget(),
                  InventarioInsumosWidget(),
                  HistorialInsumosWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoton(String texto, IconData icono, int index) {
    final bool selected = _selectedIndex == index;
    return ElevatedButton.icon(
      onPressed: () => _onTab(index),
      icon: Icon(icono, size: 18),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? const Color(0xFF4682B4) : Colors.white,
        foregroundColor: selected ? Colors.white : const Color(0xFF4682B4),
        side: const BorderSide(color: Color(0xFF4682B4)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }
}
