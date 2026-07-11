import 'package:flutter/material.dart';

import '../core/game_state.dart';
import '../core/item_instance.dart';
import '../core/pet_rules.dart' as pet_rules;

class PetStage extends StatelessWidget {
  const PetStage({
    super.key,
    required this.state,
    required this.onItemSelected,
  });

  final GameState state;
  final ValueChanged<String> onItemSelected;

  @override
  Widget build(BuildContext context) {
    final stageColors = _stageColors(state.timeOfDay);

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
                Positioned(
                  top: compact ? 8 : 14,
                  right: compact ? 8 : 14,
                  child: _StageTimeBadge(
                    timeOfDay: state.timeOfDay,
                    compact: compact,
                  ),
                ),
                for (var y = 0; y < state.gridHeight; y++)
                  for (var x = 0; x < state.gridWidth; x++)
                    Positioned(
                      left: x * cellWidth,
                      top: y * cellHeight,
                      width: cellWidth,
                      height: cellHeight,
                      child: Padding(
                        padding: EdgeInsets.all(tiny ? 2 : compact ? 4 : 6),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x40FFFFFF),
                            borderRadius: BorderRadius.circular(compact ? 12 : 18),
                            border: Border.all(color: const Color(0x33FFFFFF)),
                          ),
                        ),
                      ),
                    ),
                ...state.items.map(
                  (item) => _StageItem(
                    item: item,
                    state: state,
                    cellWidth: cellWidth,
                    cellHeight: cellHeight,
                    onTap: () => onItemSelected(item.id),
                  ),
                ),
                Positioned(
                  left: state.pet.position.x * cellWidth,
                  top: state.pet.position.y * cellHeight,
                  width: cellWidth,
                  height: cellHeight,
                  child: Padding(
                    padding: EdgeInsets.all(tiny ? 3 : compact ? 5 : 8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _petColor(state),
                        borderRadius: BorderRadius.circular(compact ? 16 : 24),
                      ),
                      child: Center(
                        child: Text(
                          '🐶',
                          style: TextStyle(
                            fontSize: tiny ? 20 : compact ? 26 : 34,
                          ),
                        ),
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
  }

  Color _petColor(GameState state) {
    return switch (state.pet.mood.name) {
      'happy' => const Color(0xFF1E7D73),
      'playful' => const Color(0xFF3A8F5A),
      'sleepy' => const Color(0xFF6C7BA6),
      'hungry' => const Color(0xFFB86A46),
      'messy' => const Color(0xFF8A6C4A),
      'grumpy' => const Color(0xFF915A72),
      'cozy' => const Color(0xFF5C7F69),
      _ => const Color(0xFF1E7D73),
    };
  }

  List<Color> _stageColors(pet_rules.TimeOfDay timeOfDay) {
    return switch (timeOfDay) {
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
  }
}

class _StageTimeBadge extends StatelessWidget {
  const _StageTimeBadge({
    required this.timeOfDay,
    required this.compact,
  });

  final pet_rules.TimeOfDay timeOfDay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = switch (timeOfDay) {
      pet_rules.TimeOfDay.morning => compact ? 'Morning' : 'Morning light',
      pet_rules.TimeOfDay.afternoon => compact ? 'Afternoon' : 'Sunny afternoon',
      pet_rules.TimeOfDay.evening => compact ? 'Evening' : 'Evening glow',
      pet_rules.TimeOfDay.night => compact ? 'Night' : 'Night hush',
    };
    final icon = switch (timeOfDay) {
      pet_rules.TimeOfDay.morning => Icons.wb_sunny_outlined,
      pet_rules.TimeOfDay.afternoon => Icons.light_mode_outlined,
      pet_rules.TimeOfDay.evening => Icons.wb_twilight_outlined,
      pet_rules.TimeOfDay.night => Icons.nightlight_round,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCCFFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 5 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 14 : 16, color: const Color(0xFF35524B)),
            SizedBox(width: compact ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF35524B),
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
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
