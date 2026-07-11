import 'grid.dart';

class ItemInstance {
  const ItemInstance({
    required this.id,
    required this.templateId,
    required this.position,
    this.consumed = false,
  });

  final String id;
  final String templateId;
  final GridCoord position;
  final bool consumed;

  ItemInstance copyWith({
    String? id,
    String? templateId,
    GridCoord? position,
    bool? consumed,
  }) {
    return ItemInstance(
      id: id ?? this.id,
      templateId: templateId ?? this.templateId,
      position: position ?? this.position,
      consumed: consumed ?? this.consumed,
    );
  }
}
