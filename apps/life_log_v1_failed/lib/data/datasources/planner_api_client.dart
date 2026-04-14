import 'package:dio/dio.dart';

class PlannerApiClient {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://192.168.45.61:8080/api'));

  Future<void> postSleepData(Map<String, dynamic> data) async {
    await _dio.post('/health/sleep', data: data);
  }
}
