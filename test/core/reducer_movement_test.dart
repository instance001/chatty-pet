import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/grid.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pet movement never exits grid', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;

    for (var index = 0; index < 12; index++) {
      state = ChattyPetReducer.reduce(state, const Tick()).state;
      expect(state.pet.position.isWithin(state.gridWidth, state.gridHeight), isTrue);
    }
  });

  test('pet can move toward item', () {
    final initial = StarterDatapack.newGame();
    final spawned = ChattyPetReducer.reduce(initial, const SpawnItem('ball')).state;

    final stepped = ChattyPetReducer.reduce(spawned, const Tick()).state;

    expect(stepped.pet.position, isNot(spawned.pet.position));
  });

  test('selected item is prioritised as the target on tick', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    state = ChattyPetReducer.reduce(state, const SpawnItem('sock')).state;

    final sock = state.items.where((item) => item.templateId == 'sock').first;
    state = state.copyWith(
      selectedItemId: sock.id,
      pet: state.pet.copyWith(
        position: const GridCoord(2, 2),
        targetItemId: null,
      ),
    );

    final result = ChattyPetReducer.reduce(state, const Tick());

    expect(result.state.pet.targetItemId, sock.id);
  });

  test('pet wanders when idle with no items on stage', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const Tick());

    expect(result.state.pet.position, isNot(state.pet.position));
    expect(result.state.pet.currentSpeech, isNotNull);
    expect(result.state.pet.currentSpeech, isNotEmpty);
  });

  test('advance to selected item runs until chatty is beside the target', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    final item = state.items.first;
    state = state.copyWith(
      selectedItemId: item.id,
      pet: state.pet.copyWith(position: const GridCoord(0, 4)),
    );

    final result = ChattyPetReducer.reduce(state, const AdvanceToSelectedItem());

    expect(
      result.state.pet.position.manhattanDistanceTo(item.position),
      lessThanOrEqualTo(1),
    );
    expect(result.state.pet.targetItemId, item.id);
    expect(result.state.pet.currentSpeech, contains('all set'));
  });

  test('advance to selected item falls back to one tick when nothing is selected', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const AdvanceToSelectedItem());

    expect(result.state.tickCount, 1);
  });

  test('advance to selected item collapses duplicate scoot lines in recent moments', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    final item = state.items.first;
    state = state.copyWith(
      selectedItemId: item.id,
      pet: state.pet.copyWith(position: const GridCoord(0, 4)),
    );

    final result = ChattyPetReducer.reduce(state, const AdvanceToSelectedItem());

    expect(
      result.state.recentLines.where((line) => line == 'Chatty scoots closer.'),
      hasLength(1),
    );
  });
}
