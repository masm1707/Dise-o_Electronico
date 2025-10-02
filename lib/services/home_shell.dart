import 'package:flutter/material.dart';
import '../services/user_store.dart';

class HomeShell extends StatefulWidget {
  final Widget child;
  const HomeShell({super.key, required this.child});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  String _username = 'Usuario';

  @override
  void initState() {
    super.initState();
    UserStore.currentUser().then((v) => setState(() => _username = v ?? 'Usuario'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoAlerta'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Cuenta',
            icon: const CircleAvatar(child: Icon(Icons.person)),
            onSelected: (value) async {
              if (value == 'pfp') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('En desarrollo')),
                );
              } else if (value == 'cfg') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('En desarrollo')),
                );
              } else if (value == 'theme') {
                // alterna tema
                final isDark = Theme.of(context).brightness == Brightness.dark;
                final newMode = isDark ? 'light' : 'dark';
                await UserStore.setThemeMode(newMode);
                // recarga tema notificando a MyApp (lo hace al volver)
                if (mounted) setState(() {});
              } else if (value == 'logout') {
                await UserStore.setLoggedIn(false);
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
                }
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'header',
                enabled: false,
                child: Text(_username, style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'pfp', child: Text('Cambiar foto de perfil')),
              const PopupMenuItem(value: 'cfg', child: Text('Configuraciones')),
              const PopupMenuItem(value: 'theme', child: Text('Modo claro/oscuro')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [Icon(Icons.logout), SizedBox(width: 8), Text('Log out')],
                ),
              ),
            ],
          ),
        ],
      ),
      body: widget.child,
    );
  }
}
