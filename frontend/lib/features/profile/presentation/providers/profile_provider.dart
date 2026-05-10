import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/profile_repository.dart';
import '../../domain/user_profile.dart';

final profileRepositoryProvider = Provider((ref) => ProfileRepository());

final profileProvider = AsyncNotifierProvider<ProfileNotifier, UserProfile?>(() {
  return ProfileNotifier();
});

class ProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  FutureOr<UserProfile?> build() async {
    try {
      return await ref.read(profileRepositoryProvider).getProfile();
    } catch (e) {
      // If we get a 401/403 or "user not found", clear the stale token
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      DioClient.clearAuthToken();
      throw Exception('Session expired. Please log in again.');
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final updatedProfile = await ref.read(profileRepositoryProvider).updateProfile(data);
      state = AsyncData(updatedProfile);
      return true;
    } catch (e, st) {
      print('Update error: $e');
      return false;
    }
  }

  Future<bool> uploadImage(File file) async {
    try {
      final updatedProfile = await ref.read(profileRepositoryProvider).uploadProfileImage(file);
      state = AsyncData(updatedProfile);
      return true;
    } catch (e) {
      print('Image upload error: $e');
      return false;
    }
  }
}
