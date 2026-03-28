import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/app_dialog.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();
  bool _passwordVisivel = false;
  bool _lembrarMe = false;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _carregarEmailGuardado();
  }

  Future<void> _carregarEmailGuardado() async {
    final prefs = await SharedPreferences.getInstance();
    final emailGuardado = prefs.getString('email_guardado') ?? '';
    final lembrar = prefs.getBool('lembrar_me') ?? false;
    if (lembrar && emailGuardado.isNotEmpty) {
      setState(() {
        _emailController.text = emailGuardado;
        _lembrarMe = true;
      });
    }
  }

  Future<void> _guardarOuLimparEmail() async {
    final prefs = await SharedPreferences.getInstance();
    if (_lembrarMe) {
      await prefs.setString('email_guardado', _emailController.text.trim());
      await prefs.setBool('lembrar_me', true);
    } else {
      await prefs.remove('email_guardado');
      await prefs.setBool('lembrar_me', false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _carregando = true);

    await _guardarOuLimparEmail();

    final resultado = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _carregando = false);
    if (!mounted) return;

    if (resultado['sucesso']) {
      final onboardingFeito = await _authService.onboardingCompleto();
      if (!mounted) return;

      if (!onboardingFeito) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        final user = _authService.currentUser;
        final nome = user?.displayName ?? 'Estudante';
        await AppDialog.bemVindo(
          context: context,
          nome: nome,
          aoFechar: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          },
        );
      }
    } else {
      await AppDialog.erro(
        context: context,
        mensagem: resultado['erro'],
      );
    }
  }

  void _irParaRegisto() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegisterScreen()),
    );
  }

  Future<void> _recuperarPassword() async {
    final emailController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Insere o teu email para receber instrucoes de recuperacao.'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              Navigator.pop(context);
              final resultado = await _authService.recuperarPassword(
                email: emailController.text,
              );
              if (!context.mounted) return;
              if (resultado['sucesso']) {
                await AppDialog.emailEnviado(
                  context: context,
                  email: emailController.text,
                );
              } else {
                await AppDialog.erro(
                  context: context,
                  mensagem: resultado['erro'],
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007AFF),
            ),
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/logo_azul_nome.png',
                      width: 180,
                    ),
                  ),
                  const SizedBox(height: 48),
                  const Text(
                    'Bem-vindo de volta!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF007AFF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Entra para continuar a estudar',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) {
                      FocusScope.of(context).requestFocus(_passwordFocus);
                    },
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email, color: Color(0xFF007AFF)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, insere o teu email';
                      if (!value.contains('@')) return 'Email invalido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: !_passwordVisivel,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _carregando ? null : _entrar(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock, color: Color(0xFF007AFF)),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisivel ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFF007AFF),
                        ),
                        onPressed: () => setState(() => _passwordVisivel = !_passwordVisivel),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF007AFF), width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Por favor, insere a tua password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _lembrarMe,
                            onChanged: (value) => setState(() => _lembrarMe = value ?? false),
                            activeColor: const Color(0xFF007AFF),
                          ),
                          const Text('Lembrar-me'),
                        ],
                      ),
                      TextButton(
                        onPressed: _recuperarPassword,
                        child: const Text(
                          'Esqueci a password',
                          style: TextStyle(color: Color(0xFF007AFF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _carregando ? null : _entrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: _carregando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OU', style: TextStyle(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: _irParaRegisto,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF007AFF), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Criar Conta Nova',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF007AFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}