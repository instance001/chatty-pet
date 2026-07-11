import 'package:flutter/material.dart';

import '../content/starter_datapack.dart';
import '../core/actions.dart';
import '../core/game_state.dart';
import '../core/item_template.dart';

class InventoryStrip extends StatelessWidget {
  const InventoryStrip({
    super.key,
    required this.state,
    required this.onItemSelected,
    required this.onAction,
  });

  final GameState state;
  final ValueChanged<String> onItemSelected;
  final ValueChanged<PetAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 120 || constraints.maxWidth < 420;
        final panelPadding = compact ? 8.0 : 14.0;
        final titleStyle = compact
            ? theme.textTheme.titleSmall
            : theme.textTheme.titleMedium;
        final hintStyle =
            (compact
                    ? theme.textTheme.bodySmall?.copyWith(fontSize: 11)
                    : theme.textTheme.bodySmall)
                ?.copyWith(color: const Color(0xFF58716C));

        return Container(
          padding: EdgeInsets.all(panelPadding),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(compact ? 16 : 24),
            border: Border.all(color: const Color(0xFFD4E4DC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!compact) ...[
                Text(
                  'Stage Items',
                  style: titleStyle?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF23433D),
                  ),
                ),
                SizedBox(height: compact ? 2 : 4),
                Text(
                  state.items.isEmpty
                      ? 'Place a few care items for Chatty.'
                      : 'Tap an item to focus Chatty on it, or use the little x to put it away.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: hintStyle,
                ),
                SizedBox(height: 12),
              ],
              if (state.items.isEmpty)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: compact ? 8 : 14,
                      horizontal: compact ? 8 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5FAF8),
                      borderRadius: BorderRadius.circular(compact ? 12 : 18),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      compact
                          ? 'No stage items.'
                          : 'No items on the stage yet.',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF5E7470),
                        fontWeight: FontWeight.w600,
                        fontSize: compact ? 12 : 14,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: state.items.map((item) {
                        final template = state.templates[item.templateId]!;
                        final selected = state.selectedItemId == item.id;
                        final isCustom = !StarterDatapack.templates.containsKey(
                          template.id,
                        );
                        return Padding(
                          padding: EdgeInsets.only(right: compact ? 8 : 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: EdgeInsets.fromLTRB(
                              compact ? 8 : 12,
                              compact ? 5 : 8,
                              compact ? 5 : 8,
                              compact ? 5 : 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFFFF0B2)
                                  : const Color(0xFFF5FAF8),
                              borderRadius: BorderRadius.circular(
                                compact ? 16 : 18,
                              ),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFFE2B94F)
                                    : const Color(0xFFD2E4DC),
                                width: selected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => onItemSelected(item.id),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2,
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          template.emoji,
                                          style: TextStyle(
                                            fontSize: compact ? 18 : 22,
                                          ),
                                        ),
                                        SizedBox(width: compact ? 6 : 8),
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              template.displayName,
                                              style: TextStyle(
                                                color: const Color(0xFF26423E),
                                                fontWeight: FontWeight.w700,
                                                fontSize: compact ? 12 : 14,
                                              ),
                                            ),
                                            if (!compact)
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    _itemSummary(template),
                                                    style: TextStyle(
                                                      color: const Color(
                                                        0xFF607571,
                                                      ),
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  if (isCustom) ...[
                                                    const SizedBox(width: 6),
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFEAF3FF,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              999,
                                                            ),
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFFBED4F0,
                                                          ),
                                                        ),
                                                      ),
                                                      child: const Text(
                                                        'Custom',
                                                        style: TextStyle(
                                                          color: Color(
                                                            0xFF355070,
                                                          ),
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: compact ? 4 : 6),
                                IconButton(
                                  tooltip: 'Put away ${template.displayName}',
                                  onPressed: () =>
                                      onAction(RemoveStageItem(item.id)),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: BoxConstraints(
                                    minWidth: compact ? 24 : 28,
                                    minHeight: compact ? 24 : 28,
                                  ),
                                  icon: Icon(
                                    Icons.close_rounded,
                                    size: compact ? 16 : 18,
                                    color: const Color(0xFF56716B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _itemSummary(ItemTemplate template) {
    return switch (template.kind) {
      ItemKind.food => 'Helps fullness',
      ItemKind.toy => 'Boosts fun',
      ItemKind.restItem => 'Helps rest',
      ItemKind.cleanItem => 'Helps cleanliness',
      ItemKind.curiosity => 'Discovery item',
      ItemKind.comfort => 'Comfort item',
    };
  }
}
