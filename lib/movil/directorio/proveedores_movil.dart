import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  String _busqueda = '';
  String? _filtroCiudad;

  Widget _buildHeader() {
    return SafeArea(
      child: Container(
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
        child: const Text(
          'Proveedores',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6EAF8),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('proveedores')
                      .orderBy('nombre')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final proveedores =
                    snapshot.data!.docs
                        .map((e) => e.data() as Map<String, dynamic>)
                        .toList();

                final ciudades =
                    proveedores.map((p) => p['ciudad'] ?? '').toSet().toList()
                      ..removeWhere((c) => c.isEmpty);

                final filtrados =
                    proveedores.where((proveedor) {
                      final nombre =
                          (proveedor['nombre'] ?? '').toString().toLowerCase();
                      final empresa =
                          (proveedor['empresa'] ?? '').toString().toLowerCase();
                      final ciudad = proveedor['ciudad'] ?? '';
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          final proveedor = filtrados[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                proveedor['nombre'] ?? '-',
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
                                        proveedor,
                                        docId: snapshot.data!.docs[index].id,
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
                                          snapshot.data!.docs[index].id;
                                      final confirm = await showDialog<bool>(
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
                                                  child: const Text('Cancelar'),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                ),
                                                TextButton(
                                                  child: const Text(
                                                    'Eliminar',
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                  onPressed:
                                                      () => Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                ),
                                              ],
                                            ),
                                      );

                                      if (confirm == true) {
                                        await FirebaseFirestore.instance
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
                              onTap: () => _mostrarDetalle(proveedor),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarFormulario(context, null);
        },
        backgroundColor: const Color(0xFF4682B4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _mostrarDetalle(Map<String, dynamic> proveedor) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD6EAF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            proveedor['nombre'] ?? '-',
            style: const TextStyle(
              color: Color(0xFF4682B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('RUC', proveedor['ruc']),
                _info('País', proveedor['pais']),
                _info('Provincia', proveedor['provincia']),
                _info('Ciudad', proveedor['ciudad']),
                _info('Empresa', proveedor['empresa']),
                _info('Dirección', proveedor['direccion']),
                Row(
                  children: [
                    const Text(
                      'Teléfono: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => _llamarTelefono(proveedor['telefono'] ?? ''),
                      child: Text(
                        proveedor['telefono'] ?? '-',
                        style: const TextStyle(
                          color: Color(0xFF4682B4),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _info('Correo', proveedor['correo']),
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
    Map<String, dynamic>? proveedor, {
    String? docId,
  }) {
    final _formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: proveedor?['nombre']);
    final rucController = TextEditingController(text: proveedor?['ruc']);
    final paisController = TextEditingController(
      text: proveedor == null ? 'Ecuador' : proveedor['pais'],
    );

    final provinciaController = TextEditingController(
      text: proveedor?['provincia'],
    );
    final ciudadController = TextEditingController(text: proveedor?['ciudad']);
    final empresaController = TextEditingController(
      text: proveedor?['empresa'],
    );
    final direccionController = TextEditingController(
      text: proveedor?['direccion'],
    );
    final telefonoController = TextEditingController(
      text: proveedor?['telefono'],
    );
    final correoController = TextEditingController(text: proveedor?['correo']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD6EAF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            proveedor == null ? 'Nuevo Proveedor' : 'Editar Proveedor',
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
              child: Text(proveedor == null ? 'Guardar' : 'Actualizar'),
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

  void _llamarTelefono(String numero) async {
    if (numero.isNotEmpty) {
      final Uri launchUri = Uri(scheme: 'tel', path: numero);
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el marcador.')),
        );
      }
    }
  }
}
