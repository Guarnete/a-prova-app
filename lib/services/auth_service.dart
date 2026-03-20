import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // REGISTAR
  Future<Map<String, dynamic>> registar({
    required String nome,
    required String email,
    required String password,
    required String telefone,
    required String provincia,
    required String dataNascimento,
  }) async {
    try {
      final UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final User? user = credential.user;
      if (user == null) return {'sucesso': false, 'erro': 'Erro ao criar conta.'};
      await user.updateDisplayName(nome);
      await _firestore.collection('utilizadores').doc(user.uid).set({
        'uid': user.uid,
        'nome': nome,
        'email': email.trim(),
        'telefone': telefone,
        'provincia': provincia,
        'dataNascimento': dataNascimento,
        'criadoEm': FieldValue.serverTimestamp(),
        'cursos': [],
        'onboardingCompleto': false,
      });
      return {'sucesso': true, 'utilizador': user};
    } on FirebaseAuthException catch (e) {
      return {'sucesso': false, 'erro': _traduzirErro(e.code)};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tenta novamente.'};
    }
  }

  // LOGIN
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
  Future<Map<String, dynamic>> recuperarPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return {'sucesso': true};
    } on FirebaseAuthException catch (e) {
      return {'sucesso': false, 'erro': _traduzirErro(e.code)};
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro inesperado. Tenta novamente.'};
    }
  }

  // LOGOUT
  Future<void> logout() async => await _auth.signOut();

  // VERIFICAR SE ONBOARDING ESTÁ COMPLETO
  Future<bool> onboardingCompleto() async {
    final user = currentUser;
    if (user == null) return false;
    final doc = await _firestore.collection('utilizadores').doc(user.uid).get();
    return doc.data()?['onboardingCompleto'] ?? false;
  }

  // ADICIONAR CURSO AO PERFIL
  Future<Map<String, dynamic>> adicionarCurso({
    required String instituicaoId,
    required String instituicaoSigla,
    required String instituicaoNome,
    required String cursoNome,
    required String disciplinas,
  }) async {
    final user = currentUser;
    if (user == null) return {'sucesso': false, 'erro': 'Utilizador não autenticado.'};

    // Verificar se o curso já existe
    final doc = await _firestore.collection('utilizadores').doc(user.uid).get();
    final dados = doc.data();
    if (dados != null) {
      final cursosExistentes = List<Map<String, dynamic>>.from(
        (dados['cursos'] as List<dynamic>? ?? [])
            .map((c) => Map<String, dynamic>.from(c)),
      );
      final jaExiste = cursosExistentes.any(
        (c) =>
            c['instituicaoId'] == instituicaoId &&
            c['cursoNome'] == cursoNome,
      );
      if (jaExiste) {
        return {
          'sucesso': false,
          'erro': 'Já tens o curso $cursoNome da $instituicaoSigla adicionado.',
        };
      }
    }

    final novoCurso = {
      'instituicaoId': instituicaoId,
      'instituicaoSigla': instituicaoSigla,
      'instituicaoNome': instituicaoNome,
      'cursoNome': cursoNome,
      'disciplinas': disciplinas,
      'plano': 'gratuito',
      'anosDesbloqueados': [],
      'progressoAnos': {},
      'mestreAiUsado': 0,
      'dataExpiracao': null,
      'adicionadoEm': DateTime.now().toIso8601String(),
    };

    await _firestore.collection('utilizadores').doc(user.uid).update({
      'cursos': FieldValue.arrayUnion([novoCurso]),
      'onboardingCompleto': true,
    });

    return {'sucesso': true};
  }
  

  // CARREGAR PERFIL COMPLETO
  Future<Map<String, dynamic>?> carregarPerfil() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('utilizadores').doc(user.uid).get();
    return doc.data();
  }

  // CARREGAR CURSOS DO UTILIZADOR
  Future<List<Map<String, dynamic>>> carregarCursos() async {
    final perfil = await carregarPerfil();
    if (perfil == null) return [];
    final cursos = perfil['cursos'] as List<dynamic>? ?? [];
    return cursos.map((c) => Map<String, dynamic>.from(c)).toList();
  }

  Future<void> guardarResultado({
    required String instituicaoId,
    required String cursoNome,
    required int ano,
    required String disciplina,
    required double nota,
    required int acertos,
    required int total,
    required int tempoGasto,
  }) async {
    final user = currentUser;
    if (user == null) return;

    // Guarda na sub-colecção de resultados
    await _firestore
        .collection('utilizadores')
        .doc(user.uid)
        .collection('resultados')
        .add({
      'instituicaoId': instituicaoId,
      'cursoNome': cursoNome,
      'ano': ano,
      'disciplina': disciplina,
      'nota': nota,
      'acertos': acertos,
      'total': total,
      'tempoGasto': tempoGasto,
      'aprovado': nota >= 13,
      'data': FieldValue.serverTimestamp(),
    });

    // Actualiza progressoAnos e melhorNota por disciplina no perfil
    final docRef = _firestore.collection('utilizadores').doc(user.uid);
    final doc = await docRef.get();
    final dados = doc.data();
    if (dados == null) return;

    final cursos = List<Map<String, dynamic>>.from(
      (dados['cursos'] as List<dynamic>? ?? [])
          .map((c) => Map<String, dynamic>.from(c)),
    );

    final idx = cursos.indexWhere(
      (c) =>
          c['instituicaoId'] == instituicaoId &&
          c['cursoNome'] == cursoNome,
    );
    if (idx == -1) return;

    // Actualiza progressoAnos/{ano}/disciplinas/{disciplina}
    final progressoAnos = Map<String, dynamic>.from(
      cursos[idx]['progressoAnos'] ?? {},
    );
    final progressoAno = Map<String, dynamic>.from(
      progressoAnos[ano.toString()] ?? {},
    );
    final disciplinas = Map<String, dynamic>.from(
      progressoAno['disciplinas'] ?? {},
    );

    // Guarda melhor nota por disciplina
    final notaAnterior =
        (disciplinas[disciplina]?['melhorNota'] ?? 0).toDouble();
    if (nota > notaAnterior) {
      disciplinas[disciplina] = {
        'melhorNota': nota,
        'tentativas':
            ((disciplinas[disciplina]?['tentativas'] ?? 0) as int) + 1,
        'aprovado': nota >= 13,
      };
    } else {
      disciplinas[disciplina] = {
        'melhorNota': notaAnterior,
        'tentativas':
            ((disciplinas[disciplina]?['tentativas'] ?? 0) as int) + 1,
        'aprovado': notaAnterior >= 13,
      };
    }

    progressoAno['disciplinas'] = disciplinas;
    progressoAno['tentativas'] =
        ((progressoAno['tentativas'] ?? 0) as int) + 1;

    // Melhor nota do ano = média das disciplinas aprovadas
    final todasNotas = disciplinas.values
        .map((d) => (d['melhorNota'] ?? 0).toDouble())
        .toList();
    if (todasNotas.isNotEmpty) {
      progressoAno['melhorNota'] =
          todasNotas.reduce((a, b) => a + b) / todasNotas.length;
    }

    progressoAnos[ano.toString()] = progressoAno;
    cursos[idx]['progressoAnos'] = progressoAnos;

    await docRef.update({'cursos': cursos});
  }

  // GUARDAR RESULTADO NO RANKING GLOBAL
  Future<void> actualizarRanking({
    required String cursoNome,
    required String instituicaoId,
    required double nota,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final nome = user.displayName ?? 'Estudante';
    final chaveRanking = '${instituicaoId}_$cursoNome';
    await _firestore
        .collection('ranking')
        .doc(chaveRanking)
        .collection('estudantes')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'nome': nome,
      'melhorNota': nota,
      'actualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // TRADUZIR ERROS
  String _traduzirErro(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Este email já está registado.';
      case 'invalid-email': return 'Email inválido.';
      case 'weak-password': return 'Password demasiado fraca. Usa pelo menos 6 caracteres.';
      case 'user-not-found': return 'Conta não encontrada. Verifica o email.';
      case 'wrong-password': return 'Password incorrecta.';
      case 'invalid-credential': return 'Email ou password incorrectos.';
      case 'too-many-requests': return 'Demasiadas tentativas. Tenta mais tarde.';
      case 'network-request-failed': return 'Sem ligação à internet.';
      default: return 'Erro de autenticação. Tenta novamente.';
    }
  }
}