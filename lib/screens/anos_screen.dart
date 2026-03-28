import 'package:flutter/material.dart';
import '../utils/normalizador.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'disciplinas_screen.dart';
import 'planos_screen.dart';

class AnosScreen extends StatefulWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final String disciplinas;

  const AnosScreen({
    super.key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.disciplinas,
  });

  @override
  State<AnosScreen> createState() => _AnosScreenState();
}

class _AnosScreenState extends State<AnosScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _planoUtilizador = 'gratuito';
  Map<String, dynamic> _progressoAnos = {};

  // Anos carregados dinamicamente do Firestore
  List<Map<String, dynamic>> _anosDisponiveis = [];

  bool _carregando = true;

  static const Map<String, int> _hierarquiaPlanos = {
    'gratuito': 0,
    'bronze': 1,
    'prata': 2,
    'ouro': 3,
    'diamante': 4,
  };

  static const Map<String, Color> _coresPlano = {
    'gratuito': Color(0xFF007AFF),
    'bronze': Color(0xFFCD7F32),
    'prata': Color(0xFF757575),
    'ouro': Color(0xFFD4AF37),
  };

  static const Map<String, String> _nomesPlano = {
    'gratuito': 'Gratuito',
    'bronze': 'Bronze',
    'prata': 'Prata',
    'ouro': 'Ouro',
  };

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() => _carregando = true);
    await Future.wait([
      _carregarAnos(),
      _carregarDadosUtilizador(),
    ]);
    if (mounted) setState(() => _carregando = false);
  }

