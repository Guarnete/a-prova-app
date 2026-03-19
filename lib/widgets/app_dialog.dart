import 'package:flutter/material.dart';

class AppDialog {
  static Future<void> mostrar({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    required String emoji,
    Color corEmoji = const Color(0xFF007AFF),
    String textoBotao = 'OK',
    VoidCallback? aoFechar,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Círculo com emoji
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: corEmoji.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 38),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Título
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              // Mensagem
              Text(
                mensagem,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Botão
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (aoFechar != null) aoFechar();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    textoBotao,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Diálogo de SUCESSO
  static Future<void> sucesso({
    required BuildContext context,
    required String titulo,
    required String mensagem,
    VoidCallback? aoFechar,
  }) async {
    await mostrar(
      context: context,
      titulo: titulo,
      mensagem: mensagem,
      emoji: '🎉',
      corEmoji: Colors.green,
      aoFechar: aoFechar,
    );
  }

  // Diálogo de ERRO
  static Future<void> erro({
    required BuildContext context,
    required String mensagem,
  }) async {
    await mostrar(
      context: context,
      titulo: 'Algo correu mal',
      mensagem: mensagem,
      emoji: '❌',
      corEmoji: Colors.red,
    );
  }

  // Diálogo de BEM-VINDO
  static Future<void> bemVindo({
    required BuildContext context,
    required String nome,
    VoidCallback? aoFechar,
  }) async {
    final primeiroNome = nome.split(' ').first;
    await mostrar(
      context: context,
      titulo: 'Seja bem-vindo, $primeiroNome!',
      mensagem: 'Estás pronto para conquistar o teu exame. Vamos estudar!',
      emoji: '👋',
      corEmoji: const Color(0xFF007AFF),
      textoBotao: 'Vamos lá!',
      aoFechar: aoFechar,
    );
  }

  // Diálogo de EMAIL ENVIADO
  static Future<void> emailEnviado({
    required BuildContext context,
    required String email,
  }) async {
    await mostrar(
      context: context,
      titulo: 'Email enviado!',
      mensagem: 'Enviámos instruções de recuperação para $email. Verifica a tua caixa de entrada.',
      emoji: '📧',
      corEmoji: const Color(0xFF007AFF),
    );
  }
}