import 'package:basefundi/desktop/personal/insumos/historial_insumos_desk.dart';
import 'package:basefundi/desktop/personal/insumos/inventario_insumos_desk.dart';
import 'package:basefundi/desktop/personal/insumos/solicitud_insumos_desk.dart';
import 'package:basefundi/settings/navbar_desk.dart';
import 'package:flutter/material.dart';

class InsumosDeskScreen extends StatefulWidget {
  const InsumosDeskScreen({super.key});

  @override
  State<InsumosDeskScreen> createState() => _InsumosDeskScreenState();
}

class _InsumosDeskScreenState extends State<InsumosDeskScreen> {
  int _selectedIndex = 0;

  void _onTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ HEADER CON FLECHA Y TRANSFORM
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
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Gestión de Insumos',
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
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ BOTONES DE NAVEGACIÓN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              _buildBoton('Solicitud', Icons.assignment, 0),
                              const SizedBox(width: 16),
                              _buildBoton('Inventario', Icons.inventory, 1),
                              const SizedBox(width: 16),
                              _buildBoton('Historial', Icons.history, 2),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // ✅ CONTENIDO DINÁMICO
                          Expanded(
                            child: IndexedStack(
                              index: _selectedIndex,
                              children: const [
                                SolicitudInsumosDeskWidget(),
                                InventarioInsumosDeskScreen(),
                                HistorialInsumosDeskWidget(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }
}
