import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PagamentoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // Preços definidos no Firestore — nunca hardcoded na app
  // Estrutura: configuracoes/planos/{planoId} → { valor, nome, descricao }
  // Por defeito (fallback) usamos estes valores em modo simulado:
  static const Map<String, double> _valoresFallback = {
    'prata': 150.0,
    'ouro': 350.0,
    'diamante': 800.0,
  };

  static const Map<String, String> _duracaoPlanos = {
    'prata': 'mes',
    'ouro': 'mes',
    'diamante': 'ano',
  };

  // ── CARREGAR PREÇOS DO FIRESTORE ──────────────────────────────────────────

  Future<Map<String, dynamic>> carregarPlanos() async {
    try {
      final doc = await _firestore
          .collection('configuracoes')
          .doc('planos')
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
      // Fallback com valores por defeito
      return {
        'prata': {
          'valor': 150.0,
          'nome': 'Prata',
          'descricao': 'Acesso a todos os anos do curso',
          'duracao': 'mes',
        },
        'ouro': {
          'valor': 350.0,
          'nome': 'Ouro',
          'descricao': 'Prata + correcao detalhada + Mestre IA',
          'duracao': 'mes',
        },
        'diamante': {
          'valor': 800.0,
          'nome': 'Diamante',
          'descricao': 'Acesso total por 1 ano a todas as instituicoes',
          'duracao': 'ano',
        },
      };
    } catch (e) {
      return {};
    }
  }

  // ── INICIAR PAGAMENTO ─────────────────────────────────────────────────────

  Future<Map<String, dynamic>> iniciarPagamento({
    required String plano,
    required String instituicaoId,
    required String cursoNome,
    required String metodo, // mpesa | emola | visa
    required String contacto, // numero de telefone ou referencia cartao
    required double valor,
  }) async {
    if (_uid.isEmpty) {
      return {'sucesso': false, 'erro': 'Utilizador nao autenticado.'};
    }

    try {
      // Gera referencia unica
      final referencia = _gerarReferencia(metodo);

      // Regista pagamento como pendente
      final docRef = await _firestore
          .collection('pagamentos')
          .doc(_uid)
          .collection('subscricoes')
          .add({
        'plano': plano,
        'instituicaoId': instituicaoId,
        'cursoNome': cursoNome,
        'metodo': metodo,
        'contacto': contacto,
        'valor': valor,
        'referencia': referencia,
        'estado': 'pendente',
        'criadoEm': FieldValue.serverTimestamp(),
        'expiracaoEm': _calcularExpiracao(plano),
        'modoSimulado': true, // remover quando API real estiver activa
      });

      // Em modo simulado: confirma automaticamente após 3 segundos
      await Future.delayed(const Duration(seconds: 3));
      await _confirmarPagamento(docRef.id, plano, instituicaoId, cursoNome);

      return {
        'sucesso': true,
        'referencia': referencia,
        'pagamentoId': docRef.id,
      };
    } catch (e) {
      return {'sucesso': false, 'erro': 'Erro ao processar pagamento.'};
    }
  }

  // ── CONFIRMAR PAGAMENTO E ACTUALIZAR PLANO ────────────────────────────────

  Future<void> _confirmarPagamento(
    String pagamentoId,
    String plano,
    String instituicaoId,
    String cursoNome,
  ) async {
    // Marca pagamento como confirmado
    await _firestore
        .collection('pagamentos')
        .doc(_uid)
        .collection('subscricoes')
        .doc(pagamentoId)
        .update({
      'estado': 'confirmado',
      'confirmadoEm': FieldValue.serverTimestamp(),
    });

    // Actualiza plano do utilizador no perfil
    final docRef = _firestore.collection('utilizadores').doc(_uid);
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

    cursos[idx]['plano'] = plano;
    cursos[idx]['dataExpiracao'] = _calcularExpiracao(plano).toIso8601String();
    cursos[idx]['subscricaoActiva'] = true;

    await docRef.update({'cursos': cursos});
  }

  // ── CARREGAR SUBSCRICOES ACTIVAS ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> carregarSubscricoes() async {
    if (_uid.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('pagamentos')
          .doc(_uid)
          .collection('subscricoes')
          .orderBy('criadoEm', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ── VERIFICAR SE PLANO ESTÁ ACTIVO ───────────────────────────────────────

  Future<bool> planoActivo({
    required String instituicaoId,
    required String cursoNome,
  }) async {
    if (_uid.isEmpty) return false;
    try {
      final snapshot = await _firestore
          .collection('pagamentos')
          .doc(_uid)
          .collection('subscricoes')
          .where('instituicaoId', isEqualTo: instituicaoId)
          .where('cursoNome', isEqualTo: cursoNome)
          .where('estado', isEqualTo: 'confirmado')
          .orderBy('criadoEm', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final dados = snapshot.docs.first.data();
      final expiracao = dados['expiracaoEm'];
      if (expiracao == null) return false;

      DateTime dataExpiracao;
      if (expiracao is DateTime) {
        dataExpiracao = expiracao;
      } else {
        dataExpiracao = DateTime.parse(expiracao.toString());
      }
      return DateTime.now().isBefore(dataExpiracao);
    } catch (e) {
      return false;
    }
  }

  // ── UTILITÁRIOS ───────────────────────────────────────────────────────────

  String _gerarReferencia(String metodo) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final prefixo = metodo.toUpperCase().substring(0, 2);
    return '$prefixo$timestamp';
  }

  DateTime _calcularExpiracao(String plano) {
    final agora = DateTime.now();
    if (plano == 'diamante') {
      return agora.add(const Duration(days: 365));
    }
    return agora.add(const Duration(days: 30));
  }

  double valorPlano(String plano) {
    return _valoresFallback[plano] ?? 0.0;
  }

  String duracaoPlano(String plano) {
    return _duracaoPlanos[plano] ?? 'mes';
  }
}