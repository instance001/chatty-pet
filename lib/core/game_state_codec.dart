import 'chatty_activity_moment.dart';
import 'chatty_life_state.dart';
import '../content/starter_datapack.dart';
import 'game_state.dart';
import 'grid.dart';
import 'item_instance.dart';
import 'item_template.dart';
import 'pet_rules.dart';
import 'pet_state.dart';

class GameStateCodec {
  static Map<String, dynamic> toJson(GameState state) {
    return {
      'gridWidth': state.gridWidth,
      'gridHeight': state.gridHeight,
      'tickCount': state.tickCount,
      'dayCount': state.dayCount,
      'timeOfDay': state.timeOfDay.name,
      'selectedItemId': state.selectedItemId,
      'nextItemId': state.nextItemId,
      'unlockedTemplateIds': state.unlockedTemplateIds.toList()..sort(),
      'recentLines': state.recentLines,
      'activityMoment': state.activityMoment.toJson(),
      'life': state.life.toJson(),
      'customTemplates': state.templates.values
          .where(
            (template) => !StarterDatapack.templates.containsKey(template.id),
          )
          .map((template) => template.toJson())
          .toList(),
      'pet': {
        'id': state.pet.id,
        'name': state.pet.name,
        'position': _coordToJson(state.pet.position),
        'mood': state.pet.mood.name,
        'targetItemId': state.pet.targetItemId,
        'currentSpeech': state.pet.currentSpeech,
        'fullness': state.pet.fullness,
        'fun': state.pet.fun,
        'rest': state.pet.rest,
        'cleanliness': state.pet.cleanliness,
        'affection': state.pet.affection,
      },
      'items': state.items
          .map(
            (item) => {
              'id': item.id,
              'templateId': item.templateId,
              'position': _coordToJson(item.position),
              'consumed': item.consumed,
            },
          )
          .toList(),
    };
  }

  static GameState fromJson(Map<String, dynamic> json) {
    final rawCustomTemplates =
        (json['customTemplates'] as List<dynamic>? ?? const []);
    final customTemplates = rawCustomTemplates
        .whereType<Map<String, dynamic>>()
        .map(ItemTemplate.fromJson)
        .toList();
    final mergedTemplates = {
      ...StarterDatapack.templates,
      for (final template in customTemplates) template.id: template,
    };
    final rawItems = (json['items'] as List<dynamic>? ?? const []);
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => ItemInstance(
            id: item['id'] as String,
            templateId: item['templateId'] as String,
            position: _coordFromJson(item['position'] as Map<String, dynamic>),
            consumed: item['consumed'] as bool? ?? false,
          ),
        )
        .where((item) => mergedTemplates.containsKey(item.templateId))
        .toList();
    final petJson = json['pet'] as Map<String, dynamic>;
    final restoredUnlocked = {
      ...StarterDatapack.newGame().unlockedTemplateIds,
      ...(json['unlockedTemplateIds'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .where(mergedTemplates.containsKey),
    };
    restoredUnlocked.addAll(customTemplates.map((template) => template.id));

    return GameState(
      gridWidth: json['gridWidth'] as int? ?? 6,
      gridHeight: json['gridHeight'] as int? ?? 5,
      pet: PetState(
        id: petJson['id'] as String? ?? 'chatty',
        name: petJson['name'] as String? ?? 'Chatty',
        position: _coordFromJson(petJson['position'] as Map<String, dynamic>),
        mood: PetMood.values.byName(
          petJson['mood'] as String? ?? PetMood.curious.name,
        ),
        targetItemId: petJson['targetItemId'] as String?,
        currentSpeech: petJson['currentSpeech'] as String?,
        fullness: PetRules.clampNeed(petJson['fullness'] as int? ?? 4),
        fun: PetRules.clampNeed(petJson['fun'] as int? ?? 4),
        rest: PetRules.clampNeed(petJson['rest'] as int? ?? 4),
        cleanliness: PetRules.clampNeed(petJson['cleanliness'] as int? ?? 4),
        affection: PetRules.clampAffection(petJson['affection'] as int? ?? 0),
      ),
      templates: mergedTemplates,
      items: items,
      tickCount: json['tickCount'] as int? ?? 0,
      dayCount: json['dayCount'] as int? ?? 1,
      timeOfDay: TimeOfDay.values.byName(
        json['timeOfDay'] as String? ?? TimeOfDay.morning.name,
      ),
      eventLog: const [],
      recentLines: (json['recentLines'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      unlockedTemplateIds: restoredUnlocked,
      activityMoment: ChattyActivityMoment.fromJson(
        json['activityMoment'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      life: ChattyLifeState.fromJson(
        json['life'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
      selectedItemId: json['selectedItemId'] as String?,
      nextItemId: json['nextItemId'] as int? ?? 1,
    );
  }

  static Map<String, dynamic> _coordToJson(GridCoord coord) {
    return {'x': coord.x, 'y': coord.y};
  }

  static GridCoord _coordFromJson(Map<String, dynamic> json) {
    return GridCoord(json['x'] as int? ?? 0, json['y'] as int? ?? 0);
  }
}
