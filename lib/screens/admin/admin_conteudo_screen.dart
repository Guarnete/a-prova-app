import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminConteudoScreen extends StatefulWidget {
  final String instituicaoId;
  final bool eSuperAdmin;

  const AdminConteudoScreen({
    super.key,
    required this.instituicaoId,
    required this.eSuperAdmin,
  });

  @override
  State<AdminConteudoScreen> createState() => _AdminConteudoScreenState();
}

class _AdminConteudoScreenState extends State<AdminConteudoScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _AnosTab(
                    instituicaoId: widget.instituicaoId,
                    adminService: _adminService,
                  ),
                  _CursosTab(
                    instituicaoId: widget.instituicaoId,
                    adminService: _adminService,
                  ),
                  if (widget.eSuperAdmin)
                    _InstituicoesTab(adminService: _adminService)
                  else
                    const Center(
                      child: Text(
                        'Apenas superadmin pode gerir instituições.',
                        style: TextStyle(color: Colors.grey),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CONTEÚDO',
                style: TextStyle(
                  color: Color(0xFF34C759),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Instituições e Cursos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF34C759),
        labelColor: const Color(0xFF34C759),
        unselectedLabelColor: Colors.white.withValues(alpha: 0.4),
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Anos'),
          Tab(text: 'Cursos'),
          Tab(text: 'Instituições'),
        ],
      ),
    );
  }
}

// ── Tab Anos ──────────────────────────────────────────────────────────────────
class _AnosTab extends StatefulWidget {
  final String instituicaoId;
  final AdminService adminService;

  const _AnosTab({required this.instituicaoId, required this.adminService});

  @override
  State<_AnosTab> createState() => _AnosTabState();
}

class _AnosTabState extends State<_AnosTab> {
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _anos = [];
  String? _cursoSeleccionado;
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  Future<void> _carregarCursos() async {
    final cursos = await widget.adminService.carregarCursos(widget.instituicaoId);
    setState(() {
      _cursos = cursos;
      _carregando = false;
    });
  }

  Future<void> _carregarAnos() async {
    if (_cursoSeleccionado == null) return;
    setState(() => _carregando = true);
    try {
      // Carrega anos directamente do Firestore
      final snapshot = await widget.adminService.carregarAnosAdmin(
        instituicaoId: widget.instituicaoId,
        cursoId: _cursoSeleccionado!,
      );
      setState(() {
        _anos = snapshot;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Selector de curso
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _cursoSeleccionado,
                hint: Text('Seleccionar curso',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4), fontSize: 13)),
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                icon: Icon(Icons.keyboard_arrow_down,
                    color: Colors.white.withValues(alpha: 0.5)),
                isExpanded: true,
                items: _cursos
                    .map((c) => DropdownMenuItem(
                          value: c['id'] as String,
                          child: Text(c['nome'] as String? ?? c['id'] as String),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() => _cursoSeleccionado = val);
                  _carregarAnos();
                },
              ),
            ),
          ),
        ),
        Expanded(
          child: _cursoSeleccionado == null
              ? Center(
                  child: Text('Selecciona um curso',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4))))
              : _carregando
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF34C759)))
                  : _buildListaAnos(),
        ),
      ],
    );
  }

  Widget _buildListaAnos() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _anos.length,
            itemBuilder: (context, index) {
              final ano = _anos[index];
              final activo = ano['activo'] as bool? ?? true;
              final planoMinimo = ano['planoMinimo'] as String? ?? 'gratuito';
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: Color(0xFF34C759), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${ano['ano']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                          ),
                          Text(
                            'Plano: $planoMinimo',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    // Toggle activo/inactivo
                    Switch(
                      value: activo,
                      activeThumbColor: const Color(0xFF34C759),
                      onChanged: (val) async {
                        await widget.adminService.toggleAnoActivo(
                          instituicaoId: widget.instituicaoId,
                          cursoId: _cursoSeleccionado!,
                          ano: '${ano['ano']}',
                          activo: val,
                        );
                        await _carregarAnos();
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Botão adicionar ano
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarFormularioAno(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
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

  void _mostrarFormularioAno(BuildContext context) {
    final anoController = TextEditingController();
    final duracaoController = TextEditingController(text: '90');
    String planoMinimo = 'gratuito';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Adicionar Ano',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDialogField(anoController, 'Ano (ex: 2026)',
                  TextInputType.number),
              const SizedBox(height: 12),
              _buildDialogField(duracaoController, 'Duração (minutos)',
                  TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: planoMinimo,
                dropdownColor: const Color(0xFF2A2A2A),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Plano mínimo',
                  labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: ['gratuito', 'bronze', 'prata', 'ouro']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) =>
                    setStateDialog(() => planoMinimo = val ?? 'gratuito'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final ano = int.tryParse(anoController.text);
                final duracao =
                    int.tryParse(duracaoController.text) ?? 90;
                if (ano == null) return;
                Navigator.pop(context);
                await widget.adminService.adicionarAno(
                  instituicaoId: widget.instituicaoId,
                  cursoId: _cursoSeleccionado!,
                  ano: ano,
                  planoMinimo: planoMinimo,
                  duracaoMinutos: duracao,
                );
                await _carregarAnos();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                elevation: 0,
              ),
              child: const Text('Adicionar',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogField(
      TextEditingController controller, String label, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF34C759)),
        ),
      ),
    );
  }
}

