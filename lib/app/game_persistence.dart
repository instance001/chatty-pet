import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/game_state.dart';
import '../core/game_state_codec.dart';

class GamePersistence {
  static const _saveKey = 'chatty_pet_save_v1';

  Future<GameState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return GameStateCodec.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(GameState state) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(GameStateCodec.toJson(state));
    await prefs.setString(_saveKey, raw);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
  }
}
