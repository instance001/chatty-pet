enum ItemKind {
  food,
  toy,
  restItem,
  cleanItem,
  curiosity,
  comfort,
}

class ItemTemplate {
  const ItemTemplate({
    required this.id,
    required this.displayName,
    required this.emoji,
    required this.kind,
    required this.inspectLines,
    required this.useLines,
    required this.noticeLines,
    this.fullnessDelta = 0,
    this.funDelta = 0,
    this.restDelta = 0,
    this.cleanlinessDelta = 0,
    this.affectionDelta = 0,
    this.unlockLevel = 0,
  });

  final String id;
  final String displayName;
  final String emoji;
  final ItemKind kind;
  final List<String> inspectLines;
  final List<String> useLines;
  final List<String> noticeLines;
  final int fullnessDelta;
  final int funDelta;
  final int restDelta;
  final int cleanlinessDelta;
  final int affectionDelta;
  final int unlockLevel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'emoji': emoji,
      'kind': kind.name,
      'inspectLines': inspectLines,
      'useLines': useLines,
      'noticeLines': noticeLines,
      'fullnessDelta': fullnessDelta,
      'funDelta': funDelta,
      'restDelta': restDelta,
      'cleanlinessDelta': cleanlinessDelta,
      'affectionDelta': affectionDelta,
      'unlockLevel': unlockLevel,
    };
  }

  static ItemTemplate fromJson(Map<String, dynamic> json) {
    return ItemTemplate(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      emoji: json['emoji'] as String,
      kind: ItemKind.values.byName(json['kind'] as String),
      inspectLines: (json['inspectLines'] as List<dynamic>).cast<String>(),
      useLines: (json['useLines'] as List<dynamic>).cast<String>(),
      noticeLines: (json['noticeLines'] as List<dynamic>).cast<String>(),
      fullnessDelta: json['fullnessDelta'] as int? ?? 0,
      funDelta: json['funDelta'] as int? ?? 0,
      restDelta: json['restDelta'] as int? ?? 0,
      cleanlinessDelta: json['cleanlinessDelta'] as int? ?? 0,
      affectionDelta: json['affectionDelta'] as int? ?? 0,
      unlockLevel: json['unlockLevel'] as int? ?? 0,
    );
  }
}
