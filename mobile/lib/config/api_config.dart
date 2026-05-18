import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String productionUrl = 'https://skillmart-backend.onrender.com/api';

  /// PC LAN IP for physical-device debug builds (`ipconfig` → IPv4 on Wi‑Fi).
  /// Override: `flutter run --dart-define=API_URL=http://YOUR_IP:5000/api`
  static const String defaultDevLanUrl = 'http://192.168.1.68:5000/api';

  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    
    // Switch between defaultDevLanUrl (local) and productionUrl (prod)
    return defaultDevLanUrl;
  }

  /// Dynmically derived asset URL (strips '/api' path)
  static String get assetsBaseUrl {
    return baseUrl.replaceAll('/api', '');
  }
}
