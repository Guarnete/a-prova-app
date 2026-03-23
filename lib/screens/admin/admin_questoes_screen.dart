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

  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _questoes = [];

  String? _cursoSeleccionado;
  String? _anoSeleccionado;
  String? _disciplinaSeleccionada;

  bool _carregandoCursos = true;
  bool _carregandoQuestoes = false;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  Future<void> _carregarCursos() async {
    setState(() => _carregandoCursos = true);
    try {
      final cursos = await _adminService.carregarCursos(widget.instituicaoId);
      setState(() {
        _cursos = cursos;
        _carregandoCursos = false;
      });
    } catch (e) {
      setState(() => _carregandoCursos = false);
    }
  }

  Future<void> _carregarQuestoes() async {
    if (_cursoSeleccionado == null ||
        _anoSeleccionado == null ||
        _disciplinaSeleccionada == null) { return; }

    setState(() => _carregandoQuestoes = true);
    try {
      final questoes = await _adminService.carregarQuestoes(
        instituicaoId: widget.instituicaoId,
        cursoId: _cursoSeleccionado!,
        ano: _anoSeleccionado!,
        disciplina: _disciplinaSeleccionada!,
      );
      setState(() {
        _questoes = questoes;
        _carregandoQuestoes = false;
      });
    } catch (e) {
      setState(() => _carregandoQuestoes = false);
    }
  }

  // Disciplinas do curso seleccionado
  List<String> get _disciplinas {
    if (_cursoSeleccionado == null) return [];
    final curso = _cursos.firstWhere(
      (c) => c['id'] == _cursoSeleccionado,
      orElse: () => {},
    );
    final disciplinasStr = curso['disciplinas'] as String? ?? '';
    return disciplinasStr.split(',').map((d) => d.trim()).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFiltros(),
            Expanded(child: _buildConteudo()),
          ],
        ),
      ),
      floatingActionButton: (_cursoSeleccionado != null &&
              _anoSeleccionado != null &&
              _disciplinaSeleccionada != null)
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QUESTÕES DE EXAME',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Gerir questões',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Contador de questões
          if (_questoes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_questoes.length} questões',
                style: const TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: const Color(0xFF1A1A1A),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Curso
          _buildDropdown(
            hint: 'Seleccionar curso',
            value: _cursoSeleccionado,
            items: _carregandoCursos
                ? []
                : _cursos.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['nome'] as String? ?? c['id'] as String),
                    )).toList(),
            onChanged: (val) {
              setState(() {
                _cursoSeleccionado = val;
                _anoSeleccionado = null;
                _disciplinaSeleccionada = null;
                _questoes = [];
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Ano
              Expanded(
                child: _buildDropdown(
                  hint: 'Ano',
                  value: _anoSeleccionado,
                  items: _cursoSeleccionado == null
                      ? []
                      : List.generate(
                          DateTime.now().year - 2018,
                          (i) => DropdownMenuItem(
                            value: '${2019 + i}',
                            child: Text('${2019 + i}'),
                          ),
                        ),
                  onChanged: (val) {
                    setState(() {
                      _anoSeleccionado = val;
                      _disciplinaSeleccionada = null;
                      _questoes = [];
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Disciplina
              Expanded(
                child: _buildDropdown(
                  hint: 'Disciplina',
                  value: _disciplinaSeleccionada,
                  items: _disciplinas
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _disciplinaSeleccionada = val;
                      _questoes = [];
                    });
                    _carregarQuestoes();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
          dropdownColor: const Color(0xFF2A2A2A),
          style: const TextStyle(color: Colors.white, fontSize: 13),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.5)),
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildConteudo() {
    if (_cursoSeleccionado == null || _anoSeleccionado == null || _disciplinaSeleccionada == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list, color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text(
              'Selecciona curso, ano e disciplina\npara ver as questões',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_carregandoQuestoes) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    if (_questoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text(
              'Ainda não há questões.\nClica em "Nova Questão" para adicionar.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _questoes.length,
      itemBuilder: (context, index) {
        final questao = _questoes[index];
        return _buildCardQuestao(questao, index);
      },
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
          // Cabeçalho
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    questao['texto'] as String? ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
                // Botões editar/apagar
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _abrirFormularioEditarQuestao(questao),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.edit, color: Color(0xFF007AFF), size: 16),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _confirmarApagar(questao['id'] as String),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.delete, color: Colors.red, size: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Opções
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: opcoes.asMap().entries.map((entry) {
                final idx = entry.key;
                final opcao = entry.value;
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
                          : Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        String.fromCharCode(65 + idx),
                        style: TextStyle(
                          color: isCorrecta ? Colors.green : Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          opcao,
                          style: TextStyle(
                            color: isCorrecta ? Colors.green : Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ),
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

  void _abrirFormularioNovaQuestao() {
    _abrirFormulario(null);
  }

  void _abrirFormularioEditarQuestao(Map<String, dynamic> questao) {
    _abrirFormulario(questao);
  }

  void _abrirFormulario(Map<String, dynamic>? questao) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioQuestao(
        questao: questao,
        onGuardar: (dados) async {
          if (questao == null) {
            // Nova questão
            await _adminService.adicionarQuestao(
              instituicaoId: widget.instituicaoId,
              cursoId: _cursoSeleccionado!,
              ano: _anoSeleccionado!,
              disciplina: _disciplinaSeleccionada!,
              texto: dados['texto'],
              opcoes: List<String>.from(dados['opcoes']),
              respostaCorrecta: dados['correcta'],
              justificacao: dados['justificacao'],
              resolucao: dados['resolucao'],
              ordem: _questoes.length + 1,
            );
          } else {
            // Editar questão
            await _adminService.editarQuestao(
              instituicaoId: widget.instituicaoId,
              cursoId: _cursoSeleccionado!,
              ano: _anoSeleccionado!,
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
        title: const Text('Apagar questão?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta acção não pode ser desfeita.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _adminService.apagarQuestao(
                instituicaoId: widget.instituicaoId,
                cursoId: _cursoSeleccionado!,
                ano: _anoSeleccionado!,
                questaoId: questaoId,
              );
              await _carregarQuestoes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
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

  const _FormularioQuestao({
    required this.questao,
    required this.onGuardar,
  });

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
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Título
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  widget.questao == null ? 'Nova Questão' : 'Editar Questão',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close,
                      color: Colors.white.withValues(alpha: 0.5)),
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto da questão
                  _buildLabel('Enunciado da questão *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _textoController,
                    hint: 'Escreve o enunciado da questão...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),

                  // Opções
                  _buildLabel('Opções de resposta *'),
                  const SizedBox(height: 4),
                  Text(
                    'Selecciona a opção correcta',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  ...List.generate(4, (i) {
                    final letra = String.fromCharCode(65 + i);
                    final isCorrecta = i == _respostaCorrecta;
                    return GestureDetector(
                      onTap: () => setState(() => _respostaCorrecta = i),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isCorrecta
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCorrecta
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isCorrecta
                                    ? Colors.green
                                    : Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  letra,
                                  style: TextStyle(
                                    color: isCorrecta
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _opcoesControllers[i],
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Opção $letra...',
                                  hintStyle: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.3),
                                      fontSize: 13),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 20),

                  // Justificação
                  _buildLabel('Explicação / Justificação *'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _justificacaoController,
                    hint: 'Explica porque a resposta está correcta...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Resolução passo-a-passo
                  _buildLabel('Resolução passo-a-passo (opcional)'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _resolucaoController,
                    hint: 'Descreve a resolução detalhada...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 32),

                  // Botão guardar
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              widget.questao == null
                                  ? 'Adicionar Questão'
                                  : 'Guardar Alterações',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

  Widget _buildLabel(String texto) {
    return Text(
      texto,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
      ),
    );
  }
}