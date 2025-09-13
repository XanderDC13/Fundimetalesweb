import 'dart:async';
import 'package:basefundi/services/navbar_desk.dart';
import 'package:basefundi/services/pdfs/antificpopdf.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class AnticiposDeskScreen extends StatefulWidget {
  const AnticiposDeskScreen({super.key});

  @override
  _AnticiposDeskScreenState createState() => _AnticiposDeskScreenState();
}

class _AnticiposDeskScreenState extends State<AnticiposDeskScreen> {
  // Controladores para datos del solicitante
  final TextEditingController _nombreSolicitanteController =
      TextEditingController();

  // Controladores para datos del anticipo
  final TextEditingController _montoAnticipoController =
      TextEditingController();
  final TextEditingController _motivoController = TextEditingController();
  final TextEditingController _justificacionController =
      TextEditingController();
  final TextEditingController _fechaSolicitudController =
      TextEditingController();
  final TextEditingController _fechaAprobacionController =
      TextEditingController();
  final TextEditingController _fechaDevolucionController =
      TextEditingController();

  // Controladores para firmas y autorizaciones
  final TextEditingController _nombreAprobadorController =
      TextEditingController();
  final TextEditingController _cargoAprobadorController =
      TextEditingController();

  String _numeroAnticipo = '';
  bool _urgente = false;
  String _tipoAnticipo = 'GASTOS DE VIAJE';

  @override
  void initState() {
    super.initState();
    _previsualizarNumeroAnticipo();
    _establecerFechaSolicitud();
  }

  Future<void> _previsualizarNumeroAnticipo() async {
    final fechaHoy = DateTime.now();
    final fechaFormateada =
        "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

    final counterRef = FirebaseFirestore.instance
        .collection('anticipos_counter')
        .doc(fechaFormateada);

    final counterDoc = await counterRef.get();
    int numero = 1;

    if (counterDoc.exists) {
      numero = counterDoc['contador'] + 1;
    } else {
      await counterRef.set({'contador': 0});
    }

    setState(() {
      _numeroAnticipo = "ANTICIPO N-$fechaFormateada-$numero";
    });
  }

