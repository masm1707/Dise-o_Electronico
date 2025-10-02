import 'package:flutter/material.dart';
import '../services/user_store.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _hasUser = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final exists = await UserStore.hasUser();
    setState(() => _hasUser = exists);
    if (exists) {
      final u = await UserStore.currentUser();
      if (u != null) _userCtrl.text = u;
    }
  }

  Future<void> _login() async {
    setState(() => _loading = true);
    final ok = await UserStore.validateLogin(_userCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);

    if (!ok) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos')),
        );
      }
      return;
    }

    await UserStore.setLoggedIn(true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/app');
    }
  }

  Future<void> _goRegister() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
    if (created == true && mounted) {
      Navigator.of(context).pushReplacementNamed('/app');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Usuario',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                  width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Entrar'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _goRegister,
              icon: const Icon(Icons.app_registration),
              label: Text(_hasUser ? 'Registrar otro usuario' : 'Crear cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}
