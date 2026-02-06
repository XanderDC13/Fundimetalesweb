import 'dart:async';
import 'package:basefundi/database/database.dart';
import 'package:basefundi/database/sync_manager.dart';
import 'package:basefundi/desktop/dashboard_desk.dart';
import 'package:basefundi/desktop/ventas/carrito_controller_desk.dart';
import 'package:basefundi/firebase_options.dart';
import 'package:basefundi/auth/login.dart';
import 'package:basefundi/auth/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

late AppDatabase database;
late SyncManager syncManager;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ NUEVO: Inicializar base de datos drift
  database = AppDatabase();
  syncManager = SyncManager(database);

  // ✅ NUEVO: Iniciar sincronización automática
  syncManager.startAutoSync();

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CarritoController())],
      child: const MyApp(),
    ),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null;
    final isOnLoginPage = state.fullPath == '/login';
    final isOnRegisterPage = state.fullPath == '/register';

    // Si no hay usuario y está intentando acceder a páginas protegidas
    if (!isLoggedIn && !isOnLoginPage && !isOnRegisterPage) {
      return '/login';
    }

    // No hacer redirección automática al dashboard
    // Dejar que el usuario navegue manualmente después del login
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardDeskScreen(),
    ),
  ],
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
);

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4682B4), // Tu color azul principal
          primary: const Color(0xFF4682B4),
          secondary: const Color(
            0xFFD6EAF8,
          ), // Tu color azul claro para selecciones
        ),
        // Personalizar específicamente los elementos de selección
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF4682B4), // Color del cursor
          selectionColor: Color(0xFFD6EAF8), // Color de selección de texto
          selectionHandleColor: Color(
            0xFF4682B4,
          ), // Color de los controladores de selección
        ),
        // Personalizar inputs y campos de texto
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4682B4), width: 2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF4682B4).withOpacity(0.3)),
          ),
        ),
        // Personalizar checkboxes, radio buttons, switches
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF4682B4);
            }
            return null;
          }),
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF4682B4);
            }
            return null;
          }),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFF4682B4);
            }
            return null;
          }),
          trackColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const Color(0xFFD6EAF8);
            }
            return null;
          }),
        ),
      ),
      routerConfig: _router,
    );
  }
}
