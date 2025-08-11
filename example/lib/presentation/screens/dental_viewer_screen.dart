import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class DentalViewerScreen extends StatelessWidget {
  final String glbUrl;
  const DentalViewerScreen({super.key, required this.glbUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('3D 뷰어', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF3869A8)),
      body: Center(
        child: ModelViewer(
          src: glbUrl,                // ← 외부 URL 사용
          alt: 'Dental 3D model',
          cameraControls: true,
          autoRotate: true,
          shadowIntensity: 1,
        ),
      ),
    );
  }
}
