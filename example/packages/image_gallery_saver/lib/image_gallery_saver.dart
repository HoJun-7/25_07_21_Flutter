import 'dart:async';
import 'dart:typed_data'; // ✅ Uint8List 사용을 위해 필요

import 'package:flutter/services.dart';

class ImageGallerySaver {
  static const MethodChannel _channel =
      MethodChannel('image_gallery_saver');

  /// save image to Gallery
  /// imageBytes can't null
  /// return Map type
  /// for example:{"isSuccess":true, "filePath":String?}
  static FutureOr<dynamic> saveImage(Uint8List imageBytes, {
    int quality = 80,
    String? name,
    // bool isReturnImagePathOfIOS = false // ❌ 제거 (네이티브에서 처리 안됨)
  }) async {
    final result =
        await _channel.invokeMethod('saveImageToGallery', <String, dynamic>{
      'imageBytes': imageBytes,
      'quality': quality,
      'name': name,
      // 'isReturnImagePathOfIOS': isReturnImagePathOfIOS, // ❌ 주석 처리
    });
    return result;
  }

  /// Save the PNG，JPG，JPEG image or video located at [file] to the local device media gallery.
  static Future saveFile(String file, {
    String? name,
    // bool isReturnPathOfIOS = false // ❌ 제거 (네이티브에서 처리 안됨)
  }) async {
    final result = await _channel.invokeMethod(
        'saveFileToGallery', <String, dynamic>{
      'file': file,
      'name': name,
      // 'isReturnPathOfIOS': isReturnPathOfIOS // ❌ 주석 처리
    });
    return result;
  }
}
