import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:fleet_management/data/services/api_service.dart';

/// Maps a filename's extension to the MIME type the backend's picture
/// upload endpoint checks for (backend/app/api/v1/profile.py:
/// _ALLOWED_PICTURE_MIME_TYPES) — set explicitly rather than relying on
/// MultipartFile.fromBytes' content-type inference, which isn't guaranteed
/// across platforms the way fromFile's path-based extension lookup is.
MediaType _pictureMediaType(String filename) {
  final ext = filename.toLowerCase();
  if (ext.endsWith('.png')) return MediaType('image', 'png');
  if (ext.endsWith('.webp')) return MediaType('image', 'webp');
  return MediaType('image', 'jpeg');
}

/// Profile API Service
class ProfileApi {
  final ApiService _apiService;

  ProfileApi(this._apiService);

  /// Get profile status
  Future<Map<String, dynamic>> getProfileStatus() async {
    final response = await _apiService.dio.get(
      '/api/profile/status',
    );

    return response.data;
  }

  /// Complete profile
  Future<Map<String, dynamic>> completeProfile(Map<String, dynamic> profileData) async {
    final response = await _apiService.dio.post(
      '/api/profile/complete',
      data: profileData,
    );

    return response.data;
  }

  /// Change user role (for Independent Users only)
  Future<Map<String, dynamic>> changeRole(Map<String, dynamic> profileData) async {
    final response = await _apiService.dio.post(
      '/api/profile/change-role',
      data: profileData,
    );

    return response.data;
  }

  /// Update user profile information
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _apiService.dio.put(
      '/api/profile/update',
      data: profileData,
    );

    return response.data;
  }

  /// Upload (or replace) the current user's profile picture. Takes raw
  /// bytes + filename (not a file path) so it works on every platform —
  /// on web, an XFile's `path` is a blob URL that dart:io can't open.
  Future<Map<String, dynamic>> uploadProfilePicture(
      Uint8List bytes, String filename) async {
    final formData = FormData.fromMap({
      'picture': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: _pictureMediaType(filename),
      ),
    });

    final response = await _apiService.dio.post(
      '/api/profile/picture',
      data: formData,
    );

    return response.data;
  }

  /// Remove the current user's profile picture
  Future<Map<String, dynamic>> deleteProfilePicture() async {
    final response = await _apiService.dio.delete('/api/profile/picture');
    return response.data;
  }

  /// Change the current user's password by re-verifying their security
  /// question answers. Only works for accounts registered with security
  /// questions (not email-authenticated accounts).
  Future<Map<String, dynamic>> changePassword({
    required List<Map<String, String>> answers,
    required String newPassword,
  }) async {
    final response = await _apiService.dio.post(
      '/api/profile/change-password',
      data: {
        'answers': answers,
        'new_password': newPassword,
      },
    );

    return response.data;
  }
}
