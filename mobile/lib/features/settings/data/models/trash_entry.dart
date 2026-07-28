class TrashEntry {
  const TrashEntry({
    required this.trashId,
    required this.cardId,
    required this.externalKey,
    required this.trashedAt,
  });

  factory TrashEntry.fromJson(Map<String, dynamic> json) {
    return TrashEntry(
      trashId: json['trashId'] as String,
      cardId: json['cardId'] as String,
      externalKey: json['externalKey'] as String,
      trashedAt: json['trashedAt'] as String,
    );
  }

  final String trashId;
  final String cardId;
  final String externalKey;
  final String trashedAt;
}
