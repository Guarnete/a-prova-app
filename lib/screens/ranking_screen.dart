import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RankingScreen extends StatefulWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;

  const RankingScreen({
    super.key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
  });

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _estudantes = [];
  bool _carregando = true;
  String? _filtroProvincia;
  List<String> _provincias = [];

  String get _chaveRanking => '${widget.instituicaoId}_${widget.cursoNome}';
  String get _uidActual => _auth.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _carregarRanking();
  }

  Future<void> _carregarRanking() async {
    setState(() => _carregando = true);
    try {
      final snapshot = await _firestore
          .collection('ranking')
          .doc(_chaveRanking)
          .collection('estudantes')
          .orderBy('melhorNota', descending: true)
          .get();

      final estudantes = snapshot.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();

      // Extrai províncias únicas para filtro
      final provincias = estudantes
          .map((e) => e['provincia'] as String? ?? '')
          .where((p) => p.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      if (mounted) {
        setState(() {
          _estudantes = estudantes;
          _provincias = provincias;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  List<Map<String, dynamic>> get _estudantesFiltrados {
    if (_filtroProvincia == null) return _estudantes;
    return _estudantes
        .where((e) => e['provincia'] == _filtroProvincia)
        .toList();
  }

  // Posição do utilizador actual no ranking filtrado
  int get _posicaoActual {
    final lista = _estudantesFiltrados;
    final idx = lista.indexWhere((e) => e['id'] == _uidActual);
    return idx == -1 ? -1 : idx + 1;
  }

  // Dados do utilizador actual
  Map<String, dynamic>? get _dadosActual {
    try {
      return _estudantes.firstWhere((e) => e['id'] == _uidActual);
    } catch (_) {
      return null;
    }
  }

  Color _corPosicao(int posicao) {
    switch (posicao) {
      case 1: return const Color(0xFFD4AF37);
      case 2: return const Color(0xFF9E9E9E);
      case 3: return const Color(0xFFCD7F32);
      default: return const Color(0xFF007AFF);
    }
  }

  IconData _iconePosicao(int posicao) {
    switch (posicao) {
      case 1: return Icons.emoji_events;
      case 2: return Icons.military_tech;
      case 3: return Icons.workspace_premium;
      default: return Icons.person;
    }
  }

  Color _corNota(double nota) {
    if (nota >= 16) return const Color(0xFFD4AF37);
    if (nota >= 13) return const Color(0xFF34C759);
    if (nota >= 10) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_carregando && _estudantes.isNotEmpty) ...[
              _buildMinhaPosicao(),
              if (_provincias.isNotEmpty) _buildFiltroProvincia(),
            ],
            _carregando
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                    ),
                  )
                : _estudantes.isEmpty
                    ? _buildVazio()
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('RANKING',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const Text('Tabela de classificação',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('${widget.instituicaoSigla} · ${widget.cursoNome}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _carregarRanking,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinhaPosicao() {
    final posicao = _posicaoActual;
    final dados = _dadosActual;
    if (dados == null) return const SizedBox();

    final nota = (dados['melhorNota'] ?? 0).toDouble();
    final totalEstudantes = _estudantesFiltrados.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF007AFF).withValues(alpha: 0.9),
            const Color(0xFF007AFF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                posicao == -1 ? '—' : '#$posicao',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('A tua posição',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text(
                  posicao == -1
                      ? 'Ainda não entraste no ranking'
                      : '$posicao de $totalEstudantes estudantes',
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(nota.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white,
                      fontWeight: FontWeight.w800, fontSize: 22)),
              const Text('/20',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroProvincia() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          const Text('Província:',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ChipFiltro(
                    label: 'Todas',
                    activo: _filtroProvincia == null,
                    onTap: () => setState(() => _filtroProvincia = null),
                  ),
                  ..._provincias.map((p) => _ChipFiltro(
                    label: p,
                    activo: _filtroProvincia == p,
                    onTap: () => setState(() => _filtroProvincia = p),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVazio() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.leaderboard, color: Colors.grey.shade300, size: 72),
            const SizedBox(height: 16),
            const Text('Ranking ainda vazio',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            const Text('Sê o primeiro a entrar!\nCompleta um exame para aparecer aqui.',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    final lista = _estudantesFiltrados;
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _carregarRanking,
        color: const Color(0xFF007AFF),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: lista.length,
          itemBuilder: (context, index) {
            final estudante = lista[index];
            final posicao = index + 1;
            final eActual = estudante['id'] == _uidActual;
            final nota = (estudante['melhorNota'] ?? 0).toDouble();
            final nome = estudante['nome'] as String? ?? 'Estudante';
            final provincia = estudante['provincia'] as String? ?? '';
            final cor = _corPosicao(posicao);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: eActual
                    ? const Color(0xFF007AFF).withValues(alpha: 0.06)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: eActual
                      ? const Color(0xFF007AFF).withValues(alpha: 0.3)
                      : posicao <= 3
                          ? cor.withValues(alpha: 0.3)
                          : Colors.grey.shade200,
                  width: eActual || posicao <= 3 ? 1.5 : 1,
                ),
                boxShadow: posicao <= 3
                    ? [BoxShadow(color: cor.withValues(alpha: 0.1),
                        blurRadius: 8, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Posição
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: posicao <= 3
                            ? cor.withValues(alpha: 0.15)
                            : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: posicao <= 3
                          ? Icon(_iconePosicao(posicao), color: cor, size: 20)
                          : Center(
                              child: Text('$posicao',
                                  style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ),
                    ),
                    const SizedBox(width: 12),

                    // Nome + província
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  eActual ? '$nome (tu)' : nome,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: eActual
                                        ? const Color(0xFF007AFF)
                                        : const Color(0xFF1A1A1A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (provincia.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(provincia,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey)),
                          ],
                        ],
                      ),
                    ),

                    // Nota
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(nota.toStringAsFixed(1),
                            style: TextStyle(
                                color: _corNota(nota),
                                fontWeight: FontWeight.w800,
                                fontSize: 18)),
                        Text('/20',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _ChipFiltro extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _ChipFiltro({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF007AFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? const Color(0xFF007AFF) : Colors.grey.shade300,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: activo ? Colors.white : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}