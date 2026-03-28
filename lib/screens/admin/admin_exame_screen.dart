import 'package:flutter/material.dart';
import '../../utils/normalizador.dart';
import '../../services/admin_service.dart';

class AdminExameScreen extends StatefulWidget {
  final String instituicaoId;
  final bool eSuperAdmin;

  const AdminExameScreen({
    super.key,
    required this.instituicaoId,
    required this.eSuperAdmin,
  });

  @override
  State<AdminExameScreen> createState() => _AdminExameScreenState();
}

class _AdminExameScreenState extends State<AdminExameScreen> {
  final AdminService _adminService = AdminService();

  // Selecções
  Map<String, dynamic>? _instituicao;
  Map<String, dynamic>? _curso;
  Map<String, dynamic>? _ano;
  String? _disciplina;
  String _tipo = 'real';
  int _duracaoMinutos = 90;

  // Dados
  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _anos = [];
  List<String> _disciplinas = [];

  // Exame criado
  String? _exameId;
  List<Map<String, dynamic>> _questoes = [];

  bool _carregando = true;
  bool _criandoExame = false;

  // Passo: 1=config, 2=questões
  int _passo = 1;

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
          _carregarCursos();
        }
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _carregarCursos() async {
    if (_instituicao == null) return;
    final cursos = await _adminService.carregarCursos(_instituicao!['id']);
    setState(() { _cursos = cursos; _curso = null; _anos = []; _disciplinas = []; });
  }

  Future<void> _carregarAnos() async {
    if (_instituicao == null || _curso == null) return;
    final anos = await _adminService.carregarAnosAdmin(
      instituicaoId: _instituicao!['id'],
      cursoId: Normalizador.cursoId(_curso!['id'] as String),
    );
    setState(() { _anos = anos; _ano = null; _disciplinas = []; });
  }
  

  void _carregarDisciplinas() {
    if (_curso == null) return;
    final disciplinasStr = _curso!['disciplinas'] as String? ?? '';
    setState(() {
      _disciplinas = disciplinasStr.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList();
      _disciplina = null;
    });
  }

  bool get _configuracaoCompleta =>
      _instituicao != null && _curso != null && _ano != null && _disciplina != null;

  Future<void> _criarExame() async {
    if (!_configuracaoCompleta) return;
    setState(() => _criandoExame = true);
    try {
      // Verifica se já existe exame para esta combinação
      final examesExistentes = await _adminService.carregarExames(
        instituicaoId: _instituicao!['id'],
        cursoId: Normalizador.cursoId(_curso!['id'] as String),
        ano: '${_ano!['ano']}',
      );

      final jaExiste = examesExistentes.any((e) =>
          e['disciplina'] == _disciplina && e['tipo'] == _tipo);

      if (jaExiste && mounted) {
        setState(() => _criandoExame = false);
        _mostrarSnack('Já existe um exame $_tipo para $_disciplina — ${_ano!['ano']}.', erro: true);
        return;
      }

      final exameId = await _adminService.criarExame(
        instituicaoId: _instituicao!['id'],
        cursoId: Normalizador.cursoId(_curso!['id'] as String),
        ano: '${_ano!['ano']}',
        disciplina: _disciplina!,
        tipo: _tipo,
        duracaoMinutos: _duracaoMinutos,
      );

      setState(() {
        _exameId = exameId;
        _questoes = [];
        _passo = 2;
        _criandoExame = false;
      });
    } catch (e) {
      setState(() => _criandoExame = false);
      _mostrarSnack('Erro ao criar exame.', erro: true);
    }
  }

  Future<void> _carregarQuestoes() async {
    if (_exameId == null) return;
    final questoes = await _adminService.carregarQuestoesExame(_exameId!);
    setState(() => _questoes = questoes);
  }

  void _mostrarSnack(String msg, {bool erro = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: erro ? Colors.red.shade700 : Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _passo == 1 ? _buildConfiguracaoExame() : _buildGestaoQuestoes(),
            ),
          ],
        ),
      ),
      floatingActionButton: _passo == 2
          ? FloatingActionButton.extended(
              onPressed: _abrirFormularioNovaQuestao,
              backgroundColor: const Color(0xFFD4AF37),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nova Questão',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (_passo == 2) {
                setState(() => _passo = 1);
              } else {
                Navigator.pop(context);
              }
            },
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
                const Text('CRIAÇÃO DE EXAME',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                Text(
                  _passo == 1 ? 'Configurar exame' : 'Adicionar questões',
                  style: const TextStyle(color: Colors.white, fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (_passo == 2)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${_questoes.length} questões',
                  style: const TextStyle(color: Color(0xFF007AFF),
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  // ── PASSO 1: CONFIGURAÇÃO ─────────────────────────────────────────────────
  Widget _buildConfiguracaoExame() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secao('Selecção'),
          const SizedBox(height: 12),

          // Instituição
          _dropdown(
            label: 'Instituição',
            value: _instituicao?['id'],
            items: _instituicoes.map((i) => DropdownMenuItem(
              value: i['id'] as String,
              child: Text(i['nome'] as String? ?? i['id'] as String),
            )).toList(),
            onChanged: (val) {
              setState(() => _instituicao = _instituicoes.firstWhere((i) => i['id'] == val));
              _carregarCursos();
            },
          ),
          const SizedBox(height: 12),

          // Curso
          _dropdown(
            label: 'Curso',
            value: _curso?['id'],
            items: _cursos.map((c) => DropdownMenuItem(
              value: c['id'] as String,
              child: Text(c['nome'] as String? ?? c['id'] as String),
            )).toList(),
            onChanged: _instituicao == null ? null : (val) {
              setState(() => _curso = _cursos.firstWhere((c) => c['id'] == val));
              _carregarAnos();
              _carregarDisciplinas();
            },
          ),
          const SizedBox(height: 12),

          // Ano
          _dropdown(
            label: 'Ano de Exame',
            value: _ano != null ? '${_ano!['ano']}' : null,
            items: _anos.map((a) => DropdownMenuItem(
              value: '${a['ano']}',
              child: Text('${a['ano']}'),
            )).toList(),
            onChanged: _curso == null ? null : (val) {
              setState(() => _ano = _anos.firstWhere((a) => '${a['ano']}' == val));
            },
          ),
          const SizedBox(height: 12),

          // Disciplina
          _dropdown(
            label: 'Disciplina',
            value: _disciplina,
            items: _disciplinas.map((d) => DropdownMenuItem(
              value: d, child: Text(d),
            )).toList(),
            onChanged: _curso == null ? null : (val) {
              setState(() => _disciplina = val);
            },
          ),

          const SizedBox(height: 24),
          _secao('Configuração do exame'),
          const SizedBox(height: 12),

          // Tipo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tipo de exame',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _tipoBtn('real', Icons.school, 'Exame Real'),
                    const SizedBox(width: 10),
                    _tipoBtn('preditiva', Icons.auto_awesome, 'Avaliação Preditiva'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Duração
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Duração do exame',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$_duracaoMinutos min',
                          style: const TextStyle(color: Color(0xFFD4AF37),
                              fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                Slider(
                  value: _duracaoMinutos.toDouble(),
                  min: 30,
                  max: 180,
                  divisions: 15,
                  activeColor: const Color(0xFFD4AF37),
                  inactiveColor: Colors.white.withValues(alpha: 0.1),
                  onChanged: (val) => setState(() => _duracaoMinutos = val.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('30 min', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                    Text('180 min', style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Botão criar exame
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: (!_configuracaoCompleta || _criandoExame) ? null : _criarExame,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _criandoExame
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _configuracaoCompleta
                          ? 'Criar Exame e Adicionar Questões →'
                          : 'Preenche todos os campos',
                      style: TextStyle(
                        color: _configuracaoCompleta ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _tipoBtn(String valor, IconData icone, String label) {
    final activo = _tipo == valor;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipo = valor),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: activo
                ? (valor == 'real' ? const Color(0xFF007AFF) : Colors.purple).withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: activo
                  ? (valor == 'real' ? const Color(0xFF007AFF) : Colors.purple)
                  : Colors.white.withValues(alpha: 0.08),
              width: activo ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icone,
                  color: activo
                      ? (valor == 'real' ? const Color(0xFF007AFF) : Colors.purple)
                      : Colors.white.withValues(alpha: 0.4),
                  size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    color: activo
                        ? (valor == 'real' ? const Color(0xFF007AFF) : Colors.purple)
                        : Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                    fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  // ── PASSO 2: QUESTÕES ─────────────────────────────────────────────────────
  Widget _buildGestaoQuestoes() {
    return Column(
      children: [
        // Info do exame
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                _tipo == 'real' ? Icons.school : Icons.auto_awesome,
                color: _tipo == 'real' ? const Color(0xFF007AFF) : Colors.purple,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_instituicao?['sigla']} · ${_curso?['nome']} · ${_ano?['ano']} · $_disciplina',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${_tipo == 'real' ? 'Exame Real' : 'Avaliação Preditiva'} · $_duracaoMinutos min',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _questoes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.quiz_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
                      const SizedBox(height: 12),
                      Text('Exame criado!\nClica em "Nova Questão" para adicionar questões.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
                          textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _questoes.length,
                  itemBuilder: (context, index) => _buildCardQuestao(_questoes[index], index),
                ),
        ),
      ],
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
                final idx = entry.key;
                final isCorrecta = idx == correcta;
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
                      Text(String.fromCharCode(65 + idx),
                          style: TextStyle(
                              color: isCorrecta ? Colors.green : Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(entry.value,
                          style: TextStyle(
                              color: isCorrecta ? Colors.green : Colors.white.withValues(alpha: 0.7),
                              fontSize: 12))),
                      if (isCorrecta) const Icon(Icons.check_circle, color: Colors.green, size: 14),
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
        content: const Text('Esta acção não pode ser desfeita.', style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.apagarQuestaoExame(exameId: _exameId!, questaoId: questaoId);
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

  Widget _secao(String titulo) => Text(titulo,
      style: TextStyle(color: Colors.white.withValues(alpha: 0.5),
          fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2));

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: onChanged == null ? 0.03 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label, style: TextStyle(
              color: Colors.white.withValues(alpha: onChanged == null ? 0.2 : 0.4), fontSize: 13)),
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down,
              color: Colors.white.withValues(alpha: onChanged == null ? 0.2 : 0.5)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
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
    for (final c in _opcoesControllers) {
      if (c.text.isEmpty) return;
    }
    setState(() => _guardando = true);
    await widget.onGuardar({
      'texto': _textoController.text.trim(),
      'opcoes': _opcoesControllers.map((c) => c.text.trim()).toList(),
      'correcta': _respostaCorrecta,
      'justificacao': _justificacaoController.text.trim(),
      'resolucao': _resolucaoController.text.trim(),
    });
    if (mounted) { Navigator.pop(context); }
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
                GestureDetector(onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.5))),
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
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
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
                          : Text(widget.questao == null ? 'Adicionar Questão' : 'Guardar Alterações',
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