import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/events.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('greeting Chatty changes the moment but not care or needs', () {
    final state = StarterDatapack.newGame();

    final result = ChattyPetReducer.reduce(state, const PetGreet());

    expect(result.events.whereType<PetGreeted>(), hasLength(1));
    expect(result.state.pet.fullness, state.pet.fullness);
    expect(result.state.pet.fun, state.pet.fun);
    expect(result.state.pet.rest, state.pet.rest);
    expect(result.state.pet.cleanliness, state.pet.cleanliness);
    expect(result.state.life.totalCareMoments, state.life.totalCareMoments);
    expect(result.state.activityMoment.serial, state.activityMoment.serial + 1);
    expect(result.state.pet.currentSpeech, contains('Chatty'));
  });
}
