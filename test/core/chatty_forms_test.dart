import 'dart:math';

import 'package:chatty_pet_mobile/core/chatty_forms.dart';
import 'package:chatty_pet_mobile/core/chatty_life_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ordinary form draw never repeats Chatty\'s current form', () {
    final life = const ChattyLifeState(activeFormId: 'sunbeam_pup');

    final selected = ChattyForms.chooseOrdinary(life, random: Random(7));

    expect(selected.id, isNot('sunbeam_pup'));
    expect(ChattyForms.ordinary.map((form) => form.id), contains(selected.id));
  });

  test('ordinary form draw keeps every ordinary form possible', () {
    final life = const ChattyLifeState(
      activeFormId: 'moonlit_bunny',
      playfulMoments: 100,
    );
    final seen = <String>{};
    final random = Random(21);

    for (var index = 0; index < 10000; index++) {
      seen.add(ChattyForms.chooseOrdinary(life, random: random).id);
    }

    expect(seen, {'sunbeam_pup', 'mossy_kit', 'comet_chick'});
  });

  test('unknown form ids safely fall back to base Chatty', () {
    expect(ChattyForms.byId('a_very_mysterious_form').id, 'chatty');
  });
}
