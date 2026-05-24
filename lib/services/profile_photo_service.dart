import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/settings_keys.dart';
import '../database/database_service.dart';

/// Picks and persists the user's profile photo per account.
class ProfilePhotoService {
  ProfilePhotoService._();

  static final ProfilePhotoService instance = ProfilePhotoService._();

  final ImagePicker _picker = ImagePicker();

  Future<bool> pickAndSave(DatabaseService database) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return false;

    final bytes = await picked.readAsBytes();
    await database.setSetting(kProfilePhotoData, base64Encode(bytes));
    return true;
  }

  Future<ImageProvider?> loadPhoto(DatabaseService database) async {
    final encoded = await database.getSetting(kProfilePhotoData);
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(encoded));
    } catch (_) {
      return null;
    }
  }
}
