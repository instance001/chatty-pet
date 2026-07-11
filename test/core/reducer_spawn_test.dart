import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/custom_item_factory.dart';
import 'package:chatty_pet_mobile/core/events.dart';
import 'package:chatty_pet_mobile/core/item_template.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('starter datapack has enough templates for a content-rich first build', () {
    expect(StarterDatapack.templates.length, greaterThanOrEqualTo(18));
  });

  test('new game creates pet inside grid', () {
    final state = StarterDatapack.newGame();

    expect(state.pet.position.isWithin(state.gridWidth, state.gridHeight), isTrue);
  });

  test('spawn known item adds item instance', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const SpawnItem('strawberry'));

    expect(result.state.items, hasLength(1));
    expect(result.events.whereType<ItemSpawned>(), isNotEmpty);
  });

  test('spawn unknown item is rejected', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const SpawnItem('mystery_cube'));

    expect(result.events.whereType<ActionRejected>(), isNotEmpty);
    expect(result.state.items, isEmpty);
  });

  test('start new game creates the intro line', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const StartNewGame());

    expect(
      result.state.recentLines,
      contains('Chatty is awake and ready to play!'),
    );
  });

  test('locked item cannot spawn before unlock threshold', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const SpawnItem('cushion'));

    expect(result.events.whereType<ActionRejected>(), isNotEmpty);
    expect(result.lines.last, contains('not unlocked'));
  });

  test('creating a custom item adds it to the unlocked shelf immediately', () {
    final template = CustomItemFactory.build(
      id: 'custom_rainbow_kite',
      displayName: 'Rainbow Kite',
      emoji: '🪁',
      kind: ItemKind.toy,
    );

    final result = ChattyPetReducer.reduce(
      StarterDatapack.newGame(),
      CreateCustomTemplate(template),
    );

    expect(result.events.whereType<CustomTemplateCreated>(), isNotEmpty);
    expect(result.state.templates.containsKey(template.id), isTrue);
    expect(result.state.unlockedTemplateIds.contains(template.id), isTrue);
  });
}