  void _establecerFechaSolicitud() {
    final fechaHoy = DateTime.now();
    final fechaFormateada =
        "${fechaHoy.day.toString().padLeft(2, '0')}/${fechaHoy.month.toString().padLeft(2, '0')}/${fechaHoy.year}";
    _fechaSolicitudController.text = fechaFormateada;
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Column(
        children: [
          // Cabecera
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
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      _numeroAnticipo,
                      style: const TextStyle(
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

          // Contenido
          Expanded(
            child: Container(
              color: Colors.white,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Fila superior: Datos del Solicitante + Datos del Anticipo
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Columna izquierda: Datos del Solicitante + Fecha
                                    Expanded(
                                      flex: 1,
                                      child: Column(
                                        children: [
                                          // Datos del Solicitante
                                          _buildDatosSolicitanteSection(),
                                          const SizedBox(height: 16),
                                          // Fecha
                                          _buildFechasSection(),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Columna derecha: Datos del Anticipo
                                    Expanded(
                                      flex: 1,
                                      child: _buildDatosAnticipoSection(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                        // Action bar
                        Padding(
                          padding: const EdgeInsets.all(32),
                          child: _buildActionBar(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatosSolicitanteSection() {
    return _buildSection(
      title: 'Datos del Solicitante',
      icon: Icons.person_outline,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          _buildUppercaseTextField(
            controller: _nombreSolicitanteController,
            label: 'Nombre Completo',
            icon: Icons.person,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDatosAnticipoSection() {
    return _buildSection(
      title: 'Datos del Anticipo',
      icon: Icons.attach_money,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          _buildUppercaseTextField(
            controller: _montoAnticipoController,
            label: 'Monto del Anticipo',
            icon: Icons.monetization_on,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),

          _buildUppercaseTextField(
            controller: _motivoController,
            label: 'Motivo del Anticipo',
            icon: Icons.description,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFechasSection() {
    return _buildSection(
      title: 'Fecha',
      icon: Icons.calendar_today,
      color: Colors.grey[800]!,
      child: Column(
        children: [
          // 📅 Fecha de Solicitud con selector
          GestureDetector(
            onTap: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _fechaSolicitudController.text =
                      "${picked.day.toString().padLeft(2, '0')}/"
                      "${picked.month.toString().padLeft(2, '0')}/"
                      "${picked.year}";
                });
              }
            },
            child: AbsorbPointer(
              // evita abrir teclado
              child: _buildUppercaseTextField(
                controller: _fechaSolicitudController,
                label: 'Fecha de Solicitud',
                icon: Icons.event,
                hintText: 'DD/MM/AAAA',
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildUppercaseTextField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    bool readOnly = false,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextStyle? style,
    Function(String)? onChanged,
    String? hintText,
    bool isEmail = false, // Nueva propiedad para correos
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: enabled ? Colors.grey[700] : Colors.grey[400],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: maxLines == 1 ? 40 : null,
          decoration: BoxDecoration(
            color: readOnly ? Colors.grey[50] : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: enabled ? Colors.grey[300]! : Colors.grey[200]!,
            ),
          ),
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            // Configurar mayúsculas automáticas solo si no es email
            textCapitalization:
                isEmail
                    ? TextCapitalization.none
                    : TextCapitalization.characters,
            inputFormatters:
                isEmail
                    ? [] // Sin formatters para emails
                    : [
                      // Formatter para convertir a mayúsculas automáticamente
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        return TextEditingValue(
                          text: newValue.text.toUpperCase(),
                          selection: newValue.selection,
                        );
                      }),
                    ],
            style:
                style ??
                TextStyle(
                  fontSize: 14,
                  color: enabled ? Colors.black : Colors.grey[500],
                ),
            onChanged: onChanged,
            decoration: InputDecoration(
              prefixIcon:
                  icon != null
                      ? Icon(icon, size: 18, color: Colors.grey[600])
                      : null,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: icon != null ? 8 : 12,
                vertical: maxLines == 1 ? 8 : 12,
              ),
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  bool _vistaPrevia = false;

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Row(
          children: [
            // Botón Cancelar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide.none,
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Imprimir
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4682B4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4682B4).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _soloImprimir,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Imprimir'),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Botón Guardar
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color:
                      _vistaPrevia ? const Color(0xFF4682B4) : Colors.grey[400],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (_vistaPrevia
                              ? const Color(0xFF4682B4)
                              : Colors.grey[400]!)
                          .withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _vistaPrevia ? _guardarEnBaseDatos : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: const Text('Guardar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _soloImprimir() async {
    try {
      final fechaHoy = DateTime.now();
      final fechaFormateada =
          "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

      final counterRef = FirebaseFirestore.instance
          .collection('anticipos_counter')
          .doc(fechaFormateada);

      final counterDoc = await counterRef.get();
      int numero = 1;
      if (counterDoc.exists) {
        numero = counterDoc['contador'] + 1;
      }

      final numeroAnticipoTemporal = "ANTICIPO N-$fechaFormateada-$numero";

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Preparando vista previa para imprimir...'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 2),
        ),
      );

      // Reemplaza esta línea:
      // await PDFGeneratorAnticipo.vistaPrevia(...);

      // Con esta llamada:
      await PDFGeneratorAnticipo.vistaPrevia(
        numeroAnticipo: numeroAnticipoTemporal,
        nombreSolicitante: _nombreSolicitanteController.text,
        montoAnticipo: _montoAnticipoController.text,
        tipoAnticipo: _tipoAnticipo,
        motivo: _motivoController.text,
        justificacion: _justificacionController.text,
        fechaSolicitud: _fechaSolicitudController.text,
        fechaAprobacion: _fechaAprobacionController.text,
        fechaDevolucion: _fechaDevolucionController.text,
        urgente: _urgente,
        nombreAprobador: _nombreAprobadorController.text,
        cargoAprobador: _cargoAprobadorController.text,
      );

      setState(() {
        _vistaPrevia = true;
        _numeroAnticipo = numeroAnticipoTemporal;
      });

      _mostrarMensajeFlotante();
    } catch (e) {
      print('❌ Error al generar vista previa: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al imprimir: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _mostrarMensajeFlotante() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _vistaPrevia) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '⚠️ No olvides de GUARDAR la solicitud de anticipo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[600],
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });
  }

  void _guardarEnBaseDatos() async {
    try {
      final fechaHoy = DateTime.now();
      final fechaFormateada =
          "${fechaHoy.year}${fechaHoy.month.toString().padLeft(2, '0')}${fechaHoy.day.toString().padLeft(2, '0')}";

      final counterRef = FirebaseFirestore.instance
          .collection('anticipos_counter')
          .doc(fechaFormateada);

      final counterDoc = await counterRef.get();
      int numero = 1;
      if (counterDoc.exists) {
        numero = counterDoc['contador'] + 1;
        await counterRef.update({'contador': numero});
      } else {
        await counterRef.set({'contador': numero});
      }

      final anticipoData = {
        'numero': _numeroAnticipo,
        'nombre_solicitante': _nombreSolicitanteController.text,
        'monto_anticipo': _montoAnticipoController.text,
        'tipo_anticipo': _tipoAnticipo,
        'motivo': _motivoController.text,
        'justificacion': _justificacionController.text,
        'fecha_solicitud': _fechaSolicitudController.text,
        'fecha_aprobacion': _fechaAprobacionController.text,
        'fecha_devolucion': _fechaDevolucionController.text,
        'urgente': _urgente,
        'nombre_aprobador': _nombreAprobadorController.text,
        'cargo_aprobador': _cargoAprobadorController.text,
        'fecha': Timestamp.now(),
      };

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

      await FirebaseFirestore.instance
          .collection('anticipos')
          .add(anticipoData);

      final auditoriaRef =
          FirebaseFirestore.instance.collection('auditoria_general').doc();
      await auditoriaRef.set({
        'fecha': FieldValue.serverTimestamp(),
        'usuario_nombre': usuarioNombre,
        'usuario_uid': user?.uid ?? 'uid_desconocido',
        'accion': 'Nueva solicitud de anticipo',
        'detalle': 'Número de anticipo: ${_numeroAnticipo}',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '✅ Solicitud de anticipo guardada correctamente en la base de datos',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      Future.delayed(const Duration(seconds: 2), () {
        Navigator.of(context).pop();
      });
    } catch (e) {
      print('❌ Error al guardar anticipo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
