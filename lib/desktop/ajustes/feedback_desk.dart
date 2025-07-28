import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:basefundi/settings/navbar_desk.dart';

class FeedbackDeskScreen extends StatefulWidget {
  const FeedbackDeskScreen({super.key});

  @override
  State<FeedbackDeskScreen> createState() => _FeedbackDeskScreenState();
}

class _FeedbackDeskScreenState extends State<FeedbackDeskScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Sugerencia';
  String _description = '';
  String _userEmail = '';
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance.collection('feedback').add({
        'type': _type,
        'description': _description,
        'userEmail': _userEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('¡Gracias por tu feedback!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      _formKey.currentState!.reset();
      setState(() {
        _type = 'Sugerencia';
        _description = '';
        _userEmail = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Error al enviar: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainDeskLayout(
      child: Container(
        color: Colors.white, // ✅ Color de fondo blanco agregado
        child: Column(
          children: [
            // ✅ CABECERA
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
                        'Feedback',
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(64),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Formulario dentro de Card
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 252, 250, 250),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tipo de Feedback',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF1E40AF,
                                      ).withOpacity(0.2),
                                    ),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: _type,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.category_outlined,
                                        color: Color(0xFF2C3E50),
                                      ),
                                    ),
                                    items:
                                        [
                                              'Sugerencia',
                                              'Reporte de error',
                                              'Pregunta',
                                              'Felicitación',
                                              'Otro',
                                            ]
                                            .map(
                                              (type) => DropdownMenuItem(
                                                value: type,
                                                child: Text(type),
                                              ),
                                            )
                                            .toList(),
                                    onChanged:
                                        (val) => setState(() => _type = val!),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Descripción',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'Cuéntanos más detalles...',
                                    prefixIcon: const Icon(
                                      Icons.description_outlined,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  maxLines: 4,
                                  validator: (val) {
                                    if (val == null || val.isEmpty) {
                                      return 'Por favor escribe una descripción.';
                                    }
                                    if (val.length < 10) {
                                      return 'La descripción debe tener al menos 10 caracteres.';
                                    }
                                    return null;
                                  },
                                  onSaved: (val) => _description = val!,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Tu email (opcional)',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'ejemplo@correo.com',
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF2C3E50),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (val) {
                                    if (val != null && val.isNotEmpty) {
                                      if (!RegExp(
                                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                      ).hasMatch(val)) {
                                        return 'Ingresa un email válido';
                                      }
                                    }
                                    return null;
                                  },
                                  onSaved: (val) => _userEmail = val ?? '',
                                ),
                                const SizedBox(height: 32),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isSubmitting ? null : _submitFeedback,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4682B4),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF94A3B8,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child:
                                        _isSubmitting
                                            ? const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Enviando...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                            : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.send),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Enviar Feedback',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C3E50).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF1E40AF).withOpacity(0.1),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFF2C3E50),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tu feedback nos ayuda a crear una mejor experiencia para todos los usuarios.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF2C3E50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
}