// Remove acentos e converte para ID do Firestore
  String _normalizarId(String texto) => Normalizador.cursoId(texto);

  // Carrega anos do Firestore: instituicoes/{id}/cursos/{cursoId}/anos
  Future<void> _carregarAnos() async {
    try {
      final anosSnapshot = await _firestore
          .collection('instituicoes')
          .doc(widget.instituicaoId)
          .collection('cursos')
          .doc(_normalizarId(widget.cursoNome))
          .collection('anos')
          .get();

      final todosAnos = anosSnapshot.docs
          .map((doc) => doc.data())
          .where((data) => data['activo'] == true)
          .toList();

      todosAnos.sort(
          (a, b) => (a['ano'] as int).compareTo(b['ano'] as int));

      final anos = todosAnos.map((data) {
        return <String, dynamic>{
          'ano': data['ano'] as int,
          'planoMinimo': data['planoMinimo'] as String? ?? 'gratuito',
        };
      }).toList();

      if (mounted) setState(() => _anosDisponiveis = anos);
    } catch (e) {
      if (mounted) setState(() => _anosDisponiveis = []);
    }
  }

  Future<void> _carregarDadosUtilizador() async {
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
        (c) =>
            c['instituicaoId'] == widget.instituicaoId &&
            c['cursoNome'] == widget.cursoNome,
        orElse: () => {},
      );

      if (mounted) {
        setState(() {
          _planoUtilizador = cursoActivo['plano'] ?? 'gratuito';
          _progressoAnos = Map<String, dynamic>.from(
            cursoActivo['progressoAnos'] ?? {},
          );
        });
      }
    } catch (e) {
      // mantém valores por defeito
    }
  }

  bool _temAcesso(Map<String, dynamic> anoData) {
    final planoMinimo = anoData['planoMinimo'] as String;
    final ano = anoData['ano'] as int;

    // Gratuito: só acesso ao ano com planoMinimo='gratuito'
    if (_planoUtilizador == 'gratuito') {
      return planoMinimo == 'gratuito';
    }

    // Verifica nível do plano
    final nivelUtilizador = _hierarquiaPlanos[_planoUtilizador] ?? 0;
    final nivelMinimo = _hierarquiaPlanos[planoMinimo] ?? 0;
    if (nivelUtilizador < nivelMinimo) return false;

    // Primeiro ano deste plano: sempre acessível se tiver o plano
    final anosDoPlano = _anosDisponiveis
        .where((a) => a['planoMinimo'] == planoMinimo)
        .toList();
    if (anosDoPlano.isNotEmpty && anosDoPlano.first['ano'] == ano) {
      return true;
    }

    // Anos seguintes: nota mínima depende do plano
    // Bronze/Prata: ≥ 13 | Ouro/Diamante: ≥ 15
    final notaMinima = (_hierarquiaPlanos[_planoUtilizador] ?? 0) >= 3
        ? 15.0
        : 13.0;
    final indexAno = _anosDisponiveis.indexWhere((a) => a['ano'] == ano);
    if (indexAno <= 0) return true;
    final anoAnterior = _anosDisponiveis[indexAno - 1]['ano'] as int;
    final progressoAnterior =
        _progressoAnos[anoAnterior.toString()] as Map<String, dynamic>?;
    final melhorNota = (progressoAnterior?['melhorNota'] ?? 0).toDouble();
    return melhorNota >= notaMinima;
  }

  Color _corDoAno(String planoMinimo) {
    return _coresPlano[planoMinimo] ?? const Color(0xFF007AFF);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildLegenda(),
            if (_carregando)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                ),
              )
            else if (_anosDisponiveis.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_empty,
                          color: Colors.grey, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Ainda não há exames disponíveis.',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              )
            else
              _buildGrid(),
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
                  widget.instituicaoSigla,
                  style: const TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Text(
                  'Escolhe o ano do exame',
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

  Widget _buildLegenda() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _LegendaItem(cor: _coresPlano['gratuito']!, texto: 'Gratuito'),
          const SizedBox(width: 14),
          _LegendaItem(cor: _coresPlano['bronze']!, texto: 'Bronze'),
          const SizedBox(width: 14),
          _LegendaItem(cor: _coresPlano['prata']!, texto: 'Prata'),
          const SizedBox(width: 14),
          _LegendaItem(cor: _coresPlano['ouro']!, texto: 'Ouro'),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final largura = constraints.maxWidth;
          final ratio = largura > 600 ? 1.4 : 0.95;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: ratio,
            ),
            itemCount: _anosDisponiveis.length,
            itemBuilder: (context, index) {
              final item = _anosDisponiveis[index];
              final temAcesso = _temAcesso(item);
              final planoMinimo = item['planoMinimo'] as String;
              final cor = _corDoAno(planoMinimo);
              final ano = item['ano'] as int;

              final progressoAno = _progressoAnos[ano.toString()]
                  as Map<String, dynamic>?;
              final melhorNota =
                  (progressoAno?['melhorNota'] ?? 0).toDouble();
              final tentativas =
                  (progressoAno?['tentativas'] ?? 0) as int;

              return GestureDetector(
                onTap: () {
                  if (!temAcesso) {
                    _mostrarDialogBloqueado(context, ano, planoMinimo);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DisciplinasScreen(
                          instituicaoId: widget.instituicaoId,
                          instituicaoSigla: widget.instituicaoSigla,
                          cursoNome: widget.cursoNome,
                          ano: ano,
                          disciplinas: widget.disciplinas,
                        ),
                      ),
                    );
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: temAcesso
                        ? Colors.white
                        : cor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: cor.withValues(
                          alpha: temAcesso ? 1.0 : 0.35),
                      width: 2,
                    ),
                    boxShadow: temAcesso
                        ? [
                            BoxShadow(
                              color: cor.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: cor.withValues(
                                alpha: temAcesso ? 0.1 : 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            temAcesso ? Icons.lock_open : Icons.lock,
                            color: cor.withValues(
                                alpha: temAcesso ? 1.0 : 0.45),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$ano',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: cor.withValues(
                                alpha: temAcesso ? 1.0 : 0.45),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cor.withValues(
                                alpha: temAcesso ? 0.1 : 0.06),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _nomesPlano[planoMinimo] ?? planoMinimo,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: cor.withValues(
                                  alpha: temAcesso ? 1.0 : 0.45),
                            ),
                          ),
                        ),
                        if (temAcesso && tentativas > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Melhor: ${melhorNota.toStringAsFixed(1)}/20',
                            style: TextStyle(
                              fontSize: 10,
                              color: melhorNota >= 13
                                  ? Colors.green.shade600
                                  : Colors.red.shade400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _mostrarDialogBloqueado(
      BuildContext context, int ano, String planoMinimo) {
    final cor = _corDoAno(planoMinimo);
    final nomePlano = _nomesPlano[planoMinimo] ?? planoMinimo;
    final nivelUtilizador = _hierarquiaPlanos[_planoUtilizador] ?? 0;
    final nivelMinimo = _hierarquiaPlanos[planoMinimo] ?? 0;
    final bloqueadoPorPlano = nivelUtilizador < nivelMinimo;

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
                  color: cor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock, color: cor, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                bloqueadoPorPlano
                    ? 'Plano $nomePlano necessário'
                    : 'Nota insuficiente',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bloqueadoPorPlano
                    ? 'O exame de $ano requer o plano $nomePlano. Faz upgrade para desbloquear.'
                    : 'Precisas de obter nota ≥ 13 no exame anterior para desbloquear $ano.',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (bloqueadoPorPlano) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlanosScreen(
                            instituicaoId: widget.instituicaoId,
                            instituicaoSigla: widget.instituicaoSigla,
                            cursoNome: widget.cursoNome,
                            planoActual: _planoUtilizador,
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    bloqueadoPorPlano
                        ? 'Ver Planos'
                        : 'Continuar a treinar',
                    style: const TextStyle(
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

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final String texto;

  const _LegendaItem({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(texto,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}