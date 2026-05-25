
import 'package:dio/dio.dart';
import '../error/failure.dart';

class AppInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    Failure failure;
    if (err.type == DioExceptionType.connectionError) {
      failure = NetworkFailure('No Internet Connection');
    } else {
      failure = ServerFailure(err.message ?? 'Unknown Server Error');
    }
    // In a real template, we would use a specialized error handler or event bus
    print('🚨 [Standardized Error] ${failure.message} (Code: ${failure.code})');
    super.onError(err, handler);
  }
}

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ));
    _dio.interceptors.add(AppInterceptor());
  }

  Dio get dio => _dio;
}
