import 'package:flutter/material.dart';

import '../core/ai_report_service.dart';

class ReportChattyReplySheet extends StatefulWidget {
  const ReportChattyReplySheet({super.key, required this.assistantResponse});

  final String assistantResponse;

  @override
  State<ReportChattyReplySheet> createState() => _ReportChattyReplySheetState();
}

class _ReportChattyReplySheetState extends State<ReportChattyReplySheet> {
  static const _reasons = <String, String>{
    'Something unkind or scary': 'offensive',
    'Hate or bullying': 'hate_or_harassment',
    'Grown-up content': 'sexual_content',
    'Dangerous or harmful': 'violence_or_self_harm',
    'Something else': 'other',
  };

  final _note = TextEditingController();
  final _service = const AiReportService();
  String _reason = 'other';
  var _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _service.submit(
        reason: _reason,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        assistantResponse: widget.assistantResponse,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Report was not sent: $error');
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 1100;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 18 : 24,
          compact ? 12 : 20,
          compact ? 18 : 24,
          (compact ? 12 : 20) + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              'Tell a grown-up',
              style:
                  (compact
                          ? Theme.of(context).textTheme.headlineMedium
                          : Theme.of(context).textTheme.headlineSmall)
                      ?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              'A grown-up can report this one Chatty reply. This sends the reply, the on-device model label, and an optional note. It does not send what you said or the rest of this chat.',
              style: compact ? Theme.of(context).textTheme.bodySmall : null,
            ),
            SizedBox(height: compact ? 10 : 20),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(
                labelText: 'Why are you reporting it?',
                border: OutlineInputBorder(),
              ),
              items: _reasons.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.value,
                      child: Text(entry.key),
                    ),
                  )
                  .toList(),
              onChanged: _sending
                  ? null
                  : (value) => setState(() => _reason = value ?? 'other'),
            ),
            SizedBox(height: compact ? 8 : 14),
            TextField(
              controller: _note,
              enabled: !_sending,
              maxLength: 2000,
              minLines: compact ? 1 : 2,
              maxLines: compact ? 2 : 4,
              decoration: const InputDecoration(
                labelText: 'Note for the grown-up (optional)',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: compact ? 4 : 8),
            if (_error != null) ...[
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: compact ? 4 : 8),
            ],
            FilledButton.icon(
              onPressed: _sending ? null : _submit,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.flag_outlined),
              label: Text(_sending ? 'Sending…' : 'Send report'),
            ),
          ],
        ),
      ),
    );
  }
}
