import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/forum_service.dart';

class ForumPostScreen extends StatefulWidget {
  final String postId;
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final String disciplinas;

  const ForumPostScreen({
    super.key,
    required this.postId,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.disciplinas,
  });

  @override
  State<ForumPostScreen> createState() => _ForumPostScreenState();
}

class _ForumPostScreenState extends State<ForumPostScreen> {
  final ForumService _forumService = ForumService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _respostaController = TextEditingController();

  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _respostas = [];
  bool _carregando = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  @override
  void dispose() {
    _respostaController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    setState(() => _carregando = true);
    try {
      final results = await Future.wait([
        _forumService.carregarPosts(
          instituicaoId: widget.instituicaoId,
          cursoNome: widget.cursoNome,
        ),
        _forumService.carregarRespostas(widget.postId),
      ]);

      final posts = results[0];
      final respostas = results[1];
      final post = posts.where((p) => p['id'] == widget.postId).firstOrNull;

      if (mounted) {
        setState(() {
          _post = post;
          _respostas = respostas;
          _carregando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _enviarResposta() async {
    if (_respostaController.text.trim().isEmpty) return;
    setState(() => _enviando = true);
    await _forumService.criarResposta(
      postId: widget.postId,
      corpo: _respostaController.text.trim(),
    );
    _respostaController.clear();
    await _carregarTudo();
    setState(() => _enviando = false);
  }

  String _formatarData(dynamic timestamp) {
    if (timestamp == null) return '-';
    try {
      final dt = (timestamp as dynamic).toDate() as DateTime;
      final agora = DateTime.now();
      final diff = agora.difference(dt);
      if (diff.inMinutes < 1) return 'agora';
      if (diff.inMinutes < 60) return '${diff.inMinutes}min';
      if (diff.inHours < 24) return '${diff.inHours}h';
      if (diff.inDays < 7) return '${diff.inDays}d';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '-';
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
            _carregando
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                    ),
                  )
                : _post == null
                    ? const Expanded(
                        child: Center(
                          child: Text('Post nao encontrado.',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : _buildConteudo(),
            _buildCaixaResposta(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF007AFF),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                const Text('FORUM',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const Text('Detalhe da duvida',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConteudo() {
    final post = _post!;
    final titulo = post['titulo'] as String? ?? '';
    final corpo = post['corpo'] as String? ?? '';
    final autorNome = post['autorNome'] as String? ?? 'Estudante';
    final disciplina = post['disciplina'] as String? ?? '';
    final totalVotos = post['totalVotos'] as int? ?? 0;
    final data = _formatarData(post['criadoEm']);
    final votantes = List<String>.from(post['votantes'] ?? []);
    final jaVotou = votantes.contains(_auth.currentUser?.uid);
    final eAutor = post['autorId'] == _auth.currentUser?.uid;

    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card do post principal
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Disciplina + data
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(disciplina,
                            style: const TextStyle(
                                color: Color(0xFF007AFF),
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                      const Spacer(),
                      Text(data,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Titulo
                  Text(titulo,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),

                  // Corpo
                  Text(corpo,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF444444),
                          height: 1.5)),
                  const SizedBox(height: 14),

                  // Footer
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: const Color(0xFFE6F1FB),
                        child: Text(
                          autorNome.isNotEmpty
                              ? autorNome[0].toUpperCase()
                              : 'E',
                          style: const TextStyle(
                              color: Color(0xFF007AFF),
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          eAutor ? 'Tu' : autorNome,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Votar
                      GestureDetector(
                        onTap: () async {
                          await _forumService.votarPost(widget.postId);
                          await _carregarTudo();
                        },
                        child: Row(
                          children: [
                            Icon(
                              jaVotou
                                  ? Icons.thumb_up
                                  : Icons.thumb_up_outlined,
                              color: jaVotou
                                  ? const Color(0xFF007AFF)
                                  : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 4),
                            Text('$totalVotos',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: jaVotou
                                        ? const Color(0xFF007AFF)
                                        : Colors.grey,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Denunciar
                      GestureDetector(
                        onTap: () async {
                          await _forumService.denunciarPost(widget.postId);
                          await _forumService
                              .verificarDenunciasPost(widget.postId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Denuncia registada.'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        },
                        child: const Icon(Icons.flag_outlined,
                            color: Colors.grey, size: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cabecalho respostas
          Row(
            children: [
              Text(
                '${_respostas.length} resposta${_respostas.length != 1 ? 's' : ''}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A1A)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Lista de respostas
          ..._respostas.map((r) => _buildCardResposta(r)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildCardResposta(Map<String, dynamic> resposta) {
    final corpo = resposta['corpo'] as String? ?? '';
    final autorNome = resposta['autorNome'] as String? ?? 'Estudante';
    final totalVotos = resposta['totalVotos'] as int? ?? 0;
    final data = _formatarData(resposta['criadoEm']);
    final votantes = List<String>.from(resposta['votantes'] ?? []);
    final jaVotou = votantes.contains(_auth.currentUser?.uid);
    final eAutor = resposta['autorId'] == _auth.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: eAutor
            ? const Color(0xFF007AFF).withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: eAutor
              ? const Color(0xFF007AFF).withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(corpo,
                style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    height: 1.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFE6F1FB),
                  child: Text(
                    autorNome.isNotEmpty ? autorNome[0].toUpperCase() : 'E',
                    style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    eAutor ? 'Tu' : autorNome,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(data,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () async {
                    await _forumService.votarResposta(
                      postId: widget.postId,
                      respostaId: resposta['id'] as String,
                    );
                    await _carregarTudo();
                  },
                  child: Row(
                    children: [
                      Icon(
                        jaVotou ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color:
                            jaVotou ? const Color(0xFF007AFF) : Colors.grey,
                        size: 15,
                      ),
                      const SizedBox(width: 3),
                      Text('$totalVotos',
                          style: TextStyle(
                              fontSize: 12,
                              color: jaVotou
                                  ? const Color(0xFF007AFF)
                                  : Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () async {
                    await _forumService.denunciarResposta(
                      postId: widget.postId,
                      respostaId: resposta['id'] as String,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Denuncia registada.'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: const Icon(Icons.flag_outlined,
                      color: Colors.grey, size: 15),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaixaResposta() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _respostaController,
              maxLines: null,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              decoration: InputDecoration(
                hintText: 'Escreve a tua resposta...',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF007AFF))),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _enviando ? null : _enviarResposta,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _enviando
                    ? Colors.grey.shade300
                    : const Color(0xFF007AFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _enviando
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}