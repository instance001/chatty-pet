import 'dart:math';

import 'chatty_life_state.dart';
import 'item_template.dart';

/// The visual and movement identity of a Chatty manifestation.
///
/// Form definitions are intentionally not an achievement catalogue. Ordinary
/// forms are selected from a weighted, hidden pool when the life system later
/// decides a surprise change can happen.
class ChattyForm {
  const ChattyForm({
    required this.id,
    required this.displayName,
    required this.animal,
    required this.emoji,
    required this.motion,
    required this.backgroundTheme,
    required this.vehicleTheme,
    this.playfulAffinity = 0,
    this.calmAffinity = 0,
    this.nourishingAffinity = 0,
    this.tidyAffinity = 0,
    this.companionAffinity = 0,
  });

  final String id;
  final String displayName;
  final String animal;
  final String emoji;
  final ChattyMotionStyle motion;
  final String backgroundTheme;
  final String vehicleTheme;

  /// These are small nudges, not rules or guarantees.
  final int playfulAffinity;
  final int calmAffinity;
  final int nourishingAffinity;
  final int tidyAffinity;
  final int companionAffinity;
}

enum ChattyMotionStyle { curious, bouncy, floaty, skittery, cozy }

class ChattyForms {
  static const base = ChattyForm(
    id: ChattyLifeState.baseFormId,
    displayName: 'Chatty',
    animal: 'Chatty',
    emoji: '🐶',
    motion: ChattyMotionStyle.curious,
    backgroundTheme: 'toy_room',
    vehicleTheme: 'little_car',
  );

  /// The first ordinary pool is deliberately small. More forms can join it
  /// later without changing any player-facing requirements.
  static const ordinary = <ChattyForm>[
    ChattyForm(
      id: 'sunbeam_pup',
      displayName: 'Sunbeam Chatty',
      animal: 'golden puppy',
      emoji: '🐕',
      motion: ChattyMotionStyle.bouncy,
      backgroundTheme: 'sunny_playroom',
      vehicleTheme: 'skate_scooter',
      playfulAffinity: 3,
      companionAffinity: 1,
    ),
    ChattyForm(
      id: 'moonlit_bunny',
      displayName: 'Moonlit Chatty',
      animal: 'soft bunny',
      emoji: '🐰',
      motion: ChattyMotionStyle.floaty,
      backgroundTheme: 'moonlit_nook',
      vehicleTheme: 'tiny_cloud_train',
      calmAffinity: 3,
      companionAffinity: 1,
    ),
    ChattyForm(
      id: 'mossy_kit',
      displayName: 'Mossy Chatty',
      animal: 'mossy kitten',
      emoji: '🐱',
      motion: ChattyMotionStyle.cozy,
      backgroundTheme: 'mossy_hideaway',
      vehicleTheme: 'leaf_wagon',
      tidyAffinity: 2,
      calmAffinity: 1,
    ),
    ChattyForm(
      id: 'comet_chick',
      displayName: 'Comet Chatty',
      animal: 'sparkly chick',
      emoji: '🐥',
      motion: ChattyMotionStyle.skittery,
      backgroundTheme: 'comet_corner',
      vehicleTheme: 'star_sled',
      playfulAffinity: 2,
      nourishingAffinity: 1,
    ),
  ];

  static const calendar = <ChattyForm>[
    ChattyForm(
      id: 'leapling_chatty',
      displayName: 'Leapling Chatty',
      animal: 'very springy frog',
      emoji: '🐸',
      motion: ChattyMotionStyle.bouncy,
      backgroundTheme: 'puddle_party',
      vehicleTheme: 'lily_pad_boat',
    ),
    ChattyForm(
      id: 'wobble_chatty',
      displayName: 'Wobble Chatty',
      animal: 'ridiculous wiggly worm',
      emoji: '🪱',
      motion: ChattyMotionStyle.skittery,
      backgroundTheme: 'banana_bonanza',
      vehicleTheme: 'banana_car',
    ),
    ChattyForm(
      id: 'spooky_chatty',
      displayName: 'Spooky Chatty',
      animal: 'tiny black cat',
      emoji: '🐈‍⬛',
      motion: ChattyMotionStyle.floaty,
      backgroundTheme: 'spooky_nook',
      vehicleTheme: 'pumpkin_coach',
    ),
    ChattyForm(
      id: 'festive_chatty',
      displayName: 'Festive Chatty',
      animal: 'jolly little reindeer',
      emoji: '🦌',
      motion: ChattyMotionStyle.bouncy,
      backgroundTheme: 'winter_workshop',
      vehicleTheme: 'candy_cane_sled',
    ),
    ChattyForm(
      id: 'cursed_chatty',
      displayName: 'Cursed Chatty',
      animal: 'mildly mysterious bat',
      emoji: '🦇',
      motion: ChattyMotionStyle.floaty,
      backgroundTheme: 'thirteenth_twilight',
      vehicleTheme: 'tiny_hearse',
    ),
    ChattyForm(
      id: 'party_chatty',
      displayName: 'Party Chatty',
      animal: 'extra-celebratory puppy',
      emoji: '🐶',
      motion: ChattyMotionStyle.bouncy,
      backgroundTheme: 'party_room',
      vehicleTheme: 'confetti_cart',
    ),
  ];

