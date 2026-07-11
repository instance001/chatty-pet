import 'package:flutter/material.dart';

import '../core/game_state.dart';
import '../core/item_template.dart';

class StatusPanel extends StatelessWidget {
  const StatusPanel({super.key, required this.state, this.compact = false});

  final GameState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final utilityCompact = compact;
    final selectedItem = state.items
        .where((item) => item.id == state.selectedItemId)
        .firstOrNull;
    final selectedTemplate = selectedItem == null
        ? null
        : state.templates[selectedItem.templateId];
    final nextUnlock =
        state.templates.values
            .where(
              (template) => !state.unlockedTemplateIds.contains(template.id),
            )
            .toList()
          ..sort((a, b) {
            final byLevel = a.unlockLevel.compareTo(b.unlockLevel);
            if (byLevel != 0) {
              return byLevel;
            }
            return a.displayName.compareTo(b.displayName);
          });

    return Card(
      elevation: 0,
      color: const Color(0xFF21453F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 28),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 6 : 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!utilityCompact) ...[
              Text(
                'Chatty Today',
                style:
                    (compact
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                _moodSummary(state),
                style:
                    (compact
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                          color: const Color(0xFFD5E9E2),
                          height: 1.28,
                          fontSize: compact ? 11 : null,
                        ),
              ),
              SizedBox(height: compact ? 8 : 10),
            ],
            Wrap(
              spacing: compact ? 5 : 6,
              runSpacing: compact ? 5 : 6,
              children: [
                _Chip(label: 'Day ${state.dayCount}', compact: compact),
                _Chip(
                  label: _timeLabel(state.timeOfDay.name),
                  compact: compact,
                ),
                _Chip(label: _moodLabel(state.pet.mood.name), compact: compact),
                _Chip(
                  label: '${state.unlockedTemplateIds.length} unlocked',
                  compact: compact,
                ),
              ],
            ),
            SizedBox(height: compact ? 5 : 12),
            _NeedMeter(
              label: 'Tummy',
              emoji: '🍽️',
              value: state.pet.fullness,
              accent: const Color(0xFFFFC96B),
              compact: compact,
            ),
            _NeedMeter(
              label: 'Play',
              emoji: '🎾',
              value: state.pet.fun,
              accent: const Color(0xFF8ED16B),
              compact: compact,
            ),
            _NeedMeter(
              label: 'Rest',
              emoji: '🌙',
              value: state.pet.rest,
              accent: const Color(0xFF9DB5FF),
              compact: compact,
            ),
            _NeedMeter(
              label: 'Clean',
              emoji: '🧼',
              value: state.pet.cleanliness,
              accent: const Color(0xFF79D7D3),
              compact: compact,
            ),
            _NeedMeter(
              label: 'Affection',
              emoji: '💛',
              value: state.pet.affection,
              maxValue: 20,
              accent: const Color(0xFFFFD966),
              compact: compact,
            ),
            if (!utilityCompact) ...[
              SizedBox(height: compact ? 8 : 12),
              _InfoCard(
                title: 'What To Try Next',
                body: _nextSuggestion(state, selectedTemplate),
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _InfoCard(
                title: 'Unlock Progress',
                body: _unlockSummary(state, nextUnlock.firstOrNull),
                compact: compact,
              ),
              SizedBox(height: compact ? 6 : 8),
              _InfoCard(
                title: 'Focused Item',
                body: selectedTemplate == null
                    ? 'Nothing selected yet. Tap a stage item to guide Chatty toward it.'
                    : '${selectedTemplate.emoji} ${selectedTemplate.displayName} is selected. ${_itemSummary(selectedTemplate)}',
                compact: compact,
              ),
              SizedBox(height: compact ? 8 : 12),
              Text(
                'Recent Moments',
                style:
                    (compact
                            ? theme.textTheme.titleSmall
                            : theme.textTheme.titleMedium)
                        ?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
              ),
              SizedBox(height: compact ? 6 : 8),
              if (state.recentLines.isEmpty)
                Text(
                  'Nothing yet. Start with a snack, toy, or cozy item.',
                  style: TextStyle(
                    color: const Color(0xFFE2F0EA),
                    fontSize: compact ? 11 : 14,
                  ),
                )
              else
                ...state.recentLines.reversed
                    .take(4)
                    .map(
                      (line) => Padding(
                        padding: EdgeInsets.only(bottom: compact ? 3 : 4),
                        child: Text(
                          '- $line',
                          style: TextStyle(
                            color: const Color(0xFFE2F0EA),
                            height: 1.25,
                            fontSize: compact ? 11 : 14,
                          ),
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  String _moodSummary(GameState state) {
    return switch (state.pet.mood.name) {
      'hungry' =>
        'Chatty is snack-minded right now and would love something tasty.',
      'sleepy' => 'Chatty is getting droopy and could use a cozy rest.',
      'messy' => 'Chatty looks a little rumpled and would enjoy a tidy-up.',
      'grumpy' => 'Chatty needs a playful little boost.',
      'happy' =>
        'Chatty is feeling bright, cared for, and ready for a lovely day.',
      'playful' => 'Chatty is full of playful energy and looking for fun.',
      'cozy' => 'Chatty feels soft, calm, and very settled.',
      _ => 'Chatty is curious and ready to explore whatever you place next.',
    };
  }

  String _nextSuggestion(GameState state, ItemTemplate? selectedTemplate) {
    final selectedItem = state.items
        .where((item) => item.id == state.selectedItemId)
        .firstOrNull;
    final selectedReady =
        selectedItem != null &&
        (state.pet.position == selectedItem.position ||
            state.pet.position.isAdjacentTo(selectedItem.position));

    if (selectedTemplate != null && selectedReady) {
      return '${selectedTemplate.displayName} is ready right now. Try using it while Chatty is close.';
    }

    final needs = <String, int>{
      'fullness': state.pet.fullness,
      'fun': state.pet.fun,
      'rest': state.pet.rest,
      'cleanliness': state.pet.cleanliness,
    };
    final lowest = needs.entries
        .reduce((a, b) => a.value <= b.value ? a : b)
        .key;
    final baseLine = switch (lowest) {
      'fullness' =>
        'Chatty looks hungriest. Try placing a food item like a berry or biscuit.',
      'fun' => 'Fun is getting low. A toy would be a good next move.',
      'rest' => 'Rest is dipping. A cozy item would help Chatty recharge.',
      'cleanliness' =>
        'Cleanliness is the weakest need. A tidy-up tool would help.',
      _ => 'Any caring item will help right now.',
    };

    if (selectedTemplate == null) {
      return baseLine;
    }

    return '$baseLine ${selectedTemplate.displayName} is selected now, so tap Scoot over to bring Chatty to it.';
  }

  String _unlockSummary(GameState state, ItemTemplate? nextUnlock) {
    if (nextUnlock == null) {
      return 'Everything in this build is unlocked. Keep caring for Chatty and enjoy the full toy box.';
    }

    final remaining = nextUnlock.unlockLevel - state.pet.affection;
    if (remaining <= 0) {
      return '${nextUnlock.emoji} ${nextUnlock.displayName} is ready to unlock with the next affectionate moment.';
    }

    final pointWord = remaining == 1 ? 'point' : 'points';
    return '${nextUnlock.emoji} ${nextUnlock.displayName} unlocks in $remaining more affection $pointWord.';
  }

  String _itemSummary(ItemTemplate template) {
    return switch (template.kind) {
      ItemKind.food => 'It helps tummy needs.',
      ItemKind.toy => 'It boosts playful energy.',
      ItemKind.restItem => 'It helps Chatty rest.',
      ItemKind.cleanItem => 'It helps Chatty get tidy.',
      ItemKind.curiosity => 'It gives Chatty something fun to discover.',
      ItemKind.comfort => 'It helps Chatty feel calm and cozy.',
    };
  }

  String _timeLabel(String timeOfDay) {
    return switch (timeOfDay) {
      'morning' => 'Morning',
      'afternoon' => 'Afternoon',
      'evening' => 'Evening',
      'night' => 'Night',
      _ => timeOfDay,
    };
  }

  String _moodLabel(String mood) {
    return switch (mood) {
      'hungry' => 'Hungry mood',
      'sleepy' => 'Sleepy mood',
      'messy' => 'Messy mood',
      'grumpy' => 'Grumpy mood',
      'happy' => 'Happy mood',
      'playful' => 'Playful mood',
      'cozy' => 'Cozy mood',
      _ => 'Curious mood',
    };
  }
}

class _NeedMeter extends StatelessWidget {
  const _NeedMeter({
    required this.label,
    required this.emoji,
    required this.value,
    required this.accent,
    required this.compact,
    this.maxValue = 5,
  });

  final String label;
  final String emoji;
  final int value;
  final int maxValue;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final progress = value / maxValue;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 6 : 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: compact ? 15 : 18)),
              SizedBox(width: compact ? 6 : 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: compact ? 12 : 14,
                  ),
                ),
              ),
              Text(
                '$value/$maxValue',
                style: TextStyle(
                  color: const Color(0xFFD5E9E2),
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 11 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 4 : 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: compact ? 7 : 9,
              value: progress,
              backgroundColor: const Color(0xFF365A54),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    required this.compact,
  });

  final String title;
  final String body;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2C5750),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: const Color(0xFF467269)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: compact ? 12 : 14,
            ),
          ),
          SizedBox(height: compact ? 3 : 4),
          Text(
            body,
            style: TextStyle(
              color: const Color(0xFFD5E9E2),
              height: 1.25,
              fontSize: compact ? 11 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.compact});

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF3A675D),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
