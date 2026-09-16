import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/activity_reaction_template.dart';
import '../core/chatty_activity_moment.dart';
import '../core/pet_rules.dart';
import 'chatty_avatar_asset.dart';

class ChattyActivityBox extends StatefulWidget {
  const ChattyActivityBox({
    super.key,
    required this.moment,
    required this.formId,
    required this.mood,
  });

  final ChattyActivityMoment moment;
  final String formId;
  final PetMood mood;

  @override
  State<ChattyActivityBox> createState() => _ChattyActivityBoxState();
}

class _ChattyActivityBoxState extends State<ChattyActivityBox>
    with TickerProviderStateMixin {
  late ActivityReactionTemplate _activeTemplate = reactionTemplateForMoment(
    moment: widget.moment,
  );

  late final AnimationController _reactionController = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: _activeTemplate.durationMs),
  )..forward();

  late final AnimationController _ambientController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat();

  bool _phaseReactionActive = false;

  @override
  void initState() {
    super.initState();
    _reactionController.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _phaseReactionActive &&
          mounted) {
        setState(() {
          _phaseReactionActive = false;
          _activeTemplate = reactionTemplateForMoment(moment: widget.moment);
        });
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChattyActivityBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    final serialChanged = oldWidget.moment.serial != widget.moment.serial;
    final phaseChanged =
        !serialChanged && oldWidget.moment.phase != widget.moment.phase;

    if (!serialChanged && !phaseChanged) {
      return;
    }

    _phaseReactionActive = phaseChanged;
    _activeTemplate = reactionTemplateForMoment(
      moment: widget.moment,
      phaseChanged: phaseChanged,
    );
    _reactionController.duration = Duration(
      milliseconds: _activeTemplate.durationMs,
    );
    _reactionController.forward(from: 0);
  }

  @override
  void dispose() {
    _reactionController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _paletteFor(widget.moment.phase, widget.formId);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 190 || constraints.maxWidth < 430;
        final zoomedOutCompact = compact && constraints.maxHeight < 210;
        final sceneScale = zoomedOutCompact ? 0.88 : 1.0;
        final captionHeight = zoomedOutCompact
            ? 24.0
            : compact
            ? 26.0
            : 62.0;
        final groundHeight = zoomedOutCompact
            ? 86.0
            : compact
            ? 98.0
            : 124.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: palette.sky,
            ),
            border: Border.all(color: palette.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220E2D26),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _reactionController,
                _ambientController,
              ]),
              builder: (context, child) {
                // The controllers may continue to exist while this widget is
                // mounted, but the rendered scene intentionally becomes a
                // still illustration when the device requests less motion.
                final reaction = reducedMotion
                    ? 1.0
                    : Curves.easeOutCubic.transform(_reactionController.value);
                final ambientPhase = reducedMotion
                    ? 0.0
                    : _ambientController.value * 2 * math.pi;
                final motion = _motionFor(
                  _activeTemplate.motion,
                  reaction,
                  math.sin(ambientPhase + 0.7),
                  ambientPhase,
                  compact,
                );

                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: const Alignment(-0.25, -0.95),
                            radius: 1.15,
                            colors: [
                              palette.glow.withValues(alpha: 0.44),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    _BackgroundBeatLayer(
                      beat: _activeTemplate.backgroundBeat,
                      compact: compact,
                      progress: reaction,
                      ambientPhase: ambientPhase,
                      isNight: palette.isNight,
                    ),
                    _SkyAccents(
                      phase: widget.moment.phase,
                      compact: compact,
                      progress: reaction,
                      ambientDrift: math.sin(ambientPhase) * 18,
                      twinkle:
                          0.5 +
                          (0.5 * ((math.sin(ambientPhase * 1.5) + 1) / 2)),
                    ),
                    _HorizonDetail(
                      compact: compact,
                      isNight: palette.isNight,
                      alignRight: false,
                      bounce: math.sin(ambientPhase * 0.8) * 5,
                    ),
                    _HorizonDetail(
                      compact: compact,
                      isNight: palette.isNight,
                      alignRight: true,
                      bounce: math.cos(ambientPhase * 0.9) * 4,
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _GroundBand(
                        compact: compact,
                        height: groundHeight,
                        palette: palette,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      top: compact ? 18 : 24,
                      bottom: captionHeight + 12,
                      child: Transform.scale(
                        alignment: Alignment.bottomCenter,
                        scale: sceneScale,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _SceneProp(
                              template: _activeTemplate,
                              compact: compact,
                              progress: reaction,
                              motion: motion,
                              // Older saved greetings used the actor emoji as
                              // a separate scene prop. The form art now owns
                              // Chatty's appearance, so suppress only that
                              // duplicate while keeping genuine item props.
                              isLegacyActorProp:
                                  widget.moment.scene == ChattyScene.idle &&
                                  _activeTemplate.propEmoji ==
                                      widget.moment.actorEmoji,
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: compact ? 18 : 24,
                              child: Center(
                                child: _GroundShadow(
                                  compact: compact,
                                  widthScale: motion.shadowScale,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: compact ? 70 : 88,
                              child: Center(
                                child: _MoodAccent(
                                  mood: widget.mood,
                                  compact: compact,
                                  phase: ambientPhase,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: compact ? 18 : 24,
                              child: Center(
                                child: _CozyBase(
                                  visible:
                                      _activeTemplate.bucket ==
                                      ActivityBucket.cozy,
                                  compact: compact,
                                  settle: motion.settle,
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: compact ? 18 : 24,
                              child: Center(
                                child: Transform.translate(
                                  offset: Offset(motion.actorX, motion.actorY),
                                  child: Transform.rotate(
                                    angle: motion.rotation,
                                    child: Transform.scale(
                                      scaleX: motion.scaleX,
                                      scaleY: motion.scaleY,
                                      child: _ChattyActor(
                                        compact: compact,
                                        formId: widget.formId,
                                        emoji: widget.moment.actorEmoji,
                                        tailWiggle: motion.tailWiggle,
                                        tilt: motion.actorTilt,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: compact ? 94 : 118,
                              child: Center(
                                child: _SceneEffect(
                                  template: _activeTemplate,
                                  compact: compact,
                                  progress: reaction,
                                  ambientFloat:
                                      math.sin(ambientPhase * 1.2) * 4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 12,
                      child: Container(
                        constraints: BoxConstraints(minHeight: captionHeight),
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 14,
                          vertical: compact ? 5 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xEEFFFFFF),
                          borderRadius: BorderRadius.circular(
                            compact ? 12 : 18,
                          ),
                          border: Border.all(color: const Color(0xC7DCE3DE)),
                        ),
                        child: Text(
                          _activeTemplate.caption,
                          maxLines: compact ? 1 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF23433D),
                            fontSize: compact ? 10.5 : 13.5,
                            fontWeight: FontWeight.w800,
                            height: compact ? 1.1 : 1.28,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// A small, wordless current-mood cue. It reflects the existing care bars;
/// it never represents an unlock, score, or progression requirement.
class _MoodAccent extends StatelessWidget {
  const _MoodAccent({
    required this.mood,
    required this.compact,
    required this.phase,
  });

  final PetMood mood;
  final bool compact;
  final double phase;

  @override
  Widget build(BuildContext context) {
    final accent = switch (mood) {
      PetMood.happy => '💛',
      PetMood.playful => '⭐',
      PetMood.hungry => '🍪',
      PetMood.sleepy => '💤',
      PetMood.messy => '🫧',
      PetMood.curious => '❔',
      PetMood.grumpy => '💢',
      PetMood.cozy => '💗',
    };
    final drift = math.sin(phase * 1.5) * (compact ? 3 : 5);
    final sway = math.cos(phase * 1.2) * 0.08;

    return ExcludeSemantics(
      child: Transform.translate(
        offset: Offset(compact ? 38 : 48, drift),
        child: Transform.rotate(
          angle: sway,
          child: Opacity(
            opacity: mood == PetMood.grumpy ? 0.58 : 0.72,
            child: Text(accent, style: TextStyle(fontSize: compact ? 17 : 22)),
          ),
        ),
      ),
    );
  }
}

class _StageMotion {
  const _StageMotion({
    this.actorX = 0,
    this.actorY = 0,
    this.rotation = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.shadowScale = 1,
    this.tailWiggle = 0,
    this.actorTilt = 0,
    this.settle = 0,
  });

  final double actorX;
  final double actorY;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final double shadowScale;
  final double tailWiggle;
  final double actorTilt;
  final double settle;
}

_StageMotion _motionFor(
  MotionPattern motion,
  double progress,
  double breathe,
  double ambientPhase,
  bool compact,
) {
  final idleY = -5 + (breathe * 3);
  final idleTail = math.sin(ambientPhase * 1.4) * 0.22;
  final bigHop = compact ? 50.0 : 64.0;

  switch (motion) {
    case MotionPattern.idleBob:
      return _StageMotion(
        actorY: idleY,
        tailWiggle: idleTail,
        actorTilt: math.sin(ambientPhase * 0.8) * 0.08,
      );
    case MotionPattern.ricochetScoot:
      final chaos = math.sin(progress * math.pi * 7);
      final chaos2 = math.cos(progress * math.pi * 10);
      return _StageMotion(
        actorX: chaos * (compact ? 98 : 126) * (1 - (progress * 0.16)),
        actorY: -chaos.abs() * (compact ? 34 : 44),
        rotation: chaos2 * 0.52,
        scaleX: 1 + (chaos.abs() * 0.14),
        scaleY: 1 - (chaos.abs() * 0.12),
        shadowScale: 1 + (chaos.abs() * 0.34),
        tailWiggle: math.sin(progress * math.pi * 15) * 0.28,
        actorTilt: math.sin(progress * math.pi * 7) * 0.18,
      );
    case MotionPattern.verticalBounce:
      final beat = math.sin(progress * math.pi * 3.2).abs();
      return _StageMotion(
        actorY: idleY - (beat * bigHop),
        actorX: math.sin(progress * math.pi * 6) * 5,
        rotation: math.sin(progress * math.pi * 3.2) * 0.12,
        scaleX: 1 + (beat * 0.1),
        scaleY: 1 - (beat * 0.08),
        shadowScale: 1 + (beat * 0.24),
        tailWiggle: math.sin(progress * math.pi * 9) * 0.22,
      );
    case MotionPattern.spinWobble:
      final wobble = progress > 0.78
          ? math.sin(((progress - 0.78) / 0.22) * math.pi * 3) * 0.24
          : 0.0;
      final beat = math.sin(progress * math.pi * 2.4).abs();
      return _StageMotion(
        actorY: idleY - (beat * (compact ? 22 : 30)),
        actorX: math.sin(progress * math.pi * 4) * 8,
        rotation: (progress * math.pi * 2) + wobble,
        scaleX: 1 + (beat * 0.08),
        scaleY: 1 - (beat * 0.08),
        shadowScale: 1 + (beat * 0.18),
        tailWiggle: math.sin(progress * math.pi * 10) * 0.24,
      );
    case MotionPattern.cozyFlop:
      final glide = Curves.easeOutExpo.transform((progress / 0.45).clamp(0, 1));
      final settle = Curves.easeOut.transform(progress);
      final flopY = progress < 0.55
          ? -math.sin((progress / 0.55) * math.pi) * (compact ? 20 : 28)
          : ((progress - 0.55) / 0.45) * (compact ? 18 : 22);
      return _StageMotion(
        actorX: (1 - glide) * -(compact ? 98 : 120),
        actorY: flopY,
        rotation: progress < 0.6 ? 0.45 * (1 - (progress / 0.6)) : 0,
        scaleY: 1 - (settle * 0.12),
        shadowScale: 1 + (settle * 0.16),
        tailWiggle: 0.04,
        settle: settle,
      );
    case MotionPattern.cleanShake:
      final bounce = math.sin(progress * math.pi * 2.6).abs();
      return _StageMotion(
        actorX: math.sin(progress * math.pi * 18) * (compact ? 8 : 10),
        actorY: idleY - (bounce * (compact ? 14 : 18)),
        rotation: math.sin(progress * math.pi * 14) * 0.15,
        scaleX: 1 + (bounce * 0.06),
        scaleY: 1 - (bounce * 0.06),
        shadowScale: 1 + (bounce * 0.2),
        tailWiggle: math.sin(progress * math.pi * 12) * 0.2,
      );
    case MotionPattern.inspectBoop:
      if (progress < 0.36) {
        final t = progress / 0.36;
        return _StageMotion(
          actorX: t * (compact ? 20 : 28),
          actorY: idleY - (t * 10),
          rotation: -0.22 * t,
          tailWiggle: 0.06,
          actorTilt: -0.24 * t,
        );
      }
      if (progress < 0.7) {
        final t = (progress - 0.36) / 0.34;
        return _StageMotion(
          actorX: (1 - t) * (compact ? 18 : 24) - (t * (compact ? 34 : 42)),
          actorY: idleY - (math.sin(t * math.pi) * (compact ? 18 : 24)),
          rotation: 0.18 * t,
          shadowScale: 1 + (0.18 * math.sin(t * math.pi)),
          tailWiggle: 0.1,
          actorTilt: -0.1,
        );
      }
      final t = (progress - 0.7) / 0.3;
      return _StageMotion(
        actorX: -(1 - t) * (compact ? 18 : 24),
        actorY: idleY - (math.sin(t * math.pi * 2) * 6 * (1 - t)),
        rotation: 0.08 * (1 - t),
        tailWiggle: 0.08,
        actorTilt: -0.06,
      );
    case MotionPattern.hopBurst:
      final beat = math.sin(progress * math.pi * 3.6).abs();
      return _StageMotion(
        actorX: math.sin(progress * math.pi * 7) * (compact ? 10 : 12),
        actorY: idleY - (beat * (compact ? 42 : 54)),
        rotation: math.sin(progress * math.pi * 7) * 0.22,
        scaleX: 1 + (beat * 0.08),
        scaleY: 1 - (beat * 0.08),
        shadowScale: 1 + (beat * 0.24),
        tailWiggle: math.sin(progress * math.pi * 12) * 0.26,
        actorTilt: math.sin(progress * math.pi * 5) * 0.08,
      );
    case MotionPattern.sunriseStretch:
      final beat = math.sin(progress * math.pi * 2.2).abs();
      return _StageMotion(
        actorY: idleY - (beat * (compact ? 24 : 30)),
        scaleX: 1 - (beat * 0.08),
        scaleY: 1 + (beat * 0.14),
        shadowScale: 1 + (beat * 0.12),
        tailWiggle: math.sin(progress * math.pi * 5) * 0.1,
        actorTilt: math.sin(progress * math.pi * 2) * 0.06,
      );
    case MotionPattern.moonFlop:
      final settle = Curves.easeOut.transform(progress);
      return _StageMotion(
        actorX: (1 - settle) * (compact ? 30 : 38),
        actorY: settle * (compact ? 16 : 20),
        rotation: (1 - settle) * 0.24,
        scaleY: 1 - (settle * 0.12),
        shadowScale: 1 + (settle * 0.1),
        settle: settle,
      );
  }
}

class _BackgroundBeatLayer extends StatelessWidget {
  const _BackgroundBeatLayer({
    required this.beat,
    required this.compact,
    required this.progress,
    required this.ambientPhase,
    required this.isNight,
  });

  final BackgroundBeat beat;
  final bool compact;
  final double progress;
  final double ambientPhase;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return Stack(
              children: [
                if (beat == BackgroundBeat.speedLines)
                  ...List.generate(6, (index) {
                    final top = 36.0 + (index * (compact ? 18 : 22));
                    final slide = ((progress * 1.2) + (index * 0.12)) % 1.0;
                    return Positioned(
                      left: (slide * (width + 140)) - 140,
                      top: top,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Container(
                          width: compact ? 96 : 132,
                          height: compact ? 8 : 10,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    );
                  }),
                if (beat == BackgroundBeat.carPass)
                  Positioned(
                    left: (-64 + ((width + 128) * ((progress + 0.2) % 1.0))),
                    bottom: compact ? 104 : 126,
                    child: Text(
                      '🚗',
                      style: TextStyle(fontSize: compact ? 26 : 34),
                    ),
                  ),
                if (beat == BackgroundBeat.cityPulse)
                  Positioned(
                    right: compact ? 26 : 32,
                    bottom: compact ? 116 : 140,
                    child: Row(
                      children: List.generate(5, (index) {
                        final alpha =
                            0.35 +
                            (0.55 *
                                ((math.sin(ambientPhase * 2 + index) + 1) / 2));
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: compact ? 10 : 12,
                          height: compact ? 10 : 12,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFF8F1A6,
                            ).withValues(alpha: alpha),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),
                  ),
                if (beat == BackgroundBeat.sunrisePop)
                  Positioned(
                    left: compact ? 56 : 70,
                    top: compact ? 22 : 28,
                    child: Transform.scale(
                      scale: 0.7 + (0.5 * math.sin(progress * math.pi).abs()),
                      child: Text(
                        '☀️',
                        style: TextStyle(fontSize: compact ? 30 : 38),
                      ),
                    ),
                  ),
                if (beat == BackgroundBeat.moonPop)
                  Positioned(
                    left: compact ? 56 : 70,
                    top: compact ? 24 : 28,
                    child: Opacity(
                      opacity: 0.5 + (0.5 * math.sin(progress * math.pi).abs()),
                      child: Row(
                        children: [
                          Text(
                            isNight ? '🌙' : '⭐',
                            style: TextStyle(fontSize: compact ? 28 : 34),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '✨',
                            style: TextStyle(fontSize: compact ? 20 : 26),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SkyAccents extends StatelessWidget {
  const _SkyAccents({
    required this.phase,
    required this.compact,
    required this.progress,
    required this.ambientDrift,
    required this.twinkle,
  });

  final SkyPhase phase;
  final bool compact;
  final double progress;
  final double ambientDrift;
  final double twinkle;

  @override
  Widget build(BuildContext context) {
    final skyEmoji = switch (phase) {
      SkyPhase.morning => '☀️',
      SkyPhase.day => '🌤️',
      SkyPhase.evening => '🌇',
      SkyPhase.night => '🌙',
    };

    return Stack(
      children: [
        Positioned(
          left: 14 + ambientDrift,
          top: 12,
          child: Container(
            width: compact ? 58 : 72,
            height: compact ? 58 : 72,
            decoration: const BoxDecoration(
              color: Color(0x44FFFFFF),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                skyEmoji,
                style: TextStyle(fontSize: compact ? 30 : 38),
              ),
            ),
          ),
        ),
        if (phase != SkyPhase.night)
          Positioned(
            right: 14 - ambientDrift,
            top: compact ? 14 : 18,
            child: Row(
              children: [
                Text('☁️', style: TextStyle(fontSize: compact ? 28 : 34)),
                const SizedBox(width: 8),
                Text('☁️', style: TextStyle(fontSize: compact ? 22 : 28)),
              ],
            ),
          ),
        if (phase == SkyPhase.night) ...[
          Positioned(
            top: 28,
            left: 112,
            child: Opacity(
              opacity: twinkle,
              child: const Text('✦', style: TextStyle(fontSize: 20)),
            ),
          ),
          Positioned(
            top: 52,
            right: 88,
            child: Opacity(
              opacity: 0.45 + (twinkle * 0.5),
              child: const Text('✦', style: TextStyle(fontSize: 18)),
            ),
          ),
          Positioned(
            top: 42,
            right: 136,
            child: Opacity(
              opacity: 0.35 + (twinkle * 0.4),
              child: const Text('⋆', style: TextStyle(fontSize: 22)),
            ),
          ),
        ],
      ],
    );
  }
}

class _GroundBand extends StatelessWidget {
  const _GroundBand({
    required this.compact,
    required this.height,
    required this.palette,
  });

  final bool compact;
  final double height;
  final _ActivityPalette palette;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: palette.grass,
                ),
              ),
            ),
          ),
          Positioned(
            left: -12,
            right: -12,
            top: -16,
            child: Container(
              height: compact ? 34 : 42,
              decoration: BoxDecoration(
                color: palette.hill,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: compact ? 8 : 10,
            child: Text('🌼', style: TextStyle(fontSize: compact ? 20 : 24)),
          ),
          Positioned(
            left: compact ? 60 : 74,
            bottom: compact ? 10 : 12,
            child: Text('🌸', style: TextStyle(fontSize: compact ? 16 : 20)),
          ),
          Positioned(
            right: 22,
            bottom: compact ? 10 : 12,
            child: Text('🌿', style: TextStyle(fontSize: compact ? 24 : 30)),
          ),
        ],
      ),
    );
  }
}

class _HorizonDetail extends StatelessWidget {
  const _HorizonDetail({
    required this.compact,
    required this.isNight,
    required this.alignRight,
    required this.bounce,
  });

  final bool compact;
  final bool isNight;
  final bool alignRight;
  final double bounce;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: alignRight ? null : (compact ? 18 : 24),
      right: alignRight ? (compact ? 18 : 24) : null,
      bottom: (compact ? 86 : 104) + bounce,
      child: _BackgroundDetail(
        compact: compact,
        isNight: isNight,
        alignRight: alignRight,
      ),
    );
  }
}

class _BackgroundDetail extends StatelessWidget {
  const _BackgroundDetail({
    required this.compact,
    required this.isNight,
    required this.alignRight,
  });

  final bool compact;
  final bool isNight;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    if (isNight || alignRight) {
      return SizedBox(
        width: compact ? 142 : 176,
        height: compact ? 92 : 116,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Building(width: compact ? 18 : 22, height: compact ? 28 : 36),
              const SizedBox(width: 6),
              _Building(width: compact ? 22 : 28, height: compact ? 52 : 66),
              const SizedBox(width: 6),
              _Building(width: compact ? 16 : 20, height: compact ? 34 : 42),
              const SizedBox(width: 6),
              _Building(width: compact ? 24 : 30, height: compact ? 42 : 54),
              const SizedBox(width: 6),
              _Building(width: compact ? 18 : 22, height: compact ? 26 : 32),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      width: compact ? 142 : 176,
      height: compact ? 120 : 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            child: Container(
              width: compact ? 20 : 26,
              height: compact ? 38 : 48,
              decoration: BoxDecoration(
                color: const Color(0xFF6D7C45),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Positioned(
            bottom: compact ? 24 : 30,
            child: Container(
              width: compact ? 86 : 106,
              height: compact ? 62 : 80,
              decoration: BoxDecoration(
                color: const Color(0xFF76C05C),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: compact ? 8 : 10,
            bottom: compact ? 54 : 68,
            child: Container(
              width: compact ? 48 : 60,
              height: compact ? 38 : 50,
              decoration: BoxDecoration(
                color: const Color(0xFF95DD72),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            right: compact ? 6 : 8,
            bottom: compact ? 48 : 62,
            child: Container(
              width: compact ? 42 : 54,
              height: compact ? 34 : 44,
              decoration: BoxDecoration(
                color: const Color(0xFF5AAA47),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            left: compact ? 10 : 12,
            bottom: compact ? 8 : 10,
            child: Text('🌼', style: TextStyle(fontSize: compact ? 16 : 20)),
          ),
          Positioned(
            right: compact ? 10 : 12,
            bottom: compact ? 8 : 10,
            child: Text('🌳', style: TextStyle(fontSize: compact ? 22 : 28)),
          ),
        ],
      ),
    );
  }
}

class _Building extends StatelessWidget {
  const _Building({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF4F6680),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        border: Border.all(color: const Color(0x44FFFFFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Wrap(
          spacing: 3,
          runSpacing: 3,
          children: List.generate(
            4,
            (_) => Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF7E7A1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroundShadow extends StatelessWidget {
  const _GroundShadow({required this.compact, required this.widthScale});

  final bool compact;
  final double widthScale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (compact ? 60 : 70) * widthScale,
      height: compact ? 12 : 14,
      decoration: BoxDecoration(
        color: const Color(0x330A241F),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ChattyActor extends StatelessWidget {
  const _ChattyActor({
    required this.compact,
    required this.formId,
    required this.emoji,
    required this.tailWiggle,
    required this.tilt,
  });

  final bool compact;
  final String formId;
  final String emoji;
  final double tailWiggle;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final petSize = compact ? 74.0 : 92.0;
    final assetPath = chattyAvatarAssetPath(formId);
    final showDogTail = assetPath == null && (emoji == '🐶' || emoji == '🐕');

    return SizedBox(
      width: compact ? 102 : 122,
      height: compact ? 84 : 102,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          if (showDogTail)
            Positioned(
              right: compact ? 14 : 18,
              bottom: compact ? 22 : 30,
              child: Transform.rotate(
                angle: tailWiggle,
                alignment: Alignment.centerLeft,
                child: Text(
                  '〰️',
                  style: TextStyle(
                    fontSize: compact ? 20 : 24,
                    color: const Color(0xFF7A5B3E),
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: compact ? 12 : 16,
            child: Transform.rotate(
              angle: tilt,
              child: assetPath == null
                  ? Text(emoji, style: TextStyle(fontSize: petSize))
                  : SizedBox(
                      width: petSize,
                      height: petSize,
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, _, _) =>
                            Text(emoji, style: TextStyle(fontSize: petSize)),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CozyBase extends StatelessWidget {
  const _CozyBase({
    required this.visible,
    required this.compact,
    required this.settle,
  });

  final bool visible;
  final bool compact;
  final double settle;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: 0.5 + (0.5 * settle),
      child: Container(
        width: compact ? 96 : 114,
        height: compact ? 28 : 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5B7),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE2CF96)),
        ),
        child: Center(
          child: Text('🛏️', style: TextStyle(fontSize: compact ? 14 : 18)),
        ),
      ),
    );
  }
}

class _SceneProp extends StatelessWidget {
  const _SceneProp({
    required this.template,
    required this.compact,
    required this.progress,
    required this.motion,
    required this.isLegacyActorProp,
  });

  final ActivityReactionTemplate template;
  final bool compact;
  final double progress;
  final _StageMotion motion;
  final bool isLegacyActorProp;

  @override
  Widget build(BuildContext context) {
    if (template.propEmoji == null || isLegacyActorProp) {
      return const SizedBox.shrink();
    }

    final propSize = compact ? 42.0 : 54.0;
    final baseLeft = switch (template.bucket) {
      ActivityBucket.autoScoot => compact ? 124.0 : 152.0,
      ActivityBucket.snack => compact ? 114.0 : 138.0,
      ActivityBucket.discovery => compact ? 116.0 : 140.0,
      ActivityBucket.play => compact ? 126.0 : 154.0,
      ActivityBucket.cozy => compact ? 100.0 : 122.0,
      _ => compact ? 118.0 : 144.0,
    };

    final bounce = switch (template.motion) {
      MotionPattern.verticalBounce =>
        -16 * math.sin(progress * math.pi * 3).abs(),
      MotionPattern.inspectBoop => -10 * math.sin(progress * math.pi),
      MotionPattern.spinWobble => -12 * math.sin(progress * math.pi * 2).abs(),
      _ => 0.0,
    };

    return Positioned(
      left: baseLeft + (motion.actorX * 0.18),
      bottom: (compact ? 34 : 42) + bounce - (motion.settle * 8),
      child: Opacity(
        opacity: 0.7 + (0.3 * progress),
        child: Text(template.propEmoji!, style: TextStyle(fontSize: propSize)),
      ),
    );
  }
}

class _SceneEffect extends StatelessWidget {
  const _SceneEffect({
    required this.template,
    required this.compact,
    required this.progress,
    required this.ambientFloat,
  });

  final ActivityReactionTemplate template;
  final bool compact;
  final double progress;
  final double ambientFloat;

  @override
  Widget build(BuildContext context) {
    final emoji = template.effectEmoji;
    if (emoji == null) {
      return const SizedBox.shrink();
    }

    return Opacity(
      opacity: 0.45 + (0.55 * progress),
      child: Transform.translate(
        offset: Offset(0, (-16 * (1 - progress)) + ambientFloat),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: TextStyle(fontSize: compact ? 28 : 36)),
            if (template.bucket == ActivityBucket.tidy ||
                template.bucket == ActivityBucket.play ||
                template.bucket == ActivityBucket.celebrate) ...[
              const SizedBox(width: 4),
              Text(
                template.bucket == ActivityBucket.tidy ? '✨' : '⭐',
                style: TextStyle(fontSize: compact ? 22 : 28),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityPalette {
  const _ActivityPalette({
    required this.sky,
    required this.grass,
    required this.hill,
    required this.border,
    required this.glow,
    required this.isNight,
  });

  final List<Color> sky;
  final List<Color> grass;
  final Color hill;
  final Color border;
  final Color glow;
  final bool isNight;
}

_ActivityPalette _paletteFor(SkyPhase phase, String formId) {
  final base = switch (phase) {
    SkyPhase.morning => const _ActivityPalette(
      sky: [Color(0xFFE8F6FF), Color(0xFFE0F4E9), Color(0xFFD2E8DF)],
      grass: [Color(0xFFA2D98C), Color(0xFF73B363)],
      hill: Color(0xFFAFDD9F),
      border: Color(0xFFD1E5DF),
      glow: Color(0xFFF8D96D),
      isNight: false,
    ),
    SkyPhase.day => const _ActivityPalette(
      sky: [Color(0xFFD9F1FF), Color(0xFFD6F0EA), Color(0xFFC8E3D8)],
      grass: [Color(0xFF9AD57F), Color(0xFF6AAA5B)],
      hill: Color(0xFFA6D78F),
      border: Color(0xFFD0E7E0),
      glow: Color(0xFFF0D86B),
      isNight: false,
    ),
    SkyPhase.evening => const _ActivityPalette(
      sky: [Color(0xFFF7D1B7), Color(0xFFEAD8D2), Color(0xFFD6DED7)],
      grass: [Color(0xFF92BC79), Color(0xFF668B58)],
      hill: Color(0xFFACC37F),
      border: Color(0xDDDAD7D1),
      glow: Color(0xFFF1A56F),
      isNight: false,
    ),
    SkyPhase.night => const _ActivityPalette(
      sky: [Color(0xFF213247), Color(0xFF274A5E), Color(0xFF2D605E)],
      grass: [Color(0xFF607F60), Color(0xFF446345)],
      hill: Color(0xFF5E775D),
      border: Color(0xFF47636A),
      glow: Color(0xFFB8C5FF),
      isNight: true,
    ),
  };
  final tint = switch (formId) {
    'sunbeam_pup' => const Color(0xFFFFD76B),
    'moonlit_bunny' => const Color(0xFFBFC6FF),
    'mossy_kit' => const Color(0xFF8CCB8D),
    'comet_chick' => const Color(0xFFFFA8D4),
    'leapling_chatty' => const Color(0xFF79D8A1),
    'wobble_chatty' => const Color(0xFFFFE05E),
    'spooky_chatty' => const Color(0xFF9B7AAE),
    'festive_chatty' => const Color(0xFFF3E2EE),
    'cursed_chatty' => const Color(0xFF6D5B83),
    'party_chatty' => const Color(0xFFFFA9C6),
    _ => const Color(0xFFB4E4D3),
  };
  return _ActivityPalette(
    sky: base.sky.map((color) => Color.lerp(color, tint, 0.16)!).toList(),
    grass: base.grass.map((color) => Color.lerp(color, tint, 0.07)!).toList(),
    hill: Color.lerp(base.hill, tint, 0.08)!,
    border: Color.lerp(base.border, tint, 0.16)!,
    glow: Color.lerp(base.glow, tint, 0.18)!,
    isNight: base.isNight,
  );
}
