import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import 'login_screen.dart';
import 'anos_screen.dart';
import 'onboarding_screen.dart';
import 'admin/admin_gate.dart';

class AdminHomeScreen extends StatelessWidget {
  final Map<String, dynamic> perfilAdmin;
  final bool eSuperAdmin;

  const AdminHomeScreen({
    super.key,
    required this.perfilAdmin,
    required this.eSuperAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final instituicaoId = perfilAdmin['instituicaoId'] as String? ?? '';
    final instituicaoNome = perfilAdmin['instituicaoNome'] as String? ?? '';
    final nomeAdmin = perfilAdmin['nome'] as String? ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, nomeAdmin, instituicaoNome),
              _buildMenuPrincipal(context, instituicaoId, instituicaoNome),
            ],
          ),
        ),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, String nomeAdmin, String instituicaoNome) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF121212)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: Color(0xFFD4AF37), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      eSuperAdmin ? 'Superadmin' : 'Admin',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'PAINEL DE ADMINISTRAÇÃO',
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Olá, $nomeAdmin',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            eSuperAdmin ? 'Acesso total ao sistema' : instituicaoNome,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── MENU PRINCIPAL ───────────────────────────────────────────────────────
  Widget _buildMenuPrincipal(
      BuildContext context, String instituicaoId, String instituicaoNome) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestão de Conteúdo',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Questões
          _ItemMenu(
            icone: Icons.quiz,
            titulo: 'Questões de Exame',
            subtitulo: 'Adicionar, editar e apagar questões',
            cor: const Color(0xFF007AFF),
            aoTapar: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminQuestoesScreen(
                  instituicaoId: instituicaoId,
                  eSuperAdmin: eSuperAdmin,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Conteúdo
          _ItemMenu(
            icone: Icons.account_balance,
            titulo: 'Instituições e Cursos',
            subtitulo: 'Gerir anos, disciplinas e planos',
            cor: const Color(0xFF34C759),
            aoTapar: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminConteudoScreen(
                  instituicaoId: instituicaoId,
                  eSuperAdmin: eSuperAdmin,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Gestão de Utilizadores',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Estatísticas
          _ItemMenu(
            icone: Icons.bar_chart,
            titulo: 'Estatísticas',
            subtitulo: 'Utilizadores, planos e desempenho',
            cor: const Color(0xFFFF9500),
            aoTapar: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminUtilizadoresScreen(
                  instituicaoId: eSuperAdmin ? null : instituicaoId,
                  eSuperAdmin: eSuperAdmin,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Pendentes (apenas superadmin)
          if (eSuperAdmin) ...[
            _ItemMenu(
              icone: Icons.pending_actions,
              titulo: 'Admins Pendentes',
              subtitulo: 'Aprovar ou rejeitar pedidos de acesso',
              cor: const Color(0xFFD4AF37),
              aoTapar: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminPendentesScreen(),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

// ── Item do menu ──────────────────────────────────────────────────────────────
class _ItemMenu extends StatelessWidget {
  final IconData icone;
  final String titulo;
  final String subtitulo;
  final Color cor;
  final VoidCallback aoTapar;

  const _ItemMenu({
    required this.icone,
    required this.titulo,
    required this.subtitulo,
    required this.cor,
    required this.aoTapar,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: aoTapar,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icone, color: cor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitulo,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
        ),
      ),
    );
  }
}