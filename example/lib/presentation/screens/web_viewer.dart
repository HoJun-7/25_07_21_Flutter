// web_viewer.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_viewer_mobile.dart' if (dart.library.html) 'web_viewer_web.dart';

class WebViewerScreen extends StatelessWidget {
  const WebViewerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PlatformWebViewer(); // 플랫폼에 따라 맞는 구현으로 이동
  }
}
