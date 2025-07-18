import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Método para registrar un nuevo usuario con correo electrónico y contraseña
  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String nombre,
    String apellido,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // Guardar datos básicos del usuario en Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'nombre': nombre,
          'apellido': apellido,
          'email': email,
        });
      }

      return user;
    } catch (error) {
      if (error is FirebaseAuthException) {
        print('Error al registrar el usuario: ${error.message}');
      } else {
        print('Error al registrar el usuario: $error');
      }
      return null;
    }
  }

  // Método para iniciar sesión con correo electrónico y contraseña
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  // Método para cerrar sesión del usuario actual
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      print(error.toString());
    }
  }

  // Método para obtener el usuario actual
  User? getCurrentUser() {
    try {
      return _auth.currentUser;
    } catch (error) {
      print(error.toString());
      return null;
    }
  }

  // Método para enviar correo de verificación
  Future<void> sendEmailVerification(String email) async {
    try {
      User? user = _auth.currentUser;
      await user?.sendEmailVerification();
    } catch (error) {
      print(error.toString());
    }
  }

  // Método para enviar correo de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error) {
      print(error.toString());
    }
  }
}
