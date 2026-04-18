import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_log_v8/domain/domain.dart';
import 'package:life_log_v8/data/datasources/planner_api_client.dart';
import 'package:mockito/mockito.dart';

class MockDio extends Mock implements Dio {
  Response? response;
  DioException? exceptionToThrow;
  String? lastUrl;
  dynamic lastData;

  @override
  Future<Response<T>> post<T>(String path,
      {Object? data,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    lastUrl = path;
    lastData = data;
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return response as Response<T>;
  }
}

void main() {
  group(PlannerApiClient, () {
    test('submitCheckin returns true on 200', () async {
      final mockDio = MockDio()
        ..response = Response<String>(
          requestOptions: RequestOptions(
            path: 'http://192.168.45.61:8080/api/health/daily-checkin',
          ),
          data: 'success',
          statusCode: 200,
        );

      final client = PlannerApiClient(dio: mockDio);
      final result = await client.submitCheckin(
        CheckinData(energyLevel: 3, mood: '😐', focusMode: '딥워크'),
      );
      expect(result, true);
    });

    test('submitCheckin throws Exception on non-200', () async {
      final mockDio = MockDio()
        ..response = Response(
          requestOptions: RequestOptions(path: '/api/health/daily-checkin'),
          statusCode: 500,
        );

      final client = PlannerApiClient(dio: mockDio);
      expect(
        () => client.submitCheckin(
          const CheckinData(energyLevel: 3, mood: '😐', focusMode: '딥워크'),
        ),
        throwsException,
      );
    });

    test('submitCheckin throws Exception on DioException', () async {
      final mockDio = MockDio()
        ..exceptionToThrow = DioException(
          requestOptions: RequestOptions(
            path: 'http://192.168.45.61:8080/api/health/daily-checkin',
          ),
          type: DioExceptionType.connectionTimeout,
        );

      final client = PlannerApiClient(dio: mockDio);
      expect(
        () => client.submitCheckin(
          const CheckinData(energyLevel: 3, mood: '😐', focusMode: '딥워크'),
        ),
        throwsException,
      );
    });

    test('submitCheckin sends correct JSON body', () async {
      final mockDio = MockDio()
        ..response = Response<String>(
          requestOptions: RequestOptions(
            path: 'http://192.168.45.61:8080/api/health/daily-checkin',
          ),
          statusCode: 200,
        );

      final client = PlannerApiClient(dio: mockDio);
      await client.submitCheckin(
        const CheckinData(energyLevel: 5, mood: '😄', focusMode: '메일'),
      );

      expect(mockDio.lastUrl, contains('192.168.45.61'));
      expect(
        mockDio.lastData,
        <String, dynamic>{
          'energyLevel': 5,
          'mood': '😄',
          'focusMode': '메일',
        },
      );
    });
  });
}
