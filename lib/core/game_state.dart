import 'chatty_activity_moment.dart';
import 'chatty_life_state.dart';
import 'events.dart';
import 'item_instance.dart';
import 'item_template.dart';
import 'pet_rules.dart';
import 'pet_state.dart';

class GameState {
  const GameState({
    required this.gridWidth,
    required this.gridHeight,
    required this.pet,
    required this.templates,
    required this.items,
    required this.tickCount,
    required this.dayCount,
    required this.timeOfDay,
    required this.eventLog,
    required this.recentLines,
    required this.unlockedTemplateIds,
    this.activityMoment = const ChattyActivityMoment(),
    this.life = const ChattyLifeState(),
    this.selectedItemId,
    this.nextItemId = 1,
  });

  final int gridWidth;
  final int gridHeight;
  final PetState pet;
  final Map<String, ItemTemplate> templates;
  final List<ItemInstance> items;
  final int tickCount;
  final int dayCount;
  final TimeOfDay timeOfDay;
  final List<PetEvent> eventLog;
  final List<String> recentLines;
  final Set<String> unlockedTemplateIds;
  final ChattyActivityMoment activityMoment;
  final ChattyLifeState life;
  final String? selectedItemId;
  final int nextItemId;

  GameState copyWith({
    int? gridWidth,
    int? gridHeight,
    PetState? pet,
    Map<String, ItemTemplate>? templates,
    List<ItemInstance>? items,
    int? tickCount,
    int? dayCount,
    TimeOfDay? timeOfDay,
    List<PetEvent>? eventLog,
    List<String>? recentLines,
    Set<String>? unlockedTemplateIds,
    ChattyActivityMoment? activityMoment,
    ChattyLifeState? life,
    Object? selectedItemId = _sentinel,
    int? nextItemId,
  }) {
    return GameState(
      gridWidth: gridWidth ?? this.gridWidth,
      gridHeight: gridHeight ?? this.gridHeight,
      pet: pet ?? this.pet,
      templates: templates ?? this.templates,
      items: items ?? this.items,
      tickCount: tickCount ?? this.tickCount,
      dayCount: dayCount ?? this.dayCount,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      eventLog: eventLog ?? this.eventLog,
      recentLines: recentLines ?? this.recentLines,
      unlockedTemplateIds: unlockedTemplateIds ?? this.unlockedTemplateIds,
      activityMoment: activityMoment ?? this.activityMoment,
      life: life ?? this.life,
      selectedItemId: selectedItemId == _sentinel
          ? this.selectedItemId
          : selectedItemId as String?,
      nextItemId: nextItemId ?? this.nextItemId,
    );
  }
}

const _sentinel = Object();
