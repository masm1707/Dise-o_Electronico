import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _form = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _pass1Ctrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _saving = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _pass1Ctrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _saving = true);
    final api = ApiService();

    // 1) Crear usuario
    final reg = await api.register(
      username: _userCtrl.text.trim(),
      password: _pass1Ctrl.text,
    );

    if (!mounted) return;

    if (!reg.ok) {
      setState(() => _saving = false);
      final msg = switch (reg.error) {
        'user_exists' => 'El usuario ya existe',
        'missing_fields' => 'Faltan datos',
        _ => reg.error ?? 'Error registrando',
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    // 2) Auto-login para guardar el token
    final login = await api.login(
      username: _userCtrl.text.trim(),
      password: _pass1Ctrl.text,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (login.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Sesión iniciada.')),
      );
      Navigator.of(context).pop(true); // -> vuelve a Login/AuthGate con éxito
    } else {
      // Usuario creado pero no se pudo iniciar sesión: vuelve con false
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta creada. Inicia sesión.')),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: ListView(
              children: [
                const SizedBox(height: 12),
                TextFormField(
                  controller: _userCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Ingresa un usuario' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pass1Ctrl,
                  obscureText: _obscure1,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure1 = !_obscure1),
                      icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (v) =>
                  (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pass2Ctrl,
                  obscureText: _obscure2,
                  decoration: InputDecoration(
                    labelText: 'Repite la contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                      icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                  validator: (v) =>
                  (v != _pass1Ctrl.text) ? 'Las contraseñas no coinciden' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _doRegister,
                  child: _saving
                      ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
