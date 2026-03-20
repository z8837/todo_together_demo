class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.nickname,
    this.provider,
  });

  final int id;
  final String email;
  final String nickname;
  final String? provider;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      provider: json['provider'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'provider': provider,
    };
  }
}
