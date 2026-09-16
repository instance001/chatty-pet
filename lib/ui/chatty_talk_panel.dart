import 'dart:async';

import 'package:flutter/material.dart';

import '../app/chatty_talk_prompt.dart';
import '../app/chatty_talk_service.dart';
import '../core/game_state.dart';
import 'report_chatty_reply_sheet.dart';

class ChattyTalkPanel extends StatefulWidget {
  const ChattyTalkPanel({super.key, required this.state, this.compact = false});

  final GameState state;
  final bool compact;

  @override
  State<ChattyTalkPanel> createState() => _ChattyTalkPanelState();
}

class _ChattyTalkPanelState extends State<ChattyTalkPanel> {
  final _service = ChattyTalkService();
  final _composer = TextEditingController();
  final _messages = <_TalkMessage>[
    const _TalkMessage(
      fromChatty: true,
      text: 'Hi! I am Chatty. Want to tell me about your day or my toy room?',
    ),
  ];
  StreamSubscription<Map<Object?, Object?>>? _events;
  Timer? _thinkingTimeout;
  var _expanded = false;
  var _preparing = false;
  String? _requestId;
  String _draft = '';
  String? _error;
  var _sillySwearReactionIndex = 0;

  static final _sillySwearPattern = RegExp(
    r'\b(?:arse|ass(?:hole)?|bastard|bitch|bloody|bugger|bullshit|crap|cunt|damn|dick|fuck(?:er|ed|ing|s)?|hell|piss(?:ed)?|shit(?:ty)?|twat|wanker)\b',
    caseSensitive: false,
  );

  static const _sillySwearReactions = [
    'Oh! Chatty\'s ears just did a little boing. That word sounds too bumpy for his toy room.',
    'Eep! Chatty made his funny confused face. Want to try a silly toy word instead?',
    'Wobble-wobble! Chatty\'s tail got puzzled by that word. Tell him about a game?',
    'Pfft! Chatty nearly dropped his imaginary biscuit. That word gave it a surprise.',
    'Uh-oh—Chatty\'s ears are doing their puzzled wiggle. He likes friendly words best.',
  ];

  static const _conversationStarters = [
    'What should we play?',
    'Tell a silly joke!',
    'How are you feeling?',
  ];

  static const _thinkingLimit = Duration(seconds: 35);

  bool get _isThinking => _requestId != null || _preparing;

  @override
  void initState() {
    super.initState();
    _events = _service.events().listen(
      _handleEvent,
      onError: (_) {
        if (mounted) setState(() => _error = 'Chatty needs a little reset.');
      },
    );
  }

