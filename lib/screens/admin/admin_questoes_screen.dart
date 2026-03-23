import 'package:flutter/material.dart';

class AdminQuestoesScreen extends StatelessWidget {
  final String instituicaoId;
  final bool eSuperAdmin;
  const AdminQuestoesScreen({super.key, required this.instituicaoId, required this.eSuperAdmin});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF121212),
    body: Center(child: Text('Questões — em construção', style: TextStyle(color: Colors.white))),
  );
}