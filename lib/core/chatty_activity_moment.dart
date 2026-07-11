import 'item_template.dart';
import 'pet_rules.dart';

enum ChattyScene {
  idle,
  scoot,
  eat,
  play,
  sleep,
  clean,
  inspect,
  celebrate,
}

enum SkyPhase {
  morning,
  day,
  evening,
  night,
}

class ChattyActivityMoment {
  const ChattyActivityMoment({
    this.serial = 0,
    this.scene = ChattyScene.idle,
    this.phase = SkyPhase.morning,
    this.caption = 'Chatty is ready for a cozy day.',
    this.propEmoji,
    this.effectEmoji,
  });

  final int serial;
  final ChattyScene scene;
  final SkyPhase phase;
  final String caption;
  final String? propEmoji;
  final String? effectEmoji;

  ChattyActivityMoment copyWith({
    int? serial,
    ChattyScene? scene,
    SkyPhase? phase,
    String? caption,
    Object? propEmoji = _sentinel,
    Object? effectEmoji = _sentinel,
  }) {
    return ChattyActivityMoment(
      serial: serial ?? this.serial,
      scene: scene ?? this.scene,
      phase: phase ?? this.phase,
      caption: caption ?? this.caption,
      propEmoji: propEmoji == _sentinel ? this.propEmoji : propEmoji as String?,
      effectEmoji: effectEmoji == _sentinel
          ? this.effectEmoji
          : effectEmoji as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serial': serial,
      'scene': scene.name,
      'phase': phase.name,
      'caption': caption,
      'propEmoji': propEmoji,
      'effectEmoji': effectEmoji,
    };
  }

  static ChattyActivityMoment fromJson(Map<String, dynamic> json) {
    return ChattyActivityMoment(
      serial: json['serial'] as int? ?? 0,
      scene: ChattyScene.values.byName(
        json['scene'] as String? ?? ChattyScene.idle.name,
      ),
      phase: SkyPhase.values.byName(
        json['phase'] as String? ?? SkyPhase.morning.name,
      ),
      caption: json['caption'] as String? ?? 'Chatty is ready for a cozy day.',
      propEmoji: json['propEmoji'] as String?,
      effectEmoji: json['effectEmoji'] as String?,
    );
  }
}

ChattyActivityMoment buildIdleActivityMoment({
  required int serial,
  required TimeOfDay timeOfDay,
  required String caption,
}) {
  return ChattyActivityMoment(
    serial: serial,
    scene: ChattyScene.idle,
    phase: skyPhaseForTimeOfDay(timeOfDay),
    caption: caption,
    effectEmoji: _idleEffectForPhase(timeOfDay),
  );
}

ChattyActivityMoment buildScootActivityMoment({
  required int serial,
  required TimeOfDay timeOfDay,
  required String caption,
  String? propEmoji,
}) {
  return ChattyActivityMoment(
    serial: serial,
    scene: ChattyScene.scoot,
    phase: skyPhaseForTimeOfDay(timeOfDay),
    caption: caption,
    propEmoji: propEmoji,
    effectEmoji: '💨',
  );
}

ChattyActivityMoment buildCelebrateActivityMoment({
  required int serial,
  required TimeOfDay timeOfDay,
  required String caption,
  String? propEmoji,
}) {
  return ChattyActivityMoment(
    serial: serial,
    scene: ChattyScene.celebrate,
    phase: skyPhaseForTimeOfDay(timeOfDay),
    caption: caption,
    propEmoji: propEmoji,
    effectEmoji: '✨',
  );
}

ChattyActivityMoment buildInspectActivityMoment({
  required int serial,
  required TimeOfDay timeOfDay,
  required ItemTemplate template,
  required String caption,
}) {
  return ChattyActivityMoment(
    serial: serial,
    scene: ChattyScene.inspect,
    phase: skyPhaseForTimeOfDay(timeOfDay),
    caption: caption,
    propEmoji: template.emoji,
    effectEmoji: template.kind == ItemKind.curiosity ? '🔎' : '👀',
  );
}

ChattyActivityMoment buildUseActivityMoment({
  required int serial,
  required TimeOfDay timeOfDay,
  required ItemTemplate template,
  required String caption,
}) {
  return ChattyActivityMoment(
    serial: serial,
    scene: _sceneForItemKind(template.kind),
    phase: skyPhaseForTimeOfDay(timeOfDay),
    caption: caption,
    propEmoji: template.emoji,
    effectEmoji: _effectForItemKind(template.kind),
  );
}

SkyPhase skyPhaseForTimeOfDay(TimeOfDay timeOfDay) {
  return switch (timeOfDay) {
    TimeOfDay.morning => SkyPhase.morning,
    TimeOfDay.afternoon => SkyPhase.day,
    TimeOfDay.evening => SkyPhase.evening,
    TimeOfDay.night => SkyPhase.night,
  };
}

ChattyScene _sceneForItemKind(ItemKind kind) {
  return switch (kind) {
    ItemKind.food => ChattyScene.eat,
    ItemKind.toy => ChattyScene.play,
    ItemKind.restItem => ChattyScene.sleep,
    ItemKind.cleanItem => ChattyScene.clean,
    ItemKind.curiosity => ChattyScene.inspect,
    ItemKind.comfort => ChattyScene.sleep,
  };
}

String _effectForItemKind(ItemKind kind) {
  return switch (kind) {
    ItemKind.food => '🍽️',
    ItemKind.toy => '🎉',
    ItemKind.restItem => '💤',
    ItemKind.cleanItem => '🫧',
    ItemKind.curiosity => '✨',
    ItemKind.comfort => '💛',
  };
}

String _idleEffectForPhase(TimeOfDay timeOfDay) {
  return switch (timeOfDay) {
    TimeOfDay.morning => '☀️',
    TimeOfDay.afternoon => '🌤️',
    TimeOfDay.evening => '🌆',
    TimeOfDay.night => '🌙',
  };
}

const _sentinel = Object();
