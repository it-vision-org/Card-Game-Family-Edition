class CardCategory {
  const CardCategory({required this.code, required this.sortOrder});

  factory CardCategory.fromJson(Map<String, dynamic> json) {
    return CardCategory(
      code: json['code'] as String,
      sortOrder: json['sortOrder'] as int,
    );
  }

  final String code;
  final int sortOrder;

  static const _arabicLabels = {
    'HOW_WELL_DO_WE_KNOW_EACH_OTHER': 'نعرفوا بعضنا قدّاش؟',
    'MEMORIES_AND_STORIES': 'ذكريات وحكايات',
    'FUN_AND_GUESSING': 'ضحك وتخمين',
    'FROM_THE_HEART': 'من القلب — حب وصراحة',
    'FUTURE_AND_FAMILY': 'المستقبل والعائلة',
    'CHALLENGES_AND_SURPRISES': 'مفاجأة وتحدّي',
  };

  String get arabicLabel => _arabicLabels[code] ?? code;
}
