import 'package:basefundi/services/importarcontactos.dart';
import 'package:basefundi/services/transition.dart';
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
    _tabController = TabController(length: 3, vsync: this); 
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
                hintText: _getSearchHint(),
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
          if (_tabController.index != 2) // Solo mostrar filtro de ciudad para clientes y proveedores
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
                underline: const SizedBox(),
                dropdownColor: Colors.white,
                style: const TextStyle(color: Colors.black),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
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

  String _getSearchHint() {
    switch (_tabController.index) {
      case 0:
      case 1:
        return 'Buscar por nombre o RUC';
      case 2:
        return 'Buscar por nombre o cédula';
      default:
        return 'Buscar...';
    }
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
              final ruc = (contacto['ruc'] ?? '').toString().toLowerCase();
              final ciudad = contacto['ciudad'] ?? '';
              final coincideBusqueda =
                  nombre.contains(_busqueda) || ruc.contains(_busqueda);
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
              child: Container(
                color: Colors.white, // 🔹 fondo blanco forzado
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
                          contacto['ruc'] ?? '',
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
                                  docId:
                                      docId, // Ahora pasamos el docId correcto
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmarEliminacion(
                                docId,
                                contacto,
                                coleccion,
                                tipoTexto,
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _mostrarDetalle(contacto),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTablaUsuarios() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('usuarios')
              .orderBy('nombre')
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        // Crear una lista con los datos Y el docId
        final usuariosConId =
            snapshot.data!.docs
                .map(
                  (doc) => {
                    'data': doc.data() as Map<String, dynamic>,
                    'docId': doc.id,
                  },
                )
                .toList();

        // Filtrar usuarios
        final filtrados =
            usuariosConId.where((item) {
              final usuario = item['data'] as Map<String, dynamic>;
              final nombre =
                  (usuario['nombre'] ?? '').toString().toLowerCase();
              final cedula = (usuario['cedula'] ?? '').toString().toLowerCase();
              final coincideBusqueda =
                  nombre.contains(_busqueda) || cedula.contains(_busqueda);
              return coincideBusqueda;
            }).toList();

        final contador = filtrados.length;

        return Column(
          children: [
            _buildSearchBar([]), // Sin filtro de ciudad para usuarios
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
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final item = filtrados[index];
                    final usuario = item['data'] as Map<String, dynamic>;
                    final docId = item['docId'] as String;

                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF4682B4),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          usuario['nombre'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          usuario['cedula'] ?? '',
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
                                _mostrarFormularioUsuario(
                                  context,
                                  usuario,
                                  docId: docId,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmarEliminacion(
                                docId,
                                usuario,
                                'usuarios',
                                'Usuario',
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _mostrarDetalleUsuario(usuario),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarEliminacion(
    String docId,
    Map<String, dynamic> item,
    String coleccion,
    String tipoTexto,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
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
                  const Icon(
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
                          fontWeight: FontWeight.bold,
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                        ),
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Eliminar',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
      await _eliminarItem(docId, item, coleccion, tipoTexto);
    }
  }

  Future<void> _eliminarItem(
    String docId,
    Map<String, dynamic> item,
    String coleccion,
    String tipoTexto,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final usuarioDoc = await FirebaseFirestore.instance
          .collection('usuarios_activos')
          .doc(user?.uid)
          .get();

      final usuarioNombre = usuarioDoc.exists
          ? (usuarioDoc['nombre'] ?? 'Desconocido')
          : 'Desconocido';

      // Eliminar el item
      await FirebaseFirestore.instance
          .collection(coleccion)
          .doc(docId)
          .delete();

      // Guardar auditoría
      final auditoriaRef = FirebaseFirestore.instance
          .collection('auditoria_general')
          .doc();

      await auditoriaRef.set({
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': usuarioNombre,
        'usuario_uid': user?.uid ?? 'uid_desconocido',
        'accion': 'Eliminar $tipoTexto',
        'detalle':
            'Se eliminó el $tipoTexto: ${item['nombre'] ?? 'Sin nombre'}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 2) {
            // Usuarios
            _mostrarFormularioUsuario(context, null);
          } else {
            // Clientes o Proveedores
            final esCliente = _tabController.index == 0;
            _mostrarFormulario(context, null, esCliente: esCliente);
          }
        },
        backgroundColor: const Color(0xFF4682B4),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        child: MainDeskLayout(
          child: Container(
            color: Colors.white,
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
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              navegarConFade(
                                context,
                                const ImportarContactosScreen(),
                              );
                            },
                            icon: const Icon(
                              Icons.upload_file,
                              size: 18,
                              color: Color(0xFF2C3E50),
                            ),
                            label: const Text(
                              'IMPORTAR CSV',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF2C3E50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Container(
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
                        tabs: const [
                          Tab(text: 'Clientes'),
                          Tab(text: 'Proveedores'),
                          Tab(text: 'Usuarios'), // Nueva pestaña
                        ],
                      ),
                    ),
                  ),
                ),
                // Contenido de las pestañas
                Expanded(
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
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
                              _buildTablaUsuarios(), // Usuarios
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
                _info('Ciudad', contacto['ciudad']),
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

  void _mostrarDetalleUsuario(Map<String, dynamic> usuario) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            usuario['nombre'] ?? '-',
            style: const TextStyle(
              color: Color(0xFF4682B4),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _info('Cédula', usuario['cedula']),
                _info('Teléfono', usuario['telefono']),
                _info('Correo', usuario['correo']),
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
    final ciudadController = TextEditingController(text: contacto?['ciudad']);
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
              onPressed: () => _guardarContacto(
                _formKey,
                {
                  'nombre': nombreController.text.trim(),
                  'ruc': rucController.text.trim(),
                  'ciudad': ciudadController.text.trim(),
                  'direccion': direccionController.text.trim(),
                  'telefono': telefonoController.text.trim(),
                  'correo': correoController.text.trim(),
                },
                coleccion,
                tipoTexto,
                docId,
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarFormularioUsuario(
    BuildContext context,
    Map<String, dynamic>? usuario, {
    String? docId,
  }) {
    final _formKey = GlobalKey<FormState>();

    final nombreController = TextEditingController(text: usuario?['nombre']);
    final cedulaController = TextEditingController(text: usuario?['cedula']);
    final telefonoController = TextEditingController(text: usuario?['telefono']);
    final correoController = TextEditingController(text: usuario?['correo']);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFFD6EAF8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            usuario == null ? 'Nuevo Usuario' : 'Editar Usuario',
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
                            required: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _campo(
                            cedulaController,
                            'Cédula',
                            Icons.credit_card,
                            keyboardType: TextInputType.number,
                            required: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _campo(
                      telefonoController,
                      'Teléfono',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                      required: true,
                    ),
                    const SizedBox(height: 12),
                    _campo(
                      correoController,
                      'Correo',
                      Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      required: false, // Opcional
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
              child: Text(usuario == null ? 'Guardar' : 'Actualizar'),
              onPressed: () => _guardarUsuario(
                _formKey,
                {
                  'nombre': nombreController.text.trim(),
                  'cedula': cedulaController.text.trim(),
                  'telefono': telefonoController.text.trim(),
                  'correo': correoController.text.trim(),
                },
                docId,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarContacto(
    GlobalKey<FormState> formKey,
    Map<String, dynamic> data,
    String coleccion,
    String tipoTexto,
    String? docId,
  ) async {
    if (formKey.currentState!.validate()) {
      try {
        // Obtener información del usuario para auditoría
        final user = FirebaseAuth.instance.currentUser;
        final usuarioDoc = await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user?.uid)
            .get();

        final usuarioNombre = usuarioDoc.exists
            ? (usuarioDoc['nombre'] ?? 'Desconocido')
            : 'Desconocido';

        String accionAuditoria;
        String detalleAuditoria;

        if (docId == null) {
          // Crear nuevo contacto
          await FirebaseFirestore.instance.collection(coleccion).add(data);

          accionAuditoria = 'Crear $tipoTexto';
          detalleAuditoria = 'Se creó un nuevo $tipoTexto: ${data['nombre']}';

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
          detalleAuditoria = 'Se editó el $tipoTexto: ${data['nombre']}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$tipoTexto actualizado exitosamente'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Guardar auditoría
        final auditoriaRef =
            FirebaseFirestore.instance.collection('auditoria_general').doc();

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
  }

  Future<void> _guardarUsuario(
    GlobalKey<FormState> formKey,
    Map<String, dynamic> data,
    String? docId,
  ) async {
    if (formKey.currentState!.validate()) {
      try {
        // Obtener información del usuario para auditoría
        final user = FirebaseAuth.instance.currentUser;
        final usuarioDoc = await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .doc(user?.uid)
            .get();

        final usuarioNombre = usuarioDoc.exists
            ? (usuarioDoc['nombre'] ?? 'Desconocido')
            : 'Desconocido';

        String accionAuditoria;
        String detalleAuditoria;

        if (docId == null) {
          // Crear nuevo usuario
          await FirebaseFirestore.instance.collection('usuarios').add(data);

          accionAuditoria = 'Crear Usuario';
          detalleAuditoria = 'Se creó un nuevo Usuario: ${data['nombre']}';

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Actualizar usuario existente
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(docId)
              .update(data);

          accionAuditoria = 'Editar Usuario';
          detalleAuditoria = 'Se editó el Usuario: ${data['nombre']}';

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado exitosamente'),
              backgroundColor: Colors.blue,
            ),
          );
        }

        // Guardar auditoría
        final auditoriaRef =
            FirebaseFirestore.instance.collection('auditoria_general').doc();

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
  }

  Widget _campo(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
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
          if (required && (value == null || value.trim().isEmpty)) {
            return 'Este campo es obligatorio';
          }
          if (!required && (value == null || value.trim().isEmpty)) {
            return null; // Campo opcional vacío es válido
          }
          if (label == 'Correo' && value!.isNotEmpty) {
            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
            if (!emailRegex.hasMatch(value)) {
              return 'Ingrese un correo válido';
            }
          }
          return null;
        },
      ),
    );
  }
}