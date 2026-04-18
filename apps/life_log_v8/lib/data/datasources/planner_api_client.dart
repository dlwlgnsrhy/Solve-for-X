import 'package:dio/dio.dart';
import '../../domain/domain.dart';

class PlannerApiClient {
  final Dio dio;

  static const baseUrl = 'http://192.168.45.61:8080';
  static const endpoint = '/api/health/daily-checkin';

  PlannerApiClient({required this.dio});

  Future<bool> submitCheckin(CheckinData data) async {
    try {
      final response = await dio.post('$baseUrl$endpoint', data: data.toJson());
      if (response.statusCode != 200) {
        throw Exception('Unexpected error: status ${response.statusCode}');
      }
      return true;
    } on DioException catch (e) {
      throw Exception('API request failed: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
