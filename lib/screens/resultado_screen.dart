import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';

class ResultadoScreen extends StatefulWidget {
  final String instituicaoSigla;
  final String cursoNome;
  final int ano;
  final String disciplina;
  final double nota;
  final int acertos;
  final int total;
  final int tempoGasto;
  final List<Map<String, dynamic>> questoes;
  final Map<int, int> respostas;

  const ResultadoScreen({
    super.key,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.ano,
    required this.disciplina,
    required this.nota,
    required this.acertos,
    required this.total,
    required this.tempoGasto,
    required this.questoes,
    required this.respostas,
  });

  @override
  State<ResultadoScreen> createState() => _ResultadoScreenState();
}

class _ResultadoScreenState extends State<ResultadoScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _planoUtilizador = 'gratuito';
  bool _carregando = true;
  bool _mostrarCorreccao = false;

  static const Map<String, int> _hierarquiaPlanos = {
    'gratuito': 0,
    'bronze': 1,
    'prata': 2,
    'ouro': 3,
    'diamante': 4,
  };

  bool get _aprovado => widget.nota >= 13;
  bool get _temAcessoCorreccao => _hierarquiaPlanos[_planoUtilizador]! >= 1;

  @override
  void initState() {
    super.initState();
    _carregarPlano();
  }

  Future<void> _carregarPlano() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final doc =
          await _firestore.collection('utilizadores').doc(uid).get();
      final dados = doc.data();
      if (dados == null) return;

      final cursos = List<Map<String, dynamic>>.from(
        (dados['cursos'] as List<dynamic>? ?? [])
            .map((c) => Map<String, dynamic>.from(c)),
      );

      final cursoActivo = cursos.firstWhere(
        (c) => c['cursoNome'] == widget.cursoNome,
        orElse: () => {},
      );

      if (mounted) {
        setState(() {
          _planoUtilizador = cursoActivo['plano'] ?? 'gratuito';
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _formatarTempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0) return '${h}h ${m}min ${s}s';
    return '${m}min ${s}s';
  }

  // Cor do header baseada na nota
  Color get _corHeader {
    if (widget.nota >= 16) return const Color(0xFFD4AF37);
    if (widget.nota >= 13) return Colors.green.shade600;
    return Colors.red.shade600;
  }

  String get _textoResultado {
    if (widget.nota >= 16) return 'EXCELENTE ⭐';
    if (widget.nota >= 13) return 'APROVADO ✓';
    return 'REPROVADO ✗';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMetricas(),
            if (_carregando)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                ),
              )
            else if (_mostrarCorreccao)
              _buildCorreccaoDetalhada()
            else
              _buildResumo(),
            _buildBotoes(),
          ],
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _corHeader,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      child: Column(
        children: [
          Text(
            widget.nota >= 16 ? '🏆' : widget.nota >= 13 ? '🎉' : '😔',
            style: const TextStyle(fontSize: 44),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.nota.toStringAsFixed(1)} / 20',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _textoResultado,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.disciplina} · ${widget.instituicaoSigla} · ${widget.ano}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── MÉTRICAS ─────────────────────────────────────────────────────────────────
  Widget _buildMetricas() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _MetricaCard(
              icone: Icons.check_circle,
              cor: Colors.green,
              valor: '${widget.acertos}/${widget.total}',
              label: 'Acertos',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricaCard(
              icone: Icons.cancel,
              cor: Colors.red,
              valor: '${widget.total - widget.acertos}/${widget.total}',
              label: 'Erros',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _MetricaCard(
              icone: Icons.timer,
              cor: const Color(0xFF007AFF),
              valor: _formatarTempo(widget.tempoGasto),
              label: 'Tempo',
            ),
          ),
        ],
      ),
    );
  }

  // ── RESUMO (sem correcção) ───────────────────────────────────────────────────
  Widget _buildResumo() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card de acesso à correcção
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(
                    _temAcessoCorreccao
                        ? Icons.menu_book
                        : Icons.lock,
                    color: _temAcessoCorreccao
                        ? const Color(0xFF007AFF)
                        : Colors.grey,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _temAcessoCorreccao
                        ? 'Correcção detalhada disponível'
                        : 'Correcção detalhada bloqueada',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _temAcessoCorreccao
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _temAcessoCorreccao
                        ? 'Vê a resolução passo-a-passo de cada questão.'
                        : 'Faz upgrade para Bronze, Prata ou Ouro para aceder à correcção detalhada com resolução passo-a-passo.',
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _temAcessoCorreccao
                          ? () => setState(() => _mostrarCorreccao = true)
                          : _mostrarDialogUpgrade,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _temAcessoCorreccao
                            ? const Color(0xFF007AFF)
                            : Colors.grey.shade400,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: Icon(
                        _temAcessoCorreccao
                            ? Icons.visibility
                            : Icons.lock,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: Text(
                        _temAcessoCorreccao
                            ? 'Ver Correcção'
                            : 'Desbloquear Correcção',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mensagem motivacional
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'O que fazer a seguir?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _aprovado
                      ? _ItemSeguinte(
                          icone: Icons.arrow_upward,
                          cor: Colors.green,
                          texto: _aprovado
                              ? 'Avança para o próximo ano de exame!'
                              : 'Continua a treinar para melhorar.',
                        )
                      : _ItemSeguinte(
                          icone: Icons.refresh,
                          cor: Colors.orange,
                          texto:
                              'Repete este exame para melhorar a nota.',
                        ),
                  const SizedBox(height: 8),
                  const _ItemSeguinte(
                    icone: Icons.auto_awesome,
                    cor: Color(0xFF007AFF),
                    texto: 'Usa o Mestre IA para esclarecer dúvidas.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── CORRECÇÃO DETALHADA ──────────────────────────────────────────────────────
  Widget _buildCorreccaoDetalhada() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da correcção
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _mostrarCorreccao = false),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back_ios,
                          color: Color(0xFF007AFF), size: 16),
                      Text(
                        'Resultados',
                        style: TextStyle(
                            color: Color(0xFF007AFF), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(Icons.list_alt,
                    color: Color(0xFF007AFF), size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Correcção Detalhada',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),

          // Lista de questões
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.questoes.length,
              itemBuilder: (context, index) {
                final questao = widget.questoes[index];
                final respostaUtilizador = widget.respostas[index];
                final respostaCorrecta = questao['correcta'] as int;
                final acertou = respostaUtilizador == respostaCorrecta;
                final opcoes = questao['opcoes'] as List<dynamic>;
                final justificacao =
                    questao['justificacao'] as String? ?? '';
                final resolucao =
                    questao['resolucao'] as String? ?? justificacao;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: acertou
                          ? Colors.green.shade200
                          : Colors.red.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho questão
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: acertou
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              acertou
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color:
                                  acertou ? Colors.green : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Questão ${index + 1}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: acertou
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              acertou ? '+1 ponto' : '0 pontos',
                              style: TextStyle(
                                fontSize: 12,
                                color: acertou
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Enunciado
                            Text(
                              questao['texto'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1A1A1A),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Resposta correcta
                            _RespostaItem(
                              texto: opcoes[respostaCorrecta].toString(),
                              tipo: _TipoResposta.correcta,
                            ),

                            // Resposta do utilizador (se errou)
                            if (!acertou &&
                                respostaUtilizador != null) ...[
                              const SizedBox(height: 6),
                              _RespostaItem(
                                texto: opcoes[respostaUtilizador]
                                    .toString(),
                                tipo: _TipoResposta.errada,
                              ),
                            ],

                            // Sem resposta
                            if (respostaUtilizador == null) ...[
                              const SizedBox(height: 6),
                              _RespostaItem(
                                texto: 'Não respondida',
                                tipo: _TipoResposta.semResposta,
                              ),
                            ],

                            const SizedBox(height: 10),

                            // Justificação
                            _BlocoExplicacao(
                              icone: Icons.info_outline,
                              cor: const Color(0xFF007AFF),
                              titulo: 'Explicação',
                              texto: justificacao,
                            ),

                            // Resolução passo-a-passo (se diferente)
                            if (resolucao.isNotEmpty &&
                                resolucao != justificacao) ...[
                              const SizedBox(height: 8),
                              _BlocoExplicacao(
                                icone: Icons.format_list_numbered,
                                cor: Colors.purple,
                                titulo: 'Resolução passo-a-passo',
                                texto: resolucao,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── BOTÕES ───────────────────────────────────────────────────────────────────
  Widget _buildBotoes() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'Tentar Novamente',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Color(0xFF007AFF)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Voltar ao Início',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogUpgrade() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock,
                    color: Color(0xFFD4AF37), size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Correcção Bloqueada',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              const Text(
                'A correcção detalhada com resolução passo-a-passo está disponível nos planos Bronze, Prata, Ouro e Diamante.',
                style: TextStyle(
                    fontSize: 13, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ver Planos',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

enum _TipoResposta { correcta, errada, semResposta }

class _RespostaItem extends StatelessWidget {
  final String texto;
  final _TipoResposta tipo;

  const _RespostaItem({required this.texto, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final Color cor;
    final IconData icone;
    final Color corFundo;
    final Color corBorda;

    switch (tipo) {
      case _TipoResposta.correcta:
        cor = Colors.green.shade700;
        icone = Icons.check;
        corFundo = Colors.green.shade50;
        corBorda = Colors.green.shade200;
        break;
      case _TipoResposta.errada:
        cor = Colors.red.shade700;
        icone = Icons.close;
        corFundo = Colors.red.shade50;
        corBorda = Colors.red.shade200;
        break;
      case _TipoResposta.semResposta:
        cor = Colors.grey;
        icone = Icons.remove;
        corFundo = Colors.grey.shade50;
        corBorda = Colors.grey.shade200;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: corBorda),
      ),
      child: Row(
        children: [
          Icon(icone, color: cor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(
                color: cor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlocoExplicacao extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String texto;

  const _BlocoExplicacao({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: cor, size: 15),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            texto,
            style: TextStyle(
              color: cor.withValues(alpha: 0.85),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSeguinte extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String texto;

  const _ItemSeguinte({
    required this.icone,
    required this.cor,
    required this.texto,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: cor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, color: cor, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final IconData icone;
  final Color cor;
  final String valor;
  final String label;

  const _MetricaCard({
    required this.icone,
    required this.cor,
    required this.valor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icone, color: cor, size: 20),
          const SizedBox(height: 6),
          Text(
            valor,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: cor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}