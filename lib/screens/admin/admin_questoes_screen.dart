import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Selecções sequenciais
  Map<String, dynamic>? _instituicao;
  Map<String, dynamic>? _curso;
  Map<String, dynamic>? _ano;
  String? _disciplina;

  // Dados carregados
  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _anos = [];
  List<String> _disciplinas = [];
  List<Map<String, dynamic>> _questoes = [];

  bool _carregando = true;

  // Passo actual: 1=Inst, 2=Curso, 3=Ano, 4=Disciplina, 5=Questões
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
        // Admin normal só vê a sua instituição
        final snapshot = await _firestore
            .collection('instituicoes')
            .doc(widget.instituicaoId)
            .get();
        lista = [{'id': snapshot.id, ...snapshot.data()!}];
      }
      setState(() {
        _instituicoes = lista;
        _carregando = false;
        // Se só tem uma instituição, selecciona automaticamente
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
    try {
      final cursos = await _adminService.carregarCursos(_instituicao!['id']);
      setState(() {
        _cursos = cursos;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _carregarAnos() async {
    if (_instituicao == null || _curso == null) return;
    setState(() => _carregando = true);
    try {
      final anos = await _adminService.carregarAnosAdmin(
        instituicaoId: _instituicao!['id'],
        cursoId: _curso!['id'],
      );
      setState(() {
        _anos = anos;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  Future<void> _carregarDisciplinas() async {
    if (_curso == null) return;
    final disciplinasStr = _curso!['disciplinas'] as String? ?? '';
    setState(() {
      _disciplinas =
          disciplinasStr.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList();
    });
  }

  Future<void> _carregarQuestoes() async {
    if (_instituicao == null || _curso == null || _ano == null || _disciplina == null) return;
    setState(() => _carregando = true);
    try {
      final snapshot = await _firestore
          .collection('instituicoes')
          .doc(_instituicao!['id'])
          .collection('cursos')
          .doc(_curso!['id'])
          .collection('anos')
          .doc('${_ano!['ano']}')
          .collection('disciplinas')
          .doc(_disciplina)
          .collection('questoes')
          .orderBy('ordem')
          .get();

      setState(() {
        _questoes = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  void _voltarPasso() {
    setState(() {
      if (_passo == 5) {
        _passo = 4;
        _disciplina = null;
        _questoes = [];
      } else if (_passo == 4) {
        _passo = 3;
        _ano = null;
        _disciplinas = [];
      } else if (_passo == 3) {
        _passo = 2;
        _curso = null;
        _anos = [];
      } else if (_passo == 2) {
        if (widget.eSuperAdmin) {
          _passo = 1;
          _instituicao = null;
          _cursos = [];
        }
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
            Expanded(child: _buildConteudoPasso()),
          ],
        ),
      ),
      floatingActionButton: _passo == 5
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
                const Text(
                  'QUESTÕES DE EXAME',
                  style: TextStyle(
                    color: Color(0xFFD4AF37),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'Selecciona ${titulos[_passo - 1]}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_questoes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_questoes.length}',
                style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
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
                      Text(
                        passos[i],
                        style: TextStyle(
                          color: activo
                              ? const Color(0xFFD4AF37)
                              : completo
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : Colors.white.withValues(alpha: 0.2),
                          fontSize: 10,
                          fontWeight: activo ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
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

  Widget _buildConteudoPasso() {
    if (_carregando) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37)));
    }

    switch (_passo) {
      case 1: return _buildListaSeleccao(
        items: _instituicoes,
        campoNome: 'nome',
        campoSub: 'cidade',
        onTap: (item) {
          setState(() { _instituicao = item; _passo = 2; });
          _carregarCursos();
        },
      );
      case 2: return _buildListaSeleccao(
        items: _cursos,
        campoNome: 'nome',
        campoSub: 'disciplinas',
        onTap: (item) {
          setState(() { _curso = item; _passo = 3; });
          _carregarAnos();
        },
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
      return Center(
        child: Text('Nenhum item disponível.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
      );
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right,
                      color: Color(0xFFD4AF37), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item[campoNome] as String? ?? item['id'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                      ),
                      if (campoSub != null && item[campoSub] != null)
                        Text(
                          item[campoSub].toString(),
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
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
    return Column(
      children: [
        Expanded(
          child: _anos.isEmpty
              ? Center(
                  child: Text('Nenhum ano disponível.',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _anos.length,
                  itemBuilder: (context, index) {
                    final ano = _anos[index];
                    final tipo = ano['tipo'] as String? ?? 'real';
                    final plano = ano['planoMinimo'] as String? ?? 'gratuito';
                    return GestureDetector(
                      onTap: () {
                        setState(() { _ano = ano; _passo = 4; });
                        _carregarDisciplinas();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (tipo == 'preditiva'
                                        ? Colors.purple
                                        : const Color(0xFF007AFF))
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                tipo == 'preditiva'
                                    ? Icons.auto_awesome
                                    : Icons.school,
                                color: tipo == 'preditiva'
                                    ? Colors.purple
                                    : const Color(0xFF007AFF),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${ano['ano']}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (tipo == 'preditiva'
                                                  ? Colors.purple
                                                  : const Color(0xFF007AFF))
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          tipo == 'preditiva'
                                              ? 'Preditiva'
                                              : 'Real',
                                          style: TextStyle(
                                            color: tipo == 'preditiva'
                                                ? Colors.purple
                                                : const Color(0xFF007AFF),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        plano,
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.4),
                                            fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios,
                                color: Colors.white.withValues(alpha: 0.3),
                                size: 16),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarFormularioAno(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Adicionar Ano',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListaDisciplinas() {
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.book,
                      color: Color(0xFFD4AF37), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    disciplina,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
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

  Widget _buildListaQuestoes() {
    if (_questoes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined,
                color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text(
              'Ainda não há questões.\nClica em "Nova Questão" para adicionar.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _questoes.length,
      itemBuilder: (context, index) {
        final questao = _questoes[index];
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
                        child: Text('${index + 1}',
                            style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
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
                            height: 1.4),
                      ),
                    ),
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
                            child: const Icon(Icons.edit,
                                color: Color(0xFF007AFF), size: 16),
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
                            child: const Icon(Icons.delete,
                                color: Colors.red, size: 16),
                          ),
                        ),
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
                    final opcao = entry.value;
                    final isCorrecta = idx == correcta;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
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
                              color: isCorrecta
                                  ? Colors.green
                                  : Colors.white.withValues(alpha: 0.5),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(opcao,
                                style: TextStyle(
                                  color: isCorrecta
                                      ? Colors.green
                                      : Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                )),
                          ),
                          if (isCorrecta)
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 14),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarFormularioAno(BuildContext context) {
    final anoController = TextEditingController();
    final duracaoController = TextEditingController(text: '90');
    String planoMinimo = 'gratuito';
    String tipo = 'real';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Adicionar Ano', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogField(anoController, 'Ano (ex: 2026)', TextInputType.number),
                const SizedBox(height: 12),
                _buildDialogField(duracaoController, 'Duração (minutos)', TextInputType.number),
                const SizedBox(height: 12),
                // Tipo
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Tipo de exame',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'real', child: Text('Exame Real')),
                    DropdownMenuItem(value: 'preditiva', child: Text('Avaliação Preditiva')),
                  ],
                  onChanged: (val) => setStateDialog(() => tipo = val ?? 'real'),
                ),
                const SizedBox(height: 12),
                // Plano mínimo
                DropdownButtonFormField<String>(
                  initialValue: planoMinimo,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Plano mínimo',
                    labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.07),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: ['gratuito', 'bronze', 'prata', 'ouro']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => planoMinimo = val ?? 'gratuito'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final ano = int.tryParse(anoController.text);
                final duracao = int.tryParse(duracaoController.text) ?? 90;
                if (ano == null) return;
                Navigator.pop(context);
                await _adminService.adicionarAno(
                  instituicaoId: _instituicao!['id'],
                  cursoId: _curso!['id'],
                  ano: ano,
                  planoMinimo: planoMinimo,
                  duracaoMinutos: duracao,
                  tipo: tipo,
                );
                await _carregarAnos();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37),
                elevation: 0,
              ),
              child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(TextEditingController controller, String label, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD4AF37)),
        ),
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
          final ref = _firestore
              .collection('instituicoes')
              .doc(_instituicao!['id'])
              .collection('cursos')
              .doc(_curso!['id'])
              .collection('anos')
              .doc('${_ano!['ano']}')
              .collection('disciplinas')
              .doc(_disciplina)
              .collection('questoes');

          if (questao == null) {
            await ref.add({...dados, 'ordem': _questoes.length + 1});
          } else {
            await ref.doc(questao['id'] as String).update(dados);
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _firestore
                  .collection('instituicoes')
                  .doc(_instituicao!['id'])
                  .collection('cursos')
                  .doc(_curso!['id'])
                  .collection('anos')
                  .doc('${_ano!['ano']}')
                  .collection('disciplinas')
                  .doc(_disciplina)
                  .collection('questoes')
                  .doc(questaoId)
                  .delete();
              await _carregarQuestoes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  widget.questao == null ? 'Nova Questão' : 'Editar Questão',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                  _label('Enunciado da questão *'),
                  const SizedBox(height: 8),
                  _campo(_textoController, 'Escreve o enunciado...', maxLines: 3),
                  const SizedBox(height: 20),
                  _label('Opções de resposta *'),
                  const SizedBox(height: 4),
                  Text('Toca na opção correcta para a seleccionar',
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
                                child: Text(letra,
                                    style: TextStyle(
                                      color: isCorrecta
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    )),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _opcoesControllers[i],
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Opção $letra...',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.3), fontSize: 13),
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
                  _label('Explicação / Justificação *'),
                  const SizedBox(height: 8),
                  _campo(_justificacaoController, 'Explica a resposta correcta...', maxLines: 3),
                  const SizedBox(height: 16),
                  _label('Resolução passo-a-passo (opcional)'),
                  const SizedBox(height: 8),
                  _campo(_resolucaoController, 'Resolução detalhada...', maxLines: 4),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _guardando ? null : _guardar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _guardando
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              widget.questao == null ? 'Adicionar Questão' : 'Guardar Alterações',
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
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
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 13,
          fontWeight: FontWeight.w600));

  Widget _campo(TextEditingController controller, String hint, {int maxLines = 1}) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD4AF37))),
        ),
      );
}