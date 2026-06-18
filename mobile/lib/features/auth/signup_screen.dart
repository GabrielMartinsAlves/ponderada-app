import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/network/api_exception.dart';
import '../../shared/widgets/lumma_brand.dart';
import 'auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});
  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _tel = TextEditingController();
  final _senha = TextEditingController();
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _tel.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();
    if (_nome.text.trim().isEmpty || _email.text.trim().isEmpty || _senha.text.length < 6) {
      setState(() => _erro = 'Preencha nome, e-mail e senha (mínimo 6 caracteres).');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).signup(
            nome: _nome.text.trim(),
            email: _email.text.trim(),
            telefone: _tel.text.trim(),
            senha: _senha.text,
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _erro = e.message);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Não foi possível cadastrar');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: LummaWordmark(fontSize: 24)),
              const SizedBox(height: 8),
              const Center(child: Text('Crie sua conta', style: TextStyle(fontSize: 16, color: Color(0xFF7A6470)))),
              const SizedBox(height: 28),
              TextField(controller: _nome, decoration: const InputDecoration(hintText: 'Nome completo', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 14),
              TextField(controller: _email, decoration: const InputDecoration(hintText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)), keyboardType: TextInputType.emailAddress, autocorrect: false),
              const SizedBox(height: 14),
              TextField(controller: _tel, decoration: const InputDecoration(hintText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
              const SizedBox(height: 14),
              TextField(controller: _senha, decoration: const InputDecoration(hintText: 'Senha', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
              if (_erro != null) ...[const SizedBox(height: 14), ErroBox(_erro!)],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _cadastrar,
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Cadastrar'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _loading ? null : () => context.go('/login'), child: const Text('Já tenho conta')),
            ],
          ),
        ),
      ),
    );
  }
}
