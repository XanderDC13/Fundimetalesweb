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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Inventario de Insumos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
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
                                          Icons.edit_outlined,
                                          color: Color(0xFF4682B4),
                                        ),
                                        tooltip: 'Editar Insumo',
                                        onPressed:
                                            () => _mostrarFormularioEditar(
                                              doc.id,
                                              insumo,
                                            ),
                                      ),
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
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Agregar insumo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _AgregarInsumoForm(onGuardado: _registrarAuditoriaNuevo),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _mostrarFormularioEditar(String insumoId, Map<String, dynamic> insumo) {
    showDialog(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Editar insumo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _EditarInsumoForm(
                        insumoId: insumoId,
                        insumoData: insumo,
                        onEditado: _registrarAuditoriaEdicion,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _mostrarDialogoEliminar(String insumoId, String nombreInsumo) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
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
                        'Eliminar insumo',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Seguro que deseas eliminar "$nombreInsumo"?',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
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
                            child: Text(
                              'Eliminar',
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
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

    if (confirmacion == true) {
      await FirebaseFirestore.instance
          .collection('inventario_insumos')
          .doc(insumoId)
          .delete();
      await _registrarAuditoria(
        accion: 'Eliminar Insumo',
        detalle: nombreInsumo,
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
          (context) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 12,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 32,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Agregar stock',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        nombreInsumo,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: cantidadAgregarCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Cantidad a agregar',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4682B4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final cantidadAgregar =
                                  int.tryParse(
                                    cantidadAgregarCtrl.text.trim(),
                                  ) ??
                                  0;
                              if (cantidadAgregar <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Ingresa una cantidad válida',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final docRef = FirebaseFirestore.instance
                                  .collection('inventario_insumos')
                                  .doc(insumoId);

                              try {
                                await FirebaseFirestore.instance.runTransaction(
                                  (transaction) async {
                                    final snapshot = await transaction.get(
                                      docRef,
                                    );
                                    final stock =
                                        (snapshot['cantidad'] ?? 0) as int;

                                    transaction.update(docRef, {
                                      'cantidad': stock + cantidadAgregar,
                                    });
                                  },
                                );

                                await _registrarAuditoria(
                                  accion: 'Agregar Stock Insumos',
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
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Agregar',
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
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
  }

  Future<void> _registrarAuditoriaNuevo(String nombreInsumo) async {
    await _registrarAuditoria(
      accion: 'Agregar Nuevo Insumo',
      detalle: nombreInsumo,
    );
  }

  Future<void> _registrarAuditoriaEdicion(
    String nombreInsumo,
    Map<String, dynamic> cambios,
  ) async {
    String detalle = 'Insumo: $nombreInsumo';
    if (cambios.isNotEmpty) {
      final cambiosTexto = cambios.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      detalle += ' - Cambios: $cambiosTexto';
    }

    await _registrarAuditoria(accion: 'Editar Insumo', detalle: detalle);
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del insumo',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator:
                      (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Ingresa un nombre válido'
                              : null,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad inicial',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator:
                      (value) =>
                          (int.tryParse(value ?? '') == null ||
                                  int.parse(value!) < 0)
                              ? 'Cantidad inválida'
                              : null,
                ),
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

class _EditarInsumoForm extends StatefulWidget {
  final String insumoId;
  final Map<String, dynamic> insumoData;
  final void Function(String nombreInsumo, Map<String, dynamic> cambios)
  onEditado;

  const _EditarInsumoForm({
    required this.insumoId,
    required this.insumoData,
    required this.onEditado,
  });

  @override
  State<_EditarInsumoForm> createState() => _EditarInsumoFormState();
}

class _EditarInsumoFormState extends State<_EditarInsumoForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _cantidadController;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(
      text: widget.insumoData['nombre'] ?? '',
    );
    _cantidadController = TextEditingController(
      text: (widget.insumoData['cantidad'] ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    super.dispose();
  }

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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del insumo',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator:
                      (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Ingresa un nombre válido'
                              : null,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _cantidadController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Cantidad',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  validator:
                      (value) =>
                          (int.tryParse(value ?? '') == null ||
                                  int.parse(value!) < 0)
                              ? 'Cantidad inválida'
                              : null,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: guardando ? null : _actualizarInsumo,
                    icon: const Icon(Icons.save),
                    label:
                        guardando
                            ? const Text('Actualizando...')
                            : const Text('Actualizar'),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _actualizarInsumo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => guardando = true);

    final nombreNuevo = _nombreController.text.trim();
    final cantidadNueva = int.tryParse(_cantidadController.text.trim()) ?? 0;

    // Detectar cambios
    final cambios = <String, dynamic>{};

    if (nombreNuevo != (widget.insumoData['nombre'] ?? '')) {
      cambios['nombre anterior'] = widget.insumoData['nombre'] ?? '';
      cambios['nombre nuevo'] = nombreNuevo;
    }

    if (cantidadNueva != (widget.insumoData['cantidad'] ?? 0)) {
      cambios['cant anterior'] = widget.insumoData['cantidad'] ?? 0;
      cambios['cant nueva'] = cantidadNueva;
    }

    try {
      await FirebaseFirestore.instance
          .collection('inventario_insumos')
          .doc(widget.insumoId)
          .update({'nombre': nombreNuevo, 'cantidad': cantidadNueva});

      widget.onEditado(nombreNuevo, cambios);

      setState(() => guardando = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insumo actualizado correctamente')),
      );
    } catch (e) {
      setState(() => guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.toString()}')),
      );
    }
  }
}
