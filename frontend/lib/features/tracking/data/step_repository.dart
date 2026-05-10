import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';

class StepRepository {
  final Dio _dio = DioClient.instance;

  /// Syncs today's step data to the backend.
  /// Loads the JWT token from SharedPreferences each time to handle the case
  /// where the call originates from a background isolate with no in-memory token.
  Future<void> syncSteps({
    required int steps,
    required double calories,
    required double distance,
  }) async {
    try {
      // Ensure the JWT token is set — critical for background isolate calls
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      if (token == null) {
        print('Step sync skipped: no auth token');
        return;
      }
      DioClient.setAuthToken(token);

      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _dio.post('/steps/sync', data: [
        {
          'date': dateStr,
          'steps': steps,
          'calories': calories,
          'distance': distance,
        }
      ]);
      print('Step sync SUCCESS: $steps steps saved');
    } on DioException catch (e) {
      // Silently fail — don't crash the app if sync fails
      print('Step sync failed: ${e.response?.statusCode} ${e.message}');
    }
  }
}
