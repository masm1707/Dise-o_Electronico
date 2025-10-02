// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ========================
/// CONFIG
/// ========================
///
// IP/host de tu backend Flask
const String apiBase = 'http://18.221.30.184:8080';

/// Tema global
final ValueNotifier<bool> _isDark = ValueNotifier<bool>(false);

/// Usuario logueado actual (solo nombre para mostrar)
String? _loggedUser;

/// ========================
/// AUTH STORE (sesión + llamadas HTTP)
/// ========================
class AuthStore {
  static const _kLogged = 'logged_in';
  static const _kUser = 'user_name';
  static const _kJwt = 'jwt';

  // ---- Helpers de storage ----
  static Future<void> _setLogged(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kLogged, v);
  }

  static Future<void> _setUser(String u) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kUser, u);
  }

  static Future<void> _setJwt(String jwt) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kJwt, jwt);
  }

  static Future<String?> getJwt() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kJwt);
  }

  static Future<String?> getUser() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kUser);
  }

  static Future<bool> isLocallyLogged() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kLogged) ?? false;
  }

  // ---- Endpoints ----

  /// Registro en `/register`
  static Future<(bool ok, String? msg)> register(String u, String p1) async {
    final uri = Uri.parse('$apiBase/register');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': u, 'password': p1}),
    );

    if (resp.statusCode == 201) {
      return (true, null);
    }

    try {
      final m = jsonDecode(resp.body) as Map<String, dynamic>;
      return (false, m['error']?.toString() ?? 'Error');
    } catch (_) {
      return (false, 'Error');
    }
  }

  /// Login en `/login` (guarda JWT)
  static Future<bool> login(String u, String p) async {
    final uri = Uri.parse('$apiBase/login');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': u, 'password': p}),
    );

    if (resp.statusCode == 200) {
      final j = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = j['access_token']?.toString();
      if (token != null && token.isNotEmpty) {
        await _setJwt(token);
        await _setUser(u);
        await _setLogged(true);
        return true;
      }
    }
    return false;
  }

  /// Verifica token en `/me`
  static Future<bool> validateSession() async {
    final jwt = await getJwt();
    if (jwt == null) return false;

    final uri = Uri.parse('$apiBase/me');
    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode == 200) {
      try {
        final j = jsonDecode(resp.body) as Map<String, dynamic>;
        if (j['ok'] == true) return true;
      } catch (_) {}
    }
    return false;
  }

  static Future<void> clearSession() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kLogged);
    await sp.remove(_kUser);
    await sp.remove(_kJwt);
  }
}

/// ========================
/// SPLASH / ROUTER
/// ========================
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Si localmente dice "logueado", validamos con /me para estar seguros.
    final local = await AuthStore.isLocallyLogged();
    final valid = local ? await AuthStore.validateSession() : false;

    if (!mounted) return;
    if (valid) {
      _loggedUser = await AuthStore.getUser();
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      await AuthStore.clearSession();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RootApp());
}

