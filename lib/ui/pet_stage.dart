import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chatty_avatar_asset.dart';
import '../core/chatty_forms.dart';
import '../core/game_state.dart';
import '../core/item_instance.dart';
import '../core/pet_rules.dart' as pet_rules;

class PetStage extends StatelessWidget {
  const PetStage({
    super.key,
    required this.state,
    required this.onItemSelected,
    required this.onPetTapped,
    this.transformationFormId,
    this.formIdOverride,
  });

  final GameState state;
  final ValueChanged<String> onItemSelected;
  final VoidCallback onPetTapped;
  final String? transformationFormId;
  final String? formIdOverride;

  @override
  Widget build(BuildContext context) {
    final form = ChattyForms.byId(formIdOverride ?? state.life.activeFormId);
    final stageColors = _stageColors(state.timeOfDay, form.backgroundTheme);
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: stageColors,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220E2F27),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 220 || constraints.maxWidth < 320;
            final tiny =
                constraints.maxHeight < 180 || constraints.maxWidth < 280;
            final cellWidth = constraints.maxWidth / state.gridWidth;
            final cellHeight = constraints.maxHeight / state.gridHeight;

            return Stack(
              children: [
                for (var y = 0; y < state.gridHeight; y++)
                  for (var x = 0; x < state.gridWidth; x++)
                    Positioned(
                      left: x * cellWidth,
                      top: y * cellHeight,
                      width: cellWidth,
                      height: cellHeight,
                      child: Padding(
                        padding: EdgeInsets.all(
                          tiny
                              ? 2
                              : compact
                              ? 4
                              : 6,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x40FFFFFF),
                            borderRadius: BorderRadius.circular(
                              compact ? 12 : 18,
                            ),
                            border: Border.all(color: const Color(0x33FFFFFF)),
                          ),
                        ),
                      ),
                    ),
                // Keep the play surface visually clear: the only persistent
                // things in its cells are Chatty and real care items.
                ...state.items.map(
                  (item) => _StageItem(
                    item: item,
                    state: state,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight,
                    onTap: () => onItemSelected(item.id),
                  ),
                ),
                AnimatedPositioned(
                  left: state.pet.position.x * cellWidth,
                  top: state.pet.position.y * cellHeight,
                  width: cellWidth,
                  height: cellHeight,
                  duration: reducedMotion
                      ? Duration.zero
                      : _movementDuration(form.motion),
                  curve: _movementCurve(form.motion),
                  child: Padding(
                    padding: EdgeInsets.all(
                      tiny
                          ? 3
                          : compact
                          ? 5
                          : 8,
                    ),
                    child: _ChattyAvatar(
                      form: form,
                      mood: state.pet.mood.name,
                      moodColor: _petColor(state, form),
                      fontSize: tiny
                          ? 20
                          : compact
                          ? 26
                          : 34,
                      cornerRadius: compact ? 16 : 24,
                      reducedMotion: reducedMotion,
                      reactionSerial: state.activityMoment.serial,
                      onTap: onPetTapped,
                    ),
                  ),
                ),
                if (transformationFormId != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _TransformationBurst(
                        form: ChattyForms.byId(transformationFormId!),
                        reducedMotion: reducedMotion,
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

  Color _petColor(GameState state, ChattyForm form) {
    final moodColor = switch (state.pet.mood.name) {
      'happy' => const Color(0xFF1E7D73),
      'playful' => const Color(0xFF3A8F5A),
      'sleepy' => const Color(0xFF6C7BA6),
      'hungry' => const Color(0xFFB86A46),
      'messy' => const Color(0xFF8A6C4A),
      'grumpy' => const Color(0xFF915A72),
      'cozy' => const Color(0xFF5C7F69),
      _ => const Color(0xFF1E7D73),
    };
    return Color.lerp(moodColor, _formColor(form.id), 0.34)!;
  }

  List<Color> _stageColors(
    pet_rules.TimeOfDay timeOfDay,
    String backgroundTheme,
  ) {
    final timeColors = switch (timeOfDay) {
      pet_rules.TimeOfDay.morning => const [
        Color(0xFFEAF6F0),
        Color(0xFFDDF1E7),
        Color(0xFFD0E6D9),
      ],
      pet_rules.TimeOfDay.afternoon => const [
        Color(0xFFF4F1D7),
        Color(0xFFE2F0DE),
        Color(0xFFD2E6D8),
      ],
      pet_rules.TimeOfDay.evening => const [
        Color(0xFFF0E1D8),
        Color(0xFFD8E5E2),
        Color(0xFFC5D7D8),
      ],
      pet_rules.TimeOfDay.night => const [
        Color(0xFF28425A),
        Color(0xFF30556A),
        Color(0xFF3B6971),
      ],
    };
    final formTint = switch (backgroundTheme) {
      'sunny_playroom' => const Color(0xFFFFD76B),
      'moonlit_nook' => const Color(0xFFBFC6FF),
      'mossy_hideaway' => const Color(0xFF8CCB8D),
      'comet_corner' => const Color(0xFFFFA8D4),
      'puddle_party' => const Color(0xFF79D8A1),
      'banana_bonanza' => const Color(0xFFFFE05E),
      'spooky_nook' => const Color(0xFF9B7AAE),
      'winter_workshop' => const Color(0xFFF3E2EE),
      'thirteenth_twilight' => const Color(0xFF6D5B83),
      'party_room' => const Color(0xFFFFA9C6),
      _ => const Color(0xFFB4E4D3),
    };
    return timeColors
        .map((color) => Color.lerp(color, formTint, 0.20)!)
        .toList();
  }

  Color _formColor(String formId) => switch (formId) {
    'sunbeam_pup' => const Color(0xFFE8AB3E),
    'moonlit_bunny' => const Color(0xFF8A91D7),
    'mossy_kit' => const Color(0xFF569D63),
    'comet_chick' => const Color(0xFFE875AA),
    'leapling_chatty' => const Color(0xFF3CA96E),
    'wobble_chatty' => const Color(0xFFF2C94C),
    'spooky_chatty' => const Color(0xFF594363),
    'festive_chatty' => const Color(0xFFBF4D52),
    'cursed_chatty' => const Color(0xFF4C3B61),
    'party_chatty' => const Color(0xFFE16693),
    _ => const Color(0xFF1E7D73),
  };

  Duration _movementDuration(ChattyMotionStyle motion) => switch (motion) {
    ChattyMotionStyle.bouncy => const Duration(milliseconds: 240),
    ChattyMotionStyle.skittery => const Duration(milliseconds: 180),
    ChattyMotionStyle.floaty => const Duration(milliseconds: 520),
    ChattyMotionStyle.cozy => const Duration(milliseconds: 420),
    ChattyMotionStyle.curious => const Duration(milliseconds: 330),
  };

  Curve _movementCurve(ChattyMotionStyle motion) => switch (motion) {
    ChattyMotionStyle.bouncy => Curves.easeOutBack,
    ChattyMotionStyle.skittery => Curves.easeInOutCubicEmphasized,
    ChattyMotionStyle.floaty => Curves.easeInOutSine,
    ChattyMotionStyle.cozy => Curves.easeInOut,
    ChattyMotionStyle.curious => Curves.easeInOutCubic,
  };
}

class _ChattyAvatar extends StatefulWidget {
  const _ChattyAvatar({
    required this.form,
    required this.mood,
    required this.moodColor,
    required this.fontSize,
    required this.cornerRadius,
    required this.reducedMotion,
    required this.reactionSerial,
    required this.onTap,
  });

  final ChattyForm form;
  final String mood;
  final Color moodColor;
  final double fontSize;
  final double cornerRadius;
  final bool reducedMotion;
  final int reactionSerial;
  final VoidCallback onTap;

  @override
  State<_ChattyAvatar> createState() => _ChattyAvatarState();
}

class _ChattyAvatarState extends State<_ChattyAvatar>
    with TickerProviderStateMixin {
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  late final AnimationController _attention = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 440),
  );

