import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/user.dart';
import '../data/user_repository.dart';

part 'user_provider.g.dart';

@riverpod
Future<List<User>> userList(UserListRef ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUsers();
}
