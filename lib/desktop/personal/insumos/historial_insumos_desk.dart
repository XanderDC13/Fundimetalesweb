import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistorialInsumosDeskWidget extends StatefulWidget {
  const HistorialInsumosDeskWidget({super.key});

  @override
  State<HistorialInsumosDeskWidget> createState() =>
      _HistorialInsumosDeskWidgetState();
}

class _HistorialInsumosDeskWidgetState
    extends State<HistorialInsumosDeskWidget> {
  // ─── Mes seleccionado ────────────────────────────────────────────────────
  DateTime _mesSeleccionado = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  // ─── Filtros ─────────────────────────────────────────────────────────────
  String _busqueda = '';
  String? _filtroEmpleado;
  String? _filtroInsumo;
  List<String> _empleadosFiltro = [];
  List<String> _insumosFiltro = [];
  final TextEditingController _busquedaController = TextEditingController();

  // ─── Caché de nombres ────────────────────────────────────────────────────
  final Map<String, String> _cacheNombresInsumo = {};
  final Map<String, String> _cacheNombresEmpleado = {};

  // ─── Fila expandida ──────────────────────────────────────────────────────
  String? _expandedDocId;

  @override
  void initState() {
    super.initState();
    _cargarFiltros();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  // ─── Cargar listas para filtros ──────────────────────────────────────────
  Future<void> _cargarFiltros() async {
    final snap =
        await FirebaseFirestore.instance
            .collection('solicitudes_insumos')
            .get();

    final empleados = <String>{};
    final insumos = <String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final empNombre = data['empleado_nombre'] ?? '';
      final insId = data['insumo_id'] ?? '';
      if (empNombre.toString().isNotEmpty) empleados.add(empNombre.toString());
      if (insId.toString().isNotEmpty) {
        final nombre = await _obtenerNombreInsumo(insId);
        insumos.add(nombre);
      }
    }

    if (mounted) {
      setState(() {
        _empleadosFiltro = empleados.toList()..sort();
        _insumosFiltro = insumos.toList()..sort();
      });
    }
  }

  // ─── Helpers de fecha ────────────────────────────────────────────────────
  String _formatearFecha(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  DateTime _inicioMes(DateTime mes) => DateTime(mes.year, mes.month, 1);
  DateTime _finMes(DateTime mes) => DateTime(mes.year, mes.month + 1, 1);
  String _nombreMes(DateTime mes) => DateFormat('MMMM yyyy').format(mes);

  void _mesAnterior() {
    setState(() {
      _mesSeleccionado = DateTime(
        _mesSeleccionado.year,
        _mesSeleccionado.month - 1,
      );
    });
  }

  void _mesSiguiente() {
    final ahora = DateTime.now();
    final siguiente = DateTime(
      _mesSeleccionado.year,
      _mesSeleccionado.month + 1,
    );
    if (!siguiente.isAfter(DateTime(ahora.year, ahora.month))) {
      setState(() => _mesSeleccionado = siguiente);
    }
  }

  // ─── Nombres con caché ───────────────────────────────────────────────────
  Future<String> _obtenerNombreInsumo(String insumoId) async {
    if (_cacheNombresInsumo.containsKey(insumoId)) {
      return _cacheNombresInsumo[insumoId]!;
    }
    final doc =
        await FirebaseFirestore.instance
            .collection('inventario_insumos')
            .doc(insumoId)
            .get();
    final nombre =
        doc.exists
            ? (doc['nombre'] ?? 'Insumo desconocido')
            : 'Insumo eliminado';
    _cacheNombresInsumo[insumoId] = nombre;
    return nombre;
  }

  Future<String> _obtenerNombreEmpleado(
    String empleadoId,
    DocumentSnapshot solicitud,
  ) async {
    final data = solicitud.data() as Map<String, dynamic>?;
    if (data != null && data.containsKey('empleado_nombre')) {
      final nombre = data['empleado_nombre'];
      if (nombre != null && nombre.toString().isNotEmpty) return nombre;
    }
    if (_cacheNombresEmpleado.containsKey(empleadoId)) {
      return _cacheNombresEmpleado[empleadoId]!;
    }
    final doc =
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(empleadoId)
            .get();
    final nombre =
        doc.exists
            ? (doc['nombre'] ?? 'Usuario desconocido')
            : 'Usuario eliminado';
    _cacheNombresEmpleado[empleadoId] = nombre;
    return nombre;
  }

  // ─── Filtrar documentos ──────────────────────────────────────────────────
  bool _aplicarFiltros(
    DocumentSnapshot doc,
    String nombreInsumo,
    String nombreEmpleado,
  ) {
    if (_busqueda.isNotEmpty) {
      final q = _busqueda.toLowerCase();
      if (!nombreInsumo.toLowerCase().contains(q) &&
          !nombreEmpleado.toLowerCase().contains(q)) {
        return false;
      }
    }
    if (_filtroEmpleado != null && !nombreEmpleado.contains(_filtroEmpleado!)) {
      return false;
    }
    if (_filtroInsumo != null && !nombreInsumo.contains(_filtroInsumo!)) {
      return false;
    }
    return true;
  }

  // ─── Exportar PDF con rango de fechas ────────────────────────────────────
  Future<void> _exportarPDF() async {
    DateTimeRange? rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _inicioMes(_mesSeleccionado),
        end: _finMes(_mesSeleccionado).subtract(const Duration(seconds: 1)),
      ),
      locale: const Locale('es'),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Color(0xFF4682B4),
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          ),
    );

    if (rango == null) return;

    final inicio = Timestamp.fromDate(rango.start);
    final fin = Timestamp.fromDate(
      DateTime(rango.end.year, rango.end.month, rango.end.day, 23, 59, 59),
    );

    final querySnapshot =
        await FirebaseFirestore.instance
            .collection('solicitudes_insumos')
            .orderBy('fecha', descending: true)
            .where('fecha', isGreaterThanOrEqualTo: inicio)
            .where('fecha', isLessThanOrEqualTo: fin)
            .get();

    if (querySnapshot.docs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay solicitudes en ese rango de fechas.'),
          ),
        );
      }
      return;
    }

    final lista = await Future.wait(
      querySnapshot.docs.map((doc) async {
        final cantidad = doc['cantidad'] ?? 0;
        final insumoId = doc['insumo_id'] ?? '';
        final empleadoId = doc['empleado_id'] ?? '';
        final fecha = (doc['fecha'] as Timestamp?)?.toDate();
        final nombreInsumo = await _obtenerNombreInsumo(insumoId);
        final nombreEmpleado = await _obtenerNombreEmpleado(empleadoId, doc);
        final fechaTexto =
            fecha != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(fecha)
                : 'Fecha desconocida';
        return {
          'insumo': nombreInsumo,
          'empleado': nombreEmpleado,
          'cantidad': cantidad,
          'fecha': fechaTexto,
        };
      }).toList(),
    );

    final pdf = pw.Document();
    final rangoTexto =
        '${DateFormat('dd/MM/yyyy').format(rango.start)} – ${DateFormat('dd/MM/yyyy').format(rango.end)}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build:
            (context) => [
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Historial de Solicitudes de Insumos',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.Text(
                      'Período: $rangoTexto',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.blueGrey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table.fromTextArray(
                border: null,
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                  ),
                ),
                cellPadding: const pw.EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 4,
                ),
                headers: ['Insumo', 'Cantidad', 'Usuario', 'Fecha'],
                data:
                    lista
                        .map(
                          (item) => [
                            item['insumo'],
                            item['cantidad'].toString(),
                            item['empleado'],
                            item['fecha'],
                          ],
                        )
                        .toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Total de solicitudes: ${lista.length}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey800,
                  ),
                ),
              ),
            ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ─── Editar cantidad ─────────────────────────────────────────────────────
  void _editarCantidadSolicitud(
    String docId,
    String insumoId,
    int cantidadActual,
  ) {
    final ctrl = TextEditingController(text: cantidadActual.toString());
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
                      Text(
                        'Editar cantidad',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Nueva cantidad',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) {
                          final cantidad = int.tryParse(value);
                          if (cantidad != null && cantidad >= 0) {
                            Navigator.pop(context, cantidad);
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[700],
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4682B4),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () async {
                              final nuevaCantidad =
                                  int.tryParse(ctrl.text) ?? cantidadActual;

                              if (nuevaCantidad == cantidadActual) {
                                Navigator.pop(context);
                                return;
                              }

                              try {
                                final insumoRef = FirebaseFirestore.instance
                                    .collection('inventario_insumos')
                                    .doc(insumoId);

                                await FirebaseFirestore.instance.runTransaction((
                                  transaction,
                                ) async {
                                  final insumoSnapshot = await transaction.get(
                                    insumoRef,
                                  );
                                  if (!insumoSnapshot.exists) {
                                    throw Exception('Insumo no encontrado.');
                                  }

                                  final stockActual =
                                      (insumoSnapshot['cantidad'] ?? 0) as int;
                                  final diferencia =
                                      nuevaCantidad - cantidadActual;
                                  final nuevoStock = stockActual - diferencia;

                                  if (nuevoStock < 0) {
                                    throw Exception(
                                      'Stock insuficiente en inventario.',
                                    );
                                  }

                                  transaction.update(insumoRef, {
                                    'cantidad': nuevoStock,
                                  });
                                  transaction.update(
                                    FirebaseFirestore.instance
                                        .collection('solicitudes_insumos')
                                        .doc(docId),
                                    {
                                      'cantidad': nuevaCantidad,
                                      'historial_ediciones':
                                          FieldValue.arrayUnion([
                                            {
                                              'fecha':
                                                  FieldValue.serverTimestamp(),
                                              'cantidad_anterior':
                                                  cantidadActual,
                                              'cantidad_nueva': nuevaCantidad,
                                              'editado_por':
                                                  FirebaseAuth
                                                      .instance
                                                      .currentUser
                                                      ?.uid ??
                                                  'desconocido',
                                            },
                                          ]),
                                    },
                                  );

                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  String auditor = 'Administrador';
                                  if (user != null) {
                                    final userDoc =
                                        await FirebaseFirestore.instance
                                            .collection('usuarios_activos')
                                            .doc(user.uid)
                                            .get();
                                    if (userDoc.exists) {
                                      auditor = userDoc['nombre'] ?? auditor;
                                    }
                                  }

                                  final insumoDoc = await insumoRef.get();
                                  final nombreInsumo =
                                      insumoDoc.exists
                                          ? (insumoDoc['nombre'] ?? insumoId)
                                          : insumoId;

                                  final auditoriaRef =
                                      FirebaseFirestore.instance
                                          .collection('auditoria_general')
                                          .doc();
                                  transaction.set(auditoriaRef, {
                                    'fecha': FieldValue.serverTimestamp(),
                                    'usuario_nombre': auditor,
                                    'accion':
                                        'Editar Cantidad Solicitud Insumos',
                                    'detalle':
                                        'Insumo: $nombreInsumo, Cantidad anterior: $cantidadActual, Cantidad nueva: $nuevaCantidad',
                                  });
                                });

                                if (context.mounted) Navigator.pop(context);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Cantidad actualizada correctamente',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) Navigator.pop(context);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Guardar'),
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

  // ─── Eliminar solicitud ──────────────────────────────────────────────────
  Future<void> _eliminarSolicitud(
    String docId,
    String insumoId,
    int cantidad,
  ) async {
    final confirm = await showDialog<bool>(
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
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Eliminar Solicitud',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¿Estás seguro de eliminar esta solicitud? El stock será devuelto al inventario.',
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

    if (confirm != true) return;

    final insumoRef = FirebaseFirestore.instance
        .collection('inventario_insumos')
        .doc(insumoId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final insumoSnapshot = await transaction.get(insumoRef);
      if (!insumoSnapshot.exists) {
        throw Exception('Insumo no encontrado para devolución de stock.');
      }
      final stockActual = (insumoSnapshot['cantidad'] ?? 0) as int;
      transaction.update(insumoRef, {
        'cantidad': stockActual + cantidad,
        'updated_at': FieldValue.serverTimestamp(),
      });

      final user = FirebaseAuth.instance.currentUser;
      String auditor = 'Administrador';
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('usuarios_activos')
                .doc(user.uid)
                .get();
        if (userDoc.exists) auditor = userDoc['nombre'] ?? auditor;
      }

      final insumoDoc = await insumoRef.get();
      final nombreInsumo =
          insumoDoc.exists ? (insumoDoc['nombre'] ?? insumoId) : insumoId;

      final auditoriaRef =
          FirebaseFirestore.instance.collection('auditoria_general').doc();
      transaction.set(auditoriaRef, {
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': auditor,
        'accion': 'Eliminar Solicitud Insumos',
        'detalle': 'Insumo: $nombreInsumo, Cantidad devuelta: $cantidad',
      });

      transaction.delete(
        FirebaseFirestore.instance.collection('solicitudes_insumos').doc(docId),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud eliminada, stock devuelto')),
      );
    }
  }

  // ─── Ver historial de ediciones ──────────────────────────────────────────
  void _verHistorialEdiciones(List<dynamic> historial) {
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
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Historial de ediciones',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      historial.isEmpty
                          ? const Text('Sin ediciones registradas.')
                          : SizedBox(
                            width: double.maxFinite,
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: historial.length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, i) {
                                final entry =
                                    historial[i] as Map<String, dynamic>;
                                final fechaEntry = entry['fecha'];
                                String fechaTexto = '—';
                                if (fechaEntry is Timestamp) {
                                  fechaTexto = DateFormat(
                                    'dd/MM/yyyy HH:mm',
                                  ).format(fechaEntry.toDate());
                                }
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.history,
                                    color: Color(0xFF4682B4),
                                    size: 20,
                                  ),
                                  title: Text(
                                    '${entry['cantidad_anterior']} → ${entry['cantidad_nueva']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(fechaTexto),
                                );
                              },
                            ),
                          ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  // ─── Resumen del mes ─────────────────────────────────────────────────────
  Widget _buildResumenMes(List<DocumentSnapshot> docs) {
    if (docs.isEmpty) return const SizedBox.shrink();

    int totalUnidades = 0;
    for (final doc in docs) {
      totalUnidades += (doc['cantidad'] ?? 0) as int;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4682B4), Color(0xFF5B9BD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4682B4).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildResumenItem(
            Icons.assignment_outlined,
            docs.length.toString(),
            'Solicitudes en el mes',
          ),
          Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
          _buildResumenItem(
            Icons.inventory_2_outlined,
            totalUnidades.toString(),
            'Unidades totales',
          ),
        ],
      ),
    );
  }

  Widget _buildResumenItem(IconData icon, String valor, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          valor,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  // ─── Navegador de meses (web: flechas + label) ───────────────────────────
  Widget _buildNavegadorMeses() {
    final ahora = DateTime.now();
    final esMesActual =
        _mesSeleccionado.year == ahora.year &&
        _mesSeleccionado.month == ahora.month;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Color(0xFF4682B4)),
            tooltip: 'Mes anterior',
            onPressed: _mesAnterior,
          ),
          Expanded(
            child: Center(
              child: Text(
                _nombreMes(_mesSeleccionado).toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4682B4),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color:
                  esMesActual ? Colors.grey.shade300 : const Color(0xFF4682B4),
            ),
            tooltip: 'Mes siguiente',
            onPressed: esMesActual ? null : _mesSiguiente,
          ),
        ],
      ),
    );
  }

  // ─── Barra de filtros ────────────────────────────────────────────────────
  Widget _buildBarraFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Row(
        children: [
          // Buscador
          Expanded(
            flex: 3,
            child: TextField(
              controller: _busquedaController,
              onChanged: (v) => setState(() => _busqueda = v),
              decoration: InputDecoration(
                hintText: 'Buscar insumo o empleado...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF4682B4)),
                suffixIcon:
                    _busqueda.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _busquedaController.clear();
                            setState(() => _busqueda = '');
                          },
                        )
                        : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Filtro empleado
          Expanded(
            flex: 2,
            child: _buildDropdownFiltro(
              hint: 'Empleado',
              value: _filtroEmpleado,
              items: _empleadosFiltro,
              onChanged: (v) => setState(() => _filtroEmpleado = v),
            ),
          ),
          const SizedBox(width: 12),
          // Filtro insumo
          Expanded(
            flex: 2,
            child: _buildDropdownFiltro(
              hint: 'Insumo',
              value: _filtroInsumo,
              items: _insumosFiltro,
              onChanged: (v) => setState(() => _filtroInsumo = v),
            ),
          ),
          if (_filtroEmpleado != null || _filtroInsumo != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.filter_list_off, color: Colors.redAccent),
              tooltip: 'Limpiar filtros',
              onPressed:
                  () => setState(() {
                    _filtroEmpleado = null;
                    _filtroInsumo = null;
                  }),
            ),
          ],
          const SizedBox(width: 12),
          // Botón exportar PDF
          ElevatedButton.icon(
            onPressed: _exportarPDF,
            icon: const Icon(Icons.picture_as_pdf, size: 18),
            label: const Text('Exportar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4682B4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownFiltro({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          value: value,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(
                'Todos ($hint)',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            ...items.map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ─── Tabla principal ─────────────────────────────────────────────────────
  Widget _buildTabla(List<_MovimientoData> filtrados) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: MaterialStateProperty.all(const Color(0xFF4682B4)),
        headingTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        dataTextStyle: const TextStyle(fontSize: 12),
        columns: const [
          DataColumn(label: Text('Insumo')),
          DataColumn(label: Text('Cantidad')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Fecha')),
          DataColumn(label: Text('Acciones')),
        ],
        rows:
            filtrados.map((item) {
              final doc = item.doc;
              final docId = doc.id;
              final cantidad = doc['cantidad'] ?? 0;
              final insumoId = doc['insumo_id'] ?? '';
              final fechaTimestamp = doc['fecha'] as Timestamp?;
              final fechaTexto =
                  fechaTimestamp != null
                      ? _formatearFecha(fechaTimestamp)
                      : 'Desconocida';
              final estaExpandido = _expandedDocId == docId;

              return DataRow(
                color: MaterialStateProperty.resolveWith((states) {
                  if (estaExpandido) {
                    return const Color(0xFF4682B4).withOpacity(0.05);
                  }
                  return null;
                }),
                cells: [
                  // Insumo
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        item.nombreInsumo,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Cantidad
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4682B4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cantidad.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4682B4),
                        ),
                      ),
                    ),
                  ),
                  // Empleado
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 160),
                      child: Text(
                        item.nombreEmpleado,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  // Fecha
                  DataCell(Text(fechaTexto)),
                  // Acciones
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: Color(0xFF4682B4),
                            size: 20,
                          ),
                          tooltip: 'Editar cantidad',
                          onPressed:
                              () => _editarCantidadSolicitud(
                                docId,
                                insumoId,
                                cantidad,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          tooltip: 'Eliminar solicitud',
                          onPressed:
                              () =>
                                  _eliminarSolicitud(docId, insumoId, cantidad),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  // ─── Panel de detalle expandido ──────────────────────────────────────────
  Widget _buildPanelExpandido(_MovimientoData item) {
    final doc = item.doc;
    final data = doc.data() as Map<String, dynamic>;
    final historialEdiciones =
        data.containsKey('historial_ediciones')
            ? (data['historial_ediciones'] as List<dynamic>)
            : <dynamic>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Historial ediciones
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, size: 16, color: Color(0xFF4682B4)),
                  const SizedBox(width: 6),
                  Text(
                    'Historial de ediciones: ${historialEdiciones.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  if (historialEdiciones.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _verHistorialEdiciones(historialEdiciones),
                      child: const Text(
                        'Ver',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4682B4),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Build principal ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final inicio = Timestamp.fromDate(_inicioMes(_mesSeleccionado));
    final fin = Timestamp.fromDate(_finMes(_mesSeleccionado));

    return Column(
      children: [
        // ── Navegador de meses ──
        _buildNavegadorMeses(),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('solicitudes_insumos')
                    .orderBy('fecha', descending: true)
                    .where('fecha', isGreaterThanOrEqualTo: inicio)
                    .where('fecha', isLessThan: fin)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final movimientos =
                  snapshot.hasData ? snapshot.data!.docs : <DocumentSnapshot>[];

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // ── Filtros y exportar ──
                    _buildBarraFiltros(),
                    const SizedBox(height: 8),

                    // ── Contenido ──
                    Expanded(
                      child:
                          movimientos.isEmpty
                              ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inbox_outlined,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Sin registros en ${_nombreMes(_mesSeleccionado)}',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              : FutureBuilder<List<Map<String, String>>>(
                                future: Future.wait(
                                  movimientos.map((doc) async {
                                    final insumoId = doc['insumo_id'] ?? '';
                                    final empleadoId = doc['empleado_id'] ?? '';
                                    final nombreInsumo =
                                        await _obtenerNombreInsumo(insumoId);
                                    final nombreEmpleado =
                                        await _obtenerNombreEmpleado(
                                          empleadoId,
                                          doc,
                                        );
                                    return {
                                      'insumo': nombreInsumo,
                                      'empleado': nombreEmpleado,
                                    };
                                  }).toList(),
                                ),
                                builder: (context, snapshotNombres) {
                                  if (!snapshotNombres.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  // Aplicar filtros
                                  final filtrados = <_MovimientoData>[];
                                  for (
                                    int i = 0;
                                    i < snapshotNombres.data!.length &&
                                        i < movimientos.length;
                                    i++
                                  ) {
                                    final nombres = snapshotNombres.data![i];
                                    if (_aplicarFiltros(
                                      movimientos[i],
                                      nombres['insumo']!,
                                      nombres['empleado']!,
                                    )) {
                                      filtrados.add(
                                        _MovimientoData(
                                          doc: movimientos[i],
                                          nombreInsumo: nombres['insumo']!,
                                          nombreEmpleado: nombres['empleado']!,
                                        ),
                                      );
                                    }
                                  }

                                  if (filtrados.isEmpty) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.search_off,
                                            size: 48,
                                            color: Colors.grey.shade300,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Sin resultados para los filtros aplicados',
                                            style: TextStyle(
                                              color: Colors.grey.shade400,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Resumen del mes
                                        _buildResumenMes(
                                          filtrados.map((e) => e.doc).toList(),
                                        ),
                                        // Tabla
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: _buildTabla(filtrados),
                                        ),
                                        // Panel expandido
                                        if (_expandedDocId != null) ...[
                                          const SizedBox(height: 8),
                                          Builder(
                                            builder: (_) {
                                              final expandedItem =
                                                  filtrados
                                                      .where(
                                                        (e) =>
                                                            e.doc.id ==
                                                            _expandedDocId,
                                                      )
                                                      .firstOrNull;
                                              if (expandedItem == null) {
                                                return const SizedBox.shrink();
                                              }
                                              return _buildPanelExpandido(
                                                expandedItem,
                                              );
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Modelo auxiliar ─────────────────────────────────────────────────────────
class _MovimientoData {
  final DocumentSnapshot doc;
  final String nombreInsumo;
  final String nombreEmpleado;

  const _MovimientoData({
    required this.doc,
    required this.nombreInsumo,
    required this.nombreEmpleado,
  });
}
