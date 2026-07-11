import 'chatty_activity_moment.dart';

enum ActivityBucket {
  idle,
  autoScoot,
  snack,
  play,
  cozy,
  tidy,
  discovery,
  celebrate,
  morningShift,
  nightShift,
}

enum MotionPattern {
  idleBob,
  ricochetScoot,
  verticalBounce,
  spinWobble,
  cozyFlop,
  cleanShake,
  inspectBoop,
  hopBurst,
  sunriseStretch,
  moonFlop,
}

enum BackgroundBeat {
  none,
  cityPulse,
  carPass,
  speedLines,
  sunrisePop,
  moonPop,
}

enum ChattySoundCue {
  morning,
  night,
  scoot,
  snack,
  play,
  cozy,
  tidy,
  curious,
  celebrate,
  idleRuff,
}

class ActivityReactionTemplate {
  const ActivityReactionTemplate({
    required this.id,
    required this.bucket,
    required this.motion,
    required this.sound,
    required this.caption,
    required this.backgroundBeat,
    this.propEmoji,
    this.effectEmoji,
    this.durationMs = 1200,
  });

  final String id;
  final ActivityBucket bucket;
  final MotionPattern motion;
  final ChattySoundCue sound;
  final String caption;
  final BackgroundBeat backgroundBeat;
  final String? propEmoji;
  final String? effectEmoji;
  final int durationMs;
}

ActivityReactionTemplate reactionTemplateForMoment({
  required ChattyActivityMoment moment,
  bool phaseChanged = false,
}) {
  if (phaseChanged && moment.phase == SkyPhase.morning) {
    return ActivityReactionTemplate(
      id: 'phase_morning_pop',
      bucket: ActivityBucket.morningShift,
      motion: MotionPattern.sunriseStretch,
      sound: ChattySoundCue.morning,
      caption: moment.caption,
      backgroundBeat: BackgroundBeat.sunrisePop,
      effectEmoji: '☀️',
      durationMs: 1100,
    );
  }

  if (phaseChanged && moment.phase == SkyPhase.night) {
    return ActivityReactionTemplate(
      id: 'phase_night_flop',
      bucket: ActivityBucket.nightShift,
      motion: MotionPattern.moonFlop,
      sound: ChattySoundCue.night,
      caption: moment.caption,
      backgroundBeat: BackgroundBeat.moonPop,
      effectEmoji: '🌙',
      durationMs: 1200,
    );
  }

  return switch (moment.scene) {
    ChattyScene.idle => ActivityReactionTemplate(
        id: 'idle_bob',
        bucket: ActivityBucket.idle,
        motion: MotionPattern.idleBob,
        sound: ChattySoundCue.idleRuff,
        caption: moment.caption,
        backgroundBeat: _ambientBeatFor(moment),
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji,
        durationMs: 900,
      ),
    ChattyScene.scoot => ActivityReactionTemplate(
        id: 'auto_scoot_waaah',
        bucket: ActivityBucket.autoScoot,
        motion: MotionPattern.ricochetScoot,
        sound: ChattySoundCue.scoot,
        caption: moment.caption,
        backgroundBeat: BackgroundBeat.speedLines,
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji ?? '💨',
        durationMs: 1450,
      ),
    ChattyScene.eat => ActivityReactionTemplate(
        id: 'snack_yum_yum',
        bucket: ActivityBucket.snack,
        motion: MotionPattern.verticalBounce,
        sound: ChattySoundCue.snack,
        caption: moment.caption,
        backgroundBeat: _ambientBeatFor(moment),
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji ?? '💚',
        durationMs: 1250,
      ),
    ChattyScene.play => ActivityReactionTemplate(
        id: 'play_spin_boop',
        bucket: ActivityBucket.play,
        motion: MotionPattern.spinWobble,
        sound: ChattySoundCue.play,
        caption: moment.caption,
        backgroundBeat: _playBeatFor(moment),
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji ?? '⭐',
        durationMs: 1350,
      ),
    ChattyScene.sleep => ActivityReactionTemplate(
        id: 'cozy_flop',
        bucket: ActivityBucket.cozy,
        motion: MotionPattern.cozyFlop,
        sound: ChattySoundCue.cozy,
        caption: moment.caption,
        backgroundBeat: _ambientBeatFor(moment),
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji ?? '💤',
        durationMs: 1300,
      ),
    ChattyScene.clean => ActivityReactionTemplate(
        id: 'tidy_shake',
        bucket: ActivityBucket.tidy,
        motion: MotionPattern.cleanShake,
        sound: ChattySoundCue.tidy,
        caption: moment.caption,
        backgroundBeat: _ambientBeatFor(moment),
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji ?? '🫧',
        durationMs: 1200,
      ),
    ChattyScene.inspect => ActivityReactionTemplate(
        id: 'discover_huh',
        bucket: ActivityBucket.discovery,
        motion: MotionPattern.inspectBoop,
        sound: ChattySoundCue.curious,
        caption: moment.caption,
        backgroundBeat: _ambientBeatFor(moment),
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji ?? '❔',
        durationMs: 1150,
      ),
    ChattyScene.celebrate => ActivityReactionTemplate(
        id: 'unlock_tada',
        bucket: ActivityBucket.celebrate,
        motion: MotionPattern.hopBurst,
        sound: ChattySoundCue.celebrate,
        caption: moment.caption,
        backgroundBeat: BackgroundBeat.cityPulse,
        propEmoji: moment.propEmoji,
        effectEmoji: moment.effectEmoji ?? '🎉',
        durationMs: 1400,
      ),
  };
}

BackgroundBeat _ambientBeatFor(ChattyActivityMoment moment) {
  final phase = moment.phase;
  if (phase == SkyPhase.night) {
    return BackgroundBeat.cityPulse;
  }

  final seed = moment.serial + phase.index + moment.scene.index;
  if (phase != SkyPhase.morning && seed.isEven) {
    return BackgroundBeat.carPass;
  }

  return BackgroundBeat.none;
}

BackgroundBeat _playBeatFor(ChattyActivityMoment moment) {
  if (moment.phase == SkyPhase.night) {
    return BackgroundBeat.cityPulse;
  }
  return BackgroundBeat.carPass;
}
