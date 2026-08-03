import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class CloudinaryService {
  static const _cloudName = "djd7kgxyb";
  static const _uploadPreset = "queerverse_profile";

  /// Uploads an image file and returns the secure URL, or null on failure.
  static Future<String?> uploadImage(File imageFile) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      return data['secure_url'];
    }
    return null;
  }

  static Future<String?> uploadImageBytes(
    Uint8List bytes, {
    String filename = 'story.jpg',
  }) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/image/upload",
    );

    final request = http.MultipartRequest("POST", uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      return data['secure_url'];
    }
    return null;
  }

  /// Uploads a video file and returns the secure URL, or null on failure.
  /// Note: your Cloudinary upload preset must allow "video" resource type
  /// (Settings -> Upload -> Upload presets -> your preset -> unsigned, and
  /// make sure it isn't restricted to "image" only).
  static Future<String?> uploadVideo(File videoFile) async {
    final uri = Uri.parse(
      "https://api.cloudinary.com/v1_1/$_cloudName/video/upload",
    );

    final request = http.MultipartRequest("POST", uri);
    request.fields['upload_preset'] = _uploadPreset;
    request.files.add(
      await http.MultipartFile.fromPath('file', videoFile.path),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      final data = jsonDecode(await response.stream.bytesToString());
      return data['secure_url'];
    }
    return null;
  }
}
