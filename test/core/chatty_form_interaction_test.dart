import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/grid.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('care keeps its normal result while a current form adds flavour', () {
    var state = StarterDatapack.newGame();
    state = ChattyPetReducer.reduce(state, const SpawnItem('ball')).state;
    final ball = state.items.single;
    state = state.copyWith(
      life: state.life.copyWith(activeFormId: 'moonlit_bunny'),
      pet: state.pet.copyWith(
        position: GridCoord(ball.position.x, ball.position.y),
      ),
    );

    final result = ChattyPetReducer.reduce(state, PetUseItem(ball.id));

    expect(result.state.pet.fun, greaterThan(state.pet.fun));
    expect(result.state.items, isEmpty);
    expect(result.state.pet.currentSpeech, contains('bunny paws'));
    expect(result.state.life.activeFormId, 'moonlit_bunny');
    expect(result.state.activityMoment.actorEmoji, '🐰');
  });

  test('an idle tick gives the current form a small present-tense moment', () {
    final state = StarterDatapack.newGame().copyWith(
      life: StarterDatapack.newGame().life.copyWith(
        activeFormId: 'comet_chick',
      ),
    );

    final result = ChattyPetReducer.reduce(state, const Tick());

    expect(result.state.pet.currentSpeech, contains('Comet Chatty'));
  });
}
