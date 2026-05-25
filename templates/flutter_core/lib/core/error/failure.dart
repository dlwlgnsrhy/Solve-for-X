
import 'package:meta/meta.dart';

@immutable
class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message, code: 'SERVER_ERROR');
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message, code: 'NETWORK_ERROR');
}
