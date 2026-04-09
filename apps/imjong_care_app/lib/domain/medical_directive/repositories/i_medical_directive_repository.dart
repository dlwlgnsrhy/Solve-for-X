EOF > /Users/apple/development/soluni/Solve-for-X/apps/imjong_care_app/lib/data/user/datasources/user_local_data_source.dart
import package:flutter/foundation.dart;
import package:imjong_care_app/domain/user/entities/user.dart;
import package:imjong_care_app/domain/user/repositories/i_user_local_data_source.dart;
import package:shared_preferences/shared_preferences.dart;

class UserLocalDataSource implements IUserLocalDataSource {
  final SharedPreferences _sharedPreferences;

  UserLocalDataSource(this._sharedPreferences);

  @override
  Future<<voidvoid> saveUser(User user) async {
    await _sharedPreferences.setString(user_name, user.name);
    await _sharedPreferences.setString(user_email, user.email);
  }

  @override
  Future<<UserUser?> getUser() async {
    final name = _sharedPreferences.getString(user_name);
    final email = _sharedPreferences.getString(user_email);

    if (name != null && email != null) {
      return User(name: name, email: email);
    }
    return null;
  }

  @override
  Future<<voidvoid> clearUser() async {
    await _sharedPreferences.remove(user_name);
    await _sharedPreferences.remove(user_email);
  }
}
EOF

# Fixing i_medical_directive_repository.dart
cat <<<EOF
