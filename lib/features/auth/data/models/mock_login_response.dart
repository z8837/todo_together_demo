import '../../domain/entities/demo_user.dart';

class MockLoginResponse {
  const MockLoginResponse({
    required this.id,
    required this.email,
    required this.nickname,
    required this.accessToken,
  });

  final int id;
  final String email;
  final String nickname;
  final String accessToken;

  factory MockLoginResponse.fromJson(Map<String, dynamic> json) {
    return MockLoginResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      nickname: json['nickname'] as String,
      accessToken: json['access_token'] as String,
    );
  }

  DemoUser toEntity() {
    return DemoUser(
      id: id,
      email: email,
      nickname: nickname,
      accessToken: accessToken,
    );
  }
}