  static const all = <ChattyForm>[base, ...ordinary, ...calendar];

  static ChattyForm byId(String id) =>
      all.where((form) => form.id == id).firstOrNull ?? base;

  static String greetingFor(ChattyForm form, String moodName, int seed) {
    final formLines = switch (form.id) {
      'sunbeam_pup' => const [
        'Sunbeam Chatty does a bright little bounce!',
        'A happy puppy wiggle appears out of nowhere!',
      ],
      'moonlit_bunny' => const [
        'Moonlit Chatty gives the air a gentle nose-boop.',
        'Soft bunny ears make a tiny hello-wave.',
      ],
      'mossy_kit' => const [
        'Mossy Chatty makes a very cosy little purr.',
        'A leafy kitten blink says hello.',
      ],
      'comet_chick' => const [
        'Comet Chatty zips a tiny circle and chirps.',
        'A sparkly chick wiggle goes peep!',
      ],
      'spooky_chatty' => const [
        'Spooky Chatty makes one extremely polite meow.',
      ],
      'festive_chatty' => const [
        'Festive Chatty jingles with a very serious little prance.',
      ],
      'cursed_chatty' => const [
        'Cursed Chatty flutters upside down for just a moment.',
      ],
      'leapling_chatty' => const ['Leapling Chatty makes a splash-free hop.'],
      'wobble_chatty' => const [
        'Wobble Chatty wobbles with impressive confidence.',
      ],
      'party_chatty' => const [
        'Party Chatty throws a tiny bit of invisible confetti.',
      ],
      _ => const [
        'Chatty looks up with a curious little wag.',
        'Chatty gives you a happy hello-wiggle.',
      ],
    };
    final moodTail = switch (moodName) {
      'hungry' => ' A snack would make that even better.',
      'sleepy' => ' It is a very gentle hello.',
      'messy' => ' The fluff is a little rumpled today.',
      'grumpy' => ' A small silly moment helps.',
      'playful' => ' Zoomies might happen next.',
      'cozy' => ' Everything feels warm and snug.',
      'happy' => ' What a lovely moment.',
      _ => ' What are we doing next?',
    };
    return '${formLines[seed.abs() % formLines.length]}$moodTail';
  }

  /// A little optional flourish after ordinary care. This is deliberately
  /// cosmetic: it never changes an item's effect, a need, or hidden life
  /// history. It simply lets the current manifestation feel present.
  static String interactionFlourishFor(
    ChattyForm form,
    ItemKind kind,
    String moodName,
    int seed,
  ) {
    final formLine = switch (form.id) {
      'sunbeam_pup' => switch (kind) {
        ItemKind.toy => const [
          'Sunbeam Chatty adds a sunny little zoom!',
          'A golden puppy bounce makes the game extra wiggly!',
        ],
        ItemKind.restItem || ItemKind.comfort => const [
          'Sunbeam Chatty curls up in a warm patch of pretend sunshine.',
        ],
        _ => const ['Sunbeam Chatty gives a bright little tail-wag.'],
      },
      'moonlit_bunny' => switch (kind) {
        ItemKind.food => const ['Moonlit Chatty gives a pleased little hop.'],
        ItemKind.toy => const ['Soft bunny paws make a gentle game of it.'],
        ItemKind.restItem || ItemKind.comfort => const [
          'Moonlit Chatty tucks in for a cloud-soft cuddle.',
        ],
        _ => const ['Moonlit Chatty does a tiny nose-twitch.'],
      },
      'mossy_kit' => switch (kind) {
        ItemKind.cleanItem => const ['Mossy Chatty purrs at the fresh fluff.'],
        ItemKind.restItem || ItemKind.comfort => const [
          'Mossy Chatty settles into a very cosy little loaf.',
        ],
        _ => const ['Mossy Chatty gives a leafy little purr.'],
      },
      'comet_chick' => switch (kind) {
        ItemKind.toy => const ['Comet Chatty chirps and skitters in a circle!'],
        ItemKind.food => const ['Comet Chatty gives an excited peep-peep!'],
        _ => const ['Comet Chatty leaves a tiny sparkle of enthusiasm.'],
      },
      'spooky_chatty' => const ['Spooky Chatty makes one happy, polite meow.'],
      'festive_chatty' => const [
        'Festive Chatty gives a small jingling prance.',
      ],
      'cursed_chatty' => const [
        'Cursed Chatty makes the silliest tiny bat-flutter.',
      ],
      'leapling_chatty' => const ['Leapling Chatty adds one cheerful hop.'],
      'wobble_chatty' => const ['Wobble Chatty wobbles with great excitement.'],
      'party_chatty' => const [
        'Party Chatty shakes out a speck of invisible confetti!',
      ],
      _ => switch (kind) {
        ItemKind.toy => const ['Chatty adds a happy little wag to the game.'],
        ItemKind.restItem || ItemKind.comfort => const [
          'Chatty lets out a very content little sigh.',
        ],
        ItemKind.cleanItem => const ['Chatty feels fresh and fluffy again.'],
        _ => const ['Chatty gives a pleased little wag.'],
      },
    };
    final moodTail = switch (moodName) {
      'grumpy' => ' That helped a little.',
      'sleepy' => ' Very gently.',
      'playful' => ' Zoomies are definitely possible now.',
      'happy' => ' What a lovely bit of care.',
      _ => '',
    };
    return '${formLine[seed.abs() % formLine.length]}$moodTail';
  }