  @override
  void dispose() {
    _thinkingTimeout?.cancel();
    _events?.cancel();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _composer.text.trim();
    if (message.isEmpty || _isThinking) return;
    _composer.clear();
    if (_needsGrownUp(message)) {
      setState(() {
        _messages
          ..add(_TalkMessage(fromChatty: false, text: message))
          ..add(
            const _TalkMessage(
              fromChatty: true,
              text:
                  'That is something a trusted grown-up can help with. Want to talk about a toy, game, snack, or feeling instead?',
            ),
          );
        _error = null;
      });
      return;
    }
    if (_containsSillySwear(message)) {
      setState(() {
        _messages
          ..add(_TalkMessage(fromChatty: false, text: message))
          ..add(
            _TalkMessage(fromChatty: true, text: _nextSillySwearReaction()),
          );
        _error = null;
      });
      return;
    }
    setState(() {
      _messages.add(_TalkMessage(fromChatty: false, text: message));
      _error = null;
      _preparing = true;
      _draft = '';
    });
    try {
      final modelPath = await _service.prepareModel();
      final started = await _service.begin(
        modelPath: modelPath,
        prompt: ChattyTalkPrompt.build(state: widget.state, message: message),
      );
      final requestId = started['requestId'] as String?;
      if (requestId == null) {
        throw StateError(
          (started['message'] as String?) ?? 'Chatty could not start thinking.',
        );
      }
      if (mounted) {
        setState(() {
          _preparing = false;
          _requestId = requestId;
        });
        _thinkingTimeout?.cancel();
        _thinkingTimeout = Timer(
          _thinkingLimit,
          () => unawaited(_timeoutThinking(requestId)),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _preparing = false;
          _thinkingTimeout?.cancel();
          _error = 'Chatty is not ready yet. Please try again in a moment.';
        });
      }
    }
  }

  void _sendStarter(String message) {
    if (_isThinking) return;
    _composer.text = message;
    unawaited(_send());
  }

  Future<void> _cancelThinking() async {
    final requestId = _requestId;
    if (requestId == null) return;

    // Clear this panel immediately. The native bridge is also asked to stop,
    // and any late event is ignored because it no longer matches the active
    // request. This keeps the child in control on a slower device.
    setState(() {
      _thinkingTimeout?.cancel();
      _requestId = null;
      _draft = '';
      _error = 'Chatty put that thought down. Try again whenever you like.';
    });
    try {
      await _service.cancel(requestId);
    } catch (_) {
      // The visible conversation is already safely settled; a native cancel
      // failure should not turn a simple Stop tap into an alarming error.
    }
  }

  Future<void> _timeoutThinking(String requestId) async {
    if (!mounted || _requestId != requestId) return;
    setState(() {
      _requestId = null;
      _draft = '';
      _messages.add(
        const _TalkMessage(
          fromChatty: true,
          text:
              'My thought got a little tangled. Want to try a shorter question or tell me about a toy?',
        ),
      );
    });
    try {
      await _service.cancel(requestId);
    } catch (_) {
      // The friendly reply is already on screen, so native cleanup failures
      // should not interrupt the conversation.
    }
  }

  void _handleEvent(Map<Object?, Object?> event) {
    final requestId = event['requestId'] as String?;
    if (requestId == null || requestId != _requestId) return;
    switch (event['type']) {
      case 'token':
        if (mounted) {
          setState(() => _draft += (event['text'] as String?) ?? '');
        }
        return;
      case 'completed':
        final raw = (event['text'] as String?)?.trim();
        final response = _friendlyReply(
          raw?.isNotEmpty == true ? raw! : _draft,
        );
        if (mounted) {
          setState(() {
            _thinkingTimeout?.cancel();
            _messages.add(_TalkMessage(fromChatty: true, text: response));
            _requestId = null;
            _draft = '';
          });
        }
        return;
      case 'failed':
      case 'cancelled':
        if (mounted) {
          setState(() {
            _thinkingTimeout?.cancel();
            _requestId = null;
            _draft = '';
            _error = 'Chatty lost that thought. Try a short question.';
          });
        }
        return;
    }
  }

  bool _needsGrownUp(String message) {
    const sensitiveTerms = [
      'address',
      'phone number',
      'email',
      'password',
      'secret',
      'nude',
      'sex',
      'weapon',
      'kill',
      'suicide',
      'hurt myself',
      'hurt yourself',
      'medicine',
      'medical',
    ];
    final normalised = message.toLowerCase();
    return sensitiveTerms.any(normalised.contains);
  }

  bool _containsSillySwear(String message) =>
      _sillySwearPattern.hasMatch(message);

  String _nextSillySwearReaction() {
    final reaction = _sillySwearReactions[_sillySwearReactionIndex];
    _sillySwearReactionIndex =
        (_sillySwearReactionIndex + 1) % _sillySwearReactions.length;
    return reaction;
  }

  String _friendlyReply(String raw) {
    final clean = raw
        .replaceAll(RegExp(r'<\|.*?\|>', dotAll: true), '')
        .replaceAll(
          RegExp(r'system:|assistant:|user:', caseSensitive: false),
          '',
        )
        .trim();
    return clean.isEmpty || clean.length > 360
        ? 'Woof! I got a bit tangled up. Want to tell me about a favourite toy?'
        : clean;
  }

  Future<void> _reportChattyReply(String reply) async {
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => ReportChattyReplySheet(assistantResponse: reply),
    );
    if (sent == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report sent. Thank you.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(widget.compact ? 14 : 18),
        border: Border.all(color: const Color(0xFFB8D1C7)),
      ),
      child: Padding(
        padding: EdgeInsets.all(widget.compact ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                child: Row(
                  children: [
                    const Icon(Icons.forum_outlined, color: Color(0xFF0B6E69)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Talk to Chatty',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF284740),
                        ),
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  children: [
                    SizedBox(
                      height: widget.compact ? 130 : 170,
                      child: ListView.builder(
                        reverse: true,
                        itemCount: _messages.length + (_isThinking ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_isThinking && index == 0) {
                            return _Bubble(
                              fromChatty: true,
                              text: _draft.isEmpty
                                  ? 'Chatty is thinking…'
                                  : _draft,
                            );
                          }
                          final offset = _isThinking ? 1 : 0;
                          final message =
                              _messages[_messages.length - 1 - index + offset];
                          return _Bubble(
                            fromChatty: message.fromChatty,
                            text: message.text,
                            onReport: message.fromChatty
                                ? () => _reportChattyReply(message.text)
                                : null,
                          );
                        },
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    if (_requestId != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: _cancelThinking,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('Stop thinking'),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final starter in _conversationStarters)
                          ActionChip(
                            avatar: const Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Color(0xFF0B6E69),
                            ),
                            label: Text(starter),
                            labelStyle: theme.textTheme.labelMedium?.copyWith(
                              color: const Color(0xFF24524A),
                              fontWeight: FontWeight.w800,
                            ),
                            backgroundColor: const Color(0xFFE4F2ED),
                            side: const BorderSide(color: Color(0xFFB8D1C7)),
                            visualDensity: VisualDensity.compact,
                            onPressed: _isThinking
                                ? null
                                : () => _sendStarter(starter),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _composer,
                            enabled: !_isThinking,
                            maxLength: 220,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _send(),
                            decoration: const InputDecoration(
                              counterText: '',
                              hintText: 'Say hi to Chatty…',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          tooltip: _isThinking ? 'Chatty is thinking' : 'Send',
                          onPressed: _isThinking ? null : _send,
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TalkMessage {
  const _TalkMessage({required this.fromChatty, required this.text});
  final bool fromChatty;
  final String text;
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.fromChatty, required this.text, this.onReport});
  final bool fromChatty;
  final String text;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) => Align(
    alignment: fromChatty ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: fromChatty ? const Color(0xFFE4F2ED) : const Color(0xFF0B6E69),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: fromChatty ? const Color(0xFF284740) : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onReport != null) ...[
            const SizedBox(height: 2),
            TextButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.flag_outlined, size: 14),
              label: const Text('Tell a grown-up'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2F6257),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}
