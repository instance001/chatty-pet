import 'item_template.dart';

class CustomItemFactory {
  static const emojiOptions = <ItemKind, List<String>>{
    ItemKind.food: ['🍎', '🧁', '🥕', '🍪', '🍌', '🍉'],
    ItemKind.toy: ['🪁', '🧸', '🪄', '🎈', '🛼', '🪀'],
    ItemKind.restItem: ['🛏️', '🧺', '☁️', '🌙', '🧸', '🧶'],
    ItemKind.cleanItem: ['🫧', '🧼', '🪥', '🧽', '🚿', '🧴'],
    ItemKind.curiosity: ['🔎', '🪨', '🦋', '🌈', '⭐', '🐚'],
    ItemKind.comfort: ['🧦', '📖', '🎵', '💡', '🕯️', '🪴'],
  };

  static ItemTemplate build({
    required String id,
    required String displayName,
    required String emoji,
    required ItemKind kind,
  }) {
    final name = displayName.trim();

    return ItemTemplate(
      id: id,
      displayName: name,
      emoji: emoji,
      kind: kind,
      inspectLines: _inspectLines(name, kind),
      useLines: _useLines(name, kind),
      noticeLines: _noticeLines(name, kind),
      fullnessDelta: switch (kind) {
        ItemKind.food => 2,
        _ => 0,
      },
      funDelta: switch (kind) {
        ItemKind.toy => 2,
        _ => 0,
      },
      restDelta: switch (kind) {
        ItemKind.restItem => 2,
        ItemKind.comfort => 1,
        _ => 0,
      },
      cleanlinessDelta: switch (kind) {
        ItemKind.cleanItem => 2,
        _ => 0,
      },
      affectionDelta: 1,
    );
  }

  static List<String> _inspectLines(String name, ItemKind kind) {
    return switch (kind) {
      ItemKind.food => [
          '$name smells tasty.',
          'Chatty gives $name a curious sniff.',
          '$name looks like a promising little snack.',
        ],
      ItemKind.toy => [
          '$name looks fun already.',
          'Chatty stares at $name like playtime is very close.',
          '$name looks like it might cause zoomies.',
        ],
      ItemKind.restItem => [
          '$name looks extra cozy.',
          'Chatty checks whether $name is nap-shaped.',
          '$name seems perfect for a little flop.',
        ],
      ItemKind.cleanItem => [
          '$name looks ready for tidy time.',
          'Chatty studies $name very carefully.',
          '$name could make the fluff feel much neater.',
        ],
      ItemKind.curiosity => [
          '$name is full of tiny mysteries.',
          'Chatty peers closely at $name.',
          '$name earns a very thoughtful little stare.',
        ],
      ItemKind.comfort => [
          '$name feels like a comforting little friend.',
          'Chatty inspects $name with a calm look.',
          '$name seems nice to keep close by.',
        ],
    };
  }

  static List<String> _useLines(String name, ItemKind kind) {
    return switch (kind) {
      ItemKind.food => [
          'Chatty enjoys the $name.',
          '$name disappears in happy little bites.',
          '$name makes for a very successful snack moment.',
        ],
      ItemKind.toy => [
          'Chatty plays happily with $name.',
          '$name sparks a burst of fun.',
          'Chatty turns $name into a game almost immediately.',
        ],
      ItemKind.restItem => [
          'Chatty settles in with $name.',
          '$name becomes a cozy resting spot.',
          '$name starts a peaceful little pause.',
        ],
      ItemKind.cleanItem => [
          '$name helps Chatty feel fresh again.',
          'Tidy time with $name goes very nicely.',
          'Chatty looks fluffier and neater after $name.',
        ],
      ItemKind.curiosity => [
          'Chatty explores $name with careful interest.',
          '$name inspires a whole little moment of discovery.',
          'Chatty investigates every tiny detail of $name very seriously.',
        ],
      ItemKind.comfort => [
          '$name helps Chatty feel safe and settled.',
          'Chatty relaxes beside $name.',
          '$name brings a gentle, cozy feeling.',
        ],
    };
  }

  static List<String> _noticeLines(String name, ItemKind kind) {
    return switch (kind) {
      ItemKind.food => [
          '$name appears on the stage.',
          'Chatty notices the tasty-looking $name.',
          '$name catches Chatty\'s eye right away.',
        ],
      ItemKind.toy => [
          '$name lands nearby.',
          'Chatty notices $name and perks up.',
          '$name looks like playtime waiting to happen already.',
        ],
      ItemKind.restItem => [
          '$name makes the room look cozier.',
          'Chatty notices a comfy $name.',
          '$name appears, and the room feels softer right away.',
        ],
      ItemKind.cleanItem => [
          '$name shows up for tidy time.',
          'Chatty notices $name and pauses.',
          '$name looks perfect for a quick freshen-up.',
        ],
      ItemKind.curiosity => [
          '$name brings a little mystery.',
          'Chatty notices the interesting $name.',
          '$name catches Chatty\'s full attention at once.',
        ],
      ItemKind.comfort => [
          '$name appears and feels friendly.',
          'Chatty notices the comforting $name.',
          '$name makes the whole room feel extra gentle.',
        ],
    };
  }
}
