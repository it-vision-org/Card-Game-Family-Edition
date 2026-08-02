class MyCard {
  const MyCard({
    required this.id,
    required this.categoryCode,
    required this.text,
    required this.eligiblePlayerPublicIds,
    required this.best,
  });

  factory MyCard.fromJson(Map<String, dynamic> json) {
    return MyCard(
      id: json['id'] as String,
      categoryCode: json['categoryCode'] as String,
      text: json['text'] as String? ?? '',
      eligiblePlayerPublicIds:
          (json['eligiblePlayerPublicIds'] as List<dynamic>)
              .map((e) => e as String)
              .toList(),
      best: json['best'] as bool? ?? false,
    );
  }

  final String id;
  final String categoryCode;
  final String text;
  final List<String> eligiblePlayerPublicIds;
  final bool best;
}
