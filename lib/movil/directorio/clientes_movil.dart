import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
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
          'Clientes',
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
                      .collection('clientes')
                      .orderBy('nombre')
                      .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final clientes =
                    snapshot.data!.docs
                        .map((e) => e.data() as Map<String, dynamic>)
                        .toList();

                final ciudades =
                    clientes.map((c) => c['ciudad'] ?? '').toSet().toList()
                      ..removeWhere((c) => c.isEmpty);

                final filtrados =
                    clientes.where((cliente) {
                      final nombre =
                          (cliente['nombre'] ?? '').toString().toLowerCase();
                      final empresa =
                          (cliente['empresa'] ?? '').toString().toLowerCase();
                      final ciudad = cliente['ciudad'] ?? '';
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
                      padding: const EdgeInsets.only(left: 16, right: 16),
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
                          final cliente = filtrados[index];
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                cliente['nombre'] ?? '-',
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
                                        cliente,
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
                                      // Mostrar un diálogo para confirmar eliminación (opcional)
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: const Text(
                                                'Confirmar eliminación',
                                              ),
                                              content: const Text(
                                                '¿Estás seguro de eliminar este cliente?',
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
                                            .collection('clientes')
                                            .doc(docId)
                                            .delete();

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cliente eliminado'),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => _mostrarDetalle(cliente),
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

  void _mostrarDetalle(Map<String, dynamic> cliente) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            cliente['nombre'] ?? '-',
            style: const TextStyle(
              color: Color(0xFF4682B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('RUC', cliente['ruc']),
                _info('País', cliente['pais']),
                _info('Provincia', cliente['provincia']),
                _info('Ciudad', cliente['ciudad']),
                _info('Empresa', cliente['empresa']),
                _info('Dirección', cliente['direccion']),
                Row(
                  children: [
                    const Text(
                      'Teléfono: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    GestureDetector(
                      onTap: () => _llamarTelefono(cliente['telefono'] ?? ''),
                      child: Text(
                        cliente['telefono'] ?? '-',
                        style: const TextStyle(
                          color: Color(0xFF4682B4),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _info('Correo', cliente['correo']),
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
    Map<String, dynamic>? cliente, {
    String? docId,
  }) {
    final _formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: cliente?['nombre']);
    final rucController = TextEditingController(text: cliente?['ruc']);
    final paisController = TextEditingController(
      text: cliente == null ? 'Ecuador' : cliente['pais'],
    );
    final provinciaController = TextEditingController(
      text: cliente?['provincia'],
    );
    final ciudadController = TextEditingController(text: cliente?['ciudad']);
    final empresaController = TextEditingController(text: cliente?['empresa']);
    final direccionController = TextEditingController(
      text: cliente?['direccion'],
    );
    final telefonoController = TextEditingController(
      text: cliente?['telefono'],
    );
    final correoController = TextEditingController(text: cliente?['correo']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD6EAF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            cliente == null ? 'Nuevo Cliente' : 'Editar Cliente',
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
              child: Text(cliente == null ? 'Guardar' : 'Actualizar'),
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
                        .collection('clientes')
                        .add(data);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('clientes')
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
