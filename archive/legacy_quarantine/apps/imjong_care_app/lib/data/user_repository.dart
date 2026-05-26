import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/user.dart';

part 'user_repository.g.dart';

class UserRepository {
  Future<List<User>> getUsers() async {
    await Future.delayed(const Duration(seconds: 2));
    return [
      const User(id: '1', name: 'John Doe'),
      const User(id: '2', name: 'Jane Doe'),
    ];
  }
}

@riverpod
UserRepository userRepository(UserRepositoryRef ref) {
  return UserRepository();
}
