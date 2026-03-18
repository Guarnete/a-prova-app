import 'package:flutter/material.dart';
import 'disciplinas_screen.dart';
import 'instituicoes_screen.dart';

class ResultadoScreen extends StatelessWidget {
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
    Key? key,
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
  }) : super(key: key);

  String _formatarTempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0) {
      return '${h}h ${m}min ${s}s';
    }
    return '${m}min ${s}s';
  }

  bool get _aprovado => nota >= 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [

            // HEADER RESULTADO
            Container(
              width: double.infinity,
              color: _aprovado ? Colors.green : Colors.red,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
              child: Column(
                children: [
                  Text(
                    _aprovado ? '🎉' : '😔',
                    style: const TextStyle(fontSize: 48),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${nota.toStringAsFixed(1)} / 20',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _aprovado ? 'APROVADO ✓' : 'REPROVADO ✗',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$disciplina · $instituicaoSigla · $ano',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // MÉTRICAS
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _MetricaCard(
                      icone: Icons.check_circle,
                      cor: Colors.green,
                      valor: '$acertos/$total',
                      label: 'Acertos',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricaCard(
                      icone: Icons.cancel,
                      cor: Colors.red,
                      valor: '${total - acertos}/$total',
                      label: 'Erros',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricaCard(
                      icone: Icons.timer,
                      cor: const Color(0xFF007AFF),
                      valor: _formatarTempo(tempoGasto),
                      label: 'Tempo',
                    ),
                  ),
                ],
              ),
            ),

            // CORREÇÃO DETALHADA
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: Color(0xFF007AFF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Correcção Detalhada',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: questoes.length,
                itemBuilder: (context, index) {
                  final questao = questoes[index];
                  final respostaUtilizador = respostas[index];
                  final respostaCorrecta = questao['correcta'] as int;
                  final acertou = respostaUtilizador == respostaCorrecta;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: acertou ? Colors.green.shade200 : Colors.red.shade200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // CABEÇALHO DA QUESTÃO
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: acertou ? Colors.green.shade50 : Colors.red.shade50,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                acertou ? Icons.check_circle : Icons.cancel,
                                color: acertou ? Colors.green : Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Questão ${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: acertou ? Colors.green.shade700 : Colors.red.shade700,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                acertou ? '+1 ponto' : '0 pontos',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: acertou ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // TEXTO DA QUESTÃO
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                questao['texto'] as String,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // RESPOSTA CORRECTA
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check, color: Colors.green, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        (questao['opcoes'] as List<String>)[respostaCorrecta],
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // RESPOSTA DO UTILIZADOR (se errou)
                              if (!acertou && respostaUtilizador != null) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.close, color: Colors.red, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          (questao['opcoes'] as List<String>)[respostaUtilizador],
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // JUSTIFICAÇÃO
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F1FB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF007AFF).withOpacity(0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, color: Color(0xFF007AFF), size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        questao['justificacao'] as String,
                                        style: const TextStyle(
                                          color: Color(0xFF007AFF),
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
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
                  );
                },
              ),
            ),

            // BOTÕES DE ACÇÃO
            Container(
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        MaterialPageRoute(builder: (context) => const InstituicoesScreen()),
                        (route) => route.isFirst,
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF007AFF)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Mudar de Disciplina',
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
            ),
          ],
        ),
      ),
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