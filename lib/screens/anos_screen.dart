import 'package:flutter/material.dart';
import 'disciplinas_screen.dart';

class AnosScreen extends StatelessWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final String disciplinas;

  const AnosScreen({
    super.key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.disciplinas,
  });

  static const List<Map<String, dynamic>> _anos = [
    {'ano': 2020, 'tier': 'Prata', 'bloqueado': false, 'cor': Color(0xFF007AFF)},
    {'ano': 2021, 'tier': 'Prata', 'bloqueado': false, 'cor': Color(0xFF007AFF)},
    {'ano': 2022, 'tier': 'Prata', 'bloqueado': false, 'cor': Color(0xFF007AFF)},
    {'ano': 2023, 'tier': 'Ouro', 'bloqueado': true, 'cor': Color(0xFFD4AF37)},
    {'ano': 2024, 'tier': 'Ouro', 'bloqueado': true, 'cor': Color(0xFFD4AF37)},
    {'ano': 2025, 'tier': 'Ouro', 'bloqueado': true, 'cor': Color(0xFFD4AF37)},
    {'ano': 2026, 'tier': 'Ouro', 'bloqueado': true, 'cor': Color(0xFFD4AF37)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              width: double.infinity,
              color: const Color(0xFF007AFF),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Passo 3 de 4 — $instituicaoSigla',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const Text(
                          'Escolhe o Ano do Exame',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cursoNome,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // LEGENDA
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _LegendaItem(cor: const Color(0xFF007AFF), texto: 'Prata — Grátis'),
                  const SizedBox(width: 20),
                  _LegendaItem(cor: const Color(0xFFD4AF37), texto: 'Ouro — Premium'),
                ],
              ),
            ),

            // GRID DE ANOS
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: _anos.length,
                itemBuilder: (context, index) {
                  final item = _anos[index];
                  final bloqueado = item['bloqueado'] as bool;
                  final cor = item['cor'] as Color;

                  return GestureDetector(
                    onTap: () {
                      if (bloqueado) {
                        _mostrarDialogPremium(context, item['ano'] as int);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DisciplinasScreen(
                              instituicaoSigla: instituicaoSigla,
                              cursoNome: cursoNome,
                              ano: item['ano'] as int,
                              disciplinas: disciplinas,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bloqueado ? Colors.grey.shade100 : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: bloqueado ? Colors.grey.shade300 : cor,
                          width: 2,
                        ),
                        boxShadow: bloqueado ? [] : [
                          BoxShadow(
                            color: cor.withValues(alpha: 0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Ícone
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: bloqueado ? Colors.grey.shade200 : cor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Icon(
                              bloqueado ? Icons.lock : Icons.lock_open,
                              color: bloqueado ? Colors.grey.shade400 : cor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Ano
                          Text(
                            '${item['ano']}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: bloqueado ? Colors.grey.shade400 : cor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Badge tier
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: bloqueado ? Colors.grey.shade200 : cor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['tier'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: bloqueado ? Colors.grey.shade400 : cor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogPremium(BuildContext context, int ano) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🔒', style: TextStyle(fontSize: 32)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Conteúdo Premium',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'O exame de $ano requer o plano Gold. Faz upgrade para aceder a todos os anos premium.',
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Ver Planos Gold',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Agora não', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final Color cor;
  final String texto;

  const _LegendaItem({required this.cor, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(texto, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}