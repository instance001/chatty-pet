import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/events.dart';
import 'package:chatty_pet_mobile/core/pet_rules.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tick decay lowers needs on schedule', () {
    var state = StarterDatapack.newGame();

    state = ChattyPetReducer.reduce(state, const Tick()).state;
    expect(state.pet.fullness, 4);
    expect(state.pet.rest, 4);

    state = ChattyPetReducer.reduce(state, const Tick()).state;
    expect(state.pet.rest, 3);

    state = ChattyPetReducer.reduce(state, const Tick()).state;
    expect(state.pet.fullness, 3);
  });

  test('day count advances after a full tick cycle', () {
    var state = StarterDatapack.newGame();
    PetEvent? dayAdvanceEvent;

    for (var tick = 0; tick < PetRules.ticksPerDay; tick++) {
      final result = ChattyPetReducer.reduce(state, const Tick());
      state = result.state;
      dayAdvanceEvent = result.events.whereType<DayAdvanced>().firstOrNull;
    }

    expect(state.dayCount, 2);
    expect(state.timeOfDay, TimeOfDay.morning);
    expect(dayAdvanceEvent, isNotNull);
  });
}
