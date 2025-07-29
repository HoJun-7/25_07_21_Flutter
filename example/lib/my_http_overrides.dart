// lib/my_http_overrides.dart
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // ⚠️ 개발용: 모든 인증서 무시
        print('📛 인증서 우회: $host:$port');
        return true;
      };
  }
}
