import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Instancia global del plugin
final FlutterLocalNotificationsPlugin notifications =
FlutterLocalNotificationsPlugin();

/// ===== Constantes del canal (compile-time) =====
const String kChannelId   = 'geoalerta_channel';
const String kChannelName = 'GeoAlerta';
const String kChannelDesc = 'Notificaciones locales de GeoAlerta';

/// Canal para Android (8.0+)
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  kChannelId,
  kChannelName,
  description: kChannelDesc,
  importance: Importance.high,
);

/// Inicializa notificaciones locales (llamar una sola vez al iniciar la app)
Future<void> initLocalNotifs() async {
  // Icono por defecto (usa @mipmap/ic_launcher)
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);

  await notifications.initialize(initSettings);

  // Crear canal en Android 8+
  final androidPlugin = notifications
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(_channel);

  // Pedir permiso en Android 13+
  await androidPlugin?.requestNotificationsPermission();
}

/// Muestra una notificación simple
Future<void> showLocalNotif(String title, String body, {String? payload}) async {
  // Usamos las constantes del canal para permitir const aquí sin errores.
  const androidDetails = AndroidNotificationDetails(
    kChannelId,
    kChannelName,
    channelDescription: kChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
  );

  const details = NotificationDetails(android: androidDetails);

  // ID único para no sobrescribir notificaciones anteriores
  final int id = DateTime.now().millisecondsSinceEpoch & 0x7fffffff;

  await notifications.show(id, title, body, details, payload: payload);
}
