import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/ui/chatty_talk_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a swear-word message gets Chatty’s local playful reaction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ChattyTalkPanel(state: StarterDatapack.newGame())),
      ),
    );

    await tester.tap(find.text('Talk to Chatty'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'This is shit');
    await tester.tap(find.byTooltip('Send'));
    await tester.pump();

    expect(find.text('This is shit'), findsOneWidget);
    expect(find.textContaining('ears just did a little boing'), findsOneWidget);
    expect(find.text('Chatty is thinking…'), findsNothing);
  });

  testWidgets(
    'a Chatty reply can be explicitly reported without chat context',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChattyTalkPanel(state: StarterDatapack.newGame()),
          ),
        ),
      );

      await tester.tap(find.text('Talk to Chatty'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tell a grown-up').first);
      await tester.pumpAndSettle();

      expect(find.text('Why are you reporting it?'), findsOneWidget);
      expect(
        find.textContaining('does not send what you said'),
        findsOneWidget,
      );
      expect(find.text('Send report'), findsOneWidget);
    },
  );
}
