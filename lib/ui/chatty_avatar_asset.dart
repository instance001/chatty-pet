/// The character art is deliberately optional: an old save or future event
/// can still use its friendly emoji while the rest of the app keeps working.
String? chattyAvatarAssetPath(String formId) => switch (formId) {
  'chatty' => 'assets/characters/chatty.png',
  'sunbeam_pup' => 'assets/characters/sunbeam_pup.png',
  'moonlit_bunny' => 'assets/characters/moonlit_bunny.png',
  'mossy_kit' => 'assets/characters/mossy_kit.png',
  'comet_chick' => 'assets/characters/comet_chick.png',
  'leapling_chatty' => 'assets/characters/leapling_chatty.png',
  'wobble_chatty' => 'assets/characters/wobble_chatty.png',
  'spooky_chatty' => 'assets/characters/spooky_chatty.png',
  'festive_chatty' => 'assets/characters/festive_chatty.png',
  'cursed_chatty' => 'assets/characters/cursed_chatty.png',
  'party_chatty' => 'assets/characters/party_chatty.png',
  _ => null,
};
