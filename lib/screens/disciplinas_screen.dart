import 'package:flutter/material.dart';
import 'simulador_screen.dart';

class DisciplinasScreen extends StatelessWidget {
  final String instituicaoSigla;
  final String cursoNome;
  final int ano;
  final String disciplinas;

  const DisciplinasScreen({
    Key? key,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.ano,
    required this.disciplinas,
  }) : super(key: key);

  List<String> get _listaDisciplinas =>
      disciplinas.split(',').map((d) => d.trim()).toList();

  IconData _iconeDisciplina(String disciplina) {
    switch (disciplina.toLowerCase()) {
      case 'matemática': return Icons.calculate;
      case 'física': return Icons.science;
      case 'biologia': return Icons.biotech;
      case 'química': return Icons.emoji_nature;
      case 'português': return Icons.menu_book;
      case 'história': return Icons.account_balance;
      default: return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              width: double.infinity,
              color: const Color(0xFF007AFF),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passo 4 de 4 — $instituicaoSigla · $ano',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Text(
                          'Escolhe a Disciplina',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cursoNome,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // INFO DO EXAME
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _InfoChip(icone: Icons.timer, texto: '90 min'),
                  const SizedBox(width: 12),
                  _InfoChip(icone: Icons.quiz, texto: '40 questões'),
                  const SizedBox(width: 12),
                  _InfoChip(icone: Icons.star, texto: '20 valores'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // TÍTULO
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Selecciona a disciplina que queres praticar:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),

            // LISTA DE DISCIPLINAS
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _listaDisciplinas.length,
                itemBuilder: (context, index) {
                  final disciplina = _listaDisciplinas[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SimuladorScreen(
                            instituicaoSigla: instituicaoSigla,
                            cursoNome: cursoNome,
                            ano: ano,
                            disciplina: disciplina,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F1FB),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: Icon(
                              _iconeDisciplina(disciplina),
                              color: const Color(0xFF007AFF),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  disciplina,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Pronto a começar',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.play_arrow, color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Iniciar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icone;
  final String texto;

  const _InfoChip({required this.icone, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icone, color: const Color(0xFF007AFF), size: 14),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              color: Color(0xFF007AFF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}