  @override
  void initState() {
    super.initState();
    _updateTicker();
  }

  @override
  void didUpdateWidget(covariant _ChattyAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTicker();
    if (!widget.reducedMotion &&
        widget.reactionSerial != oldWidget.reactionSerial) {
      _attention.forward(from: 0);
    }
  }

  void _updateTicker() {
    if (widget.reducedMotion) {
      _idle.stop();
      _idle.value = 0;
    } else if (!_idle.isAnimating) {
      _idle.repeat();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _attention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _attention]),
      builder: (context, child) {
        final phase = _idle.value * math.pi * 2;
        final pose = switch (widget.form.motion) {
          ChattyMotionStyle.bouncy => _IdlePose(
            dy: -math.sin(phase).abs() * 7,
            scale: 1 + (math.sin(phase).abs() * 0.06),
            rotation: math.sin(phase) * 0.035,
          ),
          ChattyMotionStyle.floaty => _IdlePose(
            dy: math.sin(phase) * 5,
            rotation: math.sin(phase) * 0.055,
          ),
          ChattyMotionStyle.skittery => _IdlePose(
            dx: math.sin(phase * 3) * 2.5,
            dy: -math.sin(phase * 2).abs() * 2,
            rotation: math.sin(phase * 3) * 0.045,
          ),
          ChattyMotionStyle.cozy => _IdlePose(
            dy: math.sin(phase) * 1.5,
            scale: 1 + (math.sin(phase) * 0.025),
          ),
          ChattyMotionStyle.curious => _IdlePose(
            dy: -math.sin(phase).abs() * 3,
            rotation: math.sin(phase * 0.5) * 0.04,
          ),
        };
        final moodPose = switch (widget.mood) {
          'happy' => _IdlePose(
            dy: -math.sin(phase).abs() * 2.5,
            scale: 1 + (math.sin(phase).abs() * 0.025),
          ),
          'playful' => _IdlePose(
            dx: math.sin(phase * 2) * 2,
            dy: -math.sin(phase * 2).abs() * 4,
            rotation: math.sin(phase * 2) * 0.025,
          ),
          'sleepy' => _IdlePose(
            dy: math.sin(phase * 0.5) * 1.5,
            scale: 0.975 + (math.sin(phase * 0.5) * 0.012),
          ),
          'hungry' => _IdlePose(
            dx: math.sin(phase * 1.5) * 1.5,
            dy: -math.sin(phase * 1.5).abs() * 1.2,
            rotation: math.sin(phase * 1.5) * 0.018,
          ),
          'messy' => _IdlePose(
            dx: math.sin(phase * 4) * 1.8,
            rotation: math.sin(phase * 4) * 0.035,
          ),
          'grumpy' => _IdlePose(
            dx: math.sin(phase) * 1.1,
            rotation: math.sin(phase) * 0.025,
          ),
          'cozy' => _IdlePose(
            dy: math.sin(phase * 0.55) * 1.2,
            scale: 0.99 + (math.sin(phase * 0.55) * 0.018),
          ),
          _ => const _IdlePose(),
        };
        final attention = math.sin(_attention.value * math.pi);
        return Transform.translate(
          offset: Offset(
            pose.dx + moodPose.dx,
            pose.dy + moodPose.dy - (attention * 5),
          ),
          child: Transform.rotate(
            angle: pose.rotation + moodPose.rotation + (attention * 0.08),
            child: Transform.scale(
              scale: pose.scale * moodPose.scale + (attention * 0.13),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  child!,
                  if (!widget.reducedMotion && attention > 0.01)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _AvatarReactionBurst(
                          form: widget.form,
                          progress: attention,
                          compact: widget.fontSize < 30,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      child: Semantics(
        button: true,
        label:
            'Say hello to ${widget.form.displayName}. Chatty is ${widget.mood}.',
        child: GestureDetector(
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.moodColor,
              borderRadius: BorderRadius.circular(widget.cornerRadius),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330E2F27),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _FormAvatarArt(
                form: widget.form,
                fallbackSize: widget.fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FormAvatarArt extends StatelessWidget {
  const _FormAvatarArt({required this.form, required this.fallbackSize});

  final ChattyForm form;
  final double fallbackSize;

  @override
  Widget build(BuildContext context) {
    final assetPath = chattyAvatarAssetPath(form.id);
    if (assetPath == null) {
      return Text(form.emoji, style: TextStyle(fontSize: fallbackSize));
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) =>
            Text(form.emoji, style: TextStyle(fontSize: fallbackSize)),
      ),
    );
  }
}

class _IdlePose {
  const _IdlePose({
    this.dx = 0,
    this.dy = 0,
    this.scale = 1,
    this.rotation = 0,
  });

  final double dx;
  final double dy;
  final double scale;
  final double rotation;
}

/// A very short visual cheer for an interaction. It uses the same reaction
/// serial as the avatar bounce, so it cannot create gameplay state by itself.
class _AvatarReactionBurst extends StatelessWidget {
  const _AvatarReactionBurst({
    required this.form,
    required this.progress,
    required this.compact,
  });

  final ChattyForm form;
  final double progress;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final emojis = _emojisFor(form.id);
    final distance = (compact ? 23.0 : 31.0) * progress;
    final opacity = (1 - (progress * 0.38)).clamp(0.0, 1.0);
    return Opacity(
      opacity: opacity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var index = 0; index < emojis.length; index++)
            Align(
              alignment: Alignment(
                math.cos(index * math.pi * 2 / emojis.length),
                math.sin(index * math.pi * 2 / emojis.length),
              ),
              child: Transform.translate(
                offset: Offset(
                  math.cos(index * math.pi * 2 / emojis.length) * distance,
                  math.sin(index * math.pi * 2 / emojis.length) * distance,
                ),
                child: Transform.scale(
                  scale: 0.55 + (progress * 0.65),
                  child: Text(
                    emojis[index],
                    style: TextStyle(fontSize: compact ? 15 : 19),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _emojisFor(String formId) => switch (formId) {
    'sunbeam_pup' => const ['☀️', '✨', '💛', '🐾'],
    'moonlit_bunny' => const ['🌙', '☁️', '✦', '🐾'],
    'mossy_kit' => const ['🍃', '🌱', '✨', '🐾'],
    'comet_chick' => const ['💫', '✦', '✨', '🐾'],
    'leapling_chatty' => const ['🫧', '💧', '✨', '🐾'],
    'wobble_chatty' => const ['🍌', '✨', '❔', '🐾'],
    'spooky_chatty' => const ['🦇', '✦', '🕯️', '🐾'],
    'festive_chatty' => const ['❄️', '🔔', '✨', '🐾'],
    'cursed_chatty' => const ['🕸️', '🦇', '✦', '🐾'],
    'party_chatty' => const ['🎉', '✨', '🎊', '🐾'],
    _ => const ['✨', '💛', '⭐', '🐾'],
  };
}

class _TransformationBurst extends StatefulWidget {
  const _TransformationBurst({required this.form, required this.reducedMotion});

  final ChattyForm form;
  final bool reducedMotion;

  @override
  State<_TransformationBurst> createState() => _TransformationBurstState();
}

class _TransformationBurstState extends State<_TransformationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1650),
  );

  @override
  void initState() {
    super.initState();
    _updateMotion();
  }

  @override
  void didUpdateWidget(covariant _TransformationBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reducedMotion != widget.reducedMotion) {
      _updateMotion();
    }
  }

  void _updateMotion() {
    if (widget.reducedMotion) {
      _controller.stop();
      _controller.value = 0.64;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = widget.reducedMotion
            ? 0.64
            : Curves.easeInOut.transform(_controller.value);
        final flash = widget.reducedMotion
            ? 0.16
            : math.sin(progress * math.pi).clamp(0.0, 1.0);
        return Semantics(
          liveRegion: true,
          label: '${widget.form.displayName} appeared',
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: flash * 0.58),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (!widget.reducedMotion)
                  for (var index = 0; index < 12; index++)
                    Transform.translate(
                      offset: Offset(
                        math.cos(index * math.pi / 6) * progress * 120,
                        math.sin(index * math.pi / 6) * progress * 88,
                      ),
                      child: Opacity(
                        opacity: (1 - progress).clamp(0.0, 1.0),
                        child: Text(
                          index.isEven ? '✨' : '💫',
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                Transform.scale(
                  scale: widget.reducedMotion
                      ? 1.05
                      : 0.55 + (math.sin(progress * math.pi) * 0.75),
                  child: SizedBox(
                    width: 156,
                    height: 156,
                    child: _FormAvatarArt(form: widget.form, fallbackSize: 76),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  child: Opacity(
                    opacity: widget.reducedMotion
                        ? 1
                        : ((progress - 0.30) / 0.45).clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xEFFFFFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        child: Text(
                          '${widget.form.displayName}!',
                          style: const TextStyle(
                            color: Color(0xFF284740),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StageItem extends StatelessWidget {
  const _StageItem({
    required this.item,
    required this.state,
    required this.cellWidth,
    required this.cellHeight,
    required this.onTap,
  });

  final ItemInstance item;
  final GameState state;
  final double cellWidth;
  final double cellHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final template = state.templates[item.templateId]!;
    final selected = state.selectedItemId == item.id;
    final compactCell = cellWidth < 54 || cellHeight < 54;

    return Positioned(
      left: item.position.x * cellWidth,
      top: item.position.y * cellHeight,
      width: cellWidth,
      height: cellHeight,
      child: Padding(
        padding: EdgeInsets.all(compactCell ? 4 : 10),
        child: Material(
          color: selected ? const Color(0xFFFFF4B5) : const Color(0xFFF7FBF9),
          borderRadius: BorderRadius.circular(compactCell ? 14 : 22),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(compactCell ? 14 : 22),
            child: Center(
              child: Text(
                template.emoji,
                style: TextStyle(fontSize: compactCell ? 20 : 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
