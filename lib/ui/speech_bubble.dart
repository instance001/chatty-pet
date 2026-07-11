import 'package:flutter/material.dart';

class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.compact = false,
  });

  final String? text;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final displayText = text ?? 'Chatty is listening...';
    final theme = Theme.of(context);
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 14);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFB8D1C7),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Text(
              'Chatty:',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF5D7A73),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                displayText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF284740),
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        border: Border.all(
          color: const Color(0xFFB8D1C7),
          width: compact ? 1.5 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x180F2C26),
            blurRadius: compact ? 10 : 18,
            offset: Offset(0, compact ? 4 : 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chatty says',
            style: (compact
                    ? theme.textTheme.labelMedium
                    : theme.textTheme.labelLarge)
                ?.copyWith(
              color: const Color(0xFF5D7A73),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            displayText,
            maxLines: compact ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: (compact
                    ? theme.textTheme.titleSmall
                    : theme.textTheme.titleMedium)
                ?.copyWith(
              color: const Color(0xFF284740),
              fontWeight: FontWeight.w800,
              height: compact ? 1.18 : 1.28,
            ),
          ),
        ],
      ),
    );
  }
}
