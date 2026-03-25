import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'simulador_screen.dart';

class DisciplinasScreen extends StatefulWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final int ano;
  final String disciplinas;

  const DisciplinasScreen({
    super.key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.ano,
    required this.disciplinas,
  });

  @override
  State<DisciplinasScreen> createState() => _DisciplinasScreenState();
}

class _DisciplinasScreenState extends State<DisciplinasScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // melhorNota por disciplina: { 'Biologia': 14.5, 'Química': 8.0 }
  Map<String, double> _notasPorDisciplina = {};
  bool _carregando = true;

  List<String> get _listaDisciplinas =>
      widget.disciplinas.split(',').map((d) => d.trim()).toList();

  @override
  void initState() {
    super.initState();
    _carregarResultados();
  }

  Future<void> _carregarResultados() async {
    setState(() => _carregando = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await _firestore
          .collection('utilizadores')
          .doc(uid)
          .collection('resultados')
          .where('ano', isEqualTo: widget.ano)
          .where('cursoNome', isEqualTo: widget.cursoNome)
          .where('instituicaoId', isEqualTo: widget.instituicaoId)
          .get();

      // Calcula melhor nota por disciplina
      final Map<String, double> notas = {};
      for (final doc in snapshot.docs) {
        final dados = doc.data();
        final disciplina = dados['disciplina'] as String? ?? '';
        final nota = (dados['nota'] ?? 0).toDouble();
        if (!notas.containsKey(disciplina) || nota > notas[disciplina]!) {
          notas[disciplina] = nota;
        }
      }

      if (mounted) {
        setState(() {
          _notasPorDisciplina = notas;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  // Cor do círculo baseada na nota
  Color _corProgresso(double nota) {
    if (nota >= 16) return const Color(0xFFD4AF37); // Amarelo — bem preparado
    if (nota >= 13) return const Color(0xFF4CAF50); // Verde — preparado
    return const Color(0xFFF44336);                  // Vermelho — prepare-se melhor
  }

  // Texto de estado baseado na nota
  String _textoEstado(double nota) {
    if (nota >= 16) return 'Bem preparado';
    if (nota >= 13) return 'Preparado';
    return 'Prepare-se melhor';
  }

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
            _buildHeader(),
            _buildInfoChips(),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selecciona a disciplina que queres praticar:',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ),
            _carregando
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF007AFF)),
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
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.instituicaoSigla} · ${widget.ano}',
                  style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5),
                ),
                const Text(
                  'Escolhe a disciplina',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.cursoNome,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: const Row(
        children: [
          _InfoChip(icone: Icons.timer, texto: '90 min'),
          SizedBox(width: 12),
          _InfoChip(icone: Icons.quiz, texto: '40 questões'),
          SizedBox(width: 12),
          _InfoChip(icone: Icons.star, texto: '20 valores'),
        ],
      ),
    );
  }

  Widget _buildLista() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: _listaDisciplinas.length,
        itemBuilder: (context, index) {
          final disciplina = _listaDisciplinas[index];
          final melhorNota = _notasPorDisciplina[disciplina] ?? 0.0;
          final jaFez = _notasPorDisciplina.containsKey(disciplina);
          final cor = jaFez ? _corProgresso(melhorNota) : Colors.grey.shade300;
          final progresso = melhorNota / 20.0; // 0.0 a 1.0

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SimuladorScreen(
                    instituicaoId: widget.instituicaoId,
                    instituicaoSigla: widget.instituicaoSigla,
                    cursoNome: widget.cursoNome,
                    ano: widget.ano,
                    disciplina: disciplina,
                    todasDisciplinas: widget.disciplinas,
                  ),
                ),
              ).then((_) => _carregarResultados()); // Recarrega após voltar
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Ícone da disciplina
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FB),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      _iconeDisciplina(disciplina),
                      color: const Color(0xFF007AFF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Nome + estado
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disciplina,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          jaFez ? _textoEstado(melhorNota) : 'Ainda não realizado',
                          style: TextStyle(
                            fontSize: 12,
                            color: jaFez ? cor : Colors.grey,
                            fontWeight: jaFez ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Círculo de progresso
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Círculo de fundo
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: CircularProgressIndicator(
                            value: jaFez ? progresso : 0,
                            strokeWidth: 5,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(cor),
                          ),
                        ),
                        // Texto dentro do círculo
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              jaFez
                                  ? melhorNota.toStringAsFixed(0)
                                  : '—',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: jaFez ? cor : Colors.grey.shade400,
                              ),
                            ),
                            if (jaFez)
                              Text(
                                '/20',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
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
    );
  }
}

// ── Chip de informação ────────────────────────────────────────────────────────
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