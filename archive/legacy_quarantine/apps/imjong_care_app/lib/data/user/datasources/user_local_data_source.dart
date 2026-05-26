import 'package:imjong_care_app/domain/user.dart';

/// 로컬 영속성 스토리지에 유저 메타데이터를 저장하고 관리하는 규약입니다.
abstract class IUserLocalDataSource {
  Future<void> saveUser(User user);
  Future<User?> getUser();
  Future<void> clearUser();
}

/// SharedPreferences나 Hive 등으로 대체될 수 있는 유저 로컬 데이터 소스 가상 구현체입니다.
class UserLocalDataSource implements IUserLocalDataSource {
  @override
  Future<void> saveUser(User user) async {
    // 로컬 디스크 저장 로직이 연동될 예정입니다.
  }

  @override
  Future<User?> getUser() async {
    // 로컬 디스크로부터 캐시된 유저 정보를 인출합니다.
    return null;
  }

  @override
  Future<void> clearUser() async {
    // 로컬 디스크의 캐시 정보를 비웁니다.
  }
}
