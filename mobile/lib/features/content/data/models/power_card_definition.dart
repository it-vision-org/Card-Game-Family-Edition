class PowerCardDefinition {
  const PowerCardDefinition({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
  });

  factory PowerCardDefinition.fromJson(Map<String, dynamic> json) {
    return PowerCardDefinition(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
    );
  }

  final String id;
  final String code;
  final String title;
  final String description;
}
