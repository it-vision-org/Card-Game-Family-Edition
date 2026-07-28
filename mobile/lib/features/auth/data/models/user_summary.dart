class UserSummary {
  const UserSummary({
    required this.id,
    required this.publicId,
    required this.displayName,
    required this.role,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as String,
      publicId: json['publicId'] as String,
      displayName: json['displayName'] as String,
      role: json['role'] as String,
    );
  }

  final String id;
  final String publicId;
  final String displayName;
  final String role;

  bool get isAdmin => role == 'ADMIN';
}
