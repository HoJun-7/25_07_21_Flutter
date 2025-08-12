// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'dart:convert';

class PlatformWebViewer extends StatefulWidget {
  const PlatformWebViewer({super.key});

  @override
  State<PlatformWebViewer> createState() => _PlatformWebViewerState();
}

class _PlatformWebViewerState extends State<PlatformWebViewer> {
  static const viewID = 'web-3d-viewer';

  final List<Map<String, dynamic>> predictions = [
    {'x': 100, 'y': 150, 'label': '충치', 'score': 0.92},
    {'x': 250, 'y': 300, 'label': '보철물', 'score': 0.85},
  ];

  @override
  void initState() {
    super.initState();

    // Register iframe only once
    ui.platformViewRegistry.registerViewFactory(
      viewID,
      (int viewId) {
        final element = html.IFrameElement()
          ..id = 'web-3d-viewer'
          ..src = 'http://192.168.0.19:8000/dental_viewer.html'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return element;
      },
    );

    // Send prediction data after rendering is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendPredictionsToIframe();
    });
  }

  void _sendPredictionsToIframe() {
    final iframe = html.document.getElementById('web-3d-viewer') as html.IFrameElement?;
    if (iframe != null && iframe.contentWindow != null) {
      final data = jsonEncode(predictions);
      iframe.contentWindow!.postMessage(data, '*');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('🦷 3D Viewer with Overlay')),
      body: HtmlElementView(viewType: viewID),
    );
  }
}