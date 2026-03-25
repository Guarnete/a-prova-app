import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _resultados = [];
  bool _carregando = true;

  // Filtros
  String? _filtroCurso;
  String? _filtroInstituicao;
  List<String> _cursosFiltro = [];
  List<String> _instituicoesFiltro = [];

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  Future<void> _carregarHistorico() async {
    setState(() => _carregando = true);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      final snapshot = await _firestore
          .collection('utilizadores')
          .doc(uid)
          .collection('resultados')
          .orderBy('data', descending: true)
          .get();

      final resultados = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
          // Normaliza timestamp para DateTime
          'dataFormatada': _formatarData(data['data']),
        };
      }).toList();

      // Extrai valores únicos para filtros
      final cursos = resultados.map((r) => r['cursoNome'] as String? ?? '').toSet().toList();
      final instituicoes = resultados.map((r) => r['instituicaoId'] as String? ?? '').toSet().toList();
      cursos.sort();
      instituicoes.sort();

      if (mounted) {
        setState(() {
          _resultados = resultados;
          _cursosFiltro = cursos;
          _instituicoesFiltro = instituicoes;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _formatarData(dynamic timestamp) {
    if (timestamp == null) return '—';
    try {
      final dt = (timestamp as Timestamp).toDate();
      final dia = dt.day.toString().padLeft(2, '0');
      final mes = dt.month.toString().padLeft(2, '0');
      final ano = dt.year;
      final hora = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$dia/$mes/$ano às $hora:$min';
    } catch (_) {
      return '—';
    }
  }

  String _formatarTempo(int segundos) {
    final m = segundos ~/ 60;
    final s = segundos % 60;
    return '${m}min ${s}s';
  }

  List<Map<String, dynamic>> get _resultadosFiltrados {
    return _resultados.where((r) {
      if (_filtroCurso != null && r['cursoNome'] != _filtroCurso) return false;
      if (_filtroInstituicao != null && r['instituicaoId'] != _filtroInstituicao) return false;
      return true;
    }).toList();
  }

  // Agrupa resultados por ano de exame
  Map<String, List<Map<String, dynamic>>> get _resultadosAgrupados {
    final Map<String, List<Map<String, dynamic>>> agrupados = {};
    for (final r in _resultadosFiltrados) {
      final chave = '${r['ano']}';
      agrupados.putIfAbsent(chave, () => []).add(r);
    }
    // Ordena os grupos por ano descendente
    final ordenado = Map.fromEntries(
      agrupados.entries.toList()
        ..sort((a, b) => int.parse(b.key).compareTo(int.parse(a.key))),
    );
    return ordenado;
  }

  Color _corNota(double nota) {
    if (nota >= 16) return const Color(0xFFD4AF37);
    if (nota >= 13) return const Color(0xFF34C759);
    if (nota >= 10) return const Color(0xFFFF9500);
    return const Color(0xFFFF3B30);
  }

  IconData _iconeNota(double nota) {
    if (nota >= 16) return Icons.emoji_events;
    if (nota >= 13) return Icons.check_circle;
    if (nota >= 10) return Icons.remove_circle;
    return Icons.cancel;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_carregando && _resultados.isNotEmpty) _buildFiltros(),
            _carregando
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                    ),
                  )
                : _resultados.isEmpty
                    ? _buildVazio()
                    : _resultadosFiltrados.isEmpty
                        ? _buildSemResultadosFiltro()
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
                const Text('HISTÓRICO',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const Text('Os teus exames',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                if (!_carregando && _resultados.isNotEmpty)
                  Text('${_resultados.length} exame${_resultados.length != 1 ? 's' : ''} realizados',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          // Botão refresh
          GestureDetector(
            onTap: _carregarHistorico,
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

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: _DropdownFiltro(
              valor: _filtroCurso,
              opcoes: _cursosFiltro,
              hint: 'Todos os cursos',
              onChanged: (val) => setState(() => _filtroCurso = val),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DropdownFiltro(
              valor: _filtroInstituicao,
              opcoes: _instituicoesFiltro,
              hint: 'Todas as inst.',
              onChanged: (val) => setState(() => _filtroInstituicao = val),
            ),
          ),
          if (_filtroCurso != null || _filtroInstituicao != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() {
                _filtroCurso = null;
                _filtroInstituicao = null;
              }),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close, color: Color(0xFFFF3B30), size: 16),
              ),
            ),
          ],
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
            Icon(Icons.history, color: Colors.grey.shade300, size: 72),
            const SizedBox(height: 16),
            const Text('Ainda não fizeste nenhum exame',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            const Text('Os teus resultados aparecerão aqui\ndepois de realizares o primeiro exame.',
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Ir praticar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemResultadosFiltro() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list_off, color: Colors.grey.shade300, size: 56),
            const SizedBox(height: 16),
            const Text('Sem resultados para este filtro',
                style: TextStyle(fontSize: 15, color: Colors.grey)),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _filtroCurso = null;
                _filtroInstituicao = null;
              }),
              child: const Text('Limpar filtros',
                  style: TextStyle(color: Color(0xFF007AFF))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    final agrupados = _resultadosAgrupados;
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _carregarHistorico,
        color: const Color(0xFF007AFF),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: agrupados.length,
          itemBuilder: (context, index) {
            final ano = agrupados.keys.elementAt(index);
            final resultadosAno = agrupados[ano]!;
            return _buildGrupoAno(ano, resultadosAno);
          },
        ),
      ),
    );
  }

  Widget _buildGrupoAno(String ano, List<Map<String, dynamic>> resultados) {
    // Estatísticas do grupo
    final notas = resultados.map((r) => (r['nota'] ?? 0).toDouble()).toList();
    final melhorNota = notas.isEmpty ? 0.0 : notas.reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho do grupo
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF007AFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Exame $ano',
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Text('${resultados.length} tent.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Spacer(),
              Text('Melhor: ${melhorNota.toStringAsFixed(1)}/20',
                  style: TextStyle(
                    color: _corNota(melhorNota),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),

        // Cards do grupo
        ...resultados.map((r) => _buildCardResultado(r)),
        const SizedBox(height: 8),

        // Linha separadora entre grupos
        Divider(color: Colors.grey.shade200, height: 24),
      ],
    );
  }

  Widget _buildCardResultado(Map<String, dynamic> resultado) {
    final nota = (resultado['nota'] ?? 0).toDouble();
    final acertos = resultado['acertos'] as int? ?? 0;
    final total = resultado['total'] as int? ?? 0;
    final tempoGasto = resultado['tempoGasto'] as int? ?? 0;
    final disciplina = resultado['disciplina'] as String? ?? '';
    final cursoNome = resultado['cursoNome'] as String? ?? '';
    final instituicaoId = resultado['instituicaoId'] as String? ?? '';
    final dataFormatada = resultado['dataFormatada'] as String? ?? '—';
    final aprovado = resultado['aprovado'] as bool? ?? nota >= 13;
    final cor = _corNota(nota);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Círculo de nota
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: cor.withValues(alpha: 0.3), width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(nota.toStringAsFixed(1),
                      style: TextStyle(color: cor, fontWeight: FontWeight.w800, fontSize: 14)),
                  Text('/20', style: TextStyle(color: cor.withValues(alpha: 0.7), fontSize: 9)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(disciplina,
                      style: const TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 2),
                  Text('$instituicaoId · $cursoNome',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _ChipInfo(
                        icone: Icons.check,
                        texto: '$acertos/$total',
                        cor: aprovado ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                      ),
                      const SizedBox(width: 6),
                      _ChipInfo(
                        icone: Icons.timer,
                        texto: _formatarTempo(tempoGasto),
                        cor: const Color(0xFF007AFF),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Estado + data
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(_iconeNota(nota), color: cor, size: 22),
                const SizedBox(height: 4),
                Text(dataFormatada.split(' às ').first,
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(dataFormatada.contains('às')
                    ? dataFormatada.split(' às ').last : '',
                    style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _DropdownFiltro extends StatelessWidget {
  final String? valor;
  final List<String> opcoes;
  final String hint;
  final void Function(String?) onChanged;

  const _DropdownFiltro({
    required this.valor,
    required this.opcoes,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          hint: Text(hint,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis),
          style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
          isExpanded: true,
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(hint, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            ...opcoes.map((o) => DropdownMenuItem<String>(
              value: o,
              child: Text(o, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12)),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ChipInfo extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color cor;

  const _ChipInfo({required this.icone, required this.texto, required this.cor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, color: cor, size: 11),
          const SizedBox(width: 3),
          Text(texto, style: TextStyle(color: cor, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}