// ── Tab Cursos ────────────────────────────────────────────────────────────────
class _CursosTab extends StatefulWidget {
  final String instituicaoId;
  final AdminService adminService;

  const _CursosTab({required this.instituicaoId, required this.adminService});

  @override
  State<_CursosTab> createState() => _CursosTabState();
}

class _CursosTabState extends State<_CursosTab> {
  List<Map<String, dynamic>> _cursos = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarCursos();
  }

  Future<void> _carregarCursos() async {
    setState(() => _carregando = true);
    final cursos =
        await widget.adminService.carregarCursos(widget.instituicaoId);
    setState(() {
      _cursos = cursos;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF34C759)));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cursos.length,
            itemBuilder: (context, index) {
              final curso = _cursos[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34C759).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.school,
                          color: Color(0xFF34C759), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            curso['nome'] as String? ?? curso['id'] as String,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          Text(
                            curso['disciplinas'] as String? ?? '',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
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
              onPressed: () => _mostrarFormularioCurso(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Adicionar Curso',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarFormularioCurso(BuildContext context) {
    final idController = TextEditingController();
    final nomeController = TextEditingController();
    final disciplinasController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Adicionar Curso',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(idController, 'ID do curso (ex: medicina)'),
            const SizedBox(height: 10),
            _buildField(nomeController, 'Nome (ex: Medicina)'),
            const SizedBox(height: 10),
            _buildField(disciplinasController,
                'Disciplinas (ex: Biologia,Química)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isEmpty || nomeController.text.isEmpty) {
                return;
              }
              Navigator.pop(context);
              await widget.adminService.adicionarCurso(
                instituicaoId: widget.instituicaoId,
                cursoId: idController.text.trim(),
                nome: nomeController.text.trim(),
                disciplinas: disciplinasController.text.trim(),
              );
              await _carregarCursos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF34C759),
              elevation: 0,
            ),
            child: const Text('Adicionar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF34C759)),
        ),
      ),
    );
  }
}

// ── Tab Instituições ──────────────────────────────────────────────────────────
class _InstituicoesTab extends StatefulWidget {
  final AdminService adminService;

  const _InstituicoesTab({required this.adminService});

  @override
  State<_InstituicoesTab> createState() => _InstituicoesTabState();
}

class _InstituicoesTabState extends State<_InstituicoesTab> {
  List<Map<String, dynamic>> _instituicoes = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarInstituicoes();
  }

  Future<void> _carregarInstituicoes() async {
    setState(() => _carregando = true);
    final instituicoes = await widget.adminService.carregarInstituicoes();
    setState(() {
      _instituicoes = instituicoes;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF34C759)));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _instituicoes.length,
            itemBuilder: (context, index) {
              final inst = _instituicoes[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          (inst['sigla'] as String? ?? '?')
                              .substring(0, 3.clamp(0, (inst['sigla'] as String? ?? '?').length)),
                          style: const TextStyle(
                              color: Color(0xFF007AFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inst['nome'] as String? ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                          ),
                          Text(
                            inst['cidade'] as String? ?? '',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              onPressed: () => _mostrarFormularioInstituicao(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Adicionar Instituição',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  void _mostrarFormularioInstituicao(BuildContext context) {
    final idController = TextEditingController();
    final nomeController = TextEditingController();
    final siglaController = TextEditingController();
    final cidadeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Adicionar Instituição',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(idController, 'ID (ex: UCM)'),
            const SizedBox(height: 10),
            _buildField(nomeController, 'Nome completo'),
            const SizedBox(height: 10),
            _buildField(siglaController, 'Sigla (ex: UCM)'),
            const SizedBox(height: 10),
            _buildField(cidadeController, 'Cidade'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isEmpty || nomeController.text.isEmpty) {
                return;
              }
              Navigator.pop(context);
              await widget.adminService.adicionarInstituicao(
                id: idController.text.trim(),
                nome: nomeController.text.trim(),
                sigla: siglaController.text.trim(),
                cidade: cidadeController.text.trim(),
              );
              await _carregarInstituicoes();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              elevation: 0,
            ),
            child: const Text('Adicionar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.07),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF007AFF)),
        ),
      ),
    );
  }
}