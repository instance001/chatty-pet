import 'chatty_life_state.dart';
import 'game_state.dart';

/// Local-only date surprises. This reads only the device's current date; it
/// does not use Android calendar data, contacts, location, or a network.
class ChattyCalendarEvents {
  static const _events = <ChattyCalendarEvent>[
    ChattyCalendarEvent(
      id: 'leap_day',
      formId: 'leapling_chatty',
      matches: _isLeapDay,
    ),
    ChattyCalendarEvent(
      id: 'april_fools',
      formId: 'wobble_chatty',
      matches: _isAprilFools,
    ),
    ChattyCalendarEvent(
      id: 'halloween',
      formId: 'spooky_chatty',
      matches: _isHalloween,
    ),
    ChattyCalendarEvent(
      id: 'christmas',
      formId: 'festive_chatty',
      matches: _isChristmas,
    ),
    ChattyCalendarEvent(
      id: 'friday_13th',
      formId: 'cursed_chatty',
      matches: _isFridayThe13th,
    ),
  ];

  static GameState observe(GameState state, DateTime localNow) {
    final dateKey = _dateKey(localNow);
    var life = state.life;
    if (life.adoptionDateKey == null) {
      life = life.copyWith(adoptionDateKey: dateKey);
    }
    final event = _eventFor(life, localNow);
    final eventKey = event == null ? null : '${event.id}:$dateKey';

    if (life.activeCalendarEventKey != null &&
        life.activeCalendarEventKey != eventKey) {
      life = life.finishCalendarEvent();
    }

    if (life.lastObservedLocalDateKey == dateKey &&
        (life.activeCalendarEventKey == eventKey ||
            life.pendingCalendarEventKey == eventKey)) {
      return identical(life, state.life) ? state : state.copyWith(life: life);
    }

    life = life.copyWith(lastObservedLocalDateKey: dateKey);
    if (event != null &&
        !life.encounteredEventIds.contains(eventKey) &&
        life.activeCalendarEventKey != eventKey &&
        life.pendingCalendarEventKey != eventKey) {
      life = life
          .copyWith(
            encounteredEventIds: {...life.encounteredEventIds, eventKey!},
          )
          .queueCalendarTransformation(
            formId: event.formId,
            eventKey: eventKey,
          );
    }
    return state.copyWith(life: life);
  }

  static String describeOccurrence(String occurrenceKey) {
    final parts = occurrenceKey.split(':');
    final eventId = parts.first;
    final event = _events.where((entry) => entry.id == eventId).firstOrNull;
    final dateLabel = parts.length > 1
        ? _friendlyDate(parts.sublist(1).join(':'))
        : '';
    final title = switch (eventId) {
      'leap_day' => 'Leap Day puddle party',
      'april_fools' => 'April Fools wobble',
      'halloween' => 'Halloween hush',
      'christmas' => 'Christmas sparkle',
      'friday_13th' => 'Friday the 13th oddness',
      'adoption_anniversary' => 'Chatty’s adoption day party',
      _ => event?.id ?? 'A mysterious day',
    };
    return dateLabel.isEmpty ? title : '$title · $dateLabel';
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String _friendlyDate(String key) {
    final date = DateTime.tryParse(key);
    if (date == null) return key;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static bool _isLeapDay(DateTime date) => date.month == 2 && date.day == 29;
  static bool _isAprilFools(DateTime date) => date.month == 4 && date.day == 1;
  static bool _isHalloween(DateTime date) => date.month == 10 && date.day == 31;
  static bool _isChristmas(DateTime date) => date.month == 12 && date.day == 25;
  static bool _isFridayThe13th(DateTime date) =>
      date.weekday == DateTime.friday && date.day == 13;

  static ChattyCalendarEvent? _eventFor(
    ChattyLifeState life,
    DateTime localNow,
  ) {
    final fixed = _events.where((entry) => entry.matches(localNow)).firstOrNull;
    if (fixed != null) return fixed;
    final adoptionDate = DateTime.tryParse(life.adoptionDateKey ?? '');
    if (adoptionDate != null &&
        localNow.year > adoptionDate.year &&
        localNow.month == adoptionDate.month &&
        localNow.day == adoptionDate.day) {
      return const ChattyCalendarEvent(
        id: 'adoption_anniversary',
        formId: 'party_chatty',
        matches: _neverMatchesDirectly,
      );
    }
    return null;
  }

  static bool _neverMatchesDirectly(DateTime _) => false;
}

class ChattyCalendarEvent {
  const ChattyCalendarEvent({
    required this.id,
    required this.formId,
    required this.matches,
  });

  final String id;
  final String formId;
  final bool Function(DateTime date) matches;
}
