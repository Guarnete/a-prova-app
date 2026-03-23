import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'anos_screen.dart';
import 'onboarding_screen.dart';
import '../services/admin_service.dart';
import 'admin/admin_gate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  String _nomeUtilizador = '';
  String _iniciaisUtilizador = '';

  // Lista de todos os cursos do utilizador
  List<Map<String, dynamic>> _cursos = [];

  // Índice do curso activo (tab seleccionada)
  int _cursoActivo = 0;

  bool _carregando = true;
  bool _eAdmin = false;
  final AdminService _adminService = AdminService();

  // Getters para o curso activo
  Map<String, dynamic>? get _curso =>
      _cursos.isNotEmpty ? _cursos[_cursoActivo] : null;

  String get _plano => _formatarPlano(_curso?['plano'] ?? 'gratuito');
  String get _instituicaoSigla => _curso?['instituicaoSigla'] ?? '';
  String get _cursoNome => _curso?['cursoNome'] ?? '';
  String get _instituicaoId => _curso?['instituicaoId'] ?? '';
  String get _disciplinas => _curso?['disciplinas'] ?? '';

  @override
  void initState() {
    super.initState();
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    setState(() => _carregando = true);
    try {
      final perfil = await _authService.carregarPerfil();
      if (perfil == null) return;

      final nome = perfil['nome'] ?? 'Estudante';
      final partes = nome.split(' ');
      final iniciais = partes.length >= 2
          ? '${partes[0][0]}${partes[1][0]}'.toUpperCase()
          : nome[0].toUpperCase();

      final cursos = List<Map<String, dynamic>>.from(
        (perfil['cursos'] as List<dynamic>? ?? [])
            .map((c) => Map<String, dynamic>.from(c)),
      );

      final eAdmin = await _adminService.eAdmin();

      if (mounted) {
        setState(() {
          _nomeUtilizador = nome;
          _iniciaisUtilizador = iniciais;
          _cursos = cursos;
          if (_cursoActivo >= cursos.length) _cursoActivo = 0;
          _eAdmin = eAdmin;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  String _formatarPlano(String plano) {
    switch (plano) {
      case 'bronze': return 'Plano Bronze';
      case 'prata': return 'Plano Prata';
      case 'ouro': return 'Plano Ouro';
      case 'diamante': return 'Plano Diamante';
      default: return 'Plano Gratuito';
    }
  }

  String _saudacao() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Bom dia,';
    if (hora < 18) return 'Boa tarde,';
    return 'Boa noite,';
  }

  void _irParaAvaliacaoPreditiva() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avaliação Preditiva — em breve!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF007AFF),
      ),
    );
  }

  void _irParaExame() {
    if (_instituicaoId.isEmpty || _cursoNome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum curso activo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnosScreen(
          instituicaoId: _instituicaoId,
          instituicaoSigla: _instituicaoSigla,
          cursoNome: _cursoNome,
          disciplinas: _disciplinas,
        ),
      ),
    ).then((_) => _carregarPerfil());
  }

  void _adicionarCurso() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OnboardingScreen(modoAdicionar: true),
      ),
    ).then((_) => _carregarPerfil());
  }

  Future<void> _logout() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terminar sessão'),
        content: const Text('Tens a certeza que queres sair?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child:
                const Text('Sair', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF007AFF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              if (_cursos.length > 1) _buildTabsCursos(),
              _buildProgresso(),
              _buildAcessoRapido(),
              _buildMestreIA(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF007AFF),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _saudacao(),
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  _nomeUtilizador,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                if (_cursoNome.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_instituicaoSigla · $_cursoNome',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _plano,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (_eAdmin) ...[
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminGate()),
              ),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.admin_panel_settings, color: Color(0xFFD4AF37), size: 20),
              ),
            ),
            const SizedBox(width: 8),
          ],
          GestureDetector(
            onTap: _logout,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(
                _iniciaisUtilizador,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── TABS DE CURSOS ───────────────────────────────────────────────────────
  Widget _buildTabsCursos() {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                ..._cursos.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final curso = entry.value;
                  final activo = idx == _cursoActivo;
                  return GestureDetector(
                    onTap: () => setState(() => _cursoActivo = idx),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: activo
                            ? const Color(0xFF007AFF)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: activo
                              ? const Color(0xFF007AFF)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        '${curso['instituicaoSigla']} · ${curso['cursoNome']}',
                        style: TextStyle(
                          color:
                              activo ? Colors.white : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: activo
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  );
                }),
                // Botão adicionar curso
                GestureDetector(
                  onTap: _adicionarCurso,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFF007AFF), width: 1.5),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add,
                            color: Color(0xFF007AFF), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Adicionar',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  // ── PROGRESSO ────────────────────────────────────────────────────────────
  Widget _buildProgresso() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Progresso de estudo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '0%',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF007AFF)),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '0 simulações completadas',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ── ACESSO RÁPIDO ────────────────────────────────────────────────────────
  Widget _buildAcessoRapido() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Text(
            'Acesso rápido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _BotaoAcesso(
                  icone: Icons.track_changes,
                  titulo: 'Avaliação Preditiva',
                  subtitulo: 'Exame gerado por IA',
                  aoTapar: _irParaAvaliacaoPreditiva,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BotaoAcesso(
                  icone: Icons.laptop_mac,
                  titulo: 'Simular Exame',
                  subtitulo: 'Exames reais anteriores',
                  aoTapar: _irParaExame,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _BotaoAcessoLargo(
            icone: Icons.bar_chart,
            titulo: 'Ver Resultados',
            subtitulo: 'Histórico e desempenho',
            aoTapar: () {},
          ),
        ),
        const SizedBox(height: 12),
        // Botão adicionar curso (quando só tem 1 curso)
        if (_cursos.length <= 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _BotaoAcessoLargo(
              icone: Icons.add_circle_outline,
              titulo: 'Adicionar Curso / Instituição',
              subtitulo: 'Prepara-te para mais de uma instituição',
              aoTapar: _adicionarCurso,
            ),
          ),
      ],
    );
  }

  // ── MESTRE IA ────────────────────────────────────────────────────────────
  Widget _buildMestreIA() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mestre A PROVA AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Estuda com inteligência artificial',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white70, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Botão quadrado ────────────────────────────────────────────────────────────
class _BotaoAcesso extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTapar;

  const _BotaoAcesso({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTapar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTapar,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icone, color: const Color(0xFF007AFF), size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              subtitulo,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botão largo ───────────────────────────────────────────────────────────────
class _BotaoAcessoLargo extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final VoidCallback aoTapar;

  const _BotaoAcessoLargo({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.aoTapar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTapar,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F1FB),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icone, color: const Color(0xFF007AFF), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }
}