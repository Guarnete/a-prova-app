import 'package:flutter/material.dart';
import '../services/pagamento_service.dart';
import 'pagamento_screen.dart';

class PlanosScreen extends StatefulWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final String planoActual;

  const PlanosScreen({
    super.key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.planoActual,
  });

  @override
  State<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends State<PlanosScreen> {
  final PagamentoService _pagamentoService = PagamentoService();
  Map<String, dynamic> _planos = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarPlanos();
  }

  Future<void> _carregarPlanos() async {
    setState(() => _carregando = true);
    final planos = await _pagamentoService.carregarPlanos();
    if (mounted) setState(() { _planos = planos; _carregando = false; });
  }

  static const Map<String, Color> _coresPlano = {
    'prata': Color(0xFF757575),
    'ouro': Color(0xFFD4AF37),
    'diamante': Color(0xFF007AFF),
  };

  static const Map<String, IconData> _iconesPlano = {
    'prata': Icons.workspace_premium,
    'ouro': Icons.emoji_events,
    'diamante': Icons.diamond,
  };

  static const Map<String, List<String>> _beneficiosPlano = {
    'prata': [
      'Todos os anos de exame do curso',
      'Simulacoes ilimitadas',
      'Historico completo',
      'Ranking competitivo',
    ],
    'ouro': [
      'Tudo do plano Prata',
      'Correccao detalhada pos-exame',
      'Resolucao passo-a-passo',
      'Mestre IA apos cada exame',
    ],
    'diamante': [
      'Tudo do plano Ouro',
      'Acesso a todas as instituicoes',
      'Mestre IA 24/7 ilimitado',
      'Valido por 1 ano completo',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _carregando
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                    ),
                  )
                : _buildLista(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF007AFF),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          const Text('PLANOS',
              style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11,
                  fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const Text('Escolhe o teu plano',
              style: TextStyle(color: Colors.white, fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(
            '${widget.instituicaoSigla} - ${widget.cursoNome}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Plano actual: ${_nomePlano(widget.planoActual)}',
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista() {
    final ordem = ['prata', 'ouro', 'diamante'];
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Banner modo simulado
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Modo de demonstracao activo. Pagamentos reais em breve.',
                      style: TextStyle(color: Colors.orange,
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

            ...ordem.map((planoId) {
              final dados = _planos[planoId] as Map<String, dynamic>? ?? {};
              final valor = (dados['valor'] ?? _pagamentoService.valorPlano(planoId)).toDouble();
              final duracao = dados['duracao'] as String? ?? _pagamentoService.duracaoPlano(planoId);
              final cor = _coresPlano[planoId] ?? const Color(0xFF007AFF);
              final icone = _iconesPlano[planoId] ?? Icons.star;
              final beneficios = _beneficiosPlano[planoId] ?? [];
              final eActual = widget.planoActual == planoId;
              final eDestaque = planoId == 'ouro';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: eActual ? cor : eDestaque
                        ? cor.withValues(alpha: 0.4)
                        : Colors.grey.shade200,
                    width: eActual || eDestaque ? 2 : 1,
                  ),
                  boxShadow: eDestaque
                      ? [BoxShadow(color: cor.withValues(alpha: 0.15),
                          blurRadius: 16, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Column(
                  children: [
                    // Header do plano
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cor.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: cor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(icone, color: cor, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(_nomePlano(planoId),
                                        style: TextStyle(color: cor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18)),
                                    if (eDestaque) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: cor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text('POPULAR',
                                            style: TextStyle(color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                    if (eActual) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Text('ACTIVO',
                                            style: TextStyle(color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800)),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '${valor.toStringAsFixed(0)} MT',
                                        style: TextStyle(
                                          color: cor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' / $duracao',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Beneficios
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          ...beneficios.map((b) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 20, height: 20,
                                  decoration: BoxDecoration(
                                    color: cor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check,
                                      color: cor, size: 12),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(b,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF444444))),
                                ),
                              ],
                            ),
                          )),
                          const SizedBox(height: 8),

                          // Botao
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: eActual ? null : () => _irParaPagamento(
                                planoId, valor, duracao, cor),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: eActual
                                    ? Colors.grey.shade200 : cor,
                                disabledBackgroundColor: Colors.grey.shade200,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(
                                eActual ? 'Plano actual' : 'Subscrever ${_nomePlano(planoId)}',
                                style: TextStyle(
                                  color: eActual ? Colors.grey : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),

            // Nota gratuito
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFF007AFF), size: 18),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'O plano Gratuito da acesso a 1 ano de exame por curso. Faz upgrade para desbloquear mais.',
                      style: TextStyle(fontSize: 12,
                          color: Color(0xFF007AFF), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _irParaPagamento(
      String planoId, double valor, String duracao, Color cor) {
    final route = MaterialPageRoute(
      builder: (_) => PagamentoScreen(
        planoId: planoId,
        nomePlano: _nomePlano(planoId),
        instituicaoId: widget.instituicaoId,
        instituicaoSigla: widget.instituicaoSigla,
        cursoNome: widget.cursoNome,
        valor: valor,
        duracao: duracao,
        corPlano: cor,
      ),
    );
    Navigator.push(context, route).then((_) {
      if (mounted) Navigator.pop(context, true);
    });
  }

  String _nomePlano(String plano) {
    switch (plano) {
      case 'prata': return 'Prata';
      case 'ouro': return 'Ouro';
      case 'diamante': return 'Diamante';
      default: return 'Gratuito';
    }
  }
}