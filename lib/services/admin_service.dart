import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  // ── VERIFICAR PAPEL ───────────────────────────────────────────────────────

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
    return perfil['aprovado'] as bool? ?? false;
  }

  Future<bool> eSuperAdmin() async {
    final perfil = await carregarPerfisAdmin();
    if (perfil == null) return false;
    return perfil['papel'] == 'superadmin';
  }

  // ── SOLICITAR ACESSO ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> solicitarAcesso({
    required String instituicaoId,
    required String instituicaoNome,
  }) async {
    final user = currentUser;
    if (user == null) return {'sucesso': false, 'erro': 'Não autenticado.'};
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

  Future<void> aprovarAdmin(String uid) async {
    await _firestore.collection('admins').doc(uid).update({
      'aprovado': true,
      'aprovadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejeitarAdmin(String uid) async {
    await _firestore.collection('admins').doc(uid).delete();
  }

  Future<List<Map<String, dynamic>>> carregarAdminsPendentes() async {
    final snapshot = await _firestore
        .collection('admins')
        .where('aprovado', isEqualTo: false)
        .get();
    return snapshot.docs.map((doc) => {'uid': doc.id, ...doc.data()}).toList();
  }

  // ── INSTITUIÇÕES ──────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarInstituicoes() async {
    final snapshot = await _firestore
        .collection('instituicoes')
        .orderBy('nome')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<Map<String, dynamic>?> carregarInstituicaoById(String id) async {
    final doc = await _firestore.collection('instituicoes').doc(id).get();
    if (!doc.exists) return null;
    return {'id': doc.id, ...doc.data()!};
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
      'activo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarInstituicao({
    required String id,
    required Map<String, dynamic> dados,
  }) async {
    await _firestore.collection('instituicoes').doc(id).update(dados);
  }

  Future<void> toggleInstituicaoActivo({
    required String id,
    required bool activo,
  }) async {
    await _firestore.collection('instituicoes').doc(id).update({'activo': activo});
  }

  // ── CURSOS ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarCursos(String instituicaoId) async {
    final snapshot = await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .orderBy('nome')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
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
      'activo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarCurso({
    required String instituicaoId,
    required String cursoId,
    required Map<String, dynamic> dados,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .update(dados);
  }

  Future<void> toggleCursoActivo({
    required String instituicaoId,
    required String cursoId,
    required bool activo,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .update({'activo': activo});
  }

  // ── ANOS ──────────────────────────────────────────────────────────────────

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
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> adicionarAno({
    required String instituicaoId,
    required String cursoId,
    required int ano,
    required String planoMinimo,
    String tipo = 'real',
    int duracaoMinutos = 90,
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
      'activo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> editarAno({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required Map<String, dynamic> dados,
  }) async {
    await _firestore
        .collection('instituicoes')
        .doc(instituicaoId)
        .collection('cursos')
        .doc(cursoId)
        .collection('anos')
        .doc(ano)
        .update(dados);
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

  // ── EXAMES ────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarExames({
    required String instituicaoId,
    required String cursoId,
    required String ano,
  }) async {
    final snapshot = await _firestore
        .collection('avaliacoes')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .where('cursoId', isEqualTo: cursoId)
        .where('ano', isEqualTo: ano)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<String> criarExame({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String disciplina,
    required String tipo,
    required int duracaoMinutos,
  }) async {
    final ref = await _firestore.collection('avaliacoes').add({
      'instituicaoId': instituicaoId,
      'cursoId': cursoId,
      'ano': ano,
      'disciplina': disciplina,
      'tipo': tipo,
      'duracaoMinutos': duracaoMinutos,
      'activo': true,
      'totalQuestoes': 0,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> toggleExameActivo({
    required String exameId,
    required bool activo,
  }) async {
    await _firestore.collection('avaliacoes').doc(exameId).update({'activo': activo});
  }

  // ── QUESTÕES ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarQuestoesExame(String exameId) async {
    final snapshot = await _firestore
        .collection('avaliacoes')
        .doc(exameId)
        .collection('questoes')
        .orderBy('ordem')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> adicionarQuestaoExame({
    required String exameId,
    required String texto,
    required List<String> opcoes,
    required int respostaCorrecta,
    required String justificacao,
    required String resolucao,
    required int ordem,
  }) async {
    await _firestore
        .collection('avaliacoes')
        .doc(exameId)
        .collection('questoes')
        .add({
      'texto': texto,
      'opcoes': opcoes,
      'correcta': respostaCorrecta,
      'justificacao': justificacao,
      'resolucao': resolucao,
      'ordem': ordem,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    // Actualiza contador
    await _firestore.collection('avaliacoes').doc(exameId).update({
      'totalQuestoes': FieldValue.increment(1),
    });
  }

  Future<void> editarQuestaoExame({
    required String exameId,
    required String questaoId,
    required Map<String, dynamic> dados,
  }) async {
    await _firestore
        .collection('avaliacoes')
        .doc(exameId)
        .collection('questoes')
        .doc(questaoId)
        .update(dados);
  }

  Future<void> apagarQuestaoExame({
    required String exameId,
    required String questaoId,
  }) async {
    await _firestore
        .collection('avaliacoes')
        .doc(exameId)
        .collection('questoes')
        .doc(questaoId)
        .delete();
    await _firestore.collection('avaliacoes').doc(exameId).update({
      'totalQuestoes': FieldValue.increment(-1),
    });
  }

  // ── ESTATÍSTICAS ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> carregarEstatisticas({String? instituicaoId}) async {
    final snapshot = await _firestore.collection('utilizadores').get();
    int totalUtilizadores = snapshot.docs.length;
    int planosGratuitos = 0;
    int planosPagos = 0;
    for (final doc in snapshot.docs) {
      final dados = doc.data();
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

  // ── MÉTODOS LEGACY (compatibilidade) ─────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarQuestoes({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String disciplina,
  }) async {
    // Tenta nova estrutura (avaliacoes)
    final snapshot = await _firestore
        .collection('avaliacoes')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .where('cursoId', isEqualTo: cursoId)
        .where('ano', isEqualTo: ano)
        .where('disciplina', isEqualTo: disciplina)
        .where('activo', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final exameId = snapshot.docs.first.id;
    return carregarQuestoesExame(exameId);
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
    // Encontra ou cria exame
    final snapshot = await _firestore
        .collection('avaliacoes')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .where('cursoId', isEqualTo: cursoId)
        .where('ano', isEqualTo: ano)
        .where('disciplina', isEqualTo: disciplina)
        .limit(1)
        .get();

    String exameId;
    if (snapshot.docs.isEmpty) {
      exameId = await criarExame(
        instituicaoId: instituicaoId,
        cursoId: cursoId,
        ano: ano,
        disciplina: disciplina,
        tipo: 'real',
        duracaoMinutos: 90,
      );
    } else {
      exameId = snapshot.docs.first.id;
    }

    await adicionarQuestaoExame(
      exameId: exameId,
      texto: texto,
      opcoes: opcoes,
      respostaCorrecta: respostaCorrecta,
      justificacao: justificacao,
      resolucao: resolucao,
      ordem: ordem,
    );
  }

  Future<void> editarQuestao({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String questaoId,
    required Map<String, dynamic> dados,
  }) async {
    // Encontra o exame
    final snapshot = await _firestore
        .collection('avaliacoes')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .where('cursoId', isEqualTo: cursoId)
        .where('ano', isEqualTo: ano)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return;
    await editarQuestaoExame(
      exameId: snapshot.docs.first.id,
      questaoId: questaoId,
      dados: dados,
    );
  }

  Future<void> apagarQuestao({
    required String instituicaoId,
    required String cursoId,
    required String ano,
    required String questaoId,
  }) async {
    final snapshot = await _firestore
        .collection('avaliacoes')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .where('cursoId', isEqualTo: cursoId)
        .where('ano', isEqualTo: ano)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return;
    await apagarQuestaoExame(
      exameId: snapshot.docs.first.id,
      questaoId: questaoId,
    );
  }
}