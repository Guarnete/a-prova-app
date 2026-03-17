import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Utilizador actual
  User? get currentUser => _auth.currentUser;

  // Stream de mudanças de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // REGISTAR novo utilizador
  Future<Map<String, dynamic>> registar({
    required String nome,
    required String email,
    required String password,
    required String telefone,
    required String provincia,
    required String dataNascimento,
  }) async {
    try {
      // Criar conta no Firebase Auth
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = credential.user;
      if (user == null) {
        return {'sucesso': false, 'erro': 'Erro ao criar conta.'};
      }

      // Actualizar nome no Firebase Auth
      await user.updateDisplayName(nome);

      // Guardar dados extras no Firestore
      await _firestore.collection('utilizadores').doc(user.uid).set({
        'uid': user.uid,
        'nome': nome,
        'email': email.trim(),
        'telefone': telefone,
        'provincia': provincia,
        'dataNascimento': dataNascimento,
        'plano': 'gratuito',
        'criadoEm': FieldValue.serverTimestamp(),
      });

      return {'sucesso': true, 'utilizador': user};
    } on FirebaseAuthException catch (e) {
      return {'sucesso': false, 'erro': _traduzirErro(e.code)};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tenta novamente.'};
    }
  }

  // FAZER LOGIN
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return {'sucesso': true};
    } on FirebaseAuthException catch (e) {
      return {'sucesso': false, 'erro': _traduzirErro(e.code)};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tenta novamente.'};
    }
  }

  // RECUPERAR PASSWORD
  Future<Map<String, dynamic>> recuperarPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'sucesso': true};
    } on FirebaseAuthException catch (e) {
      return {'sucesso': false, 'erro': _traduzirErro(e.code)};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tenta novamente.'};
    }
  }

  // FAZER LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Traduzir erros Firebase para Português
  String _traduzirErro(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este email já está registado.';
      case 'invalid-email':
        return 'Email inválido.';
      case 'weak-password':
        return 'Password demasiado fraca. Usa pelo menos 6 caracteres.';
      case 'user-not-found':
        return 'Conta não encontrada. Verifica o email.';
      case 'wrong-password':
        return 'Password incorrecta.';
      case 'invalid-credential':
        return 'Email ou password incorrectos.';
      case 'too-many-requests':
        return 'Demasiadas tentativas. Tenta mais tarde.';
      case 'network-request-failed':
        return 'Sem ligação à internet.';
      default:
        return 'Erro de autenticação. Tenta novamente.';
    }
  }
}
