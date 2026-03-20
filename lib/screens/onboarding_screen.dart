import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final bool modoAdicionar;

  const OnboardingScreen({
    super.key,
    this.modoAdicionar = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _pesquisaController = TextEditingController();

  int _passo = 1;
  List<Map<String, dynamic>> _instituicoes = [];
  List<Map<String, dynamic>> _cursos = [];
  Map<String, dynamic>? _instituicaoSeleccionada;
  Map<String, dynamic>? _cursoSeleccionado;
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
      if (mounted) _mostrarErro('Erro ao carregar instituições.');
    }
  }

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
      if (mounted) _mostrarErro('Erro ao carregar cursos.');
    }
  }

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

  void _seleccionarCurso(Map<String, dynamic> curso) {
    setState(() => _cursoSeleccionado = curso);
  }

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

  Future<void> _concluirOnboarding() async {
    if (_instituicaoSeleccionada == null || _cursoSeleccionado == null) return;
    setState(() => _isSaving = true);
    try {
      final disciplinas = _cursoSeleccionado!['disciplinas'] ?? '';
      final resultado = await _authService.adicionarCurso(
        instituicaoId: _instituicaoSeleccionada!['id'],
        instituicaoSigla: _instituicaoSeleccionada!['sigla'] ?? '',
        instituicaoNome: _instituicaoSeleccionada!['nome'] ?? '',
        cursoNome: _cursoSeleccionado!['nome'] ?? '',
        disciplinas: disciplinas is List
            ? disciplinas.join(',')
            : disciplinas.toString(),
      );

      if (!mounted) return;

      if (resultado['sucesso'] == false) {
        setState(() => _isSaving = false);
        _mostrarErro(resultado['erro'] ?? 'Erro ao adicionar curso.');
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) _mostrarErro('Erro ao guardar perfil. Tenta novamente.');
    }
  }

  void _mostrarErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> get _listaFiltrada {
    final lista = _passo == 1 ? _instituicoes : _cursos;
    if (_pesquisa.isEmpty) return lista;
    return lista.where((item) {
      final nome = (item['nome'] ?? '').toString().toLowerCase();
      return nome.contains(_pesquisa.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildIndicadorPassos(),
          _buildBarraPesquisa(),
          Expanded(child: _buildLista()),
          if (_passo == 2) _buildBotaoConcluir(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF007AFF),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 16,
        20,
        20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_passo == 2) ...[
            GestureDetector(
              onTap: _voltarParaInstituicoes,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Instituições',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(
            _passo == 1
                ? (widget.modoAdicionar ? 'ADICIONAR CURSO' : 'BEM-VINDO À A PROVA')
                : (_instituicaoSeleccionada!['sigla'] ?? '').toString().toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _passo == 1
                ? (widget.modoAdicionar ? 'Adiciona uma instituição' : 'Selecciona a tua instituição')
                : 'Selecciona o teu curso',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _passo == 1 ? 'Onde vais candidatar-te?' : 'Qual é o curso que pretendes?',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicadorPassos() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          _buildPasso(numero: 1, label: 'Instituição', activo: _passo == 1, completo: _passo > 1),
          Expanded(
            child: Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _passo > 1 ? const Color(0xFF007AFF) : Colors.grey.shade200,
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
    final Color corFundo = (activo || completo) ? const Color(0xFF007AFF) : Colors.grey.shade200;
    final Color corTexto = (activo || completo) ? Colors.white : Colors.grey;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: corFundo, shape: BoxShape.circle),
          child: Center(
            child: completo
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$numero',
                    style: TextStyle(color: corTexto, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: (activo || completo) ? const Color(0xFF007AFF) : Colors.grey,
            fontSize: 11,
            fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildBarraPesquisa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          controller: _pesquisaController,
          onChanged: (v) => setState(() => _pesquisa = v),
          style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 15),
          decoration: InputDecoration(
            hintText: _passo == 1 ? 'Pesquisar instituição...' : 'Pesquisar curso...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLista() {
    final isLoading = _passo == 1 ? _isLoadingInstituicoes : _isLoadingCursos;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF007AFF)));
    }

    final lista = _listaFiltrada;

    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: Colors.grey.shade300, size: 48),
            const SizedBox(height: 12),
            Text('Nenhum resultado encontrado',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final item = lista[index];
        final isSeleccionado = _passo == 2 &&
            _cursoSeleccionado != null &&
            _cursoSeleccionado!['id'] == item['id'];
        return _buildItemLista(
          item: item,
          isSeleccionado: isSeleccionado,
          onTap: () => _passo == 1 ? _seleccionarInstituicao(item) : _seleccionarCurso(item),
        );
      },
    );
  }

  Widget _buildItemLista({
    required Map<String, dynamic> item,
    required bool isSeleccionado,
    required VoidCallback onTap,
  }) {
    final sigla = (item['sigla'] ?? '?').toString();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSeleccionado ? const Color(0xFF007AFF).withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSeleccionado
                ? const Color(0xFF007AFF)
                : const Color(0xFF007AFF).withValues(alpha: 0.3),
            width: isSeleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSeleccionado
                    ? const Color(0xFF007AFF).withValues(alpha: 0.1)
                    : const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  _passo == 1
                      ? sigla.substring(0, sigla.length > 3 ? 3 : sigla.length)
                      : _iconeCurso(item['nome'] ?? ''),
                  style: TextStyle(
                    color: const Color(0xFF007AFF),
                    fontWeight: FontWeight.w700,
                    fontSize: _passo == 1 ? 11 : 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['nome'] ?? '',
                    style: TextStyle(
                      color: isSeleccionado ? const Color(0xFF007AFF) : const Color(0xFF1A1A1A),
                      fontSize: 15,
                      fontWeight: isSeleccionado ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                  if (_passo == 1 && item['cidade'] != null) ...[
                    const SizedBox(height: 2),
                    Text(item['cidade'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  ],
                ],
              ),
            ),
            if (_passo == 1)
              const Icon(Icons.chevron_right, color: Color(0xFF007AFF), size: 20)
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSeleccionado ? const Color(0xFF007AFF) : Colors.transparent,
                  border: Border.all(
                    color: isSeleccionado ? const Color(0xFF007AFF) : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: isSeleccionado ? const Icon(Icons.check, color: Colors.white, size: 13) : null,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoConcluir() {
    final bool habilitado = _cursoSeleccionado != null && !_isSaving;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    widget.modoAdicionar ? 'Adicionar Curso' : 'Começar a estudar',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                  ),
          ),
        ),
      ),
    );
  }

  String _iconeCurso(String nomeCurso) {
    final nome = nomeCurso.toLowerCase();
    if (nome.contains('medicina') || nome.contains('enfermagem')) return '🏥';
    if (nome.contains('direito')) return '⚖️';
    if (nome.contains('engenharia') || nome.contains('informática') || nome.contains('informatica')) return '💻';
    if (nome.contains('economia') || nome.contains('gestão')) return '📊';
    if (nome.contains('educação') || nome.contains('pedagogia')) return '📚';
    if (nome.contains('arquitectura')) return '🏛️';
    if (nome.contains('biologia')) return '🔬';
    if (nome.contains('química') || nome.contains('farmácia')) return '⚗️';
    if (nome.contains('física') || nome.contains('matemática')) return '🔭';
    if (nome.contains('comunicação') || nome.contains('jornalismo')) return '📡';
    if (nome.contains('psicologia')) return '🧠';
    if (nome.contains('agricultura')) return '🌱';
    return '🎓';
  }
}