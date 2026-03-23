import 'package:flutter/material.dart';

class AdminConteudoScreen extends StatelessWidget {
  final String instituicaoId;
  final bool eSuperAdmin;
  const AdminConteudoScreen({super.key, required this.instituicaoId, required this.eSuperAdmin});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF121212),
    body: Center(child: Text('Conteúdo — em construção', style: TextStyle(color: Colors.white))),
  );
}