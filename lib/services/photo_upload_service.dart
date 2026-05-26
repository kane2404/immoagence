import 'dart:convert';

import 'package:image_picker/image_picker.dart';

import 'admin_api.dart';

class PhotoUploadService {
  const PhotoUploadService();

  Future<String?> pickAndUpload({required String fileName}) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 78,
      maxWidth: 1800,
    );

    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final mime = _mimeFromName(file.name);
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    return const AdminApi().uploadImageDataUrl(
      fileName: fileName,
      dataUrl: dataUrl,
    );
  }
}

String _mimeFromName(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}
