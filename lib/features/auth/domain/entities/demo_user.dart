class DemoUser {
  const DemoUser({
    required this.id,
    required this.email,
    required this.nickname,
    required this.accessToken,
  });

  final int id;
  final String email;
  final String nickname;
  final String accessToken;
}
