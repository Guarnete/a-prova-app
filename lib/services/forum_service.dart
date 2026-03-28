import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForumService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uidActual => _auth.currentUser?.uid ?? '';
  String get _nomeActual => _auth.currentUser?.displayName ?? 'Estudante';

  // ── POSTS ─────────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarPosts({
    required String instituicaoId,
    required String cursoNome,
    String? disciplina,
  }) async {
    Query query = _firestore
        .collection('forum')
        .where('instituicaoId', isEqualTo: instituicaoId)
        .where('cursoNome', isEqualTo: cursoNome)
        .where('activo', isEqualTo: true)
        .orderBy('criadoEm', descending: true);

    if (disciplina != null) {
      query = query.where('disciplina', isEqualTo: disciplina);
    }

    final snapshot = await query.limit(50).get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>}).toList();
  }

  Future<String> criarPost({
    required String titulo,
    required String corpo,
    required String instituicaoId,
    required String cursoNome,
    required String disciplina,
  }) async {
    final ref = await _firestore.collection('forum').add({
      'titulo': titulo,
      'corpo': corpo,
      'autorId': _uidActual,
      'autorNome': _nomeActual,
      'instituicaoId': instituicaoId,
      'cursoNome': cursoNome,
      'disciplina': disciplina,
      'totalRespostas': 0,
      'totalVotos': 0,
      'votantes': [],
      'denuncias': [],
      'activo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> votarPost(String postId) async {
    final ref = _firestore.collection('forum').doc(postId);
    final doc = await ref.get();
    final votantes = List<String>.from(doc.data()?['votantes'] ?? []);
    if (votantes.contains(_uidActual)) {
      // Remove voto
      await ref.update({
        'votantes': FieldValue.arrayRemove([_uidActual]),
        'totalVotos': FieldValue.increment(-1),
      });
    } else {
      // Adiciona voto
      await ref.update({
        'votantes': FieldValue.arrayUnion([_uidActual]),
        'totalVotos': FieldValue.increment(1),
      });
    }
  }

  Future<void> denunciarPost(String postId) async {
    await _firestore.collection('forum').doc(postId).update({
      'denuncias': FieldValue.arrayUnion([_uidActual]),
    });
  }

  // Auto-desactiva post com 5+ denúncias
  Future<void> verificarDenunciasPost(String postId) async {
    final doc = await _firestore.collection('forum').doc(postId).get();
    final denuncias = List<String>.from(doc.data()?['denuncias'] ?? []);
    if (denuncias.length >= 5) {
      await _firestore.collection('forum').doc(postId).update({'activo': false});
    }
  }

  // ── RESPOSTAS ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarRespostas(String postId) async {
    final snapshot = await _firestore
        .collection('forum')
        .doc(postId)
        .collection('respostas')
        .where('activo', isEqualTo: true)
        .orderBy('criadoEm', descending: false)
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<void> criarResposta({
    required String postId,
    required String corpo,
  }) async {
    // Cria resposta
    await _firestore
        .collection('forum')
        .doc(postId)
        .collection('respostas')
        .add({
      'corpo': corpo,
      'autorId': _uidActual,
      'autorNome': _nomeActual,
      'totalVotos': 0,
      'votantes': [],
      'denuncias': [],
      'activo': true,
      'criadoEm': FieldValue.serverTimestamp(),
    });
    // Incrementa contador do post
    await _firestore.collection('forum').doc(postId).update({
      'totalRespostas': FieldValue.increment(1),
    });
  }

  Future<void> votarResposta({
    required String postId,
    required String respostaId,
  }) async {
    final ref = _firestore
        .collection('forum')
        .doc(postId)
        .collection('respostas')
        .doc(respostaId);
    final doc = await ref.get();
    final votantes = List<String>.from(doc.data()?['votantes'] ?? []);
    if (votantes.contains(_uidActual)) {
      await ref.update({
        'votantes': FieldValue.arrayRemove([_uidActual]),
        'totalVotos': FieldValue.increment(-1),
      });
    } else {
      await ref.update({
        'votantes': FieldValue.arrayUnion([_uidActual]),
        'totalVotos': FieldValue.increment(1),
      });
    }
  }

  Future<void> denunciarResposta({
    required String postId,
    required String respostaId,
  }) async {
    await _firestore
        .collection('forum')
        .doc(postId)
        .collection('respostas')
        .doc(respostaId)
        .update({
      'denuncias': FieldValue.arrayUnion([_uidActual]),
    });
    // Auto-desactiva com 5+ denúncias
    final doc = await _firestore
        .collection('forum')
        .doc(postId)
        .collection('respostas')
        .doc(respostaId)
        .get();
    final denuncias = List<String>.from(doc.data()?['denuncias'] ?? []);
    if (denuncias.length >= 5) {
      await _firestore
          .collection('forum')
          .doc(postId)
          .collection('respostas')
          .doc(respostaId)
          .update({'activo': false});
    }
  }

  // ── ADMIN ─────────────────────────────────────────────────────────────────

  Future<void> desactivarPost(String postId) async {
    await _firestore.collection('forum').doc(postId).update({'activo': false});
  }

  Future<void> desactivarResposta({
    required String postId,
    required String respostaId,
  }) async {
    await _firestore
        .collection('forum')
        .doc(postId)
        .collection('respostas')
        .doc(respostaId)
        .update({'activo': false});
  }

  // Carrega um post directamente pelo ID
  Future<Map<String, dynamic>?> carregarPostPorId(String postId) async {
    try {
      final doc = await _firestore.collection('forum').doc(postId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      return null;
    }
  }
}