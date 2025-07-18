import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProformasGuardadasScreen extends StatelessWidget {
  const ProformasGuardadasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proformas Guardadas'),
        backgroundColor: const Color(0xFF4682B4),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('proformas')
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
            return const Center(child: Text('No hay proformas guardadas.'));
          }

          return ListView.builder(
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: ListTile(
                  title: Text(
                    numero,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cliente: $cliente'),
                      Text(
                        'Fecha: ${fecha.toLocal().toString().split('.')[0]}',
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Aquí podrías navegar a una pantalla de detalle o abrir el PDF si ya lo tienes generado.
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
