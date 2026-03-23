import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import 'admin_home_screen.dart';

class AdminGate extends StatefulWidget {
  const AdminGate({super.key});

  @override
  State<AdminGate> createState() => _AdminGateState();
}

class _AdminGateState extends State<AdminGate> {
  final AdminService _adminService = AdminService();
  bool _carregando = true;
  bool _eAdmin = false;
  bool _eSuperAdmin = false;
  Map<String, dynamic>? _perfilAdmin;

  @override
  void initState() {
    super.initState();
    _verificarAcesso();
  }

  Future<void> _verificarAcesso() async {
    setState(() => _carregando = true);
    final perfil = await _adminService.carregarPerfisAdmin();
    if (mounted) {
      setState(() {
        _perfilAdmin = perfil;
        _eAdmin = perfil != null && (perfil['aprovado'] as bool? ?? false);
        _eSuperAdmin = perfil?['papel'] == 'superadmin';
        _carregando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
        ),
      );
    }

    if (_eAdmin) {
      return AdminHomeScreen(
        perfilAdmin: _perfilAdmin!,
        eSuperAdmin: _eSuperAdmin,
      );
    }

    // Não é admin — mostrar tela de solicitação
    return _SolicitarAcessoScreen(
      perfilAdmin: _perfilAdmin,
      onSolicitado: _verificarAcesso,
    );
  }
}

// ── Tela de solicitação de acesso ─────────────────────────────────────────────
class _SolicitarAcessoScreen extends StatefulWidget {
  final Map<String, dynamic>? perfilAdmin;
  final VoidCallback onSolicitado;

  const _SolicitarAcessoScreen({
    required this.perfilAdmin,
    required this.onSolicitado,
  });

  @override
  State<_SolicitarAcessoScreen> createState() => _SolicitarAcessoScreenState();
}

class _SolicitarAcessoScreenState extends State<_SolicitarAcessoScreen> {
  final AdminService _adminService = AdminService();
  final _instituicaoController = TextEditingController();
  final _nomeInstituicaoController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _instituicaoController.dispose();
    _nomeInstituicaoController.dispose();
    super.dispose();
  }

  Future<void> _solicitarAcesso() async {
    if (_instituicaoController.text.isEmpty ||
        _nomeInstituicaoController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preenche todos os campos.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _enviando = true);
    final resultado = await _adminService.solicitarAcesso(
      instituicaoId: _instituicaoController.text.trim(),
      instituicaoNome: _nomeInstituicaoController.text.trim(),
    );
    setState(() => _enviando = false);

    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pedido enviado! Aguarda aprovação do superadmin.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.onSolicitado();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado['erro'] ?? 'Erro ao enviar pedido.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendente = widget.perfilAdmin != null &&
        !(widget.perfilAdmin!['aprovado'] as bool? ?? false);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Painel Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),

              // Ícone
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings,
                      color: Color(0xFFD4AF37), size: 40),
                ),
              ),
              const SizedBox(height: 24),

              if (pendente) ...[
                // Pedido pendente
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Pedido em análise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'O teu pedido de acesso foi enviado e está a ser analisado pelo superadmin.',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 14,
                            height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFD4AF37)
                                  .withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.hourglass_empty,
                                color: Color(0xFFD4AF37), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Instituição: ${widget.perfilAdmin!['instituicaoNome']}',
                                style: const TextStyle(
                                    color: Color(0xFFD4AF37), fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Formulário de solicitação
                const Text(
                  'Solicitar acesso',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Preenche os dados da tua instituição para solicitar acesso ao painel de administração.',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 14,
                      height: 1.5),
                ),
                const SizedBox(height: 32),

                // ID da instituição
                _buildCampo(
                  controller: _instituicaoController,
                  label: 'ID da Instituição',
                  hint: 'Ex: UEM',
                  icone: Icons.business,
                ),
                const SizedBox(height: 16),

                // Nome da instituição
                _buildCampo(
                  controller: _nomeInstituicaoController,
                  label: 'Nome da Instituição',
                  hint: 'Ex: Universidade Eduardo Mondlane',
                  icone: Icons.school,
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _enviando ? null : _solicitarAcesso,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _enviando
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Solicitar Acesso',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCampo({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icone,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icone,
                color: Colors.white.withValues(alpha: 0.5), size: 20),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD4AF37)),
            ),
          ),
        ),
      ],
    );
  }
}