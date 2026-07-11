import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/chatty_activity_moment.dart';
import 'package:chatty_pet_mobile/core/events.dart';
import 'package:chatty_pet_mobile/core/grid.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inspect requires valid adjacent item', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const PetInspect());

    expect(result.events.whereType<ActionRejected>(), isNotEmpty);
  });

  test('eat consumes edible item', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('strawberry')).state;
    final item = state.items.first;
    final adjusted = state.copyWith(
      pet: state.pet.copyWith(position: GridCoord(item.position.x, item.position.y)),
      selectedItemId: item.id,
    );

    final result = ChattyPetReducer.reduce(
      adjusted,
      PetUseItem(item.id),
    );

    expect(result.events.whereType<PetAteItem>(), isNotEmpty);
    expect(result.state.items, isEmpty);
    expect(result.state.pet.fullness, greaterThan(adjusted.pet.fullness));
    expect(result.state.activityMoment.scene, ChattyScene.eat);
    expect(result.state.activityMoment.propEmoji, '🍓');
  });

  test('play with toy consumes toy to keep the stage tidy', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    final item = state.items.first;
    state = state.copyWith(
      pet: state.pet.copyWith(position: item.position),
      selectedItemId: item.id,
    );

    final result = ChattyPetReducer.reduce(state, PetUseItem(item.id));

    expect(result.events.whereType<PetPlayedWithItem>(), isNotEmpty);
    expect(result.state.items, isEmpty);
    expect(result.state.pet.fun, greaterThan(state.pet.fun));
    expect(result.state.activityMoment.scene, ChattyScene.play);
  });

  test('reducer result emits events and lines', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const StartNewGame());

    expect(result.events, isNotEmpty);
    expect(result.lines, isNotEmpty);
  });

  test('inspect explains when selected item is too far away', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('sock')).state;
    final item = state.items.first;
    state = state.copyWith(
      selectedItemId: item.id,
      pet: state.pet.copyWith(position: const GridCoord(5, 4)),
    );

    final result = ChattyPetReducer.reduce(state, PetInspect(item.id));

    expect(result.events.whereType<ActionRejected>(), isNotEmpty);
    expect(result.lines.last, contains('too far away'));
  });

  test('care unlocks new items after affection threshold', () {
    var state = StarterDatapack.newGame();
    for (var count = 0; count < 4; count++) {
      state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
      final item = state.items.last;
      state = state.copyWith(
        pet: state.pet.copyWith(position: item.position),
        selectedItemId: item.id,
      );
      state = ChattyPetReducer.reduce(state, PetUseItem(item.id)).state;
    }

    expect(state.unlockedTemplateIds.contains('brush'), isTrue);
    expect(state.unlockedTemplateIds.contains('cushion'), isTrue);
  });

  test('higher affection unlocks deeper content tiers', () {
    var state = StarterDatapack.newGame();
    for (var count = 0; count < 8; count++) {
      state = ChattyPetReducer.reduce(state, const SpawnItem('strawberry')).state;
      final item = state.items.last;
      state = state.copyWith(
        pet: state.pet.copyWith(position: item.position),
        selectedItemId: item.id,
      );
      state = ChattyPetReducer.reduce(state, PetUseItem(item.id)).state;
    }

    expect(state.unlockedTemplateIds.contains('biscuit'), isTrue);
    expect(state.unlockedTemplateIds.contains('blanket'), isTrue);
    expect(state.unlockedTemplateIds.contains('storybook'), isTrue);
  });

  test('clear stage removes all items and resets selection', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    state = ChattyPetReducer.reduce(state, const SpawnItem('sock')).state;
    state = state.copyWith(selectedItemId: state.items.first.id);

    final result = ChattyPetReducer.reduce(state, const ClearStage());

    expect(result.events.whereType<StageCleared>().single.clearedCount, 2);
    expect(result.state.items, isEmpty);
    expect(result.state.selectedItemId, isNull);
  });

  test('remove stage item puts away just one item and clears selection if needed', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    state = ChattyPetReducer.reduce(state, const SpawnItem('sock')).state;
    final removedItem = state.items.first;
    state = state.copyWith(
      selectedItemId: removedItem.id,
      pet: state.pet.copyWith(targetItemId: removedItem.id),
    );

    final result = ChattyPetReducer.reduce(state, RemoveStageItem(removedItem.id));

    expect(result.events.whereType<StageItemRemoved>().single.itemId, removedItem.id);
    expect(result.state.items, hasLength(1));
    expect(result.state.items.single.id, isNot(removedItem.id));
    expect(result.state.selectedItemId, isNull);
    expect(result.state.pet.targetItemId, isNull);
  });

  test('use when ready auto-scoots to selected food and uses it in one action', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('strawberry')).state;
    final item = state.items.first;
    state = state.copyWith(
      selectedItemId: item.id,
      pet: state.pet.copyWith(position: const GridCoord(5, 4)),
    );

    final result = ChattyPetReducer.reduce(state, const UseSelectedItemWhenReady());

    expect(result.events.whereType<PetAteItem>(), isNotEmpty);
    expect(result.state.items, isEmpty);
    expect(result.state.selectedItemId, isNull);
    expect(result.state.pet.targetItemId, isNull);
  });

  test('use when ready rejects cleanly when nothing is selected', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const UseSelectedItemWhenReady());

    expect(result.events.whereType<ActionRejected>(), isNotEmpty);
    expect(result.lines.last, contains('Pick a stage item first'));
  });

  test('inspect when ready auto-scoots to selected item and inspects it', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('sock')).state;
    final item = state.items.first;
    state = state.copyWith(
      selectedItemId: item.id,
      pet: state.pet.copyWith(position: const GridCoord(5, 4)),
    );

    final result = ChattyPetReducer.reduce(
      state,
      const InspectSelectedItemWhenReady(),
    );

    expect(result.events.whereType<PetInspectedItem>(), isNotEmpty);
    expect(result.state.selectedItemId, item.id);
    expect(result.state.pet.targetItemId, item.id);
  });

  test('inspect when ready rejects cleanly when nothing is selected', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(
      state,
      const InspectSelectedItemWhenReady(),
    );

    expect(result.events.whereType<ActionRejected>(), isNotEmpty);
    expect(result.lines.last, contains('Pick a stage item first'));
  });

  test('repeated identical item use still increments activity serial', () {
    var state = StarterDatapack.newGame();

    state = ChattyPetReducer.reduce(state, const SpawnItem('strawberry')).state;
    var item = state.items.last;
    state = state.copyWith(
      pet: state.pet.copyWith(position: item.position),
      selectedItemId: item.id,
    );
    state = ChattyPetReducer.reduce(state, PetUseItem(item.id)).state;

    final firstSerial = state.activityMoment.serial;

    state = ChattyPetReducer.reduce(state, const SpawnItem('strawberry')).state;
    item = state.items.last;
    state = state.copyWith(
      pet: state.pet.copyWith(position: item.position),
      selectedItemId: item.id,
    );
    state = ChattyPetReducer.reduce(state, PetUseItem(item.id)).state;

    expect(state.activityMoment.scene, ChattyScene.eat);
    expect(state.activityMoment.serial, greaterThan(firstSerial));
  });

  test('tick phase updates activity background without needing a new scene', () {
    final state = StarterDatapack.newGame().copyWith(
      activityMoment: const ChattyActivityMoment(
        serial: 5,
        scene: ChattyScene.play,
        phase: SkyPhase.morning,
        caption: 'Playful little bounce.',
      ),
      tickCount: 1,
    );

    final result = ChattyPetReducer.reduce(state, const Tick());

    expect(result.state.timeOfDay.name, 'morning');
    expect(result.state.activityMoment.phase, SkyPhase.morning);
    expect(result.state.activityMoment.serial, 5);
  });
}
