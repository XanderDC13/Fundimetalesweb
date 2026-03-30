import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _cedulaController = TextEditingController();
  final FocusNode _cedulaFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _cedulaValida = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSearchingCedula = false;
  String? _cedulaErrorMessage;
  String? _selectedRole;
  String? _selectedSede;
  String? _errorMessage;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _cedulaController.dispose(); // ← AGREGAR ESTA LÍNEA
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cedulaFocus.dispose(); // ← AGREGAR ESTA LÍNEA
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate() && !_isLoading) {
      _register();
    }
  }

  // Método para mostrar el popup elegante
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: 320, // 👈 ancho fijo más compacto
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono de éxito
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),

                // Título
                const Text(
                  '¡Registro Exitoso!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Mensaje principal
                const Text(
                  'Debes verificar tu correo y esperar la verificación de un administrador para poder ingresar.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF5D6D7E),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Mensaje de agradecimiento
                Text(
                  'Gracias por registrarte',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Botón de aceptar
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Cerrar el diálogo
                      context.go('/login'); // Navegar al login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4682B4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Aceptar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _searchUserByCedula(String cedula) async {
    if (cedula.trim().isEmpty || cedula.length != 10) return;

    setState(() {
      _isSearchingCedula = true;
      _cedulaErrorMessage = null;
      _cedulaValida = false;
    });

    try {
      final querySnapshot =
          await _firestore
              .collection('usuarios')
              .where('cedula', isEqualTo: cedula)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        setState(() {
          _nameController.text = userData['nombre'] ?? '';
          _isSearchingCedula = false;
          _cedulaValida = true; // ✅ Activar campos
        });
      } else {
        setState(() {
          _cedulaErrorMessage = 'Cédula no encontrada en el sistema';
          _nameController.clear();
          _isSearchingCedula = false;
          _cedulaValida = false; // ❌ Ocultar campos
        });
      }
    } catch (e) {
      setState(() {
        _cedulaErrorMessage = 'Error al buscar la cédula';
        _isSearchingCedula = false;
        _cedulaValida = false;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final cedula = _cedulaController.text.trim();
        final name = _nameController.text.trim();
        final email = _emailController.text.trim();
        final password = _passwordController.text;

        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user!.sendEmailVerification();

        await _firestore
            .collection('usuarios_pendientes')
            .doc(userCredential.user!.uid)
            .set({
              'cedula': cedula,
              'nombre': name,
              'email': email,
              'rol': _selectedRole,
              'sede': _selectedSede,
              'uid': userCredential.user!.uid,
              'estado': 'pendiente',
              'verificado': false,
              'fechaRegistro': FieldValue.serverTimestamp(),
            });

        // 🔥 CRÍTICO: Cerrar sesión inmediatamente
        await _auth.signOut();

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        _showSuccessDialog();
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;

        String errorMessage = 'Error al registrar';
        if (e.code == 'email-already-in-use') {
          errorMessage = 'Este correo electrónico ya está registrado';
        } else if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es demasiado débil';
        } else {
          errorMessage = e.message ?? 'Error desconocido';
        }

        setState(() {
          _errorMessage = errorMessage;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'Error inesperado: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF2F8), Color(0xFFD6EAF8), Color(0xFFB0D4F1)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isWideScreen = constraints.maxWidth > 1000;
            bool isMediumScreen = constraints.maxWidth > 600;

            return Row(
              children: [
                // Panel izquierdo - Solo en pantallas grandes
                if (isWideScreen)
                  Expanded(
                    flex: 3,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Elementos decorativos
                            Positioned(
                              top: 80,
                              left: 80,
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 120,
                              right: 60,
                              child: Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.1),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            // Contenido principal
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 60,
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    const SizedBox(height: 30),
                                    const Text(
                                      'Únete a nuestro\nequipo',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 42,
                                        fontWeight: FontWeight.bold,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'Crea tu cuenta y forma parte de la plataforma de gestión más avanzada',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 18,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 40),
                                    _buildFeature(
                                      Icons.verified_user,
                                      'Proceso de verificación seguro',
                                    ),
                                    const SizedBox(height: 15),
                                    _buildFeature(
                                      Icons.admin_panel_settings,
                                      'Aprobación administrativa',
                                    ),
                                    const SizedBox(height: 15),
                                    _buildFeature(
                                      Icons.email,
                                      'Verificación por correo',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Panel derecho - Formulario de registro
                Expanded(
                  flex: isWideScreen ? 2 : 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.all(isMediumScreen ? 24 : 16),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 30,
                                      offset: const Offset(0, 10),
                                      spreadRadius: 0,
                                    ),
                                  ],
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        '¡Nos alegra tenerte aquí!',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF2C3E50),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Completa el formulario para crear tu cuenta',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 20),
                                      // Campo de cédula (AGREGAR COMO PRIMER CAMPO)
                                      TextFormField(
                                        controller: _cedulaController,
                                        focusNode: _cedulaFocus,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        maxLength: 10,
                                        onFieldSubmitted:
                                            (_) => _nameFocus.requestFocus(),
                                        onChanged: (value) {
                                          if (value.length == 10) {
                                            _searchUserByCedula(value);
                                          } else if (value.length < 10) {
                                            setState(() {
                                              _cedulaErrorMessage = null;
                                              _nameController.clear();
                                              _cedulaValida =
                                                  false; // Ocultar campos
                                            });
                                          }
                                        },
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(10),
                                        ],
                                        decoration: _inputDecoration(
                                          icon: Icons.credit_card,
                                          hint: 'Cédula de identidad',
                                          suffix:
                                              _isSearchingCedula
                                                  ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFF4682B4,
                                                          ),
                                                        ),
                                                  )
                                                  : _nameController
                                                      .text
                                                      .isNotEmpty
                                                  ? const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20,
                                                  )
                                                  : null,
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // Mensaje de error específico para cédula (AGREGAR DESPUÉS del campo de cédula)
                                      if (_cedulaErrorMessage != null)
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(8),
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: Colors.orange.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.info_outline,
                                                color: Colors.orange.shade600,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  _cedulaErrorMessage!,
                                                  style: TextStyle(
                                                    color:
                                                        Colors.orange.shade800,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      // Campo de nombre
                                      if (_cedulaValida) ...[
                                        // Campo de nombre
                                        TextFormField(
                                          controller: _nameController,
                                          focusNode: _nameFocus,
                                          textInputAction: TextInputAction.next,
                                          readOnly:
                                              _nameController.text.isNotEmpty,
                                          onFieldSubmitted:
                                              (_) => _emailFocus.requestFocus(),
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r'[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]'),
                                            ),
                                          ],
                                          decoration: _inputDecoration(
                                            icon: Icons.person_outline,
                                            hint:
                                                _nameController.text.isEmpty
                                                    ? 'Nombre completo'
                                                    : 'Nombre encontrado automáticamente',
                                          ).copyWith(
                                            fillColor:
                                                _nameController.text.isNotEmpty
                                                    ? Colors.grey.shade100
                                                    : Colors.white,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Por favor ingresa tu nombre';
                                            }
                                            if (value.trim().length < 2) {
                                              return 'El nombre debe tener al menos 2 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Campo de correo
                                        TextFormField(
                                          controller: _emailController,
                                          focusNode: _emailFocus,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          onFieldSubmitted:
                                              (_) =>
                                                  _passwordFocus.requestFocus(),
                                          decoration: _inputDecoration(
                                            icon: Icons.email_outlined,
                                            hint: 'Correo electrónico',
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Por favor ingresa tu correo';
                                            }
                                            if (!RegExp(
                                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                            ).hasMatch(value)) {
                                              return 'Ingresa un correo válido';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Campo de contraseña
                                        TextFormField(
                                          controller: _passwordController,
                                          focusNode: _passwordFocus,
                                          obscureText: _obscurePassword,
                                          textInputAction: TextInputAction.done,
                                          onFieldSubmitted:
                                              (_) => _handleSubmit(),
                                          decoration: _inputDecoration(
                                            icon: Icons.lock_outline,
                                            hint: 'Contraseña',
                                            suffix: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_outlined
                                                    : Icons
                                                        .visibility_off_outlined,
                                                color: const Color(0xFF4682B4),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _obscurePassword =
                                                      !_obscurePassword;
                                                });
                                              },
                                            ),
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor ingresa una contraseña';
                                            }
                                            if (value.length < 6) {
                                              return 'La contraseña debe tener al menos 6 caracteres';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Dropdown de rol
                                        DropdownButtonFormField<String>(
                                          value: _selectedRole,
                                          decoration: _inputDecoration(
                                            icon: Icons.badge_outlined,
                                            hint: 'Selecciona tu rol',
                                          ).copyWith(fillColor: Colors.white),
                                          dropdownColor: Colors.white,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Gerente',
                                              child: Text('Gerente'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Administrador General',
                                              child: Text(
                                                'Administrador General',
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Vendedor',
                                              child: Text('Vendedor'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'SupervisorFundicion',
                                              child: Text(
                                                'Supervisor Fundicion',
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'OperadorFundicion',
                                              child: Text('Operador Fundicion'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'SupervisorMecanizado',
                                              child: Text(
                                                'Supervisor Mecanizado',
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'OperadorMecanizado',
                                              child: Text(
                                                'Operador Mecanizado',
                                              ),
                                            ),
                                          ],
                                          onChanged:
                                              (value) => setState(
                                                () => _selectedRole = value!,
                                              ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor selecciona un rol';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 12),

                                        // Dropdown de sede
                                        DropdownButtonFormField<String>(
                                          value: _selectedSede,
                                          decoration: _inputDecoration(
                                            icon: Icons.location_city_outlined,
                                            hint: 'Selecciona tu sede',
                                          ).copyWith(fillColor: Colors.white),
                                          dropdownColor: Colors.white,
                                          items: const [
                                            DropdownMenuItem(
                                              value: 'Tulcán',
                                              child: Text('Tulcán'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Quito',
                                              child: Text('Quito'),
                                            ),
                                            DropdownMenuItem(
                                              value: 'Guayaquil',
                                              child: Text('Guayaquil'),
                                            ),
                                          ],
                                          onChanged:
                                              (value) => setState(
                                                () => _selectedSede = value,
                                              ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Por favor selecciona una sede';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 16),

                                        // Mensajes de error
                                        if (_errorMessage != null)
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            margin: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.red.shade200,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  color: Colors.red.shade600,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    _errorMessage!,
                                                    style: TextStyle(
                                                      color:
                                                          Colors.red.shade800,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Botón de registro
                                        SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: ElevatedButton(
                                            onPressed:
                                                _isLoading ? null : _register,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF4682B4,
                                              ),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                            child:
                                                _isLoading
                                                    ? const SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                    : const Text(
                                                      'Crear Cuenta',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                      ],

                                      // Texto de login
                                      TextButton(
                                        onPressed: () {
                                          context.go('/login');
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            children: const [
                                              TextSpan(
                                                text: '¿Ya tienes cuenta? ',
                                              ),
                                              TextSpan(
                                                text: 'Inicia sesión',
                                                style: TextStyle(
                                                  color: Color(0xFF4682B4),
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
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required IconData icon,
    required String hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      prefixIcon: Icon(icon, color: const Color(0xFF4682B4), size: 22),
      suffixIcon: suffix,
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
        borderSide: const BorderSide(color: Color(0xFF4682B4), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    );
  }
}
