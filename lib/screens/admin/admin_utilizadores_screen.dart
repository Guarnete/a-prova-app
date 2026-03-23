import 'package:flutter/material.dart';

class AdminUtilizadoresScreen extends StatelessWidget {
  final String? instituicaoId;
  final bool eSuperAdmin;
  const AdminUtilizadoresScreen({super.key, this.instituicaoId, required this.eSuperAdmin});
  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Color(0xFF121212),
    body: Center(child: Text('Utilizadores — em construção', style: TextStyle(color: Colors.white))),
  );
}