import 'package:flutter/material.dart';

import '../content/starter_datapack.dart';
import '../core/actions.dart';
import '../core/game_state.dart';
import '../core/item_template.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({
    super.key,
    required this.state,
    required this.templates,
    required this.onAction,
    required this.onMakeItem,
    required this.onToggleMute,
    required this.onResetWorld,
    required this.onOpenHelp,
    required this.onOpenPrivacy,
    required this.onOpenAbout,
    required this.isBusy,
    required this.soundMuted,
    this.compact = false,
  });

  final GameState state;
  final List<ItemTemplate> templates;
  final ValueChanged<PetAction> onAction;
  final VoidCallback onMakeItem;
  final VoidCallback onToggleMute;
  final VoidCallback onResetWorld;
  final VoidCallback onOpenHelp;
  final VoidCallback onOpenPrivacy;
  final VoidCallback onOpenAbout;
  final bool isBusy;
  final bool soundMuted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final utilityCompact = compact;
    final groupedTemplates = <ItemKind, List<ItemTemplate>>{};
    for (final template in templates) {
      groupedTemplates.putIfAbsent(template.kind, () => []).add(template);
    }
    for (final entry in groupedTemplates.entries) {
      entry.value.sort((a, b) {
        final aCustom = _isCustomTemplate(a);
        final bCustom = _isCustomTemplate(b);
        if (aCustom != bCustom) {
          return aCustom ? -1 : 1;
        }
        final byUnlock = a.unlockLevel.compareTo(b.unlockLevel);
        if (byUnlock != 0) {
          return byUnlock;
        }
        return a.displayName.compareTo(b.displayName);
      });
    }
    final customCount = templates.where(_isCustomTemplate).length;

    final selectedItem = state.items
        .where((item) => item.id == state.selectedItemId)
        .firstOrNull;
    final selectedTemplate = selectedItem == null
        ? null
        : state.templates[selectedItem.templateId];
    final selectedReady =
        selectedItem != null &&
        (state.pet.position == selectedItem.position ||
            state.pet.position.isAdjacentTo(selectedItem.position));

    return Card(
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.82),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(compact ? 12 : 28),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 5 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!utilityCompact) ...[
              Text(
                'Care Shelf',
                style:
                    (compact
                            ? theme.textTheme.titleMedium
                            : theme.textTheme.titleLarge)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF25453F),
                        ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                'Place helpful items, then guide Chatty through the next little moment.',
                maxLines: compact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF60716C),
                  height: 1.2,
                  fontSize: compact ? 10.5 : 12,
                ),
              ),
            ],
            if (customCount > 0) ...[
              if (!utilityCompact) ...[
                SizedBox(height: compact ? 4 : 6),
                _CustomShelfHint(count: customCount, compact: compact),
              ],
            ],
            SizedBox(height: compact ? 3 : 8),
            _SelectionBanner(
              selectedTemplate: selectedTemplate,
              readyToUse: selectedReady,
              compact: compact,
            ),
            SizedBox(height: compact ? 4 : 8),
            Wrap(
              spacing: compact ? 3 : 6,
              runSpacing: compact ? 3 : 6,
              children: [
                FilledButton(
                  onPressed: isBusy
                      ? null
                      : () => onAction(
                          selectedReady
                              ? const Tick()
                              : const AdvanceToSelectedItem(),
                        ),
                  style: compact ? _compactActionStyle() : null,
                  child: Text(
                    isBusy
                        ? 'Scooting...'
                        : selectedReady
                        ? 'Next'
                        : 'Scoot',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: isBusy || selectedItem == null
                      ? null
                      : () => onAction(
                          selectedReady
                              ? PetInspect(state.selectedItemId)
                              : const InspectSelectedItemWhenReady(),
                        ),
                  style: compact ? _compactActionStyle() : null,
                  child: const Text('Inspect'),
                ),
                FilledButton.tonal(
                  onPressed: isBusy || selectedItem == null
                      ? null
                      : () => onAction(
                          selectedReady
                              ? PetUseItem(state.selectedItemId)
                              : const UseSelectedItemWhenReady(),
                        ),
                  style: compact ? _compactActionStyle() : null,
                  child: const Text('Use'),
                ),
                FilledButton.tonal(
                  onPressed: isBusy || state.items.isEmpty
                      ? null
                      : () => onAction(const ClearStage()),
                  style: compact ? _compactActionStyle() : null,
                  child: const Text('Clear'),
                ),
              ],
            ),
            SizedBox(height: compact ? 4 : 8),
            ...ItemKind.values.where(groupedTemplates.containsKey).map((kind) {
              final entries = groupedTemplates[kind]!;
              return Padding(
                padding: EdgeInsets.only(bottom: compact ? 3 : 8),
                child: _KindSection(
                  label: compact ? _compactKindLabel(kind) : _kindLabel(kind),
                  caption: _kindCaption(kind),
                  count: entries.length,
                  compact: compact,
                  ultraCompact: utilityCompact,
                  children: entries.map((template) {
                    return _SpawnButton(
                      label: compact
                          ? template.emoji
                          : '${template.emoji} ${template.displayName}',
                      isCustom: _isCustomTemplate(template),
                      compact: compact,
                      onPressed: () => onAction(SpawnItem(template.id)),
                    );
                  }).toList(),
                ),
              );
            }),
            SizedBox(height: compact ? 2 : 2),
            Wrap(
              spacing: compact ? 3 : 6,
              runSpacing: compact ? 3 : 6,
              children: [
                FilledButton.tonal(
                  onPressed: isBusy ? null : onMakeItem,
                  style: compact ? _compactActionStyle() : null,
                  child: Text(compact ? 'Make' : 'Make an item'),
                ),
                FilledButton.tonal(
                  onPressed: onToggleMute,
                  style: compact ? _compactActionStyle() : null,
                  child: Text(soundMuted ? 'Unmute' : 'Mute'),
                ),
                if (compact) ...[
                  FilledButton.tonal(
                    onPressed: isBusy ? null : onResetWorld,
                    style: _compactActionStyle(),
                    child: const Text('Reset'),
                  ),
                  FilledButton.tonal(
                    onPressed: onOpenHelp,
                    style: _compactActionStyle(),
                    child: const Text('Help'),
                  ),
                  FilledButton.tonal(
                    onPressed: onOpenPrivacy,
                    style: _compactActionStyle(),
                    child: const Text('Privacy'),
                  ),
                  FilledButton.tonal(
                    onPressed: onOpenAbout,
                    style: _compactActionStyle(),
                    child: const Text('About'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _kindLabel(ItemKind kind) {
    return switch (kind) {
      ItemKind.food => 'Snack Time',
      ItemKind.toy => 'Play Time',
      ItemKind.restItem => 'Cozy Time',
      ItemKind.cleanItem => 'Tidy Time',
      ItemKind.curiosity => 'Discovery',
      ItemKind.comfort => 'Comfort',
    };
  }

  String _kindCaption(ItemKind kind) {
    return switch (kind) {
      ItemKind.food => 'Quick bites for hungry moments.',
      ItemKind.toy => 'Fun picks to perk Chatty up.',
      ItemKind.restItem => 'Soft spots for sleepy check-ins.',
      ItemKind.cleanItem => 'Tidy tools for freshening up.',
      ItemKind.curiosity => 'Little treasures to discover.',
      ItemKind.comfort => 'Calm extras for cozy feelings.',
    };
  }

  String _compactKindLabel(ItemKind kind) {
    return switch (kind) {
      ItemKind.food => 'Food',
      ItemKind.toy => 'Play',
      ItemKind.restItem => 'Rest',
      ItemKind.cleanItem => 'Clean',
      ItemKind.curiosity => 'Look',
      ItemKind.comfort => 'Calm',
    };
  }

  bool _isCustomTemplate(ItemTemplate template) {
    return !StarterDatapack.templates.containsKey(template.id);
  }

  ButtonStyle _compactActionStyle() {
    return FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SelectionBanner extends StatelessWidget {
  const _SelectionBanner({
    required this.selectedTemplate,
    required this.readyToUse,
    required this.compact,
  });

  final ItemTemplate? selectedTemplate;
  final bool readyToUse;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final body = selectedTemplate == null
        ? compact
              ? 'Pick a stage item.'
              : 'Nothing is selected yet. Tap a stage item after you place it so Chatty knows what to focus on.'
        : readyToUse
        ? compact
              ? '${selectedTemplate!.emoji} ${selectedTemplate!.displayName} ready.'
              : '${selectedTemplate!.emoji} ${selectedTemplate!.displayName} is ready. Inspect it or use it now.'
        : compact
        ? '${selectedTemplate!.emoji} ${selectedTemplate!.displayName} selected.'
        : '${selectedTemplate!.emoji} ${selectedTemplate!.displayName} is selected. Tap Scoot over to guide Chatty right to it.';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 12,
        vertical: compact ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: readyToUse ? const Color(0xFFEAF7EB) : const Color(0xFFF6F4EA),
        borderRadius: BorderRadius.circular(compact ? 10 : 18),
        border: Border.all(
          color: readyToUse ? const Color(0xFF8FC893) : const Color(0xFFD7D0C1),
        ),
      ),
      child: Text(
        body,
        maxLines: compact ? 1 : 4,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF35524B),
          fontWeight: FontWeight.w600,
          height: 1.2,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _KindSection extends StatelessWidget {
  const _KindSection({
    required this.label,
    required this.caption,
    required this.count,
    required this.children,
    required this.compact,
    required this.ultraCompact,
  });

  final String label;
  final String caption;
  final int count;
  final List<Widget> children;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        compact ? 6 : 10,
        compact ? 4 : 8,
        compact ? 6 : 10,
        compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(compact ? 10 : 18),
        border: Border.all(color: const Color(0xFFD7E8E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style:
                      (compact
                              ? theme.textTheme.labelMedium
                              : theme.textTheme.labelLarge)
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF355A52),
                          ),
                ),
              ),
              _CountPill(count: count, compact: compact),
            ],
          ),
          if (!ultraCompact) ...[
            const SizedBox(height: 1),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6A7D77),
                height: 1.1,
                fontSize: compact ? 10 : 11,
              ),
            ),
            SizedBox(height: compact ? 4 : 6),
          ] else
            const SizedBox(height: 3),
          Wrap(
            spacing: compact ? 4 : 5,
            runSpacing: compact ? 4 : 5,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count, required this.compact});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F0EA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF3A5C55),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CustomShelfHint extends StatelessWidget {
  const _CustomShelfHint({required this.count, required this.compact});

  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(color: const Color(0xFFBED4F0)),
      ),
      child: Text(
        count == 1
            ? '1 custom item is on the shelf now. Look for the little Custom badge.'
            : '$count custom items are on the shelf now. Look for the little Custom badge.',
        style: const TextStyle(
          color: Color(0xFF355070),
          fontWeight: FontWeight.w700,
          height: 1.2,
          fontSize: 11.5,
        ),
      ),
    );
  }
}

class _SpawnButton extends StatelessWidget {
  const _SpawnButton({
    required this.label,
    required this.isCustom,
    required this.onPressed,
    required this.compact,
  });

  final String label;
  final bool isCustom;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 9,
          vertical: compact ? 6 : 7,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: TextStyle(
          fontSize: compact ? 10.5 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (isCustom && !compact) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFBED4F0)),
              ),
              child: const Text(
                'Custom',
                style: TextStyle(
                  color: Color(0xFF355070),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
