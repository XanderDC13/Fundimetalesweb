import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotificationService {
  static const String _serverUrl =
      'https://fundimetalesnotificaciones.onrender.com';

  // Obtener tokens por rol
  Future<List<String>> _obtenerTokensPorRol(String rol) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('usuarios_activos')
            .where('rol', isEqualTo: rol)
            .where('estado', isEqualTo: 'aceptado')
            .get();

    List<String> tokens = [];
    for (var doc in snapshot.docs) {
      final token = doc.data()['fcmToken'];
      if (token != null && token.toString().isNotEmpty) {
        tokens.add(token.toString());
      }
    }
    return tokens;
  }

  // Enviar notificación a un token
  Future<void> _enviarNotificacion({
    required String token,
    required String titulo,
    required String mensaje,
  }) async {
    try {
      await http.post(
        Uri.parse('$_serverUrl/enviar-notificacion'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'titulo': titulo,
          'mensaje': mensaje,
        }),
      );
    } catch (e) {
      print('Error enviando notificación: $e');
    }
  }

  // Notificar al Supervisor cuando Gerente asigna tarea
  Future<void> notificarTareaAsignada({
    required String referencia,
    required String prioridad,
    required int cantidad,
  }) async {
    final tokens = await _obtenerTokensPorRol('Supervisor Fundición');
    for (var token in tokens) {
      await _enviarNotificacion(
        token: token,
        titulo: '📋 Nueva tarea asignada',
        mensaje:
            'Referencia: $referencia - Cantidad: $cantidad - Prioridad: $prioridad',
      );
    }
  }

  // Notificar al Gerente cuando Supervisor completa tarea
  Future<void> notificarTareaCompletada({
    required String operadorNombre,
    required String referencia,
    required int cantidad,
    required String tipoCompletado,
  }) async {
    final tokens = await _obtenerTokensPorRol('Gerente');
    final tipo =
        tipoCompletado == 'completa' ? 'completada' : 'completada parcialmente';
    for (var token in tokens) {
      await _enviarNotificacion(
        token: token,
        titulo: '✅ Tarea $tipo',
        mensaje: '$operadorNombre completó $cantidad unidades de $referencia',
      );
    }
  }

  // Notificar al Gerente cuando Supervisor crea tarea extra
  Future<void> notificarTareaExtra({
    required String operadorNombre,
    required String tipoTarea,
  }) async {
    final tokens = await _obtenerTokensPorRol('Gerente');
    for (var token in tokens) {
      await _enviarNotificacion(
        token: token,
        titulo: '⚡ Nueva tarea extra',
        mensaje: '$tipoTarea asignada a $operadorNombre',
      );
    }
  }

  // Notificar nueva proforma a Gerente y usuarios de la sede
  Future<void> notificarNuevaProforma({
    required String sede,
    required String numeroProforma,
    required String cliente,
    required String total,
  }) async {
    final tokens = await _obtenerTokensPorRol('Gerente');
    for (var token in tokens) {
      await _enviarNotificacion(
        token: token,
        titulo: '🧾 Nueva Proforma - $sede',
        mensaje: 'N° $numeroProforma | Cliente: $cliente | Total: \$$total',
      );
    }
  }

  // ✨ NUEVA FUNCIÓN: Notificar cuando se crea una solicitud de productos
  Future<void> notificarSolicitudCreada({
    required String sede,
    required int cantidadProductos,
    required double cantidadTotal,
  }) async {
    final tokens = await _obtenerTokensPorRol('Gerente');
    for (var token in tokens) {
      await _enviarNotificacion(
        token: token,
        titulo: '🛒 Nueva Solicitud de Productos',
        mensaje:
            'Sede $sede solicita $cantidadProductos productos (Total: $cantidadTotal unidades)',
      );
    }
  }
}