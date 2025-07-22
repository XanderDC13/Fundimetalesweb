import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class ProveedoresDeskScreen extends StatefulWidget {
  const ProveedoresDeskScreen({super.key});

  @override
  State<ProveedoresDeskScreen> createState() => _ProveedoresDeskScreen();
}

class _ProveedoresDeskScreen extends State<ProveedoresDeskScreen> {
  String _busqueda = '';
  String? _filtroCiudad;

  Widget _buildSearchBar(List<String> ciudades) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _busqueda = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o empresa',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          DropdownButton<String>(
            value: _filtroCiudad,
            hint: const Text('Ciudad'),
            onChanged: (value) {
              setState(() {
                _filtroCiudad = value;
              });
            },
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              ...ciudades.map(
                (c) => DropdownMenuItem(value: c, child: Text(c)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarFormulario(context, null);
        },
        backgroundColor: const Color(0xFF4682B4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: MainDeskLayout(
        child: Column(
          children: [
            // Cabecera con flecha y contenido
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
                        'Proveedores',
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

            // ✅ CONTENIDO
            Expanded(
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('proveedores')
                                .orderBy('nombre')
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final proveedores =
                              snapshot.data!.docs
                                  .map((e) => e.data() as Map<String, dynamic>)
                                  .toList();

                          final ciudades =
                              proveedores
                                  .map((c) => c['ciudad'] ?? '')
                                  .toSet()
                                  .toList()
                                ..removeWhere((c) => c.isEmpty);

                          final filtrados =
                              proveedores.where((proveedores) {
                                final nombre =
                                    (proveedores['nombre'] ?? '')
                                        .toString()
                                        .toLowerCase();
                                final empresa =
                                    (proveedores['empresa'])
                                        .toString()
                                        .toLowerCase();
                                final ciudad = proveedores['ciudad'] ?? '';
                                final coincideBusqueda =
                                    nombre.contains(_busqueda) ||
                                    empresa.contains(_busqueda);
                                final coincideCiudad =
                                    _filtroCiudad == null
                                        ? true
                                        : ciudad == _filtroCiudad;
                                return coincideBusqueda && coincideCiudad;
                              }).toList();

                          final contador = filtrados.length;

                          return Column(
                            children: [
                              _buildSearchBar(ciudades.cast<String>()),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      'Total: $contador',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: filtrados.length,
                                  itemBuilder: (context, index) {
                                    final proveedores = filtrados[index];
                                    return Card(
                                      color: Colors.white,
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      elevation: 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          proveedores['nombre'] ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit_outlined,
                                                color: Color(0xFF4682B4),
                                              ),
                                              onPressed: () {
                                                _mostrarFormulario(
                                                  context,
                                                  proveedores,
                                                  docId:
                                                      snapshot
                                                          .data!
                                                          .docs[index]
                                                          .id,
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () async {
                                                final docId =
                                                    snapshot
                                                        .data!
                                                        .docs[index]
                                                        .id;
                                                final confirm = await showDialog<
                                                  bool
                                                >(
                                                  context: context,
                                                  builder:
                                                      (context) => AlertDialog(
                                                        title: const Text(
                                                          'Confirmar eliminación',
                                                        ),
                                                        content: const Text(
                                                          '¿Estás seguro de eliminar este proveedor?',
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            child: const Text(
                                                              'Cancelar',
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      false,
                                                                    ),
                                                          ),
                                                          TextButton(
                                                            child: const Text(
                                                              'Eliminar',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                              ),
                                                            ),
                                                            onPressed:
                                                                () =>
                                                                    Navigator.pop(
                                                                      context,
                                                                      true,
                                                                    ),
                                                          ),
                                                        ],
                                                      ),
                                                );

                                                if (confirm == true) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('proveedores')
                                                      .doc(docId)
                                                      .delete();

                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Proveedor eliminado',
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        onTap:
                                            () => _mostrarDetalle(proveedores),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> proveedores) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            proveedores['nombre'] ?? '-',
            style: const TextStyle(
              color: Color(0xFF4682B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('RUC', proveedores['ruc']),
                _info('País', proveedores['pais']),
                _info('Provincia', proveedores['provincia']),
                _info('Ciudad', proveedores['ciudad']),
                _info('Empresa', proveedores['empresa']),
                _info('Dirección', proveedores['direccion']),
                _info('Teléfono', proveedores['telefono']),
                _info('Correo', proveedores['correo']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cerrar',
                style: TextStyle(color: Color(0xFF4682B4)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _info(String label, String? valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$label: ${valor ?? '-'}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  void _mostrarFormulario(
    BuildContext context,
    Map<String, dynamic>? proveedores, {
    String? docId,
  }) {
    final _formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(
      text: proveedores?['nombre'],
    );
    final rucController = TextEditingController(text: proveedores?['ruc']);
    final paisController = TextEditingController(
      text: proveedores == null ? 'Ecuador' : proveedores['pais'],
    );
    final provinciaController = TextEditingController(
      text: proveedores?['provincia'],
    );
    final ciudadController = TextEditingController(
      text: proveedores?['ciudad'],
    );
    final empresaController = TextEditingController(
      text: proveedores?['empresa'],
    );
    final direccionController = TextEditingController(
      text: proveedores?['direccion'],
    );
    final telefonoController = TextEditingController(
      text: proveedores?['telefono'],
    );
    final correoController = TextEditingController(
      text: proveedores?['correo'],
    );

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD6EAF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            proveedores == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
            style: const TextStyle(
              color: Color(0xFF4682B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _campo(nombreController, 'Nombre', Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campo(rucController, 'RUC', Icons.business),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _campo(paisController, 'País', Icons.flag),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _campo(
                          provinciaController,
                          'Provincia',
                          Icons.map,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _campo(ciudadController, 'Ciudad', Icons.location_city),
                  const SizedBox(height: 12),
                  _campo(empresaController, 'Empresa', Icons.business),
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Color(0xFF4682B4)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4682B4),
                foregroundColor: Colors.white,
              ),
              child: Text(proveedores == null ? 'Guardar' : 'Actualizar'),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final data = {
                    'nombre': nombreController.text.trim(),
                    'ruc': rucController.text.trim(),
                    'pais': paisController.text.trim(),
                    'provincia': provinciaController.text.trim(),
                    'ciudad': ciudadController.text.trim(),
                    'empresa': empresaController.text.trim(),
                    'direccion': direccionController.text.trim(),
                    'telefono': telefonoController.text.trim(),
                    'correo': correoController.text.trim(),
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
