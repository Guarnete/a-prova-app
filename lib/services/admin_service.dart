import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // ── VERIFICAR PAPEL DO UTILIZADOR ────────────────────────────────────────
  Future<Map<String, dynamic>?> carregarPerfisAdmin() async {
    final user = currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('admins').doc(user.uid).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  Future<bool> eAdmin() async {
    final perfil = await carregarPerfisAdmin();
    if (perfil == null) return false;
    final aprovado = perfil['aprovado'] as bool? ?? false;
    return aprovado;
  }

  Future<bool> eSuperAdmin() async {
    final perfil = await carregarPerfisAdmin();
    if (perfil == null) return false;
    return perfil['papel'] == 'superadmin';
  }

  // ── SOLICITAR ACESSO ADMIN ────────────────────────────────────────────────
  Future<Map<String, dynamic>> solicitarAcesso({
    required String instituicaoId,
    required String instituicaoNome,
  }) async {
    final user = currentUser;
    if (user == null) return {'sucesso': false, 'erro': 'Não autenticado.'};

    // Verificar se já existe pedido
    final doc = await _firestore.collection('admins').doc(user.uid).get();
    if (doc.exists) {
      final aprovado = doc.data()?['aprovado'] as bool? ?? false;
      if (aprovado) return {'sucesso': false, 'erro': 'Já és admin.'};
      return {'sucesso': false, 'erro': 'Pedido já enviado. Aguarda aprovação.'};
    }

    await _firestore.collection('admins').doc(user.uid).set({
      'uid': user.uid,
      'nome': user.displayName ?? 'Admin',
      'email': user.email ?? '',
      'instituicaoId': instituicaoId,
      'instituicaoNome': instituicaoNome,
      'papel': 'admin',
      'aprovado': false,
      'solicitadoEm': FieldValue.serverTimestamp(),
    });

    return {'sucesso': true};
  }

  // ── APROVAR / REJEITAR ADMIN (superadmin) ─────────────────────────────────
  Future<void> aprovarAdmin(String uid) async {
    await _firestore.collection('admins').doc(uid).update({
      'aprovado': true,
      'aprovadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejeitarAdmin(String uid) async {
    await _firestore.collection('admins').doc(uid).delete();
  }

  // ── CARREGAR ADMINS PENDENTES (superadmin) ────────────────────────────────
  Future<List<Map<String, dynamic>>> carregarAdminsPendentes() async {
    final snapshot = await _firestore
        .collection('admins')
        .where('aprovado', isEqualTo: false)
        .get();
    return snapshot.docs
        .map((doc) => {'uid': doc.id, ...doc.data()})
        .toList();
  }

  // ── QUESTÕES ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarQuestoes({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String disciplina,
  }) async {
    final snapshot = await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .doc(ano)
        .collection('questoes')
        .where('disciplina', isEqualTo: disciplina)
        .orderBy('ordem')
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Future<void> adicionarQuestao({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String disciplina,
    required String texto,
    required List<String> opcoes,
    required int respostaCorrecta,
    required String justificacao,
    required String resolucao,
    required int ordem,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .doc(ano)
        .collection('questoes')
        .add({
      'disciplina': disciplina,
      'texto': texto,
      'opcoes': opcoes,
      'correcta': respostaCorrecta,
      'justificacao': justificacao,
      'resolucao': resolucao,
      'ordem': ordem,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarQuestao({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String questaoId,
    required Map<String, dynamic> dados,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .doc(ano)
        .collection('questoes')
        .doc(questaoId)
        .update(dados);
  }

  Future<void> apagarQuestao({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String questaoId,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .doc(ano)
        .collection('questoes')
        .doc(questaoId)
        .delete();
  }

  // ── INSTITUIÇÕES ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarInstituicoes() async {
    final snapshot = await _firestore
        .collection('instituicoes')
        .orderBy('nome')
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Future<void> adicionarInstituicao({
    required String id,
    required String nome,
    required String sigla,
    required String cidade,
  }) async {
    await _firestore.collection('instituicoes').doc(id).set({
      'nome': nome,
      'sigla': sigla,
      'cidade': cidade,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  // ── CURSOS ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarCursos(String instituicaoId) async {
    final snapshot = await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .orderBy('nome')
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  Future<void> adicionarCurso({
    required String instituicaoId,
    required String cursoId,
    required String nome,
    required String disciplinas,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .set({
      'nome': nome,
      'disciplinas': disciplinas,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  // ── ANOS ──────────────────────────────────────────────────────────────────

  Future<void> adicionarAno({
    required String instituicaoId,
    required String cursoId,
    required int ano,
    required String planoMinimo,
    required int duracaoMinutos,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .doc(ano.toString())
        .set({
      'ano': ano,
      'planoMinimo': planoMinimo,
      'duracaoMinutos': duracaoMinutos,
      'activo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> toggleAnoActivo({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required bool activo,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .doc(ano)
        .update({'activo': activo});
  }

  Future<List<Map<String, dynamic>>> carregarAnosAdmin({
    required String instituicaoId,
    required String cursoId,
  }) async {
    final snapshot = await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .orderBy('ano')
        .get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  // ── ESTATÍSTICAS ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> carregarEstatisticas({
    String? instituicaoId,
  }) async {
    Query query = _firestore.collection('utilizadores');

    final snapshot = await query.get();
    int totalUtilizadores = snapshot.docs.length;
    int planosGratuitos = 0;
    int planosPagos = 0;

    for (final doc in snapshot.docs) {
      final dados = doc.data() as Map<String, dynamic>;
      final cursos = dados['cursos'] as List<dynamic>? ?? [];
      for (final curso in cursos) {
        final plano = (curso as Map<String, dynamic>)['plano'] ?? 'gratuito';
        if (plano == 'gratuito') {
          planosGratuitos++;
        } else {
          planosPagos++;
        }
      }
    }

    return {
      'totalUtilizadores': totalUtilizadores,
      'planosGratuitos': planosGratuitos,
      'planosPagos': planosPagos,
    };
  }
}