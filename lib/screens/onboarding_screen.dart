import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _pesquisaController = TextEditingController();

  // Controlo de passos: 1 = Instituição, 2 = Curso
  int _passo = 1;

  // Dados carregados do Firestore
  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _cursos = [];

  // Selecções do utilizador
  Map<String, dynamic>? _instituicaoSeleccionada;
  Map<String, dynamic>? _cursoSeleccionado;

  // Estados UI
  bool _isLoadingInstituicoes = true;
  bool _isLoadingCursos = false;
  bool _isSaving = false;
  String _pesquisa = '';

  @override
  void initState() {
    super.initState();
    _carregarInstituicoes();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  // ─── Carrega todas as instituições do Firestore ───────────────────────────

  Future<void> _carregarInstituicoes() async {
    setState(() => _isLoadingInstituicoes = true);
    try {
      final snapshot = await _firestore
          .collection('instituicoes')
          .orderBy('nome')
          .get();
      setState(() {
        _instituicoes = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _isLoadingInstituicoes = false;
      });
    } catch (e) {
      setState(() => _isLoadingInstituicoes = false);
      if (mounted) {
        _mostrarErro('Erro ao carregar instituições. Verifica a ligação.');
      }
    }
  }

  // ─── Carrega cursos da instituição seleccionada ───────────────────────────

  Future<void> _carregarCursos(String instituicaoId) async {
    setState(() => _isLoadingCursos = true);
    try {
      final snapshot = await _firestore
          .collection('instituicoes')
          .doc(instituicaoId)
          .collection('cursos')
          .orderBy('nome')
          .get();
      setState(() {
        _cursos = snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();
        _isLoadingCursos = false;
      });
    } catch (e) {
      setState(() => _isLoadingCursos = false);
      if (mounted) {
        _mostrarErro('Erro ao carregar cursos. Verifica a ligação.');
      }
    }
  }

  // ─── Seleccionar instituição e avançar para passo 2 ──────────────────────

  void _seleccionarInstituicao(Map<String, dynamic> instituicao) {
    setState(() {
      _instituicaoSeleccionada = instituicao;
      _cursoSeleccionado = null;
      _cursos = [];
      _passo = 2;
      _pesquisaController.clear();
      _pesquisa = '';
    });
    _carregarCursos(instituicao['id']);
  }

  // ─── Seleccionar curso ────────────────────────────────────────────────────

  void _seleccionarCurso(Map<String, dynamic> curso) {
    setState(() => _cursoSeleccionado = curso);
  }

  // ─── Voltar ao passo 1 ────────────────────────────────────────────────────

  void _voltarParaInstituicoes() {
    setState(() {
      _passo = 1;
      _instituicaoSeleccionada = null;
      _cursoSeleccionado = null;
      _cursos = [];
      _pesquisaController.clear();
      _pesquisa = '';
    });
  }

  // ─── Guardar no Firebase e navegar para Home ──────────────────────────────

  Future<void> _concluirOnboarding() async {
    if (_instituicaoSeleccionada == null || _cursoSeleccionado == null) return;

    setState(() => _isSaving = true);

    try {
      // Buscar lista de disciplinas do curso seleccionado
      final disciplinas = _cursoSeleccionado!['disciplinas'] ?? '';

      await _authService.adicionarCurso(
        instituicaoId: _instituicaoSeleccionada!['id'],
        instituicaoSigla: _instituicaoSeleccionada!['sigla'] ?? '',
        instituicaoNome: _instituicaoSeleccionada!['nome'] ?? '',
        cursoNome: _cursoSeleccionado!['nome'] ?? '',
        disciplinas: disciplinas is List
            ? disciplinas.join(',')
            : disciplinas.toString(),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        _mostrarErro('Erro ao guardar perfil. Tenta novamente.');
      }
    }
  }

  // ─── Helper: mostrar erro ─────────────────────────────────────────────────

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Filtro de pesquisa ───────────────────────────────────────────────────

  List<Map<String, dynamic>> get _listaFiltrada {
    final lista = _passo == 1 ? _instituicoes : _cursos;
    if (_pesquisa.isEmpty) return lista;
    return lista.where((item) {
      final nome = (item['nome'] ?? '').toString().toLowerCase();
      return nome.contains(_pesquisa.toLowerCase());
    }).toList();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildIndicadorPassos(),
            _buildBarraPesquisa(),
            Expanded(child: _buildLista()),
            if (_passo == 2) _buildBotaoConcluir(),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botão voltar (apenas no passo 2)
          if (_passo == 2)
            GestureDetector(
              onTap: _voltarParaInstituicoes,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, color: Color(0xFF007AFF), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Instituições',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (_passo == 2) const SizedBox(height: 20),

          // Título
          Text(
            _passo == 1 ? 'Bem-vindo à A PROVA' : _instituicaoSeleccionada!['sigla'] ?? '',
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _passo == 1
                ? 'Selecciona a tua instituição'
                : 'Selecciona o teu curso',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _passo == 1
                ? 'Onde vais candidatar-te?'
                : 'Qual é o curso que pretendes?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  // ─── Indicador de passos ──────────────────────────────────────────────────

  Widget _buildIndicadorPassos() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _buildPasso(numero: 1, label: 'Instituição', activo: _passo == 1, completo: _passo > 1),
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _passo > 1
                  ? const Color(0xFF007AFF)
                  : Colors.white.withValues(alpha: 0.15),
            ),
          ),
          _buildPasso(numero: 2, label: 'Curso', activo: _passo == 2, completo: false),
        ],
      ),
    );
  }

  Widget _buildPasso({
    required int numero,
    required String label,
    required bool activo,
    required bool completo,
  }) {
    final Color corFundo = completo
        ? const Color(0xFF007AFF)
        : activo
            ? const Color(0xFF007AFF)
            : Colors.white.withValues(alpha: 0.1);

    final Color corTexto = (activo || completo) ? Colors.white : Colors.white.withValues(alpha: 0.4);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: corFundo,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completo
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$numero',
                    style: TextStyle(
                      color: corTexto,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: corTexto,
            fontSize: 11,
            fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ─── Barra de pesquisa ────────────────────────────────────────────────────

  Widget _buildBarraPesquisa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: TextField(
          controller: _pesquisaController,
          onChanged: (v) => setState(() => _pesquisa = v),
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: _passo == 1 ? 'Pesquisar instituição...' : 'Pesquisar curso...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.35), size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ─── Lista de itens ───────────────────────────────────────────────────────

  Widget _buildLista() {
    final isLoading = _passo == 1 ? _isLoadingInstituicoes : _isLoadingCursos;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF007AFF)),
      );
    }

    final lista = _listaFiltrada;

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: Colors.white.withValues(alpha: 0.2), size: 48),
            const SizedBox(height: 12),
            Text(
              'Nenhum resultado encontrado',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final item = lista[index];
        final isSeleccionado = _passo == 2 &&
            _cursoSeleccionado != null &&
            _cursoSeleccionado!['id'] == item['id'];

        return _buildItemLista(
          item: item,
          isSeleccionado: isSeleccionado,
          onTap: () => _passo == 1
              ? _seleccionarInstituicao(item)
              : _seleccionarCurso(item),
        );
      },
    );
  }

  Widget _buildItemLista({
    required Map<String, dynamic> item,
    required bool isSeleccionado,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: isSeleccionado
              ? const Color(0xFF007AFF).withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSeleccionado
                ? const Color(0xFF007AFF)
                : Colors.white.withValues(alpha: 0.08),
            width: isSeleccionado ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Ícone / sigla
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSeleccionado
                    ? const Color(0xFF007AFF).withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _passo == 1
                      ? (item['sigla'] ?? '?').toString().substring(0, 
                          (item['sigla'] ?? '?').toString().length > 3 ? 3 : 
                          (item['sigla'] ?? '?').toString().length)
                      : _iconeCurso(item['nome'] ?? ''),
                  style: TextStyle(
                    color: isSeleccionado
                        ? const Color(0xFF007AFF)
                        : Colors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                    fontSize: _passo == 1 ? 11 : 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Nome
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nome'] ?? '',
                    style: TextStyle(
                      color: isSeleccionado ? Colors.white : Colors.white.withValues(alpha: 0.85),
                      fontSize: 15,
                      fontWeight: isSeleccionado ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (_passo == 1 && item['cidade'] != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item['cidade'],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Indicador de selecção (passo 2) ou seta (passo 1)
            if (_passo == 1)
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.3), size: 20)
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSeleccionado ? const Color(0xFF007AFF) : Colors.transparent,
                  border: Border.all(
                    color: isSeleccionado
                        ? const Color(0xFF007AFF)
                        : Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: isSeleccionado
                    ? const Icon(Icons.check, color: Colors.white, size: 13)
                    : null,
              ),
          ],
        ),
      ),
    );
  }

  // ─── Botão Começar (passo 2) ──────────────────────────────────────────────

  Widget _buildBotaoConcluir() {
    final bool habilitado = _cursoSeleccionado != null && !_isSaving;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: AnimatedOpacity(
          opacity: habilitado ? 1.0 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: habilitado ? _concluirOnboarding : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
              disabledBackgroundColor: const Color(0xFF007AFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    'Começar a estudar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // ─── Helper: emoji por área de curso ─────────────────────────────────────

  String _iconeCurso(String nomeCurso) {
    final nome = nomeCurso.toLowerCase();
    if (nome.contains('medicina') || nome.contains('saúde') || nome.contains('enfermagem')) return '🏥';
    if (nome.contains('direito') || nome.contains('ciências jurídicas')) return '⚖️';
    if (nome.contains('engenharia') || nome.contains('informática') || nome.contains('tecnologia')) return '💻';
    if (nome.contains('economia') || nome.contains('gestão') || nome.contains('contabilidade')) return '📊';
    if (nome.contains('educação') || nome.contains('pedagogia') || nome.contains('ensino')) return '📚';
    if (nome.contains('arquitectura') || nome.contains('urbanismo')) return '🏛️';
    if (nome.contains('biologia') || nome.contains('bioquímica')) return '🔬';
    if (nome.contains('química') || nome.contains('farmácia')) return '⚗️';
    if (nome.contains('física') || nome.contains('matemática')) return '🔭';
    if (nome.contains('comunicação') || nome.contains('jornalismo') || nome.contains('relações')) return '📡';
    if (nome.contains('psicologia')) return '🧠';
    if (nome.contains('agricultura') || nome.contains('veterinária') || nome.contains('zootecnia')) return '🌱';
    return '🎓';
  }
}