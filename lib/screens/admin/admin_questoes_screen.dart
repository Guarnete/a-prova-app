import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminQuestoesScreen extends StatefulWidget {
  final String instituicaoId;
  final bool eSuperAdmin;

  const AdminQuestoesScreen({
    super.key,
    required this.instituicaoId,
    required this.eSuperAdmin,
  });

  @override
  State<AdminQuestoesScreen> createState() => _AdminQuestoesScreenState();
}

class _AdminQuestoesScreenState extends State<AdminQuestoesScreen> {
  final AdminService _adminService = AdminService();

  Map<String, dynamic>? _instituicao;
  Map<String, dynamic>? _curso;
  Map<String, dynamic>? _ano;
  String? _disciplina;
  String? _exameId;

  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _anos = [];
  List<String> _disciplinas = [];
  List<Map<String, dynamic>> _questoes = [];

  bool _carregando = true;
  int _passo = 1; // 1=Inst, 2=Curso, 3=Ano, 4=Disciplina, 5=Questões

  @override
  void initState() {
    super.initState();
    _carregarInstituicoes();
  }

  Future<void> _carregarInstituicoes() async {
    setState(() => _carregando = true);
    try {
      List<Map<String, dynamic>> lista;
      if (widget.eSuperAdmin) {
        lista = await _adminService.carregarInstituicoes();
      } else {
        final inst = await _adminService.carregarInstituicaoById(widget.instituicaoId);
        lista = inst != null ? [inst] : [];
      }
      setState(() {
        _instituicoes = lista;
        _carregando = false;
        if (lista.length == 1) {
          _instituicao = lista.first;
          _passo = 2;
          _carregarCursos();
        }
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _carregarCursos() async {
    if (_instituicao == null) return;
    setState(() => _carregando = true);
    final cursos = await _adminService.carregarCursos(_instituicao!['id']);
    setState(() { _cursos = cursos; _carregando = false; });
  }

  Future<void> _carregarAnos() async {
    if (_instituicao == null || _curso == null) return;
    setState(() => _carregando = true);
    final anos = await _adminService.carregarAnosAdmin(
      instituicaoId: _instituicao!['id'],
      cursoId: _curso!['id'],
    );
    setState(() { _anos = anos; _carregando = false; });
  }

  void _carregarDisciplinas() {
    if (_curso == null) return;
    final str = _curso!['disciplinas'] as String? ?? '';
    setState(() {
      _disciplinas = str.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList();
      _disciplina = null;
    });
  }

  Future<void> _carregarQuestoes() async {
    if (_instituicao == null || _curso == null || _ano == null || _disciplina == null) return;
    setState(() => _carregando = true);
    try {
      // Encontra o exame na colecção avaliacoes
      final exames = await _adminService.carregarExames(
        instituicaoId: _instituicao!['id'],
        cursoId: _curso!['id'],
        ano: '${_ano!['ano']}',
      );
      final exame = exames.where((e) => e['disciplina'] == _disciplina).firstOrNull;
      if (exame == null) {
        setState(() { _exameId = null; _questoes = []; _carregando = false; });
        return;
      }
      _exameId = exame['id'] as String;
      final questoes = await _adminService.carregarQuestoesExame(_exameId!);
      setState(() { _questoes = questoes; _carregando = false; });
    } catch (e) {
      setState(() { _questoes = []; _carregando = false; });
    }
  }

  void _voltarPasso() {
    setState(() {
      switch (_passo) {
        case 2: if (widget.eSuperAdmin) { _passo = 1; _instituicao = null; _cursos = []; } break;
        case 3: _passo = 2; _curso = null; _anos = []; _disciplinas = []; break;
        case 4: _passo = 3; _disciplina = null; break;
        case 5: _passo = 4; _questoes = []; _exameId = null; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMigalhas(),
            Expanded(child: _buildConteudo()),
          ],
        ),
      ),
      floatingActionButton: _passo == 5
          ? FloatingActionButton.extended(
              onPressed: _exameId != null ? _abrirFormularioNovaQuestao : null,
              backgroundColor: _exameId != null
                  ? const Color(0xFFD4AF37)
                  : Colors.grey.shade700,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nova Questão',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    final titulos = ['Instituição', 'Curso', 'Ano', 'Disciplina', 'Questões'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          GestureDetector(
            onTap: _passo == 1 ? () => Navigator.pop(context) : _voltarPasso,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUESTÕES DE EXAME',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                Text('Selecciona ${titulos[_passo - 1]}',
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (_passo == 5 && _questoes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_questoes.length}',
                  style: const TextStyle(color: Color(0xFF007AFF),
                      fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  Widget _buildMigalhas() {
    final passos = ['Inst.', 'Curso', 'Ano', 'Disc.', 'Quest.'];
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: List.generate(passos.length, (i) {
          final activo = i + 1 == _passo;
          final completo = i + 1 < _passo;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: completo || activo
                              ? const Color(0xFFD4AF37)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(passos[i],
                          style: TextStyle(
                            color: activo ? const Color(0xFFD4AF37)
                                : completo ? Colors.white.withValues(alpha: 0.6)
                                : Colors.white.withValues(alpha: 0.2),
                            fontSize: 10,
                            fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                          )),
                    ],
                  ),
                ),
                if (i < passos.length - 1) const SizedBox(width: 4),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }
    switch (_passo) {
      case 1: return _buildListaSeleccao(
        items: _instituicoes, campoNome: 'nome', campoSub: 'cidade',
        onTap: (item) { setState(() { _instituicao = item; _passo = 2; }); _carregarCursos(); },
      );
      case 2: return _buildListaSeleccao(
        items: _cursos, campoNome: 'nome', campoSub: 'disciplinas',
        onTap: (item) { setState(() { _curso = item; _passo = 3; }); _carregarAnos(); _carregarDisciplinas(); },
      );
      case 3: return _buildListaAnos();
      case 4: return _buildListaDisciplinas();
      case 5: return _buildListaQuestoes();
      default: return const SizedBox();
    }
  }

  Widget _buildListaSeleccao({
    required List<Map<String, dynamic>> items,
    required String campoNome,
    required String? campoSub,
    required void Function(Map<String, dynamic>) onTap,
  }) {
    if (items.isEmpty) {
      return Center(child: Text('Nenhum item disponível.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () => onTap(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right, color: Color(0xFFD4AF37), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item[campoNome] as String? ?? item['id'] as String? ?? '',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      if (campoSub != null && item[campoSub] != null)
                        Text(item[campoSub].toString(),
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaAnos() {
    if (_anos.isEmpty) {
      return Center(child: Text('Nenhum ano disponível.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _anos.length,
      itemBuilder: (context, index) {
        final ano = _anos[index];
        final plano = ano['planoMinimo'] as String? ?? 'gratuito';
        return GestureDetector(
          onTap: () { setState(() { _ano = ano; _passo = 4; }); },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: Color(0xFF007AFF), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${ano['ano']}',
                          style: const TextStyle(color: Colors.white,
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(plano,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaDisciplinas() {
    if (_disciplinas.isEmpty) {
      return Center(child: Text('Nenhuma disciplina configurada.',
          style: TextStyle(color: Colors.white.withValues(alpha: 0.4))));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _disciplinas.length,
      itemBuilder: (context, index) {
        final disciplina = _disciplinas[index];
        return GestureDetector(
          onTap: () {
            setState(() { _disciplina = disciplina; _passo = 5; });
            _carregarQuestoes();
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book, color: Color(0xFFD4AF37), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(disciplina,
                      style: const TextStyle(color: Colors.white,
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListaQuestoes() {
    if (_exameId == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text('Nenhum exame criado para\n$_disciplina — ${_ano?['ano']}.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('Usa "Criar Exame" para criar o exame primeiro.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (_questoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text('Nenhuma questão ainda.\nClica em "Nova Questão" para adicionar.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _questoes.length,
      itemBuilder: (context, index) => _buildCardQuestao(_questoes[index], index),
    );
  }

  Widget _buildCardQuestao(Map<String, dynamic> questao, int index) {
    final opcoes = List<String>.from(questao['opcoes'] ?? []);
    final correcta = questao['correcta'] as int? ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('${index + 1}',
                      style: const TextStyle(color: Color(0xFFD4AF37),
                          fontWeight: FontWeight.bold, fontSize: 12))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(questao['texto'] as String? ?? '',
                      style: const TextStyle(color: Colors.white, fontSize: 13,
                          fontWeight: FontWeight.w500, height: 1.4)),
                ),
                Row(
                  children: [
                    _iconBtn(Icons.edit, const Color(0xFF007AFF),
                        () => _abrirFormularioEditarQuestao(questao)),
                    const SizedBox(width: 6),
                    _iconBtn(Icons.delete, Colors.red,
                        () => _confirmarApagar(questao['id'] as String)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: opcoes.asMap().entries.map((entry) {
                final isCorrecta = entry.key == correcta;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCorrecta
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isCorrecta
                            ? Colors.green.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.06)),
                  ),
                  child: Row(
                    children: [
                      Text(String.fromCharCode(65 + entry.key),
                          style: TextStyle(
                              color: isCorrecta ? Colors.green : Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value,
                          style: TextStyle(
                              color: isCorrecta ? Colors.green : Colors.white.withValues(alpha: 0.7),
                              fontSize: 12))),
                      if (isCorrecta)
                        const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icone, Color cor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icone, color: cor, size: 16),
      ),
    );
  }

  void _abrirFormularioNovaQuestao() => _abrirFormulario(null);
  void _abrirFormularioEditarQuestao(Map<String, dynamic> q) => _abrirFormulario(q);

  void _abrirFormulario(Map<String, dynamic>? questao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioQuestao(
        questao: questao,
        onGuardar: (dados) async {
          if (questao == null) {
            await _adminService.adicionarQuestaoExame(
              exameId: _exameId!,
              texto: dados['texto'],
              opcoes: List<String>.from(dados['opcoes']),
              respostaCorrecta: dados['correcta'],
              justificacao: dados['justificacao'],
              resolucao: dados['resolucao'],
              ordem: _questoes.length + 1,
            );
          } else {
            await _adminService.editarQuestaoExame(
              exameId: _exameId!,
              questaoId: questao['id'] as String,
              dados: dados,
            );
          }
          await _carregarQuestoes();
        },
      ),
    );
  }

  void _confirmarApagar(String questaoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Apagar questão?', style: TextStyle(color: Colors.white)),
        content: const Text('Esta acção não pode ser desfeita.',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.apagarQuestaoExame(
                  exameId: _exameId!, questaoId: questaoId);
              await _carregarQuestoes();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text('Apagar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ── Formulário de questão ─────────────────────────────────────────────────────
class _FormularioQuestao extends StatefulWidget {
  final Map<String, dynamic>? questao;
  final Future<void> Function(Map<String, dynamic>) onGuardar;

  const _FormularioQuestao({required this.questao, required this.onGuardar});

  @override
  State<_FormularioQuestao> createState() => _FormularioQuestaoState();
}

class _FormularioQuestaoState extends State<_FormularioQuestao> {
  final _textoController = TextEditingController();
  final _justificacaoController = TextEditingController();
  final _resolucaoController = TextEditingController();
  final List<TextEditingController> _opcoesControllers =
      List.generate(4, (_) => TextEditingController());
  int _respostaCorrecta = 0;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    if (widget.questao != null) {
      final q = widget.questao!;
      _textoController.text = q['texto'] as String? ?? '';
      _justificacaoController.text = q['justificacao'] as String? ?? '';
      _resolucaoController.text = q['resolucao'] as String? ?? '';
      _respostaCorrecta = q['correcta'] as int? ?? 0;
      final opcoes = List<String>.from(q['opcoes'] ?? []);
      for (int i = 0; i < opcoes.length && i < 4; i++) {
        _opcoesControllers[i].text = opcoes[i];
      }
    }
  }

  @override
  void dispose() {
    _textoController.dispose();
    _justificacaoController.dispose();
    _resolucaoController.dispose();
    for (final c in _opcoesControllers) { c.dispose(); }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_textoController.text.isEmpty) return;
    for (final c in _opcoesControllers) { if (c.text.isEmpty) return; }
    setState(() => _guardando = true);
    await widget.onGuardar({
      'texto': _textoController.text.trim(),
      'opcoes': _opcoesControllers.map((c) => c.text.trim()).toList(),
      'correcta': _respostaCorrecta,
      'justificacao': _justificacaoController.text.trim(),
      'resolucao': _resolucaoController.text.trim(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(child: Container(
            margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(widget.questao == null ? 'Nova Questão' : 'Editar Questão',
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Enunciado *'),
                  const SizedBox(height: 8),
                  _campo(_textoController, 'Escreve o enunciado...', maxLines: 3),
                  const SizedBox(height: 20),
                  _label('Opções de resposta *'),
                  const SizedBox(height: 4),
                  Text('Toca na letra para marcar como correcta',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12)),
                  const SizedBox(height: 10),
                  ...List.generate(4, (i) {
                    final letra = String.fromCharCode(65 + i);
                    final isCorrecta = i == _respostaCorrecta;
                    return GestureDetector(
                      onTap: () => setState(() => _respostaCorrecta = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCorrecta
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isCorrecta
                                  ? Colors.green.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: isCorrecta ? Colors.green : Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Center(child: Text(letra,
                                  style: TextStyle(
                                      color: isCorrecta ? Colors.white : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.bold, fontSize: 13))),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: TextField(
                              controller: _opcoesControllers[i],
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Opção $letra...',
                                hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
                                border: InputBorder.none,
                              ),
                            )),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  _label('Explicação / Justificação *'),
                  const SizedBox(height: 8),
                  _campo(_justificacaoController, 'Explica a resposta correcta...', maxLines: 3),
                  const SizedBox(height: 16),
                  _label('Resolução passo-a-passo (opcional)'),
                  const SizedBox(height: 8),
                  _campo(_resolucaoController, 'Resolução detalhada...', maxLines: 4),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _guardando
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              widget.questao == null ? 'Adicionar Questão' : 'Guardar Alterações',
                              style: const TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String texto) => Text(texto,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13, fontWeight: FontWeight.w600));

  Widget _campo(TextEditingController controller, String hint, {int maxLines = 1}) =>
      TextField(
        controller: controller, maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD4AF37))),
        ),
      );
}