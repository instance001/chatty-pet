import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/chatty_activity_moment.dart';
import 'package:chatty_pet_mobile/core/chatty_life_state.dart';
import 'package:chatty_pet_mobile/core/custom_item_factory.dart';
import 'package:chatty_pet_mobile/core/game_state_codec.dart';
import 'package:chatty_pet_mobile/core/item_template.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('game state codec round-trips important progression fields', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    final item = state.items.single;
    state = state.copyWith(
      selectedItemId: item.id,
      pet: state.pet.copyWith(position: item.position),
    );
    state = ChattyPetReducer.reduce(state, PetUseItem(item.id)).state;

    final encoded = GameStateCodec.toJson(state);
    final decoded = GameStateCodec.fromJson(encoded);

    expect(decoded.pet.affection, state.pet.affection);
    expect(decoded.pet.fun, state.pet.fun);
    expect(decoded.items.length, state.items.length);
    expect(decoded.selectedItemId, state.selectedItemId);
    expect(decoded.unlockedTemplateIds, state.unlockedTemplateIds);
    expect(decoded.activityMoment.scene, state.activityMoment.scene);
    expect(decoded.activityMoment.serial, state.activityMoment.serial);
    expect(decoded.activityMoment.phase, state.activityMoment.phase);
  });

  test('game state codec round-trips custom templates', () {
    final customTemplate = CustomItemFactory.build(
      id: 'custom_snuggle_lamp',
      displayName: 'Snuggle Lamp',
      emoji: '💡',
      kind: ItemKind.comfort,
    );
    final state = ChattyPetReducer.reduce(
      StarterDatapack.newGame(),
      CreateCustomTemplate(customTemplate),
    ).state;

    final encoded = GameStateCodec.toJson(state);
    final decoded = GameStateCodec.fromJson(encoded);

    expect(decoded.templates.containsKey(customTemplate.id), isTrue);
    expect(decoded.templates[customTemplate.id]?.displayName, 'Snuggle Lamp');
    expect(decoded.unlockedTemplateIds.contains(customTemplate.id), isTrue);
  });

  test('game state codec round-trips activity moments', () {
    final state = StarterDatapack.newGame().copyWith(
      activityMoment: const ChattyActivityMoment(
        serial: 9,
        scene: ChattyScene.clean,
        phase: SkyPhase.night,
        caption: 'Bubble sparkle scrub time.',
        propEmoji: '🧼',
        effectEmoji: '🫧',
      ),
    );

    final encoded = GameStateCodec.toJson(state);
    final decoded = GameStateCodec.fromJson(encoded);

    expect(decoded.activityMoment.serial, 9);
    expect(decoded.activityMoment.scene, ChattyScene.clean);
    expect(decoded.activityMoment.phase, SkyPhase.night);
    expect(decoded.activityMoment.propEmoji, '🧼');
    expect(decoded.activityMoment.effectEmoji, '🫧');
  });

  test('game state codec keeps Chatty\'s hidden life memories', () {
    var state = StarterDatapack.newGame();
    for (final kind in ChattyCareKind.values) {
      state = state.copyWith(
        life: state.life.recordCare(kind, dayCount: kind.index + 1),
      );
    }
    state = state.copyWith(
      life: state.life.copyWith(
        activeFormId: 'sunny_bunny',
        discoveredFormIds: {'chatty', 'sunny_bunny'},
        encounteredEventIds: {'halloween_2026'},
        lastObservedLocalDateKey: '2026-10-31',
      ),
    );

    final decoded = GameStateCodec.fromJson(GameStateCodec.toJson(state));

    expect(decoded.life.activeFormId, 'sunny_bunny');
    expect(decoded.life.discoveredFormIds, {'chatty', 'sunny_bunny'});
    expect(decoded.life.encounteredEventIds, {'halloween_2026'});
    expect(decoded.life.lastObservedLocalDateKey, '2026-10-31');
    expect(decoded.life.totalCareMoments, state.life.totalCareMoments);
  });
}
