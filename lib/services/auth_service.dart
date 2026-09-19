import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Maneja registro, login y sesión del jugador.
/// La seguridad real de las contraseñas la maneja Firebase Auth
/// (nunca se guardan en texto plano, ni siquiera nosotros las vemos).
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Crea el documento de progreso inicial del jugador en Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'username': username.trim(),
      'email': email.trim(),
      'xp': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'puzzlesCompletedSurvival': <String>[],
      'ticketsUnlocked': <String, bool>{},
    });

    return cred;
  }

  Future<UserCredential> login({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> logout() => _auth.signOut();

  Future<void> resetPassword(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }
}
