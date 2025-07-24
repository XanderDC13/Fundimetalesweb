import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class ProformasGuardadasDeskScreen extends StatefulWidget {
  const ProformasGuardadasDeskScreen({super.key});

  @override
  State<ProformasGuardadasDeskScreen> createState() =>
      _ProformasGuardadasDeskScreenState();
}

class _ProformasGuardadasDeskScreenState
    extends State<ProformasGuardadasDeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ✅ CABECERA CON Transform.translate
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
                      'Proformas Guardadas',
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

          // ✅ TABS PARA SELECCIONAR TIPO DE PROFORMA
          Container(
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF4682B4),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF4682B4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: const Color(0xFF4682B4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [Tab(text: 'Fundición'), Tab(text: 'Ventas')],
                ),
              ),
            ),
          ),

          // ✅ CONTENIDO PRINCIPAL CON TABBARVIEW
          Expanded(
            child: Container(
              color: const Color(0xFFFFFFFF),
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab de Fundición
                  _buildProformasList('proformasfundicion'),
                  // Tab de Ventas
                  _buildProformasList('proformas'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProformasList(String collection) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(collection)
              .orderBy('fecha', descending: true)
              .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar proformas: ${snapshot.error}'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No hay proformas guardadas.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  collection == 'proformasfundicion'
                      ? 'Las proformas de fundición aparecerán aquí.'
                      : 'Las proformas de ventas aparecerán aquí.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final numero = doc['numero'] ?? 'Sin número';
            final cliente = doc['cliente'] ?? 'Cliente no definido';
            final fechaTimestamp = doc['fecha'] as Timestamp?;
            final fecha =
                fechaTimestamp != null
                    ? fechaTimestamp.toDate()
                    : DateTime.now();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    collection == 'proformasfundicion'
                        ? Icons.factory_outlined
                        : Icons.description_outlined,
                    color: const Color(0xFF4682B4),
                    size: 36,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              numero,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    collection == 'proformasfundicion'
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                collection == 'proformasfundicion'
                                    ? 'Fundición'
                                    : 'Ventas',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      collection == 'proformasfundicion'
                                          ? Colors.orange[700]
                                          : Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cliente: $cliente',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fecha: ${fecha.toLocal().toString().split('.')[0]}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
