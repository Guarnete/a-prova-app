import 'package:flutter/material.dart';
import '../../services/admin_service.dart';

class AdminUtilizadoresScreen extends StatefulWidget {
  final String? instituicaoId;
  final bool eSuperAdmin;

  const AdminUtilizadoresScreen({
    super.key,
    this.instituicaoId,
    required this.eSuperAdmin,
  });

  @override
  State<AdminUtilizadoresScreen> createState() =>
      _AdminUtilizadoresScreenState();
}

class _AdminUtilizadoresScreenState extends State<AdminUtilizadoresScreen> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _estatisticas = {};
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarEstatisticas();
  }

  Future<void> _carregarEstatisticas() async {
    setState(() => _carregando = true);
    try {
      final stats = await _adminService.carregarEstatisticas(
        instituicaoId: widget.instituicaoId,
      );
      setState(() {
        _estatisticas = stats;
        _carregando = false;
      });
    } catch (e) {
      setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _carregando
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFFF9500)),
                    ),
                  )
                : _buildConteudo(),
          ],
        ),
      ),
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
              child: const Icon(Icons.arrow_back,
                  color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ESTATÍSTICAS',
                style: TextStyle(
                  color: Color(0xFFFF9500),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                'Utilizadores e Planos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _carregarEstatisticas,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    final total = _estatisticas['totalUtilizadores'] as int? ?? 0;
    final gratuitos = _estatisticas['planosGratuitos'] as int? ?? 0;
    final pagos = _estatisticas['planosPagos'] as int? ?? 0;
    final taxaConversao = total > 0 ? (pagos / total * 100) : 0.0;

    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cards principais
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    titulo: 'Total',
                    valor: '$total',
                    subtitulo: 'utilizadores',
                    icone: Icons.people,
                    cor: const Color(0xFF007AFF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    titulo: 'Pagos',
                    valor: '$pagos',
                    subtitulo: 'subscrições',
                    icone: Icons.star,
                    cor: const Color(0xFFD4AF37),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    titulo: 'Gratuitos',
                    valor: '$gratuitos',
                    subtitulo: 'plano free',
                    icone: Icons.person_outline,
                    cor: const Color(0xFF34C759),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    titulo: 'Conversão',
                    valor: '${taxaConversao.toStringAsFixed(1)}%',
                    subtitulo: 'free → pago',
                    icone: Icons.trending_up,
                    cor: const Color(0xFFFF9500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Barra de distribuição de planos
            Text(
              'Distribuição de planos',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07)),
              ),
              child: Column(
                children: [
                  _BarraPlano(
                    label: 'Gratuito',
                    valor: gratuitos,
                    total: total,
                    cor: const Color(0xFF007AFF),
                  ),
                  const SizedBox(height: 12),
                  _BarraPlano(
                    label: 'Pagos',
                    valor: pagos,
                    total: total,
                    cor: const Color(0xFFD4AF37),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nota informativa
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9500).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFFFF9500).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: Color(0xFFFF9500), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Estatísticas actualizadas em tempo real do Firebase.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
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
}

class _StatCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final String subtitulo;
  final IconData icone;
  final Color cor;

  const _StatCard({
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    required this.icone,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icone, color: cor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitulo,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarraPlano extends StatelessWidget {
  final String label;
  final int valor;
  final int total;
  final Color cor;

  const _BarraPlano({
    required this.label,
    required this.valor,
    required this.total,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final percentagem = total > 0 ? valor / total : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text(
              '$valor (${(percentagem * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                  color: cor, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentagem,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
          ),
        ),
      ],
    );
  }
}