class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDark,
      builder: (_, isDark, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GeoAlerta',
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          routes: {
            '/': (_) => const SplashGate(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/home': (_) => const HomePage(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}

/// ========================
/// LOGIN
/// ========================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userCtl = TextEditingController();
  final _passCtl = TextEditingController();
  bool _obscure = true;
  String? _error;

  Future<void> _tryLogin() async {
    final u = _userCtl.text.trim();
    final p = _passCtl.text;

    if (u.isEmpty || p.isEmpty) {
      setState(() => _error = 'Completa usuario y contraseña');
      _snack('Completa usuario y contraseña');
      return;
    }

    final ok = await AuthStore.login(u, p);
    if (ok) {
      _loggedUser = u;
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      setState(() => _error = 'Usuario o contraseña incorrectos');
      _snack('Usuario o contraseña incorrectos');
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
        actions: [
          IconButton(
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            onPressed: () => _isDark.value = !_isDark.value,
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          )
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 72),
                const SizedBox(height: 16),
                TextField(
                  controller: _userCtl,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Ingresar'),
                    onPressed: _tryLogin,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  icon: const Icon(Icons.person_add_alt),
                  label: const Text('Crear cuenta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ========================
/// REGISTRO (usuario + confirmar contraseña)
/// ========================
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _u = TextEditingController();
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  bool _obs1 = true, _obs2 = true;

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _register() async {
    final u = _u.text.trim();
    final p1 = _p1.text;
    final p2 = _p2.text;

    if (u.isEmpty || p1.isEmpty || p2.isEmpty) {
      _snack('Completa todos los campos');
      return;
    }
    if (p1 != p2) {
      _snack('Las contraseñas no coinciden');
      return;
    }
    if (p1.length < 6) {
      _snack('La contraseña debe tener al menos 6 caracteres');
      return;
    }

    final (ok, msg) = await AuthStore.register(u, p1);
    if (ok) {
      _snack('Usuario creado. Ahora inicia sesión.');
      if (!mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/login'));
    } else {
      _snack(msg ?? 'No se pudo crear el usuario');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _u,
                  decoration: const InputDecoration(
                    labelText: 'Usuario',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _p1,
                  obscureText: _obs1,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obs1 = !_obs1),
                      icon: Icon(
                          _obs1 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _p2,
                  obscureText: _obs2,
                  decoration: InputDecoration(
                    labelText: 'Repite la contraseña',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obs2 = !_obs2),
                      icon: Icon(
                          _obs2 ? Icons.visibility : Icons.visibility_off),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Crear usuario'),
                    onPressed: _register,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ========================
/// HOME (APP)
/// ========================
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

enum _MenuAction { profile, settings, theme, logout }

class _HomePageState extends State<HomePage> {
  Position? _pos;
  String _estado = 'Listo';
  XFile? _imagen;
  bool _enviando = false;

  // campo para descripción del reporte
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  // ----- UBICACIÓN -----
  Future<void> _obtenerUbicacion() async {
    setState(() => _estado = 'Verificando GPS/permisos...');
    try {
      final gpsOn = await Geolocator.isLocationServiceEnabled();
      if (!gpsOn) {
        setState(() => _estado = 'GPS desactivado. Actívalo.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        setState(() => _estado = 'Permiso de ubicación denegado.');
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );
      setState(() {
        _pos = p;
        _estado = 'Ubicación lista ✔︎';
      });
    } catch (_) {
      setState(() => _estado = 'informacion no enviada');
      _showSnack('informacion no enviada');
    }
  }

  // ----- GALERÍA -----
  Future<void> _seleccionarImagen() async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85);
      if (x != null) {
        setState(() {
          _imagen = x;
          _estado = 'Imagen seleccionada: ${x.name}';
        });
      } else {
        setState(() => _estado = 'No se seleccionó imagen.');
      }
    } catch (_) {
      setState(() => _estado = 'informacion no enviada');
      _showSnack('informacion no enviada');
    }
  }

  // ----- ENVIAR -----
  Future<void> _enviar() async {
    if (_pos == null) {
      setState(() => _estado = 'Primero obtén la ubicación.');
      return;
    }
    if (_imagen == null) {
      setState(() => _estado = 'Selecciona una imagen primero.');
      return;
    }

    final jwt = await AuthStore.getJwt();
    if (jwt == null) {
      _showSnack('Inicia sesión para enviar reportes');
      return;
    }

    final uri = Uri.parse('$apiBase/reportes');

    setState(() {
      _enviando = true;
      _estado = 'Enviando a ${uri.toString()}...';
    });

    try {
      final bytes = await File(_imagen!.path).readAsBytes();
      final b64 = base64Encode(bytes);

      final payload = {
        'lat': _pos!.latitude,
        'lon': _pos!.longitude,
        'fecha': DateTime.now().toIso8601String(),
        'foto_base64': b64,
        // ⬇️ requerido por el backend
        'descripcion': _descCtrl.text.trim().isEmpty
            ? 'Reporte desde la app'
            : _descCtrl.text.trim(),
      };

      final resp = await http
          .post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        setState(() => _estado = 'Reporte enviado ✔︎ (${resp.statusCode})');
        _showSnack('Enviado (${resp.statusCode})');
      } else {
        // Muestra error del backend si viene
        try {
          final j = jsonDecode(resp.body) as Map<String, dynamic>;
          final e = j['error']?.toString() ?? 'informacion no enviada';
          setState(() => _estado = e);
          _showSnack(e);
        } catch (_) {
          setState(() => _estado = 'informacion no enviada');
          _showSnack('informacion no enviada');
        }
      }
    } on SocketException {
      setState(() => _estado = 'informacion no enviada');
      _showSnack('informacion no enviada');
    } on TimeoutException {
      setState(() => _estado = 'informacion no enviada');
      _showSnack('informacion no enviada');
    } catch (_) {
      setState(() => _estado = 'informacion no enviada');
      _showSnack('informacion no enviada');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _onMenuSelect(_MenuAction a) async {
    switch (a) {
      case _MenuAction.profile:
        _showSnack('en desarrollo');
        break;
      case _MenuAction.settings:
        _showSnack('en desarrollo');
        break;
      case _MenuAction.theme:
        _isDark.value = !_isDark.value;
        break;
      case _MenuAction.logout:
        _loggedUser = null;
        await AuthStore.clearSession();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lat = _pos?.latitude.toStringAsFixed(6) ?? '--';
    final lon = _pos?.longitude.toStringAsFixed(6) ?? '--';
    final user = _loggedUser ?? 'usuario';

    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoAlerta'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(user,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
          PopupMenuButton<_MenuAction>(
            tooltip: 'Menú',
            onSelected: _onMenuSelect,
            itemBuilder: (context) {
              final isDark = _isDark.value;
              return [
                const PopupMenuItem(
                  value: _MenuAction.profile,
                  child: Text('Cambiar foto de perfil'),
                ),
                const PopupMenuItem(
                  value: _MenuAction.settings,
                  child: Text('Configuraciones'),
                ),
                PopupMenuItem(
                  value: _MenuAction.theme,
                  child: Text(isDark ? 'Modo claro' : 'Modo oscuro'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: _MenuAction.logout,
                  child: Text('Log out'),
                ),
              ];
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: CircleAvatar(
                radius: 16,
                child: Icon(Icons.person, size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(_estado)),
            ]),
            const SizedBox(height: 12),

            // Ubicación
            ListTile(
              leading: const Icon(Icons.place),
              title: Text('Lat: $lat   Lon: $lon'),
              subtitle: Text(_pos != null
                  ? 'Precisión: ${_pos!.accuracy.toStringAsFixed(1)} m'
                  : 'Sin coordenadas'),
              trailing: ElevatedButton(
                onPressed: _obtenerUbicacion,
                child: const Text('Obtener ubicación'),
              ),
            ),
            const SizedBox(height: 8),

            // Imagen
            ListTile(
              leading: _imagen == null
                  ? const Icon(Icons.image_outlined)
                  : Image.file(
                File(_imagen!.path),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
              title: Text(_imagen?.name ?? 'Sin imagen'),
              trailing: ElevatedButton(
                onPressed: _seleccionarImagen,
                child: const Text('Seleccionar imagen'),
              ),
            ),

            const SizedBox(height: 8),

            // Descripción (requerida por backend)
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Descripción del reporte (obligatoria)',
                border: OutlineInputBorder(),
              ),
            ),

            const Spacer(),

            // Enviar
            ElevatedButton.icon(
              onPressed: _enviando ? null : _enviar,
              icon: _enviando
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
              label: const Text('Enviar a API'),
            ),
          ],
        ),
      ),
    );
  }
}
