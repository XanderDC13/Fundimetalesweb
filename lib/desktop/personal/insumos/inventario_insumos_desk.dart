import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InventarioInsumosDeskScreen extends StatefulWidget {
  const InventarioInsumosDeskScreen({super.key});

  @override
  State<InventarioInsumosDeskScreen> createState() =>
      _InventarioInsumosDeskScreenState();
}

class _InventarioInsumosDeskScreenState
    extends State<InventarioInsumosDeskScreen> {
  String filtroBusqueda = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventario de Insumos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar insumo...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
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
            const SizedBox(height: 24),
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
                    return const Center(
                      child: Text('No hay insumos registrados'),
                    );
                  }

                  final insumos =
                      snapshot.data!.docs.where((doc) {
                        final nombre =
                            (doc['nombre'] ?? '').toString().toLowerCase();
                        return nombre.contains(filtroBusqueda);
                      }).toList();

                  if (insumos.isEmpty) {
                    return const Center(
                      child: Text('No se encontraron insumos'),
                    );
                  }

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 32,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'Nombre',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Descripción',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Cantidad',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                        DataColumn(
                          label: Text(
                            'Acciones',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                      rows:
                          insumos.map((doc) {
                            final insumo = doc.data() as Map<String, dynamic>;
                            final cantidad = (insumo['cantidad'] ?? 0) as int;

                            return DataRow(
                              cells: [
                                DataCell(Text(insumo['nombre'] ?? '')),
                                DataCell(Text(insumo['descripcion'] ?? '')),
                                DataCell(
                                  Center(
                                    child: Text(
                                      cantidad.toString(),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.blue,
                                        ),
                                        tooltip: 'Agregar Stock',
                                        onPressed:
                                            () => _mostrarDialogoAgregarStock(
                                              doc.id,
                                              cantidad,
                                              insumo['nombre'] ?? '',
                                            ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.redAccent,
                                        ),
                                        tooltip: 'Eliminar Insumo',
                                        onPressed:
                                            () => _mostrarDialogoEliminar(
                                              doc.id,
                                              insumo['nombre'] ?? '',
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _mostrarFormularioAgregar,
              icon: const Icon(Icons.add),
              label: const Text('Agregar Insumo'),
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
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioAgregar() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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

  void _mostrarDialogoEliminar(String insumoId, String nombreInsumo) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Eliminar insumo'),
            content: Text('¿Seguro que deseas eliminar "$nombreInsumo"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmacion == true) {
      await FirebaseFirestore.instance
          .collection('inventario_insumos')
          .doc(insumoId)
          .delete();
      await _registrarAuditoria(
        accion: 'Eliminar Insumo',
        detalle: 'Insumo eliminado: $nombreInsumo',
      );
    }
  }

  void _mostrarDialogoAgregarStock(
    String insumoId,
    int stockActual,
    String nombreInsumo,
  ) {
    final TextEditingController cantidadAgregarCtrl = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Agregar stock a: $nombreInsumo'),
            content: TextField(
              controller: cantidadAgregarCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Cantidad a agregar',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final cantidad =
                      int.tryParse(cantidadAgregarCtrl.text.trim()) ?? 0;
                  if (cantidad <= 0) return;

                  final ref = FirebaseFirestore.instance
                      .collection('inventario_insumos')
                      .doc(insumoId);
                  await FirebaseFirestore.instance.runTransaction((txn) async {
                    final snapshot = await txn.get(ref);
                    final actual = (snapshot['cantidad'] ?? 0) as int;
                    txn.update(ref, {'cantidad': actual + cantidad});
                  });

                  await _registrarAuditoria(
                    accion: 'Agregar Stock',
                    detalle:
                        'Insumo: $nombreInsumo, Cantidad agregada: $cantidad',
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Agregar'),
              ),
            ],
          ),
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
      final doc =
          await FirebaseFirestore.instance
              .collection('usuarios_activos')
              .doc(user.uid)
              .get();
      if (doc.exists) {
        nombreUsuario = doc['nombre'] ?? nombreUsuario;
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
                validator:
                    (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Ingresa un nombre válido'
                            : null,
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
                validator:
                    (value) =>
                        (int.tryParse(value ?? '') == null ||
                                int.parse(value!) < 0)
                            ? 'Cantidad inválida'
                            : null,
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

    setState(() => guardando = true);

    final nombre = _nombreController.text.trim();
    await FirebaseFirestore.instance.collection('inventario_insumos').add({
      'nombre': nombre,
      'descripcion': _descripcionController.text.trim(),
      'cantidad': int.tryParse(_cantidadController.text.trim()) ?? 0,
      'fecha': FieldValue.serverTimestamp(),
    });

    widget.onGuardado(nombre);

    setState(() => guardando = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Insumo agregado correctamente')),
    );
  }
}
