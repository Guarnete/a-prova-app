import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/forum_service.dart';
import 'forum_post_screen.dart';

class ForumScreen extends StatefulWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String cursoNome;
  final String disciplinas;

  const ForumScreen({
    super.key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.cursoNome,
    required this.disciplinas,
  });

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  final ForumService _forumService = ForumService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _posts = [];
  bool _carregando = true;
  String? _disciplinaActiva;

  List<String> get _listaDisciplinas =>
      widget.disciplinas.split(',').map((d) => d.trim()).where((d) => d.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    _carregarPosts();
  }

  Future<void> _carregarPosts() async {
    setState(() => _carregando = true);
    try {
      final posts = await _forumService.carregarPosts(
        instituicaoId: widget.instituicaoId,
        cursoNome: widget.cursoNome,
        disciplina: _disciplinaActiva,
      );
      if (mounted) setState(() { _posts = posts; _carregando = false; });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
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
    } catch (_) { return '-'; }
  }

  void _abrirNovoPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioPost(
        disciplinas: _listaDisciplinas,
        disciplinaInicial: _disciplinaActiva,
        onPublicar: (titulo, corpo, disciplina) async {
          await _forumService.criarPost(
            titulo: titulo,
            corpo: corpo,
            instituicaoId: widget.instituicaoId,
            cursoNome: widget.cursoNome,
            disciplina: disciplina,
          );
          await _carregarPosts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildFiltrosDisciplina(),
            _carregando
                ? const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF007AFF)),
                    ),
                  )
                : _posts.isEmpty
                    ? _buildVazio()
                    : _buildLista(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoPost,
        backgroundColor: const Color(0xFF007AFF),
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('Nova Duvida',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                const Text('FORUM',
                    style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11,
                        fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                const Text('Duvidas e respostas',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('${widget.instituicaoSigla} - ${widget.cursoNome}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _carregarPosts,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.refresh, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosDisciplina() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ChipDisciplina(
              label: 'Todas',
              activo: _disciplinaActiva == null,
              onTap: () {
                setState(() => _disciplinaActiva = null);
                _carregarPosts();
              },
            ),
            ..._listaDisciplinas.map((d) => _ChipDisciplina(
              label: d,
              activo: _disciplinaActiva == d,
              onTap: () {
                setState(() => _disciplinaActiva = d);
                _carregarPosts();
              },
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildVazio() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.forum_outlined, color: Colors.grey.shade300, size: 72),
            const SizedBox(height: 16),
            Text(
              _disciplinaActiva == null
                  ? 'Ainda nao ha duvidas publicadas'
                  : 'Sem duvidas em $_disciplinaActiva',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 8),
            const Text('Se o primeiro a colocar uma duvida!',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildLista() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: _carregarPosts,
        color: const Color(0xFF007AFF),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: _posts.length,
          itemBuilder: (context, index) => _buildCardPost(_posts[index]),
        ),
      ),
    );
  }

  Widget _buildCardPost(Map<String, dynamic> post) {
    final titulo = post['titulo'] as String? ?? '';
    final corpo = post['corpo'] as String? ?? '';
    final autorNome = post['autorNome'] as String? ?? 'Estudante';
    final disciplina = post['disciplina'] as String? ?? '';
    final totalRespostas = post['totalRespostas'] as int? ?? 0;
    final totalVotos = post['totalVotos'] as int? ?? 0;
    final data = _formatarData(post['criadoEm']);
    final eAutor = post['autorId'] == _auth.currentUser?.uid;
    final votantes = List<String>.from(post['votantes'] ?? []);
    final jaVotou = votantes.contains(_auth.currentUser?.uid);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ForumPostScreen(
            postId: post['id'] as String,
            instituicaoId: widget.instituicaoId,
            instituicaoSigla: widget.instituicaoSigla,
            cursoNome: widget.cursoNome,
            disciplinas: widget.disciplinas,
          ),
        ),
      ).then((_) => _carregarPosts()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(disciplina,
                        style: const TextStyle(color: Color(0xFF007AFF),
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  Text(data,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text(titulo,
                  style: const TextStyle(fontWeight: FontWeight.bold,
                      fontSize: 15, color: Color(0xFF1A1A1A))),
              const SizedBox(height: 4),
              Text(
                corpo.length > 100 ? '${corpo.substring(0, 100)}...' : corpo,
                style: const TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFFE6F1FB),
                    child: Text(
                      autorNome.isNotEmpty ? autorNome[0].toUpperCase() : 'E',
                      style: const TextStyle(color: Color(0xFF007AFF),
                          fontSize: 11, fontWeight: FontWeight.bold),
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
                  GestureDetector(
                    onTap: () async {
                      await _forumService.votarPost(post['id'] as String);
                      await _carregarPosts();
                    },
                    child: Row(
                      children: [
                        Icon(
                          jaVotou ? Icons.thumb_up : Icons.thumb_up_outlined,
                          color: jaVotou ? const Color(0xFF007AFF) : Colors.grey,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('$totalVotos',
                            style: TextStyle(
                              fontSize: 12,
                              color: jaVotou ? const Color(0xFF007AFF) : Colors.grey,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text('$totalRespostas',
                          style: const TextStyle(fontSize: 12, color: Colors.grey,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 14),
                  GestureDetector(
                    onTap: () async {
                      await _forumService.denunciarPost(post['id'] as String);
                      await _forumService.verificarDenunciasPost(post['id'] as String);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Denuncia registada.'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                      await _carregarPosts();
                    },
                    child: const Icon(Icons.flag_outlined, color: Colors.grey, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Chip de disciplina ────────────────────────────────────────────────────────
class _ChipDisciplina extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;

  const _ChipDisciplina({
    required this.label,
    required this.activo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? const Color(0xFF007AFF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: activo ? const Color(0xFF007AFF) : Colors.grey.shade300,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              color: activo ? Colors.white : Colors.grey.shade600,
              fontSize: 12,
              fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

// ── Formulario de novo post ───────────────────────────────────────────────────
class _FormularioPost extends StatefulWidget {
  final List<String> disciplinas;
  final String? disciplinaInicial;
  final Future<void> Function(String titulo, String corpo, String disciplina) onPublicar;

  const _FormularioPost({
    required this.disciplinas,
    required this.disciplinaInicial,
    required this.onPublicar,
  });

  @override
  State<_FormularioPost> createState() => _FormularioPostState();
}

class _FormularioPostState extends State<_FormularioPost> {
  final _tituloController = TextEditingController();
  final _corpoController = TextEditingController();
  late String _disciplinaSel;
  bool _publicando = false;

  @override
  void initState() {
    super.initState();
    _disciplinaSel = widget.disciplinaInicial ?? widget.disciplinas.first;
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _corpoController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (_tituloController.text.trim().isEmpty ||
        _corpoController.text.trim().isEmpty) { return; }
    setState(() => _publicando = true);
    await widget.onPublicar(
      _tituloController.text.trim(),
      _corpoController.text.trim(),
      _disciplinaSel,
    );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(child: Container(
            margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Text('Nova Duvida',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A))),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade200),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Disciplina *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.disciplinas.map((d) {
                        final activo = d == _disciplinaSel;
                        return GestureDetector(
                          onTap: () => setState(() => _disciplinaSel = d),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
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
                            child: Text(d,
                                style: TextStyle(
                                  color: activo ? Colors.white : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight: activo ? FontWeight.w600 : FontWeight.w400,
                                )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Titulo *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _tituloController,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Ex: Como resolver equacoes do 2 grau?',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF007AFF))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Descricao da duvida *',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _corpoController,
                    maxLines: 5,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                    decoration: InputDecoration(
                      hintText: 'Descreve a tua duvida em detalhe...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: const Color(0xFFF5F7FA),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF007AFF))),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _publicando ? null : _publicar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF007AFF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _publicando
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Publicar Duvida',
                              style: TextStyle(color: Colors.white,
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}