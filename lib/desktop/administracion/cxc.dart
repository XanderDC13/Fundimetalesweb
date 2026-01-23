import 'package:basefundi/desktop/administracion/detalleclientecxc.dart';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/transition.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CxcScreen extends StatefulWidget {
  const CxcScreen({super.key});

  @override
  State<CxcScreen> createState() => _CxcScreenState();
}

class _CxcScreenState extends State<CxcScreen> {
  String _busqueda = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _clientes = [];

  @override
  void initState() {
    super.initState();
    _cargarClientes();
  }

  Future<void> _cargarClientes() async {
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('clientes')
              .orderBy('nombre')
              .get();

      _clientes =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'nombre': data['nombre'] ?? 'Sin nombre',
              'ruc': data['ruc'] ?? '',
              'ciudad': data['ciudad'] ?? '',
              'telefono': data['telefono'] ?? '',
            };
          }).toList();
    } catch (_) {}

    setState(() => _isLoading = false);
  }

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
                  // 🔙 Flecha retroceso
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

                  // 🧾 Título centrado real
                  const Align(
                    alignment: Alignment.center,
                    child: Text(
                      'Cuentas por Cobrar',
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
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 24),
                      Expanded(child: _buildClientesList()),
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

  // ================= SEARCH =================
  Widget _buildSearchBar() {
    return SizedBox(
      width: 420,
      child: TextField(
        onChanged: (value) {
          setState(() => _busqueda = value.toLowerCase());
        },
        decoration: InputDecoration(
          hintText: 'Buscar cliente por nombre o RUC',
          prefixIcon: const Icon(Icons.search, color: Color(0xFF2C3E50)),
          filled: true,
          fillColor: const Color(0xFFF2F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ================= LIST =================
  Widget _buildClientesList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2C3E50)),
      );
    }

    final clientesFiltrados =
        _clientes.where((cliente) {
          if (_busqueda.isEmpty) return true;
          return cliente['nombre'].toLowerCase().contains(_busqueda) ||
              cliente['ruc'].toLowerCase().contains(_busqueda);
        }).toList();

    if (clientesFiltrados.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron clientes',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return ListView.separated(
      itemCount: clientesFiltrados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final cliente = clientesFiltrados[index];
        return _buildClienteCard(cliente);
      },
    );
  }

  // ================= CARD =================
  Widget _buildClienteCard(Map<String, dynamic> cliente) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _verDetalleCliente(cliente),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFF2C3E50),
                child: Text(
                  cliente['nombre'][0].toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    if (cliente['ruc'].toString().isNotEmpty)
                      Text(
                        'RUC: ${cliente['ruc']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // ================= NAV =================
  void _verDetalleCliente(Map<String, dynamic> cliente) {
    navegarConFade(context, ClienteDetalleDeskScreen(clienteData: cliente));
  }
}
