import 'package:flutter/material.dart';
import 'cursos_screen.dart';

class InstituicoesScreen extends StatefulWidget {
  const InstituicoesScreen({Key? key}) : super(key: key);

  @override
  State<InstituicoesScreen> createState() => _InstituicoesScreenState();
}

class _InstituicoesScreenState extends State<InstituicoesScreen> {
  final _searchController = TextEditingController();
  String _pesquisa = '';

  final List<Map<String, String>> _instituicoes = [
    {
      'id': 'uem',
      'sigla': 'UEM',
      'nome': 'Universidade Eduardo Mondlane',
      'cursos': '15 cursos disponíveis',
    },
    {
      'id': 'up',
      'sigla': 'UP',
      'nome': 'Universidade Pedagógica',
      'cursos': '8 cursos disponíveis',
    },
    {
      'id': 'isri',
      'sigla': 'ISRI',
      'nome': 'Inst. Sup. de Relações Internacionais',
      'cursos': '3 cursos disponíveis',
    },
    {
      'id': 'unizambeze',
      'sigla': 'UniZB',
      'nome': 'Universidade Zambeze',
      'cursos': '6 cursos disponíveis',
    },
    {
      'id': 'ucm',
      'sigla': 'UCM',
      'nome': 'Universidade Católica de Moçambique',
      'cursos': '5 cursos disponíveis',
    },
    {
      'id': 'ispu',
      'sigla': 'ISPU',
      'nome': 'Instituto Superior Politécnico e Universitário',
      'cursos': '7 cursos disponíveis',
    },
  ];

  List<Map<String, String>> get _instituicoesFiltradas {
    if (_pesquisa.isEmpty) return _instituicoes;
    return _instituicoes.where((i) =>
      i['sigla']!.toLowerCase().contains(_pesquisa.toLowerCase()) ||
      i['nome']!.toLowerCase().contains(_pesquisa.toLowerCase())
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // HEADER
            Container(
              width: double.infinity,
              color: const Color(0xFF007AFF),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Passo 1 de 4',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            'Escolhe a tua Instituição',
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
                    hintText: 'Pesquisar universidade...',
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

            // LISTA DE INSTITUIÇÕES
            Expanded(
              child: _instituicoesFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma instituição encontrada',
                            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _instituicoesFiltradas.length,
                      itemBuilder: (context, index) {
                        final inst = _instituicoesFiltradas[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CursosScreen(
                                  instituicaoId: inst['id']!,
                                  instituicaoSigla: inst['sigla']!,
                                  instituicaoNome: inst['nome']!,
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
                                  child: Center(
                                    child: Text(
                                      inst['sigla']!,
                                      style: const TextStyle(
                                        color: Color(0xFF007AFF),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
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
                                        inst['sigla']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF007AFF),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        inst['nome']!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        inst['cursos']!,
                                        style: const TextStyle(
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