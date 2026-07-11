import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../core/activity_reaction_template.dart';
import '../core/game_state.dart';
import '../core/reducer_result.dart';

export '../core/activity_reaction_template.dart' show ChattySoundCue;

class ChattySoundscape {
  ChattySoundscape() : _enabled = !_isUnsupportedDesktopAudioTarget() {
    if (_enabled) {
      _player.setReleaseMode(ReleaseMode.stop);
    }
  }

  final AudioPlayer _player = AudioPlayer();
  final bool _enabled;

  Future<void> dispose() async {
    if (_enabled) {
      await _player.dispose();
    }
  }

  Future<void> stop() async {
    if (_enabled) {
      await _player.stop();
    }
  }

  Future<void> playCue(ChattySoundCue cue) async {
    if (!_enabled) {
      return;
    }

    final assetPath = switch (cue) {
      ChattySoundCue.morning => 'audio/yawn.wav',
      ChattySoundCue.night => 'audio/yawn.wav',
      ChattySoundCue.scoot => 'audio/play.wav',
      ChattySoundCue.snack => 'audio/snack.wav',
      ChattySoundCue.play => 'audio/play.wav',
      ChattySoundCue.cozy => 'audio/cozy.wav',
      ChattySoundCue.tidy => 'audio/tidy.wav',
      ChattySoundCue.curious => 'audio/curious.wav',
      ChattySoundCue.celebrate => 'audio/celebrate.wav',
      ChattySoundCue.idleRuff => 'audio/idle_ruff.wav',
    };

    final volume = switch (cue) {
      ChattySoundCue.idleRuff => 0.18,
      ChattySoundCue.morning || ChattySoundCue.night => 0.20,
      ChattySoundCue.cozy => 0.20,
      ChattySoundCue.tidy => 0.18,
      _ => 0.24,
    };

    try {
      await _player.stop();
      await _player.play(
        AssetSource(assetPath),
        mode: PlayerMode.lowLatency,
        volume: volume,
      );
    } catch (_) {
      // Soft-fail if a desktop target or asset setup cannot play a cue.
    }
  }

  Future<void> playForTransition({
    required GameState previousState,
    required ReducerResult result,
  }) async {
    final nextState = result.state;
    final phaseChanged =
        nextState.activityMoment.phase != previousState.activityMoment.phase;

    if (nextState.activityMoment.serial !=
        previousState.activityMoment.serial) {
      final template = reactionTemplateForMoment(
        moment: nextState.activityMoment,
      );
      await playCue(template.sound);
      return;
    }

    if (phaseChanged) {
      final template = reactionTemplateForMoment(
        moment: nextState.activityMoment,
        phaseChanged: true,
      );
      await playCue(template.sound);
    }
  }
}

bool _isUnsupportedDesktopAudioTarget() {
  if (kIsWeb) {
    return false;
  }

  return defaultTargetPlatform == TargetPlatform.windows;
}
