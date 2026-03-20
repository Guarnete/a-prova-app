import 'package:flutter/material.dart';
import 'resultado_screen.dart';

class SimuladorScreen extends StatefulWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final int ano;
  final String disciplina;
  final String todasDisciplinas;

  const SimuladorScreen({
    super.key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.ano,
    required this.disciplina,
    required this.todasDisciplinas,
  });

  @override
  State<SimuladorScreen> createState() => _SimuladorScreenState();
}

class _SimuladorScreenState extends State<SimuladorScreen> {
  int _perguntaActual = 0;
  final Map<int, int> _respostas = {};
  int _tempoRestante = 90 * 60; // 90 minutos
  bool _timerActivo = true;

  final List<Map<String, dynamic>> _questoes = [
    {
      'texto': 'A Constituição da República de Moçambique define o Estado como:',
      'opcoes': [
        'A) Autocrático',
        'B) De Direito Democrático',
        'C) Monárquico',
        'D) Teocrático',
      ],
      'correcta': 1,
      'justificacao': 'O Artigo 1 da CRM estabelece Moçambique como um Estado de Direito Democrático.',
    },
    {
      'texto': 'O Rio Zambeze desagua no Oceano:',
      'opcoes': [
        'A) Atlântico',
        'B) Pacífico',
        'C) Índico',
        'D) Antártico',
      ],
      'correcta': 2,
      'justificacao': 'O Rio Zambeze desagua no Canal de Moçambique, parte do Oceano Índico.',
    },
    {
      'texto': 'Qual é a capital de Moçambique?',
      'opcoes': [
        'A) Beira',
        'B) Nampula',
        'C) Maputo',
        'D) Quelimane',
      ],
      'correcta': 2,
      'justificacao': 'Maputo é a capital e maior cidade de Moçambique.',
    },
    {
      'texto': 'Moçambique tornou-se independente em:',
      'opcoes': [
        'A) 1964',
        'B) 1970',
        'C) 1975',
        'D) 1980',
      ],
      'correcta': 2,
      'justificacao': 'Moçambique proclamou a sua independência a 25 de Junho de 1975.',
    },
    {
      'texto': 'Qual é a língua oficial de Moçambique?',
      'opcoes': [
        'A) Inglês',
        'B) Francês',
        'C) Swahili',
        'D) Português',
      ],
      'correcta': 3,
      'justificacao': 'O Português é a língua oficial de Moçambique, herança do período colonial.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _iniciarTimer();
  }

  void _iniciarTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_timerActivo) return false;
      setState(() {
        if (_tempoRestante > 0) {
          _tempoRestante--;
        } else {
          _timerActivo = false;
          _finalizarExame();
        }
      });
      return _timerActivo && _tempoRestante > 0;
    });
  }

  String _formatarTempo(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _corTimer() {
    if (_tempoRestante > 30 * 60) return Colors.white;
    if (_tempoRestante > 10 * 60) return Colors.amber;
    return Colors.red.shade300;
  }

  void _finalizarExame() {
    // Verificar questões por responder
    final naoRespondidas = <int>[];
    for (int i = 0; i < _questoes.length; i++) {
      if (!_respostas.containsKey(i)) naoRespondidas.add(i + 1);
    }

    // Se há questões por responder e o tempo não esgotou, alertar
    if (naoRespondidas.isNotEmpty && _timerActivo) {
      _mostrarDialogQuestoesPorResponder(naoRespondidas);
      return;
    }

    _submeterExame();
  }

  void _mostrarDialogQuestoesPorResponder(List<int> naoRespondidas) {
    final numerosFormatados = naoRespondidas.join(', ');
    final totalPorResponder = naoRespondidas.length;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.orange.shade600, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Questões por responder',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tens $totalPorResponder questão(ões) sem resposta:',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Lista das questões por responder
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Questão(ões) nº $numerosFormatados',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              // Botão: ir para primeira questão por responder
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      // Navega para a primeira questão por responder
                      _perguntaActual = naoRespondidas.first - 1;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Responder questões em falta',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Botão: submeter mesmo assim
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _submeterExame();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Submeter assim mesmo',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submeterExame() {
    _timerActivo = false;
    final tempoGasto = (90 * 60) - _tempoRestante;
    int acertos = 0;
    for (int i = 0; i < _questoes.length; i++) {
      if (_respostas[i] == _questoes[i]['correcta']) acertos++;
    }
    final nota = (acertos / _questoes.length) * 20;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultadoScreen(
          instituicaoId: widget.instituicaoId,
          instituicaoSigla: widget.instituicaoSigla,
          cursoNome: widget.cursoNome,
          ano: widget.ano,
          disciplina: widget.disciplina,
          todasDisciplinas: widget.todasDisciplinas,
          nota: nota,
          acertos: acertos,
          total: _questoes.length,
          tempoGasto: tempoGasto,
          questoes: _questoes,
          respostas: _respostas,
        ),
      ),
    );
  }

  void _confirmarSaida() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              const Text(
                'Sair do Exame?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'O teu progresso será perdido se saíres agora.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Continuar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        _timerActivo = false;
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Sair', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timerActivo = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final questao = _questoes[_perguntaActual];
    final progresso = (_perguntaActual + 1) / _questoes.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [

            // HEADER DO SIMULADOR
            Container(
              color: const Color(0xFF007AFF),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _confirmarSaida,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        widget.disciplina.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${widget.instituicaoSigla} · ${widget.ano}',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _formatarTempo(_tempoRestante),
                          style: TextStyle(
                            color: _corTimer(),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // BARRA DE PROGRESSO
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questão ${_perguntaActual + 1} de ${_questoes.length}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Text(
                        '${(_respostas.length)} respondidas',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progresso,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF007AFF)),
                    ),
                  ),
                ],
              ),
            ),

            // QUESTÃO
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // CARD DA QUESTÃO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        questao['texto'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // OPÇÕES
                    ...(questao['opcoes'] as List<String>).asMap().entries.map((entry) {
                      final idx = entry.key;
                      final opcao = entry.value;
                      final seleccionada = _respostas[_perguntaActual] == idx;

                      return GestureDetector(
                        onTap: () => setState(() => _respostas[_perguntaActual] = idx),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: seleccionada ? const Color(0xFF007AFF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: seleccionada ? const Color(0xFF007AFF) : Colors.grey.shade200,
                              width: seleccionada ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: seleccionada ? Colors.white24 : const Color(0xFFE6F1FB),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    opcao[0],
                                    style: TextStyle(
                                      color: seleccionada ? Colors.white : const Color(0xFF007AFF),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  opcao.substring(3),
                                  style: TextStyle(
                                    color: seleccionada ? Colors.white : const Color(0xFF1A1A1A),
                                    fontSize: 14,
                                    fontWeight: seleccionada ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (seleccionada)
                                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // FOOTER — NAVEGAÇÃO
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_perguntaActual > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _perguntaActual--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFF007AFF)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text(
                          '← Anterior',
                          style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  if (_perguntaActual > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _perguntaActual == _questoes.length - 1
                          ? _finalizarExame
                          : () => setState(() => _perguntaActual++),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _perguntaActual == _questoes.length - 1
                            ? Colors.green
                            : const Color(0xFF007AFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _perguntaActual == _questoes.length - 1 ? 'Finalizar ✓' : 'Próxima →',
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
          ],
        ),
      ),
    );
  }
}