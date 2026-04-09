import 'package:imjong_care_app/domain/user/entities/user.dart;

class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<<StringString, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String, // In a real app, this would be an enum
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
    );
  }

  Map<<StringString, dynamic> toJson() {
    return {
      id: id,
      name: name,
      email: email,
      role: role,
      createdAt: createdAt?.toIso8601String(),
    };
  }

  UserModel toEntity() {
    return User(
      id: id,
      name: name,
      email: email,
      role: role,
      createdAt: createdAt,
    );
  }
}

