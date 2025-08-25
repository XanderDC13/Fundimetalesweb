import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:basefundi/services/navbar_desk.dart';

class ContactosDeskScreen extends StatefulWidget {
  const ContactosDeskScreen({super.key});

  @override
  State<ContactosDeskScreen> createState() => _ContactosDeskScreenState();
}

class _ContactosDeskScreenState extends State<ContactosDeskScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _busqueda = '';
  String? _filtroCiudad;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.transparent),
            ),
            child: DropdownButton<String?>(
              value: _filtroCiudad,
              hint: const Text('Ciudad'),
              underline: const SizedBox(), // quita la línea de abajo
              dropdownColor:
                  Colors.white, // Color de fondo del menú desplegable
              style: const TextStyle(color: Colors.black), // Color del texto
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Colors.black,
              ), // Color del ícono
              onChanged: (value) {
                setState(() {
                  _filtroCiudad = value;
                });
              },
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas'),
                ),
                ...ciudades.map(
                  (c) => DropdownMenuItem<String?>(value: c, child: Text(c)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablaContactos(bool esCliente) {
    final String coleccion = esCliente ? 'clientes' : 'proveedores';
    final String tipoTexto = esCliente ? 'Cliente' : 'Proveedor';

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection(coleccion)
              .orderBy('nombre')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Crear una lista con los datos Y el docId
        final contactosConId =
            snapshot.data!.docs
                .map(
                  (doc) => {
                    'data': doc.data() as Map<String, dynamic>,
                    'docId': doc.id,
                  },
                )
                .toList();

        final ciudades =
            contactosConId
                .map(
                  (item) =>
                      (item['data'] as Map<String, dynamic>)['ciudad'] ?? '',
                )
                .toSet()
                .toList()
              ..removeWhere((c) => (c as String).isEmpty);

        // Filtrar manteniendo la referencia al docId
        final filtrados =
            contactosConId.where((item) {
              final contacto = item['data'] as Map<String, dynamic>;
              final nombre =
                  (contacto['nombre'] ?? '').toString().toLowerCase();
              final empresa =
                  (contacto['empresa'] ?? '').toString().toLowerCase();
              final ciudad = contacto['ciudad'] ?? '';
              final coincideBusqueda =
                  nombre.contains(_busqueda) || empresa.contains(_busqueda);
              final coincideCiudad =
                  _filtroCiudad == null ? true : ciudad == _filtroCiudad;
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
                  final item = filtrados[index];
                  final contacto = item['data'] as Map<String, dynamic>;
                  final docId = item['docId'] as String;

                  return Card(
                    color: Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(
                        contacto['nombre'] ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        contacto['empresa'] ?? '',
                        style: const TextStyle(fontSize: 12),
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
                                contacto,
                                esCliente: esCliente,
                                docId: docId, // Ahora pasamos el docId correcto
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => Center(
                                      child: ConstrainedBox(
                                        constraints: const BoxConstraints(
                                          maxWidth: 500,
                                        ),
                                        child: Dialog(
                                          backgroundColor: Colors.transparent,
                                          insetPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 24,
                                              ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.2),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 24,
                                              horizontal: 28,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.warning_amber_rounded,
                                                  color: Colors.redAccent,
                                                  size: 48,
                                                ),
                                                const SizedBox(height: 12),
                                                Text(
                                                  'Eliminar $tipoTexto',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.black87,
                                                      ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '¿Seguro que deseas eliminar este $tipoTexto?',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Colors.black54,
                                                      ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 28),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                            foregroundColor:
                                                                Colors
                                                                    .grey[700],
                                                          ),
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        'Cancelar',
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                12,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed:
                                                          () => Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        'Eliminar',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                              );

                              if (confirm == true) {
                                try {
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  final usuarioDoc =
                                      await FirebaseFirestore.instance
                                          .collection('usuarios_activos')
                                          .doc(user?.uid)
                                          .get();

                                  final usuarioNombre =
                                      usuarioDoc.exists
                                          ? (usuarioDoc['nombre'] ??
                                              'Desconocido')
                                          : 'Desconocido';

                                  // Eliminar el contacto
                                  await FirebaseFirestore.instance
                                      .collection(coleccion)
                                      .doc(docId)
                                      .delete();

                                  // Guardar auditoría
                                  final auditoriaRef =
                                      FirebaseFirestore.instance
                                          .collection('auditoria_general')
                                          .doc();

                                  await auditoriaRef.set({
                                    'fecha': FieldValue.serverTimestamp(),
                                    'usuario_nombre': usuarioNombre,
                                    'usuario_uid':
                                        user?.uid ?? 'uid_desconocido',
                                    'accion': 'Eliminar $tipoTexto',
                                    'detalle':
                                        'Se eliminó el $tipoTexto: ${contacto['nombre'] ?? 'Sin nombre'} - ${contacto['empresa'] ?? 'Sin empresa'}',
                                  });

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$tipoTexto eliminado'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error al eliminar: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () => _mostrarDetalle(contacto),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final esCliente = _tabController.index == 0;
          _mostrarFormulario(context, null, esCliente: esCliente);
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
                        'Contactos',
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
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  onTap: (index) {
                    setState(() {
                      _busqueda = '';
                      _filtroCiudad = null;
                    });
                  },
                  tabs: const [Tab(text: 'Clientes'), Tab(text: 'Proveedores')],
                ),
              ),
            ),
            // Contenido de las pestañas
            Expanded(
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTablaContactos(true), // Clientes
                          _buildTablaContactos(false), // Proveedores
                        ],
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

  void _mostrarDetalle(Map<String, dynamic> contacto) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            contacto['nombre'] ?? '-',
            style: const TextStyle(
              color: Color(0xFF4682B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('RUC', contacto['ruc']),
                _info('País', contacto['pais']),
                _info('Provincia', contacto['provincia']),
                _info('Ciudad', contacto['ciudad']),
                _info('Empresa', contacto['empresa']),
                _info('Dirección', contacto['direccion']),
                _info('Teléfono', contacto['telefono']),
                _info('Correo', contacto['correo']),
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
    Map<String, dynamic>? contacto, {
    required bool esCliente,
    String? docId,
  }) {
    final _formKey = GlobalKey<FormState>();
    final String tipoTexto = esCliente ? 'Cliente' : 'Proveedor';
    final String coleccion = esCliente ? 'clientes' : 'proveedores';

    final nombreController = TextEditingController(text: contacto?['nombre']);
    final rucController = TextEditingController(text: contacto?['ruc']);
    final paisController = TextEditingController(
      text: contacto == null ? 'ECUADOR' : contacto['pais'],
    );
    final provinciaController = TextEditingController(
      text: contacto?['provincia'],
    );
    final ciudadController = TextEditingController(text: contacto?['ciudad']);
    final empresaController = TextEditingController(text: contacto?['empresa']);
    final direccionController = TextEditingController(
      text: contacto?['direccion'],
    );
    final telefonoController = TextEditingController(
      text: contacto?['telefono'],
    );
    final correoController = TextEditingController(text: contacto?['correo']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD6EAF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            contacto == null ? 'Nuevo $tipoTexto' : 'Editar $tipoTexto',
            style: const TextStyle(
              color: Color(0xFF4682B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _campo(
                            nombreController,
                            'Nombre',
                            Icons.person,
                          ),
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
              child: Text(contacto == null ? 'Guardar' : 'Actualizar'),
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

                  try {
                    // Obtener información del usuario para auditoría
                    final user = FirebaseAuth.instance.currentUser;
                    final usuarioDoc =
                        await FirebaseFirestore.instance
                            .collection('usuarios_activos')
                            .doc(user?.uid)
                            .get();

                    final usuarioNombre =
                        usuarioDoc.exists
                            ? (usuarioDoc['nombre'] ?? 'Desconocido')
                            : 'Desconocido';

                    String accionAuditoria;
                    String detalleAuditoria;

                    if (docId == null) {
                      // Crear nuevo contacto
                      await FirebaseFirestore.instance
                          .collection(coleccion)
                          .add(data);

                      accionAuditoria = 'Crear $tipoTexto';
                      detalleAuditoria =
                          'Se creó un nuevo $tipoTexto: ${data['nombre']} - ${data['empresa']}';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$tipoTexto creado exitosamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Actualizar contacto existente
                      await FirebaseFirestore.instance
                          .collection(coleccion)
                          .doc(docId)
                          .update(data);

                      accionAuditoria = 'Editar $tipoTexto';
                      detalleAuditoria =
                          'Se editó el $tipoTexto: ${data['nombre']} - ${data['empresa']}';

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$tipoTexto actualizado exitosamente'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }

                    // Guardar auditoría
                    final auditoriaRef =
                        FirebaseFirestore.instance
                            .collection('auditoria_general')
                            .doc();

                    await auditoriaRef.set({
                      'fecha': FieldValue.serverTimestamp(),
                      'usuario_nombre': usuarioNombre,
                      'usuario_uid': user?.uid ?? 'uid_desconocido',
                      'accion': accionAuditoria,
                      'detalle': detalleAuditoria,
                    });

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF4682B4)),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          isDense: true,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo es obligatorio';
          }
          return null;
        },
      ),
    );
  }
}
