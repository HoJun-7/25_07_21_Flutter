import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PlatformWebViewer extends StatefulWidget {
  const PlatformWebViewer({super.key});

  @override
  State<PlatformWebViewer> createState() => _PlatformWebViewerState();
}

class _PlatformWebViewerState extends State<PlatformWebViewer> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('http://192.168.0.19:8000/dental_viewer.html')); // ✅ GLB 포함 HTML
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('3D Viewer')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
