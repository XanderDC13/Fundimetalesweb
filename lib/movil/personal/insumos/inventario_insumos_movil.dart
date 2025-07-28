import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Si tienes auth

class InventarioInsumosWidget extends StatefulWidget {
  final Color colorTarjeta;
  const InventarioInsumosWidget({
    super.key,
    this.colorTarjeta = const Color(0xFFE3F2FD),
  });

  @override
  State<InventarioInsumosWidget> createState() =>
      _InventarioInsumosWidgetState();
}

class _InventarioInsumosWidgetState extends State<InventarioInsumosWidget> {
  String filtroBusqueda = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar insumo...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (valor) {
              setState(() {
                filtroBusqueda = valor.trim().toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('inventario_insumos')
                    .orderBy('fecha', descending: true)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No hay insumos registrados'));
              }

              final insumos =
                  snapshot.data!.docs.where((doc) {
                    final nombre =
                        (doc['nombre'] ?? '').toString().toLowerCase();
                    return nombre.contains(filtroBusqueda);
                  }).toList();

              if (insumos.isEmpty) {
                return const Center(child: Text('No se encontraron insumos'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: insumos.length,
                itemBuilder: (context, index) {
                  final insumo = insumos[index];
                  final cantidad = (insumo['cantidad'] ?? 0) as int;

                  return Card(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        insumo['nombre'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cantidad: $cantidad'),
                          Text('Descripción: ${insumo['descripcion'] ?? ''}'),
                        ],
                      ),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Eliminar Insumo',
                            onPressed:
                                () => _mostrarDialogoEliminar(
                                  insumo.id,
                                  insumo['nombre'] ?? '',
                                ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              color: Color(0xFF4682B4),
                            ),
                            tooltip: 'Agregar Stock',
                            onPressed:
                                () => _mostrarDialogoAgregarStock(
                                  insumo.id,
                                  cantidad,
                                  insumo['nombre'],
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _mostrarFormularioAgregar,
            icon: const Icon(Icons.add),
            label: const Text('Agregar Insumo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4682B4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarFormularioAgregar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: _AgregarInsumoForm(onGuardado: _registrarAuditoriaNuevo),
        );
      },
    );
  }

  void _mostrarDialogoEliminar(String insumoId, String nombreInsumo) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Eliminar insumo'),
          content: Text(
            '¿Seguro que quieres eliminar "$nombreInsumo"? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                try {
                  await FirebaseFirestore.instance
                      .collection('inventario_insumos')
                      .doc(insumoId)
                      .delete();

                  await _registrarAuditoria(
                    accion: 'Eliminar Insumo',
                    detalle: 'Insumo eliminado: $nombreInsumo',
                  );

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Insumo "$nombreInsumo" eliminado')),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e')),
                  );
                }
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoAgregarStock(
    String insumoId,
    int stockActual,
    String nombreInsumo,
  ) {
    final TextEditingController cantidadAgregarCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white, // Fondo blanco puro
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('Agregar stock a: $nombreInsumo'),
          content: TextField(
            controller: cantidadAgregarCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Cantidad a agregar',
              hintText: 'Ej: 5',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cantidadAgregar =
                    int.tryParse(cantidadAgregarCtrl.text.trim()) ?? 0;
                if (cantidadAgregar <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ingresa una cantidad válida'),
                    ),
                  );
                  return;
                }

                final docRef = FirebaseFirestore.instance
                    .collection('inventario_insumos')
                    .doc(insumoId);

                try {
                  await FirebaseFirestore.instance.runTransaction((
                    transaction,
                  ) async {
                    final snapshot = await transaction.get(docRef);
                    final stock = (snapshot['cantidad'] ?? 0) as int;

                    transaction.update(docRef, {
                      'cantidad': stock + cantidadAgregar,
                    });
                  });

                  await _registrarAuditoria(
                    accion: 'Agregar Stock',
                    detalle:
                        'Insumo: $nombreInsumo, Cantidad agregada: $cantidadAgregar',
                  );

                  Navigator.of(context).pop();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Se agregaron $cantidadAgregar unidades a "$nombreInsumo"',
                      ),
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Agregar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _registrarAuditoriaNuevo(String nombreInsumo) async {
    await _registrarAuditoria(
      accion: 'Agregar Nuevo Insumo',
      detalle: 'Nuevo insumo: $nombreInsumo',
    );
  }

  Future<void> _registrarAuditoria({
    required String accion,
    required String detalle,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    String nombreUsuario = 'Administrador';

    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        nombreUsuario = userDoc['nombre'] ?? nombreUsuario;
      }
    }

    await FirebaseFirestore.instance.collection('auditoria_general').add({
      'fecha': FieldValue.serverTimestamp(),
      'usuario_nombre': nombreUsuario,
      'accion': accion,
      'detalle': detalle,
    });
  }
}

class _AgregarInsumoForm extends StatefulWidget {
  final void Function(String nombreInsumo) onGuardado;

  const _AgregarInsumoForm({required this.onGuardado});

  @override
  State<_AgregarInsumoForm> createState() => _AgregarInsumoFormState();
}

class _AgregarInsumoFormState extends State<_AgregarInsumoForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _cantidadController = TextEditingController(
    text: '0',
  );

  bool guardando = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nuevo Insumo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del insumo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa un nombre válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Cantidad inicial',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed < 0) {
                    return 'Cantidad inválida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: guardando ? null : _guardarInsumo,
                icon: const Icon(Icons.save),
                label:
                    guardando
                        ? const Text('Guardando...')
                        : const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4682B4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarInsumo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      guardando = true;
    });

    final nombreInsumo = _nombreController.text.trim();

    await FirebaseFirestore.instance.collection('inventario_insumos').add({
      'nombre': nombreInsumo,
      'descripcion': _descripcionController.text.trim(),
      'cantidad': int.tryParse(_cantidadController.text.trim()) ?? 0,
      'fecha': FieldValue.serverTimestamp(),
    });

    widget.onGuardado(nombreInsumo);

    setState(() {
      guardando = false;
    });

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Insumo agregado correctamente')),
    );
  }
}
