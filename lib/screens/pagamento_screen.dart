import 'package:flutter/material.dart';
import '../services/pagamento_service.dart';
import 'home_screen.dart';

class PagamentoScreen extends StatefulWidget {
  final String planoId;
  final String nomePlano;
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final double valor;
  final String duracao;
  final Color corPlano;

  const PagamentoScreen({
    super.key,
    required this.planoId,
    required this.nomePlano,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.valor,
    required this.duracao,
    required this.corPlano,
  });

  @override
  State<PagamentoScreen> createState() => _PagamentoScreenState();
}

class _PagamentoScreenState extends State<PagamentoScreen> {
  final PagamentoService _pagamentoService = PagamentoService();
  final TextEditingController _contactoController = TextEditingController();

  String _metodo = 'mpesa';
  bool _processando = false;
  bool _concluido = false;
  String _referencia = '';
  String _erro = '';

  static const Map<String, String> _nomesMetodo = {
    'mpesa': 'M-Pesa',
    'emola': 'e-Mola',
    'visa': 'Visa / Mastercard',
  };

  static const Map<String, IconData> _iconesMetodo = {
    'mpesa': Icons.phone_android,
    'emola': Icons.smartphone,
    'visa': Icons.credit_card,
  };

  static const Map<String, String> _hintContacto = {
    'mpesa': 'Ex: 84XXXXXXX',
    'emola': 'Ex: 86XXXXXXX',
    'visa': 'Ex: 4111 1111 1111 1111',
  };

  @override
  void dispose() {
    _contactoController.dispose();
    super.dispose();
  }

  Future<void> _processarPagamento() async {
    if (_contactoController.text.trim().isEmpty) {
      setState(() => _erro = 'Preenche o campo de contacto.');
      return;
    }
    setState(() { _processando = true; _erro = ''; });

    final resultado = await _pagamentoService.iniciarPagamento(
      plano: widget.planoId,
      instituicaoId: widget.instituicaoId,
      cursoNome: widget.cursoNome,
      metodo: _metodo,
      contacto: _contactoController.text.trim(),
      valor: widget.valor,
    );

    if (!mounted) return;

    if (resultado['sucesso'] == true) {
      setState(() {
        _processando = false;
        _concluido = true;
        _referencia = resultado['referencia'] as String? ?? '';
      });
    } else {
      setState(() {
        _processando = false;
        _erro = resultado['erro'] as String? ?? 'Erro ao processar pagamento.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _concluido ? _buildSucesso() : _buildFormulario(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: widget.corPlano,
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
                const Text('PAGAMENTO',
                    style: TextStyle(color: Colors.white70, fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                Text('Plano ${widget.nomePlano}',
                    style: const TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text(
                  '${widget.valor.toStringAsFixed(0)} MT / ${widget.duracao}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulario() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Resumo da subscricao',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 14, color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 12),
                  _LinhaResumo(label: 'Plano', valor: widget.nomePlano),
                  _LinhaResumo(
                      label: 'Instituicao',
                      valor: '${widget.instituicaoSigla} - ${widget.cursoNome}'),
                  _LinhaResumo(
                      label: 'Duracao',
                      valor: widget.duracao == 'ano' ? '1 ano' : '1 mes'),
                  Divider(color: Colors.grey.shade200),
                  _LinhaResumo(
                    label: 'Total',
                    valor: '${widget.valor.toStringAsFixed(0)} MT',
                    destaque: true,
                    cor: widget.corPlano,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Metodo de pagamento
            const Text('Metodo de pagamento',
                style: TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 14, color: Color(0xFF1A1A1A))),
            const SizedBox(height: 12),

            Row(
              children: ['mpesa', 'emola', 'visa'].map((m) {
                final activo = _metodo == m;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _metodo = m;
                      _contactoController.clear();
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: EdgeInsets.only(
                          right: m != 'visa' ? 8 : 0),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: activo
                            ? widget.corPlano.withValues(alpha: 0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: activo
                              ? widget.corPlano
                              : Colors.grey.shade200,
                          width: activo ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(_iconesMetodo[m],
                              color: activo
                                  ? widget.corPlano
                                  : Colors.grey,
                              size: 22),
                          const SizedBox(height: 4),
                          Text(
                            m == 'visa' ? 'Cartao' : _nomesMetodo[m]!,
                            style: TextStyle(
                              fontSize: 10,
                              color: activo
                                  ? widget.corPlano
                                  : Colors.grey,
                              fontWeight: activo
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Campo contacto
            Text(
              _metodo == 'visa' ? 'Numero do cartao' : 'Numero de telefone',
              style: const TextStyle(fontWeight: FontWeight.bold,
                  fontSize: 14, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contactoController,
              keyboardType: _metodo == 'visa'
                  ? TextInputType.number
                  : TextInputType.phone,
              style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: _hintContacto[_metodo],
                hintStyle: TextStyle(
                    color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(_iconesMetodo[_metodo],
                    color: widget.corPlano, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: widget.corPlano)),
              ),
            ),

            // Erro
            if (_erro.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_erro,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Nota modo simulado
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.science_outlined,
                      color: Colors.orange, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Modo de demonstracao: nenhum pagamento real sera processado.',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Botao pagar
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _processando ? null : _processarPagamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.corPlano,
                  disabledBackgroundColor:
                      widget.corPlano.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _processando
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          ),
                          SizedBox(width: 12),
                          Text('A processar...',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ],
                      )
                    : Text(
                        'Pagar ${widget.valor.toStringAsFixed(0)} MT',
                        style: const TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSucesso() {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle,
                  color: Colors.green, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Pagamento confirmado!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A))),
            const SizedBox(height: 8),
            Text(
              'O teu plano ${widget.nomePlano} esta activo para ${widget.cursoNome}.',
              style: const TextStyle(fontSize: 14, color: Colors.grey,
                  height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _LinhaResumo(label: 'Plano', valor: widget.nomePlano),
                  _LinhaResumo(
                      label: 'Metodo',
                      valor: _nomesMetodo[_metodo] ?? _metodo),
                  _LinhaResumo(label: 'Referencia', valor: _referencia),
                  _LinhaResumo(
                      label: 'Valor',
                      valor: '${widget.valor.toStringAsFixed(0)} MT',
                      destaque: true,
                      cor: Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const HomeScreen()),
                  (route) => false,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.corPlano,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Ir para o inicio',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
class _LinhaResumo extends StatelessWidget {
  final String label;
  final String valor;
  final bool destaque;
  final Color? cor;

  const _LinhaResumo({
    required this.label,
    required this.valor,
    this.destaque = false,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(valor,
              style: TextStyle(
                fontSize: destaque ? 15 : 13,
                fontWeight: destaque ? FontWeight.bold : FontWeight.w500,
                color: cor ?? const Color(0xFF1A1A1A),
              )),
        ],
      ),
    );
  }
}