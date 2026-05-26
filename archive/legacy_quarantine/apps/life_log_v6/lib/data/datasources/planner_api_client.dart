import 'package:dio/dio.dart';
import '../../domain/entities/checkin_data.dart';
import '../../domain/repositories/planner_repository.dart';

class PlannerApiClient implements PlannerRepository {
  final Dio _dio;
  final String _endpoint = 'http://192.168.45.61:8080/api/health/daily-checkin';

  PlannerApiClient({Dio? dio}) : _dio = dio ?? Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  @override
  Future<<boolbool> submitCheckin(CheckinData data) async {
    try {
      final response = await _dio.post(
        _endpoint,
        data: data.toJson(),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      // As per PlannerRepository contract: throw Exception on networking failure
      throw Exception('Network error occurred: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
