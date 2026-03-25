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

class _AdminConteudoScreenState extends State<AdminConteudoScreen> {
  final AdminService _adminService = AdminService();

  // Selecções sequenciais
  Map<String, dynamic>? _instituicao;
  Map<String, dynamic>? _curso;

  // Dados
  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _cursos = [];
  List<Map<String, dynamic>> _anos = [];

  bool _carregando = true;

  // Passo: 1=Instituição, 2=Curso, 3=Anos
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

  void _voltarPasso() {
    setState(() {
      if (_passo == 3) { _passo = 2; _curso = null; _anos = []; }
      else if (_passo == 2 && widget.eSuperAdmin) { _passo = 1; _instituicao = null; _cursos = []; }
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
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildHeader() {
    final titulos = ['Instituição', 'Curso', 'Anos de Exame'];
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
                const Text('CONTEÚDO',
                    style: TextStyle(color: Color(0xFF34C759), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                Text('Selecciona ${titulos[_passo - 1]}',
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigalhas() {
    final passos = ['Inst.', 'Curso', 'Anos'];
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
                              ? const Color(0xFF34C759)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(passos[i],
                          style: TextStyle(
                            color: activo ? const Color(0xFF34C759)
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
      return const Center(child: CircularProgressIndicator(color: Color(0xFF34C759)));
    }
    switch (_passo) {
      case 1: return _buildLista(_instituicoes, 'nome', 'cidade', (item) {
        setState(() { _instituicao = item; _passo = 2; });
        _carregarCursos();
      });
      case 2: return _buildLista(_cursos, 'nome', 'disciplinas', (item) {
        setState(() { _curso = item; _passo = 3; });
        _carregarAnos();
      });
      case 3: return _buildListaAnos();
      default: return const SizedBox();
    }
  }

  Widget _buildLista(
    List<Map<String, dynamic>> items,
    String campoNome,
    String? campoSub,
    void Function(Map<String, dynamic>) onTap,
  ) {
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
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chevron_right, color: Color(0xFF34C759), size: 22),
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
    return Column(
      children: [
        Expanded(
          child: _anos.isEmpty
              ? Center(
                  child: Text('Nenhum ano adicionado ainda.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4))))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _anos.length,
                  itemBuilder: (context, index) {
                    final ano = _anos[index];
                    final activo = ano['activo'] as bool? ?? true;
                    final plano = ano['planoMinimo'] as String? ?? 'gratuito';
                    final tipo = ano['tipo'] as String? ?? 'real';
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
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: (tipo == 'preditiva' ? Colors.purple : const Color(0xFF007AFF))
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              tipo == 'preditiva' ? Icons.auto_awesome : Icons.school,
                              color: tipo == 'preditiva' ? Colors.purple : const Color(0xFF007AFF),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${ano['ano']}',
                                    style: const TextStyle(color: Colors.white,
                                        fontWeight: FontWeight.bold, fontSize: 15)),
                                Row(
                                  children: [
                                    _badge(tipo == 'preditiva' ? 'Preditiva' : 'Real',
                                        tipo == 'preditiva' ? Colors.purple : const Color(0xFF007AFF)),
                                    const SizedBox(width: 6),
                                    _badge(plano, const Color(0xFFD4AF37)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: activo,
                            activeThumbColor: const Color(0xFF34C759),
                            onChanged: (val) async {
                              await _adminService.toggleAnoActivo(
                                instituicaoId: _instituicao!['id'],
                                cursoId: _curso!['id'],
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _mostrarFormularioAno(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34C759),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Adicionar Ano',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _badge(String texto, Color cor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(texto,
          style: TextStyle(color: cor, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget? _buildFAB() {
    if (_passo == 2) {
      return FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioCurso(context),
        backgroundColor: const Color(0xFF34C759),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Adicionar Curso',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    if (_passo == 1 && widget.eSuperAdmin) {
      return FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioInstituicao(context),
        backgroundColor: const Color(0xFF007AFF),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Adicionar Instituição',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }
    return null;
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
                _campo(anoController, 'Ano (ex: 2026)', TextInputType.number),
                const SizedBox(height: 12),
                _campo(duracaoController, 'Duração (minutos)', TextInputType.number),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoracao('Tipo de exame'),
                  items: const [
                    DropdownMenuItem(value: 'real', child: Text('Exame Real')),
                    DropdownMenuItem(value: 'preditiva', child: Text('Avaliação Preditiva')),
                  ],
                  onChanged: (val) => setStateDialog(() => tipo = val ?? 'real'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: planoMinimo,
                  dropdownColor: const Color(0xFF2A2A2A),
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoracao('Plano mínimo'),
                  items: ['gratuito', 'bronze', 'prata', 'ouro']
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => planoMinimo = val ?? 'gratuito'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
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
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34C759), elevation: 0),
              child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Adicionar Curso em ${_instituicao?['sigla'] ?? _instituicao?['nome'] ?? ''}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(idController, 'ID do curso (ex: medicina)', TextInputType.text),
            const SizedBox(height: 10),
            _campo(nomeController, 'Nome (ex: Medicina)', TextInputType.text),
            const SizedBox(height: 10),
            _campo(disciplinasController, 'Disciplinas (ex: Biologia,Química)', TextInputType.text),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isEmpty || nomeController.text.isEmpty) return;
              Navigator.pop(context);
              await _adminService.adicionarCurso(
                instituicaoId: _instituicao!['id'],
                cursoId: idController.text.trim(),
                nome: nomeController.text.trim(),
                disciplinas: disciplinasController.text.trim(),
              );
              await _carregarCursos();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34C759), elevation: 0),
            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Adicionar Instituição', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _campo(idController, 'ID (ex: UCM)', TextInputType.text),
            const SizedBox(height: 10),
            _campo(nomeController, 'Nome completo', TextInputType.text),
            const SizedBox(height: 10),
            _campo(siglaController, 'Sigla (ex: UCM)', TextInputType.text),
            const SizedBox(height: 10),
            _campo(cidadeController, 'Cidade', TextInputType.text),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.isEmpty || nomeController.text.isEmpty) return;
              Navigator.pop(context);
              await _adminService.adicionarInstituicao(
                id: idController.text.trim(),
                nome: nomeController.text.trim(),
                sigla: siglaController.text.trim(),
                cidade: cidadeController.text.trim(),
              );
              await _carregarInstituicoes();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF007AFF), elevation: 0),
            child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _campo(TextEditingController controller, String label, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: _decoracao(label),
    );
  }

  InputDecoration _decoracao(String label) {
    return InputDecoration(
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
        borderSide: const BorderSide(color: Color(0xFF34C759)),
      ),
    );
  }
}