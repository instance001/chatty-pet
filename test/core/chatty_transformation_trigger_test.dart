import 'dart:math';

import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/actions.dart';
import 'package:chatty_pet_mobile/core/chatty_life_state.dart';
import 'package:chatty_pet_mobile/core/events.dart';
import 'package:chatty_pet_mobile/core/reducer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an eligible new day can queue one hidden ordinary transformation', () {
    final state = StarterDatapack.newGame().copyWith(
      tickCount: 23,
      dayCount: 3,
      life: const ChattyLifeState(
        playfulMoments: 9,
        caredForDays: 3,
        variedCareDays: 2,
        lastCareDay: 3,
        ordinaryTransformationEligible: true,
      ),
    );

    final result = ChattyPetReducer.reduce(
      state,
      const Tick(),
      random: _AlwaysZeroRandom(),
    );

    expect(result.events.whereType<ChattyTransformationQueued>(), hasLength(1));
    expect(result.state.life.pendingTransformationFormId, isNotNull);
    expect(result.state.life.activeFormId, 'chatty');
  });

  test('a completed transformation starts its hidden cooldown', () {
    const life = ChattyLifeState(
      pendingTransformationFormId: 'mossy_kit',
      ordinaryTransformationEligible: true,
    );

    final completed = life.completeQueuedTransformation(dayCount: 12);

    expect(completed.activeFormId, 'mossy_kit');
    expect(completed.discoveredFormIds, contains('mossy_kit'));
    expect(completed.lastTransformationDay, 12);
    expect(completed.ordinaryTransformationEligible, isFalse);
    expect(completed.pendingTransformationFormId, isNull);
  });
}

class _AlwaysZeroRandom implements Random {
  @override
  bool nextBool() => false;

  @override
  double nextDouble() => 0;

  @override
  int nextInt(int max) => 0;
}
