import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:life_log_v5/data/datasources/planner_api_client.dart';
import 'package:life_log_v5/domain/entities/checkin_data.dart';

import 'planner_api_client_test.mocks.dart';

void main() {
  late PlannerApiClient apiClient;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    apiClient = PlannerApiClient(dio: mockDio);
  });

  group('PlannerApiClient Tests', () {
    final tCheckinData = CheckinData(
      energyLevel: 4,
      mood: 'Happy',
      focusMode: 'Deep Work',
    );

    test(
      'submitCheckin should return true when API call is successful',
      () async {
        // Arrange
        when(
          mockDio.post(
            'http://192.168.45.61:8080/api/health/daily-checkin',
            data: anyNamed('data'),
          ),
        ).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(),
            data: {'status': 'success'},
            statusCode: 200,
          ),
        );

        // Act
        final result = await apiClient.submitCheckin(tCheckinData);

        // Assert
        expect(result, true);
        verify(
          mockDio.post(
            'http://192.168.45.61:8080/api/health/daily-checkin',
            data: tCheckinData.toJson(),
          ),
        ).called(1);
      },
    );

    test(
      'submitCheckin should throw Exception when API call fails (500)',
      () async {
        // Arrange
        when(
          mockDio.post(
            'http://192.168.45.61:8080/api/health/daily-checkin',
            data: anyNamed('data'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 500,
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        // Act & Assert
        expect(
          () => apiClient.submitCheckin(tCheckinData),
          throwsA(
            isA << ExceptionException >
                ().having((e) => e.toString(), 'message', contains('서버 연결 실패')),
          ),
        );
      },
    );

    test('submitCheckin should throw Exception on timeout', () async {
      // Arrange
      when(
        mockDio.post(
          'http://192.168.45.61:8080/api/health/daily-checkin',
          data: anyNamed('data'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionTimeout,
        ),
      );

      // Act & Assert
      expect(
        () => apiClient.submitCheckin(tCheckinData),
        throwsA(
          isA << ExceptionException >
              ().having((e) => e.toString(), 'message', contains('연결 시간 초과')),
        ),
      );
    });
  });
}
