import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ClienteDetalleDeskScreen extends StatefulWidget {
  final Map<String, dynamic> clienteData;

  const ClienteDetalleDeskScreen({super.key, required this.clienteData});

  @override
  State<ClienteDetalleDeskScreen> createState() =>
      _ClienteDetalleDeskScreenState();
}

class _ClienteDetalleDeskScreenState extends State<ClienteDetalleDeskScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ================= HEADER =================
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
                      'Detalle del Cliente',
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

          // ================= CONTENT =================
          Expanded(
            child: Container(
              color: Colors.white,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildClienteCard(),
                      const SizedBox(height: 32),
                      Expanded(child: _buildProformasTable()), // 👈 NUEVO
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CARD CLIENTE =================
  Widget _buildClienteCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: const Color(0xFF2C3E50),
              child: Text(
                widget.clienteData['nombre'][0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clienteData['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 8),

                  if ((widget.clienteData['ruc'] ?? '').toString().isNotEmpty)
                    _infoRow(
                      icon: Icons.badge_outlined,
                      text: 'RUC: ${widget.clienteData['ruc']}',
                    ),

                  if ((widget.clienteData['telefono'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _infoRow(
                      icon: Icons.phone_outlined,
                      text: 'Teléfono: ${widget.clienteData['telefono']}',
                    ),

                  if ((widget.clienteData['ciudad'] ?? '')
                      .toString()
                      .isNotEmpty)
                    _infoRow(
                      icon: Icons.location_city_outlined,
                      text: 'Ciudad: ${widget.clienteData['ciudad']}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TABLA PROFORMAS =================
  Widget _buildProformasTable() {
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('proformas')
        .where(
          'ci_ruc',
          isEqualTo: widget.clienteData['ruc'],
        )
        .orderBy('fecha', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final proformas = snapshot.data!.docs;

      if (proformas.isEmpty) {
        return const Center(
          child: Text('Este cliente no tiene proformas'),
        );
      }

      return ListView.builder(
        itemCount: proformas.length,
        itemBuilder: (_, i) {
          final p = proformas[i];

          return _tableRow({
            'factura': p['numero'],
            'tipo': 'FAC',
            'valor': double.parse(p['total']),
            'fecha': _formatFecha(p['fecha']),
            'estado': p['estado'] ?? 'Pendiente',
          });
        },
      );
    },
  );
}
String _formatFecha(Timestamp ts) {
  final date = ts.toDate();
  return '${date.day}/${date.month}/${date.year}';
}


  Widget _tableRow(Map<String, dynamic> p) {
    final bool cobrado = p['estado'] == 'Cobrado';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _Cell(text: p['factura'], flex: 2),
          _Cell(text: p['tipo'], flex: 1),
          _Cell(text: '\$${p['valor'].toStringAsFixed(2)}', flex: 2),
          _Cell(text: p['fecha'], flex: 2),
          _Cell(
            text: p['estado'],
            flex: 2,
            color: cobrado ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _infoRow({required IconData icon, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }
}

// ================= CELDA =================
class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  final Color? color;

  const _Cell({
    required this.text,
    required this.flex,
    this.bold = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          color: color ?? Colors.black87,
        ),
      ),
    );
  }
}
