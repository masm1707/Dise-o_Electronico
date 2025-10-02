import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const String _base = 'http://18.221.30.184:8080'; // backend

  // --- Helpers de almacenamiento de token ---
  Future<void> _saveToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('jwt', token);
  }

  Future<String?> _getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString('jwt');
  }

  Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('jwt');
  }

  Map<String, String> _jsonHeaders({String? token}) => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  // Decodifica seguro (UTF8) y garantiza Map
  Map<String, dynamic> _safeJson(http.Response r) {
    final raw = r.bodyBytes.isEmpty ? utf8.encode('{}') : r.bodyBytes;
    final decoded = jsonDecode(utf8.decode(raw));
    return (decoded is Map<String, dynamic>) ? decoded : <String, dynamic>{};
  }

  // Envoltorio para manejar timeout/errores de red en una sola línea
  Future<http.Response> _send(Future<http.Response> future) async {
    try {
      return await future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      // simulamos una Response de error para tratarla igual
      return http.Response(jsonEncode({'error': 'timeout'}), 599);
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 598);
    }
  }

  // 1) Registro
  Future<({bool ok, String? error})> register({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$_base/register');
    final r = await _send(_client.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    ));

    if (r.statusCode == 201) return (ok: true, error: null);

    final j = _safeJson(r);
    return (ok: false, error: (j['error'] ?? 'unknown_error').toString());
  }

  // 2) Login (guarda el JWT)
  Future<({bool ok, String? error})> login({
    required String username,
    required String password,
  }) async {
    final url = Uri.parse('$_base/login');
    final r = await _send(_client.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode({'username': username, 'password': password}),
    ));

    final j = _safeJson(r);
    if (r.statusCode == 200 && j['ok'] == true && j['access_token'] != null) {
      await _saveToken(j['access_token'] as String);
      return (ok: true, error: null);
    }
    return (ok: false, error: (j['error'] ?? 'invalid_credentials').toString());
  }

  // 3) Yo (/me) para verificar token
  Future<({bool ok, String? user, String? error})> me() async {
    final token = await _getToken();
    if (token == null) return (ok: false, user: null, error: 'no_token');

    final url = Uri.parse('$_base/me');
    final r = await _send(_client.get(url, headers: _jsonHeaders(token: token)));
    final j = _safeJson(r);

    if (r.statusCode == 200 && j['ok'] == true) {
      return (ok: true, user: j['user']?.toString(), error: null);
    }
    return (ok: false, user: null, error: (j['error'] ?? 'unauthorized').toString());
  }

  // 4) Crear reporte (protegido con JWT)
  Future<({bool ok, int? id, String? error})> crearReporte({
    required double lat,
    required double lon,
    required String fechaIso8601,
    required String fotoBase64,
    required String descripcion,
  }) async {
    final token = await _getToken();
    if (token == null) return (ok: false, id: null, error: 'no_token');

    final url = Uri.parse('$_base/reportes');
    final r = await _send(_client.post(
      url,
      headers: _jsonHeaders(token: token),
      body: jsonEncode({
        'lat': lat,
        'lon': lon,
        'fecha': fechaIso8601,
        'foto_base64': fotoBase64,
        'descripcion': descripcion,
      }),
    ));

    final j = _safeJson(r);
    if (r.statusCode == 200 && j['ok'] == true) {
      return (ok: true, id: (j['id'] as num?)?.toInt(), error: null);
    }
    return (ok: false, id: null, error: (j['error'] ?? 'error_crear').toString());
  }

  // 5) Listar reportes (protegido)
  Future<({bool ok, List<Map<String, dynamic>> reportes, String? error})>
  listarReportes() async {
    final token = await _getToken();
    if (token == null) {
      return (ok: false, reportes: const <Map<String, dynamic>>[], error: 'no_token');
    }

    final url = Uri.parse('$_base/reportes');
    final r = await _send(_client.get(url, headers: _jsonHeaders(token: token)));
    final j = _safeJson(r);

    if (r.statusCode == 200 && j['ok'] == true) {
      final list = (j['reportes'] as List).cast<Map<String, dynamic>>();
      return (ok: true, reportes: list, error: null);
    }
    return (
    ok: false,
    reportes: const <Map<String, dynamic>>[],
    error: (j['error'] ?? 'error_listar').toString()
    );
  }
}
