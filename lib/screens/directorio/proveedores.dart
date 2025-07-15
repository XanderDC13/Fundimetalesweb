import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proveedores'),
        backgroundColor: const Color(0xFF4682B4),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('proveedores')
                .orderBy('nombre')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final proveedores = snapshot.data?.docs ?? [];

          if (proveedores.isEmpty) {
            return const Center(
              child: Text(
                'No hay proveedores registrados.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: proveedores.length,
            itemBuilder: (context, index) {
              final proveedor =
                  proveedores[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    proveedor['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ciudad: ${proveedor['ciudad'] ?? '-'}'),
                      Text('Teléfono: ${proveedor['telefono'] ?? '-'}'),
                      Text('Correo: ${proveedor['correo'] ?? '-'}'),
                      Text('RUC: ${proveedor['ruc'] ?? '-'}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF4682B4)),
                    onPressed: () {
                      _mostrarFormulario(
                        context,
                        proveedor,
                        docId: proveedores[index].id,
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarFormulario(context, null);
        },
        backgroundColor: const Color(0xFF4682B4),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _mostrarFormulario(
    BuildContext context,
    Map<String, dynamic>? proveedor, {
    String? docId,
  }) {
    final _formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: proveedor?['nombre']);
    final ciudadController = TextEditingController(text: proveedor?['ciudad']);
    final direccionController = TextEditingController(
      text: proveedor?['direccion'],
    );
    final telefonoController = TextEditingController(
      text: proveedor?['telefono'],
    );
    final correoController = TextEditingController(text: proveedor?['correo']);
    final rucController = TextEditingController(text: proveedor?['ruc']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _campo(nombreController, 'Nombre', Icons.business),
                  const SizedBox(height: 12),
                  _campo(ciudadController, 'Ciudad', Icons.location_city),
                  const SizedBox(height: 12),
                  _campo(direccionController, 'Dirección', Icons.home),
                  const SizedBox(height: 12),
                  _campo(
                    telefonoController,
                    'Teléfono',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _campo(
                    correoController,
                    'Correo',
                    Icons.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  _campo(rucController, 'RUC', Icons.numbers),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
              ),
              child: Text(proveedor == null ? 'Guardar' : 'Actualizar'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'nombre': nombreController.text.trim(),
                    'ciudad': ciudadController.text.trim(),
                    'direccion': direccionController.text.trim(),
                    'telefono': telefonoController.text.trim(),
                    'correo': correoController.text.trim(),
                    'ruc': rucController.text.trim(),
                  };

                  if (docId == null) {
                    await FirebaseFirestore.instance
                        .collection('proveedores')
                        .add(data);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('proveedores')
                        .doc(docId)
                        .update(data);
                  }

                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF4682B4)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }
}
