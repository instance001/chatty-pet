import 'dart:io';

import 'package:chatty_pet_mobile/core/chatty_forms.dart';
import 'package:chatty_pet_mobile/ui/chatty_avatar_asset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every Chatty form has a bundled character image', () {
    for (final form in ChattyForms.all) {
      final assetPath = chattyAvatarAssetPath(form.id);

      expect(assetPath, isNotNull, reason: '${form.id} needs character art');
      expect(
        File(assetPath!).existsSync(),
        isTrue,
        reason: '${form.id} points to a missing asset: $assetPath',
      );
    }
  });
}
