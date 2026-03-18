import 'package:flutter/material.dart';
import 'anos_screen.dart';

class CursosScreen extends StatefulWidget {
  final String instituicaoId;
  final String instituicaoSigla;
  final String instituicaoNome;

  const CursosScreen({
    Key? key,
    required this.instituicaoId,
    required this.instituicaoSigla,
    required this.instituicaoNome,
  }) : super(key: key);

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  final _searchController = TextEditingController();
  String _pesquisa = '';

  final Map<String, List<Map<String, String>>> _cursosPorInstituicao = {
    'uem': [
      {'nome': 'Medicina', 'disciplinas': 'Biologia, Química'},
      {'nome': 'Direito', 'disciplinas': 'Português, História'},
      {'nome': 'Engenharia Informática', 'disciplinas': 'Matemática, Física'},
      {'nome': 'Economia', 'disciplinas': 'Matemática, Português'},
      {'nome': 'Arquitectura', 'disciplinas': 'Matemática, Desenho'},
    ],
    'up': [
      {'nome': 'Ensino de Biologia', 'disciplinas': 'Biologia, Química'},
      {'nome': 'Ensino de Matemática', 'disciplinas': 'Matemática, Física'},
      {'nome': 'Ensino de Português', 'disciplinas': 'Português, História'},
      {'nome': 'Ensino de História', 'disciplinas': 'História, Português'},
    ],
    'isri': [
      {'nome': 'Relações Internacionais', 'disciplinas': 'Português, História'},
      {'nome': 'Diplomacia', 'disciplinas': 'Português, História'},
      {'nome': 'Ciência Política', 'disciplinas': 'Português, História'},
    ],
    'unizambeze': [
      {'nome': 'Gestão de Empresas', 'disciplinas': 'Matemática, Português'},
      {'nome': 'Contabilidade', 'disciplinas': 'Matemática, Português'},
      {'nome': 'Direito', 'disciplinas': 'Português, História'},
    ],
    'ucm': [
      {'nome': 'Medicina', 'disciplinas': 'Biologia, Química'},
      {'nome': 'Direito', 'disciplinas': 'Português, História'},
      {'nome': 'Gestão', 'disciplinas': 'Matemática, Português'},
    ],
    'ispu': [
      {'nome': 'Engenharia Informática', 'disciplinas': 'Matemática, Física'},
      {'nome': 'Engenharia Civil', 'disciplinas': 'Matemática, Física'},
      {'nome': 'Gestão', 'disciplinas': 'Matemática, Português'},
    ],
  };

  List<Map<String, String>> get _cursosFiltrados {
    final cursos = _cursosPorInstituicao[widget.instituicaoId] ?? [];
    if (_pesquisa.isEmpty) return cursos;
    return cursos.where((c) =>
      c['nome']!.toLowerCase().contains(_pesquisa.toLowerCase())
    ).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passo 2 de 4 — ${widget.instituicaoSigla}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const Text(
                        'Escolhe o teu Curso',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // BARRA DE PESQUISA
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _pesquisa = v),
                  decoration: InputDecoration(
                    hintText: 'Pesquisar curso...',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF007AFF)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: _pesquisa.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _pesquisa = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),

            // LISTA DE CURSOS
            Expanded(
              child: _cursosFiltrados.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum curso encontrado',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cursosFiltrados.length,
                      itemBuilder: (context, index) {
                        final curso = _cursosFiltrados[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnosScreen(
                                  instituicaoId: widget.instituicaoId,
                                  instituicaoSigla: widget.instituicaoSigla,
                                  cursoNome: curso['nome']!,
                                  disciplinas: curso['disciplinas']!,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F1FB),
                                    borderRadius: BorderRadius.circular(26),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book,
                                    color: Color(0xFF007AFF),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        curso['nome']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Disciplinas: ${curso['disciplinas']}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Licenciatura',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF007AFF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 20,
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
}