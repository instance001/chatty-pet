import 'package:chatty_pet_mobile/content/starter_datapack.dart';
import 'package:chatty_pet_mobile/core/chatty_calendar_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Halloween queues a local-only themed Chatty form once', () {
    final halloween = DateTime(2026, 10, 31, 9, 30);
    final first = ChattyCalendarEvents.observe(
      StarterDatapack.newGame(),
      halloween,
    );
    final second = ChattyCalendarEvents.observe(first, halloween);

    expect(first.life.pendingTransformationFormId, 'spooky_chatty');
    expect(first.life.encounteredEventIds, contains('halloween:2026-10-31'));
    expect(identical(first, second), isTrue);
  });

  test('a completed calendar form returns to the previous form afterwards', () {
    final start = StarterDatapack.newGame();
    final halloween = ChattyCalendarEvents.observe(
      start.copyWith(life: start.life.copyWith(activeFormId: 'mossy_kit')),
      DateTime(2026, 10, 31),
    );
    final active = halloween.copyWith(
      life: halloween.life.completeQueuedTransformation(dayCount: 6),
    );
    final nextDay = ChattyCalendarEvents.observe(active, DateTime(2026, 11, 1));

    expect(active.life.activeFormId, 'spooky_chatty');
    expect(nextDay.life.activeFormId, 'mossy_kit');
    expect(nextDay.life.activeCalendarEventKey, isNull);
  });

  test('Friday the 13th and leap day have their own surprises', () {
    final friday = ChattyCalendarEvents.observe(
      StarterDatapack.newGame(),
      DateTime(2026, 11, 13),
    );
    final leapDay = ChattyCalendarEvents.observe(
      StarterDatapack.newGame(),
      DateTime(2028, 2, 29),
    );

    expect(friday.life.pendingTransformationFormId, 'cursed_chatty');
    expect(leapDay.life.pendingTransformationFormId, 'leapling_chatty');
  });

  test(
    'Chatty celebrates an adoption anniversary, not adoption day itself',
    () {
      final adoptionDay = ChattyCalendarEvents.observe(
        StarterDatapack.newGame(),
        DateTime(2026, 9, 16),
      );
      final anniversary = ChattyCalendarEvents.observe(
        adoptionDay,
        DateTime(2027, 9, 16),
      );

      expect(adoptionDay.life.adoptionDateKey, '2026-09-16');
      expect(adoptionDay.life.pendingTransformationFormId, isNull);
      expect(anniversary.life.pendingTransformationFormId, 'party_chatty');
      expect(
        anniversary.life.encounteredEventIds,
        contains('adoption_anniversary:2027-09-16'),
      );
    },
  );
}
