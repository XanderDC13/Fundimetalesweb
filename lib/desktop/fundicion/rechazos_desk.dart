import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/pdfs/rechazospdf.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class RechazosFundicionDeskScreen extends StatefulWidget {
  const RechazosFundicionDeskScreen({super.key});

  @override
  State<RechazosFundicionDeskScreen> createState() =>
      _RechazosFundicionDeskScreenState();
}

class _RechazosFundicionDeskScreenState
    extends State<RechazosFundicionDeskScreen> {
  List<Map<String, dynamic>> _rechazos = [];
  bool _cargando = false;
  DateTimeRange? _rangoFecha;

  @override
  void initState() {
    super.initState();
    _obtenerDatos();
  }

  Future<void> _obtenerDatos() async {
    setState(() => _cargando = true);
    try {
      Query query = FirebaseFirestore.instance
          .collection('rechazos_fundicion')
          .orderBy('fecha', descending: true);

      if (_rangoFecha != null) {
        query = query
            .where(
              'fecha',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_rangoFecha!.start),
            )
            .where(
              'fecha',
              isLessThanOrEqualTo: Timestamp.fromDate(
                _rangoFecha!.end.add(const Duration(days: 1)),
              ),
            );
      }

      final snap = await query.get();
      setState(() {
        _rechazos =
            snap.docs.map((d) {
              final data = d.data() as Map<String, dynamic>;
              data['id'] = d.id;
              return data;
            }).toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      _showSnack('Error al cargar rechazos: $e', color: Colors.red);
    }
  }

  int get _totalPiezas => _rechazos.fold(
    0,
    (sum, r) => sum + ((r['cantidad'] as num?)?.toInt() ?? 0),
  );

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return '—';
    try {
      if (fecha is Timestamp) {
        return DateFormat('dd/MM/yyyy HH:mm').format(fecha.toDate());
      }
      return fecha.toString();
    } catch (_) {
      return '—';
    }
  }

  void _showSnack(String msg, {Color color = Colors.green}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  Future<void> _eliminarRechazo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Eliminar rechazo'),
            content: const Text(
              '¿Está seguro que desea eliminar este registro?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('rechazos_fundicion')
          .doc(id)
          .delete();
      _obtenerDatos();
      _showSnack('Rechazo eliminado');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // ── CABECERA ──────────────────────────────────────────────────────
          Transform.translate(
            offset: const Offset(-0.5, 0),
            child: Container(
              width: double.infinity,
              color: const Color(0xFF2C3E50),
              padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 38),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rechazos de Fundición',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Control de Calidad — Piezas Rechazadas',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: _mostrarDialogoAgregar,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuevo Rechazo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TARJETAS RESUMEN ──────────────────────────────────────────────
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildResumenCard(
                  icon: Icons.cancel_outlined,
                  label: 'Total Registros',
                  value: '${_rechazos.length}',
                  color: const Color(0xFF2C3E50),
                ),
                const SizedBox(width: 16),
                _buildResumenCard(
                  icon: Icons.production_quantity_limits,
                  label: 'Piezas Rechazadas',
                  value: '$_totalPiezas',
                  color: Colors.red[700]!,
                ),
                const SizedBox(width: 16),
                _buildResumenCard(
                  icon: Icons.date_range,
                  label: 'Período',
                  value:
                      _rangoFecha == null
                          ? 'Todos'
                          : '${DateFormat('dd/MM/yy').format(_rangoFecha!.start)} - ${DateFormat('dd/MM/yy').format(_rangoFecha!.end)}',
                  color: const Color(0xFF4682B4),
                ),
              ],
            ),
          ),

          // ── CONTENIDO PRINCIPAL ───────────────────────────────────────────
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  // Filtros
                  _buildFiltros(),
                  const SizedBox(height: 16),

                  // Tabla
                  _cargando
                      ? const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                      : _rechazos.isEmpty
                      ? Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 72,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No hay rechazos registrados',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              if (_rangoFecha != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Prueba con un rango de fechas diferente',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                      : Expanded(
                        child: SingleChildScrollView(child: _buildTabla()),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        color: color,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Row(
      children: [
        // Rango de fechas
        ElevatedButton.icon(
          onPressed: () async {
            final picked = await showDialog<DateTimeRange>(
              context: context,
              builder:
                  (ctx) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      width: 400,
                      height: 500,
                      child: DateRangePickerDialog(
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: _rangoFecha,
                      ),
                    ),
                  ),
            );
            if (picked != null) {
              setState(() => _rangoFecha = picked);
              _obtenerDatos();
            }
          },
          icon: const Icon(Icons.date_range, color: Colors.white),
          label: Text(
            _rangoFecha == null
                ? 'Filtrar por fecha'
                : '${DateFormat('dd/MM/yyyy').format(_rangoFecha!.start)} — ${DateFormat('dd/MM/yyyy').format(_rangoFecha!.end)}',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4682B4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),

        if (_rangoFecha != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {
              setState(() => _rangoFecha = null);
              _obtenerDatos();
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Limpiar'),
          ),
        ],

        const Spacer(),

        // Exportar PDF
        ElevatedButton.icon(
          onPressed:
              _rechazos.isEmpty
                  ? null
                  : () => RechazosPdfService.generarYCompartir(
                    rechazos: _rechazos,
                    rango: _rangoFecha,
                  ),
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exportar PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTabla() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header tabla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.red.shade700,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 2, child: _TablaHeader('Fecha')),
                Expanded(flex: 2, child: _TablaHeader('Referencia')),
                Expanded(
                  flex: 1,
                  child: _TablaHeader('Cantidad', center: true),
                ),
                Expanded(flex: 3, child: _TablaHeader('Motivo')),
                SizedBox(width: 48),
              ],
            ),
          ),

          // Filas
          ..._rechazos.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final esPar = i % 2 == 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: esPar ? Colors.white : Colors.grey.shade50,
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  // Fecha
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatearFecha(r['fecha']),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Referencia
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        r['referencia']?.toString() ?? '—',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ),
                  ),
                  // Cantidad
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          r['cantidad']?.toString() ?? '0',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  // Motivo
                  Expanded(
                    flex: 3,
                    child: Text(
                      r['motivo']?.toString().isNotEmpty == true
                          ? r['motivo'].toString()
                          : 'Sin motivo',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            r['motivo']?.toString().isNotEmpty == true
                                ? Colors.black87
                                : Colors.grey,
                        fontStyle:
                            r['motivo']?.toString().isNotEmpty == true
                                ? FontStyle.normal
                                : FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Eliminar
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      onPressed: () => _eliminarRechazo(r['id'].toString()),
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                      tooltip: 'Eliminar',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── DIÁLOGO AGREGAR RECHAZO ──────────────────────────────────────────────
  void _mostrarDialogoAgregar() {
    final referenciaCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();
    final motivoCtrl = TextEditingController();
    final registradoPorCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.cancel_outlined, color: Colors.red[700]),
                const SizedBox(width: 10),
                const Text(
                  'Registrar Rechazo',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Referencia
                    _buildCampoDialog(
                      controller: referenciaCtrl,
                      label: 'Referencia *',
                      hint: 'Ej: 635TD',
                      icon: Icons.qr_code,
                      inputFormatters: [
                        TextInputFormatter.withFunction(
                          (old, newVal) =>
                              newVal.copyWith(text: newVal.text.toUpperCase()),
                        ),
                      ],
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 14),
                    // Cantidad
                    _buildCampoDialog(
                      controller: cantidadCtrl,
                      label: 'Cantidad rechazada *',
                      hint: 'Ej: 5',
                      icon: Icons.production_quantity_limits,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    // Motivo
                    _buildCampoDialog(
                      controller: motivoCtrl,
                      label: 'Motivo (opcional)',
                      hint: 'Ej: Porosidad, grieta, mal acabado...',
                      icon: Icons.info_outline,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (referenciaCtrl.text.trim().isEmpty ||
                      cantidadCtrl.text.trim().isEmpty ||
                      registradoPorCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete los campos obligatorios (*)'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  final cantidad = int.tryParse(cantidadCtrl.text.trim()) ?? 0;
                  if (cantidad <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ingrese una cantidad válida'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  try {
                    await FirebaseFirestore.instance
                        .collection('rechazos_fundicion')
                        .add({
                          'referencia':
                              referenciaCtrl.text.trim().toUpperCase(),
                          'cantidad': cantidad,
                          'motivo': motivoCtrl.text.trim(),
                          'registrado_por': registradoPorCtrl.text.trim(),
                          'fecha': Timestamp.now(),
                        });

                    Navigator.of(ctx).pop();
                    _obtenerDatos();
                    _showSnack(
                      '✅ Rechazo registrado: ${referenciaCtrl.text.trim()}',
                    );
                  } catch (e) {
                    _showSnack('Error al guardar: $e', color: Colors.red);
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCampoDialog({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

// ── Widget auxiliar para header de tabla ────────────────────────────────────
class _TablaHeader extends StatelessWidget {
  final String text;
  final bool center;
  const _TablaHeader(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.left,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}