  /// A small, spontaneous moment while Chatty has nothing urgent to do.
  /// It is presentation only: no care, life, or transformation state changes.
  static String idleFor(ChattyForm form, String moodName, int seed) {
    final formLines = switch (form.id) {
      'sunbeam_pup' => const [
        'Sunbeam Chatty chases a bright patch across the floor.',
        'A golden puppy wiggle appears for absolutely no reason.',
      ],
      'moonlit_bunny' => const [
        'Moonlit Chatty makes a quiet hop-hop around the room.',
        'Soft bunny ears listen very carefully to the quiet.',
      ],
      'mossy_kit' => const [
        'Mossy Chatty purrs at a very interesting bit of fluff.',
        'A leafy kitten blink says the room is just right.',
      ],
      'comet_chick' => const [
        'Comet Chatty skitters after a tiny sparkle and chirps.',
        'Comet Chatty makes a sparkly little peep around the room.',
      ],
      'spooky_chatty' => const [
        'Spooky Chatty watches a friendly shadow go by. Meow.',
      ],
      'festive_chatty' => const [
        'Festive Chatty practises a tiny jingling prance.',
      ],
      'cursed_chatty' => const [
        'Cursed Chatty hangs upside down for one very silly second.',
      ],
      'leapling_chatty' => const [
        'Leapling Chatty makes a little puddle-free hop.',
      ],
      'wobble_chatty' => const [
        'Wobble Chatty wobbles around with great purpose.',
      ],
      'party_chatty' => const [
        'Party Chatty finds one last invisible piece of confetti.',
      ],
      _ => const [
        'Chatty has a curious little look around.',
        'Chatty gives a small happy wag.',
      ],
    };
    final moodTail = switch (moodName) {
      'hungry' => ' A snack is sounding nice.',
      'sleepy' => ' It is all very gentle.',
      'messy' => ' The fluff is a little rumpled.',
      'grumpy' => ' A silly game could help.',
      'playful' => ' Zoomies might happen!',
      'cozy' => ' Everything feels snug.',
      'happy' => ' What a lovely day.',
      _ => '',
    };
    return '${formLines[seed.abs() % formLines.length]}$moodTail';
  }

  /// Draws from every non-current ordinary form, with care history quietly
  /// changing the odds. [random] is injected so the future trigger and tests
  /// can be deterministic without making the player experience predictable.
  static ChattyForm chooseOrdinary(
    ChattyLifeState life, {
    required Random random,
  }) {
    final candidates = ordinary
        .where((form) => form.id != life.activeFormId)
        .toList();
    final usableCandidates = candidates.isEmpty ? ordinary : candidates;
    final weights = usableCandidates
        .map((form) => _weightFor(form, life))
        .toList();
    final totalWeight = weights.fold<int>(0, (total, weight) => total + weight);
    var roll = random.nextInt(totalWeight);
    for (var index = 0; index < usableCandidates.length; index++) {
      roll -= weights[index];
      if (roll < 0) return usableCandidates[index];
    }
    return usableCandidates.last;
  }

  static int _weightFor(ChattyForm form, ChattyLifeState life) {
    final affinityNudge =
        (life.playfulMoments * form.playfulAffinity) +
        (life.calmMoments * form.calmAffinity) +
        (life.nourishingMoments * form.nourishingAffinity) +
        (life.tidyMoments * form.tidyAffinity) +
        (life.companionMoments * form.companionAffinity);
    // Every form always remains possible; care only makes a form more likely.
    return 8 + affinityNudge;
  }
}
