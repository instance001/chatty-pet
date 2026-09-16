import 'package:chatty_pet_mobile/app/chatty_talk_prompt.dart';
import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the local chat prompt knows Chatty’s current form without revealing rules',
    () {
      final start = StarterDatapack.newGame();
      final state = start.copyWith(
        life: start.life.copyWith(activeFormId: 'moonlit_bunny'),
      );

      final prompt = ChattyTalkPrompt.build(
        state: state,
        message: 'Want to play hopscotch?',
      );

      expect(prompt, contains('Moonlit Chatty'));
      expect(prompt, contains('soft bunny'));
      expect(prompt, contains('Chatty currently feels curious'));
      expect(prompt, contains('Want to play hopscotch?'));
      expect(prompt, contains('never explain hidden game rules'));
    },
  );
}
