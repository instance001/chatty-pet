import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/starter_datapack.dart';
import '../core/actions.dart';
import '../core/custom_item_factory.dart';
import '../core/game_state.dart';
import '../core/item_instance.dart';
import '../core/item_template.dart';
import '../core/pet_rules.dart' as pet_rules;
import '../core/reducer.dart';
import '../core/reducer_result.dart';
import '../ui/chatty_activity_box.dart';
import '../ui/control_panel.dart';
import '../ui/inventory_strip.dart';
import '../ui/pet_stage.dart';
import '../ui/speech_bubble.dart';
import '../ui/status_panel.dart';
import 'game_persistence.dart';
import 'chatty_soundscape.dart';

const _chattyPetPrivacyUrl = 'https://instance001.github.io/privacy/chatty-pet.html';

class ChattyPetApp extends StatelessWidget {
  const ChattyPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2A8C82),
        brightness: Brightness.light,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'Chatty-Pet',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        scaffoldBackgroundColor: const Color(0xFFF4F1E8),
        textTheme: baseTheme.textTheme.copyWith(
          headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            height: 1.0,
          ),
          headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
          titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
          bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(height: 1.3),
          bodySmall: baseTheme.textTheme.bodySmall?.copyWith(height: 1.25),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
            disabledBackgroundColor: const Color(0xFFD6DEDB),
            disabledForegroundColor: const Color(0xFF86948F),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF7B908A), width: 1.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            foregroundColor: const Color(0xFF0B6E69),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.1,
            ),
            disabledForegroundColor: const Color(0xFF8A9894),
          ),
        ),
        chipTheme: baseTheme.chipTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          side: BorderSide.none,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      home: const _LaunchGate(),
    );
  }
}

class _LaunchGate extends StatefulWidget {
  const _LaunchGate();

  @override
  State<_LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<_LaunchGate> {
  bool _showHome = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _finishSplash() {
    if (!mounted || _showHome) {
      return;
    }
    setState(() {
      _showHome = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      child: _showHome
          ? const ChattyPetHomePage()
          : _SplashScreen(onContinue: _finishSplash),
    );
  }
}

class ChattyPetHomePage extends StatefulWidget {
  const ChattyPetHomePage({super.key});

  @override
  State<ChattyPetHomePage> createState() => _ChattyPetHomePageState();
}

class _ChattyPetHomePageState extends State<ChattyPetHomePage> {
  final GamePersistence _persistence = GamePersistence();
  final ChattySoundscape _soundscape = ChattySoundscape();
  final Random _idleRandom = Random();
  static const _autoStepDelay = Duration(milliseconds: 260);
  ReducerResult _result = _buildFreshGame();
  bool _loading = true;
  bool _animating = false;
  bool _soundMuted = false;
  Timer? _idleSoundTimer;
  DateTime _lastSoundActivityAt = DateTime.now();

  static ReducerResult _buildFreshGame() {
    return ChattyPetReducer.reduce(
      StarterDatapack.newGame(),
      const StartNewGame(),
    );
  }

  GameState get _state => _result.state;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSavedGame());
  }

  @override
  void dispose() {
    _idleSoundTimer?.cancel();
    unawaited(_soundscape.dispose());
    super.dispose();
  }

  Future<void> _loadSavedGame() async {
    final savedState = await _persistence.load();
    if (!mounted) {
      return;
    }

    setState(() {
      if (savedState != null) {
        _result = ReducerResult(
          state: savedState,
          events: const [],
          lines: const [],
        );
      }
      _loading = false;
    });
    _lastSoundActivityAt = DateTime.now();
    _scheduleIdleSound();
  }

  void _dispatch(PetAction action) {
    if (_animating && action is! ClearSpeech && action is! StartNewGame) {
      return;
    }

    if (action is AdvanceToSelectedItem) {
      unawaited(_animateAdvanceToSelectedItem());
      return;
    }
    if (action is UseSelectedItemWhenReady) {
      unawaited(_animateUseSelectedItemWhenReady());
      return;
    }
    if (action is InspectSelectedItemWhenReady) {
      unawaited(_animateInspectSelectedItemWhenReady());
      return;
    }

    _applyAction(action);
  }

  void _applyAction(PetAction action) {
    final previousState = _state;
    setState(() {
      if (action is StartNewGame) {
        _result = _buildFreshGame();
      } else {
        _result = ChattyPetReducer.reduce(_state, action);
      }
    });
    unawaited(_handleSoundTransition(previousState, _result));
    unawaited(_persistence.save(_result.state));
  }

  Future<void> _handleSoundTransition(
    GameState previousState,
    ReducerResult result,
  ) async {
    final nextState = result.state;
    final hadMeaningfulChange =
        result.events.isNotEmpty ||
        nextState.timeOfDay != previousState.timeOfDay ||
        nextState.activityMoment.serial != previousState.activityMoment.serial;

    if (!hadMeaningfulChange) {
      return;
    }

    _lastSoundActivityAt = DateTime.now();
    _scheduleIdleSound();
    if (_soundMuted) {
      return;
    }
    await _soundscape.playForTransition(
      previousState: previousState,
      result: result,
    );
  }

  Future<void> _toggleSoundMuted() async {
    setState(() {
      _soundMuted = !_soundMuted;
    });
    if (_soundMuted) {
      await _soundscape.stop();
    }
  }

  void _scheduleIdleSound() {
    _idleSoundTimer?.cancel();
    final delay = Duration(seconds: 30 + _idleRandom.nextInt(16));
    _idleSoundTimer = Timer(delay, _maybePlayIdleSound);
  }

  Future<void> _maybePlayIdleSound() async {
    if (!mounted || _loading) {
      return;
    }

    final quietFor = DateTime.now().difference(_lastSoundActivityAt);
    if (_animating || quietFor < const Duration(seconds: 30)) {
      _scheduleIdleSound();
      return;
    }

    _lastSoundActivityAt = DateTime.now();
    if (!_soundMuted) {
      await _soundscape.playCue(ChattySoundCue.idleRuff);
    }
    _scheduleIdleSound();
  }

  Future<void> _animateAdvanceToSelectedItem() async {
    if (_animating) {
      return;
    }

    final selectedItem = _selectedItem;
    if (selectedItem == null) {
      _applyAction(const Tick());
      return;
    }

    await _runAnimatedApproachUntilReady();
  }

  Future<void> _animateUseSelectedItemWhenReady() async {
    if (_animating) {
      return;
    }

    final selectedItem = _selectedItem;
    if (selectedItem == null) {
      _applyAction(const UseSelectedItemWhenReady());
      return;
    }

    final isReady = _isSelectedItemReady();
    if (!isReady) {
      await _runAnimatedApproachUntilReady();
    }
    if (!mounted || _selectedItem == null || !_isSelectedItemReady()) {
      return;
    }

    _applyAction(PetUseItem(_state.selectedItemId));
  }

  Future<void> _animateInspectSelectedItemWhenReady() async {
    if (_animating) {
      return;
    }

    final selectedItem = _selectedItem;
    if (selectedItem == null) {
      _applyAction(const InspectSelectedItemWhenReady());
      return;
    }

    final isReady = _isSelectedItemReady();
    if (!isReady) {
      await _runAnimatedApproachUntilReady();
    }
    if (!mounted || _selectedItem == null || !_isSelectedItemReady()) {
      return;
    }

    _applyAction(PetInspect(_state.selectedItemId));
  }

  Future<void> _runAnimatedApproachUntilReady() async {
    if (_animating) {
      return;
    }

    setState(() {
      _animating = true;
    });

    try {
      while (mounted) {
        final selectedItem = _selectedItem;
        if (selectedItem == null || _isSelectedItemReady()) {
          break;
        }

        _applyAction(const Tick());
        await Future<void>.delayed(_autoStepDelay);
      }
    } finally {
      if (mounted) {
        setState(() {
          _animating = false;
        });
      }
    }
  }

  ItemInstance? get _selectedItem => _state.items
      .where((item) => item.id == _state.selectedItemId)
      .firstOrNull;

  bool _isSelectedItemReady() {
    final selectedItem = _selectedItem;
    if (selectedItem == null) {
      return false;
    }
    return _state.pet.position == selectedItem.position ||
        _state.pet.position.isAdjacentTo(selectedItem.position);
  }

  void _showSupportSheet(_SupportView initialView) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) {
        return _SupportSheet(initialView: initialView);
      },
    );
  }

  Future<void> _showMakeItemSheet() async {
    final created = await showModalBottomSheet<ItemTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (context) => const _MakeItemSheet(),
    );

    if (created == null || !mounted) {
      return;
    }

    _dispatch(CreateCustomTemplate(created));
  }

  Future<void> _confirmResetGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Chatty?'),
          content: const Text(
            'This clears the local save and starts a fresh care game on this device.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _persistence.clear();
    if (!mounted) {
      return;
    }

    setState(() {
      _result = _buildFreshGame();
    });
    unawaited(_persistence.save(_result.state));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final compactMobileChrome =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        mediaQuery.size.height < 430;
    final ultraCompactMobileChrome =
        compactMobileChrome && mediaQuery.size.height < 390;
    final nightMode = _state.timeOfDay == pet_rules.TimeOfDay.night;
    final headerPrimaryColor = nightMode
        ? const Color(0xFFF5F8FA)
        : const Color(0xFF203B35);
    final headerSecondaryColor = nightMode
        ? const Color(0xFFD6E8E8)
        : const Color(0xFF47615B);
    final headerIconColor = nightMode
        ? const Color(0xFFEAF4F2)
        : const Color(0xFF203B35);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unlockedTemplates =
        _state.unlockedTemplateIds
            .map((id) => _state.templates[id])
            .whereType<ItemTemplate>()
            .toList()
          ..sort((a, b) {
            final byUnlock = a.unlockLevel.compareTo(b.unlockLevel);
            if (byUnlock != 0) {
              return byUnlock;
            }
            return a.displayName.compareTo(b.displayName);
          });

    final isMobileTarget =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    final tooNarrow = !isMobileTarget && mediaQuery.size.width < 960;
    final portraitLike = mediaQuery.size.width < mediaQuery.size.height;
    if (tooNarrow || portraitLike) {
      return _RotateDeviceScreen(portraitLike: portraitLike);
    }

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _appBackgroundColors(_state.timeOfDay),
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) {
              final useMobileLandscape =
                  isMobileTarget &&
                  (viewport.maxWidth < 1100 || viewport.maxHeight < 620);
              final gameplayPadding = EdgeInsets.all(
                useMobileLandscape
                    ? (ultraCompactMobileChrome ? 6 : 8)
                    : (ultraCompactMobileChrome
                          ? 6
                          : compactMobileChrome
                          ? 10
                          : 16),
              );

              if (useMobileLandscape) {
                return Padding(
                  padding: gameplayPadding,
                  child: _buildMobileLandscapeLayout(
                    constraints: BoxConstraints(
                      maxWidth: viewport.maxWidth - gameplayPadding.horizontal,
                      maxHeight: viewport.maxHeight - gameplayPadding.vertical,
                    ),
                    unlockedTemplates: unlockedTemplates,
                  ),
                );
              }

              return Padding(
                padding: gameplayPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!ultraCompactMobileChrome)
                                Text(
                                  'Chatty-Pet',
                                  style:
                                      (compactMobileChrome
                                              ? theme.textTheme.titleLarge
                                              : theme.textTheme.headlineMedium)
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: headerPrimaryColor,
                                            fontSize: ultraCompactMobileChrome
                                                ? 22
                                                : null,
                                          ),
                                ),
                              if (!ultraCompactMobileChrome) ...[
                                SizedBox(height: compactMobileChrome ? 2 : 4),
                                Text(
                                  'A local-first care toy for small cozy check-ins.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      (compactMobileChrome
                                              ? theme.textTheme.bodySmall
                                              : theme.textTheme.bodyMedium)
                                          ?.copyWith(
                                            color: headerSecondaryColor,
                                          ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: ultraCompactMobileChrome ? 2 : 12),
                        PopupMenuButton<_SupportView>(
                          tooltip: 'Open support menu',
                          onSelected: _showSupportSheet,
                          padding: EdgeInsets.all(
                            ultraCompactMobileChrome
                                ? 0
                                : compactMobileChrome
                                ? 4
                                : 8,
                          ),
                          iconSize: ultraCompactMobileChrome
                              ? 16
                              : compactMobileChrome
                              ? 22
                              : 24,
                          icon: Icon(Icons.more_horiz, color: headerIconColor),
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: _SupportView.help,
                              child: Text('Help'),
                            ),
                            PopupMenuItem(
                              value: _SupportView.privacy,
                              child: Text('Privacy'),
                            ),
                            PopupMenuItem(
                              value: _SupportView.about,
                              child: Text('About'),
                            ),
                          ],
                        ),
                        IconButton(
                          tooltip: 'Reset game',
                          onPressed: _confirmResetGame,
                          padding: EdgeInsets.all(
                            ultraCompactMobileChrome
                                ? 0
                                : compactMobileChrome
                                ? 4
                                : 8,
                          ),
                          iconSize: ultraCompactMobileChrome
                              ? 16
                              : compactMobileChrome
                              ? 22
                              : 24,
                          icon: Icon(Icons.restart_alt, color: headerIconColor),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: ultraCompactMobileChrome
                          ? 2
                          : compactMobileChrome
                          ? 8
                          : 12,
                    ),
                    Expanded(
                      child: _buildDesktopGameLayout(
                        constraints: BoxConstraints(
                          maxWidth:
                              viewport.maxWidth - gameplayPadding.horizontal,
                          maxHeight:
                              viewport.maxHeight - gameplayPadding.vertical,
                        ),
                        unlockedTemplates: unlockedTemplates,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopGameLayout({
    required BoxConstraints constraints,
    required List<ItemTemplate> unlockedTemplates,
  }) {
    final statusWidth = constraints.maxWidth >= 1500 ? 430.0 : 390.0;
    final columnGap = constraints.maxWidth >= 1400 ? 18.0 : 14.0;
    final stageHeight = constraints.maxHeight >= 760 ? 308.0 : 248.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SpeechBubble(text: _state.pet.currentSpeech),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: stageHeight,
                      child: PetStage(
                        state: _state,
                        onItemSelected: (itemId) {
                          _dispatch(SelectItem(itemId));
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ChattyActivityBox(
                              moment: _state.activityMoment,
                            ),
                          ),
                          const SizedBox(height: 10),
                          InventoryStrip(
                            state: _state,
                            onItemSelected: (itemId) {
                              _dispatch(SelectItem(itemId));
                            },
                            onAction: _dispatch,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: columnGap),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: SingleChildScrollView(
                    child: ControlPanel(
                      state: _state,
                      templates: unlockedTemplates,
                      onAction: _dispatch,
                      onMakeItem: _showMakeItemSheet,
                      onToggleMute: () {
                        unawaited(_toggleSoundMuted());
                      },
                      onResetWorld: _confirmResetGame,
                      onOpenHelp: () => _showSupportSheet(_SupportView.help),
                      onOpenPrivacy: () =>
                          _showSupportSheet(_SupportView.privacy),
                      onOpenAbout: () => _showSupportSheet(_SupportView.about),
                      isBusy: _animating,
                      soundMuted: _soundMuted,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: statusWidth,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SingleChildScrollView(child: StatusPanel(state: _state)),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLandscapeLayout({
    required BoxConstraints constraints,
    required List<ItemTemplate> unlockedTemplates,
  }) {
    final compactRightPanel = constraints.maxHeight < 460;
    final ultraCompact = constraints.maxHeight < 390;
    const stageFlex = 1;
    const activityFlex = 1;
    final compactTabBar = Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(
          ultraCompact
              ? 8
              : compactRightPanel
              ? 10
              : 14,
        ),
        border: Border.all(color: const Color(0xFFD6E5DE)),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: const Color(0xFF0B6E69),
        unselectedLabelColor: const Color(0xFF60716C),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: ultraCompact
              ? 9
              : compactRightPanel
              ? 11
              : 13,
        ),
        labelPadding: EdgeInsets.symmetric(
          horizontal: ultraCompact
              ? 0
              : compactRightPanel
              ? 4
              : 8,
        ),
        indicator: const BoxDecoration(
          color: Color(0xFFE4F2ED),
          borderRadius: BorderRadius.all(Radius.circular(18)),
        ),
        tabs: [
          Tab(
            text: 'Care',
            height: ultraCompact
                ? 24
                : compactRightPanel
                ? 28
                : 34,
          ),
          Tab(
            text: 'Today',
            height: ultraCompact
                ? 24
                : compactRightPanel
                ? 28
                : 34,
          ),
        ],
      ),
    );

    final rightPanel = Expanded(
      flex: ultraCompact ? 4 : 5,
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            compactTabBar,
            SizedBox(height: ultraCompact ? 2 : 8),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ControlPanel(
                      state: _state,
                      templates: unlockedTemplates,
                      onAction: _dispatch,
                      onMakeItem: _showMakeItemSheet,
                      onToggleMute: () {
                        unawaited(_toggleSoundMuted());
                      },
                      onResetWorld: _confirmResetGame,
                      onOpenHelp: () => _showSupportSheet(_SupportView.help),
                      onOpenPrivacy: () =>
                          _showSupportSheet(_SupportView.privacy),
                      onOpenAbout: () => _showSupportSheet(_SupportView.about),
                      isBusy: _animating,
                      compact: compactRightPanel,
                      soundMuted: _soundMuted,
                    ),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: StatusPanel(
                      state: _state,
                      compact: compactRightPanel,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: ultraCompact ? 11 : 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: stageFlex,
                child: PetStage(
                  state: _state,
                  onItemSelected: (itemId) {
                    _dispatch(SelectItem(itemId));
                  },
                ),
              ),
              SizedBox(height: ultraCompact ? 4 : 6),
              Expanded(
                flex: activityFlex,
                child: ChattyActivityBox(moment: _state.activityMoment),
              ),
            ],
          ),
        ),
        SizedBox(width: ultraCompact ? 6 : 8),
        rightPanel,
      ],
    );
  }
}

List<Color> _appBackgroundColors(pet_rules.TimeOfDay timeOfDay) {
  return switch (timeOfDay) {
    pet_rules.TimeOfDay.morning => const [
      Color(0xFFF9F1DD),
      Color(0xFFE7F3E8),
      Color(0xFFD9EDE8),
    ],
    pet_rules.TimeOfDay.afternoon => const [
      Color(0xFFF6E9CC),
      Color(0xFFDBF0E2),
      Color(0xFFCBE4DE),
    ],
    pet_rules.TimeOfDay.evening => const [
      Color(0xFFF1DDCE),
      Color(0xFFD8E4E2),
      Color(0xFFC5D8DF),
    ],
    pet_rules.TimeOfDay.night => const [
      Color(0xFF1F3041),
      Color(0xFF25485A),
      Color(0xFF315F63),
    ],
  };
}

enum _SupportView { help, privacy, about }

class _MakeItemSheet extends StatefulWidget {
  const _MakeItemSheet();

  @override
  State<_MakeItemSheet> createState() => _MakeItemSheetState();
}

class _MakeItemSheetState extends State<_MakeItemSheet> {
  final TextEditingController _nameController = TextEditingController();
  ItemKind _kind = ItemKind.toy;
  String _emoji = CustomItemFactory.emojiOptions[ItemKind.toy]!.first;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emojiChoices = CustomItemFactory.emojiOptions[_kind]!;
    const panelInk = Color(0xFF203B35);
    const fieldBorder = Color(0xFF97B7AE);
    const chipSelected = Color(0xFFC8EEE5);
    const chipSelectedBorder = Color(0xFF67A89C);
    const chipUnselected = Color(0xFFFFFFFF);
    const chipUnselectedBorder = Color(0xFFC9D8D3);

    return _ModalPanelShell(
      maxWidth: 640,
      maxHeightFactor: 0.54,
      bottomInset: MediaQuery.of(context).viewInsets.bottom,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Make an item',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: panelInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Give Chatty a simple local custom item. Pick a care type, choose a little icon, and we will handle the reactions safely.',
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: const Color(0xFF35524B),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              maxLength: 18,
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: panelInk,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                labelText: 'Item name',
                hintText: 'Rainbow Biscuit',
                labelStyle: const TextStyle(
                  color: Color(0xFF35524B),
                  fontWeight: FontWeight.w700,
                ),
                hintStyle: const TextStyle(color: Color(0xFF6C837D)),
                counterStyle: const TextStyle(
                  color: Color(0xFF55716A),
                  fontWeight: FontWeight.w600,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: fieldBorder, width: 1.4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: chipSelectedBorder,
                    width: 1.8,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: fieldBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Care type',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF274640),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItemKind.values.map((kind) {
                return ChoiceChip(
                  label: Text(_kindLabel(kind)),
                  showCheckmark: true,
                  selected: _kind == kind,
                  onSelected: (_) {
                    setState(() {
                      _kind = kind;
                      _emoji = CustomItemFactory.emojiOptions[kind]!.first;
                    });
                  },
                  backgroundColor: chipUnselected,
                  selectedColor: chipSelected,
                  side: BorderSide(
                    color: _kind == kind
                        ? chipSelectedBorder
                        : chipUnselectedBorder,
                  ),
                  labelStyle: TextStyle(
                    color: _kind == kind ? panelInk : const Color(0xFF4D6761),
                    fontWeight: FontWeight.w800,
                  ),
                  checkmarkColor: panelInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Text(
              'Pick an icon',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF274640),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: emojiChoices.map((choice) {
                return ChoiceChip(
                  label: Text(choice, style: const TextStyle(fontSize: 20)),
                  showCheckmark: true,
                  selected: _emoji == choice,
                  onSelected: (_) {
                    setState(() {
                      _emoji = choice;
                    });
                  },
                  backgroundColor: chipUnselected,
                  selectedColor: chipSelected,
                  side: BorderSide(
                    color: _emoji == choice
                        ? chipSelectedBorder
                        : chipUnselectedBorder,
                  ),
                  checkmarkColor: panelInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F4EA),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFD7D0C1)),
              ),
              child: Text(
                _previewText(),
                style: const TextStyle(
                  color: Color(0xFF35524B),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Add to shelf'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    final slug = trimmedName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final id =
        'custom_${slug.isEmpty ? 'item' : slug}_${DateTime.now().microsecondsSinceEpoch}';

    Navigator.of(context).pop(
      CustomItemFactory.build(
        id: id,
        displayName: trimmedName,
        emoji: _emoji,
        kind: _kind,
      ),
    );
  }

  String _previewText() {
    final typedName = _nameController.text.trim();
    final name = typedName.isEmpty ? 'Your item' : typedName;
    return 'Preview: $_emoji $name will appear under ${_kindLabel(_kind)} and use safe built-in reactions for that care type.';
  }

  String _kindLabel(ItemKind kind) {
    return switch (kind) {
      ItemKind.food => 'Snack',
      ItemKind.toy => 'Play',
      ItemKind.restItem => 'Cozy',
      ItemKind.cleanItem => 'Tidy',
      ItemKind.curiosity => 'Discovery',
      ItemKind.comfort => 'Comfort',
    };
  }
}

class _SupportSheet extends StatefulWidget {
  const _SupportSheet({required this.initialView});

  final _SupportView initialView;

  @override
  State<_SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<_SupportSheet> {
  late _SupportView _activeView = widget.initialView;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _ModalPanelShell(
      maxWidth: 620,
      maxHeightFactor: 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SupportTabChip(
                label: 'Help',
                selected: _activeView == _SupportView.help,
                onSelected: () {
                  setState(() => _activeView = _SupportView.help);
                },
              ),
              _SupportTabChip(
                label: 'Privacy',
                selected: _activeView == _SupportView.privacy,
                onSelected: () {
                  setState(() => _activeView = _SupportView.privacy);
                },
              ),
              _SupportTabChip(
                label: 'About',
                selected: _activeView == _SupportView.about,
                onSelected: () {
                  setState(() => _activeView = _SupportView.about);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: SingleChildScrollView(
              child: switch (_activeView) {
                _SupportView.help => _HelpPanel(theme: theme),
                _SupportView.privacy => _PrivacyPanel(theme: theme),
                _SupportView.about => _AboutPanel(theme: theme),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ModalPanelShell extends StatelessWidget {
  const _ModalPanelShell({
    required this.child,
    this.maxWidth = 620,
    this.maxHeightFactor = 0.52,
    this.bottomInset = 0,
  });

  final Widget child;
  final double maxWidth;
  final double maxHeightFactor;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final panelHeight = mediaQuery.size.height * maxHeightFactor;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              maxHeight: panelHeight,
            ),
            child: Material(
              color: const Color(0xFFF0F5F3),
              elevation: 18,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 34,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A5D5A),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportTabChip extends StatelessWidget {
  const _SupportTabChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      onSelected: (_) => onSelected(),
      backgroundColor: const Color(0xFFF0F5F3),
      selectedColor: const Color(0xFFC9ECE8),
      side: BorderSide(
        color: selected ? const Color(0xFF7CB8B0) : const Color(0xFFD4E3DE),
      ),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF21453F) : const Color(0xFF5D7771),
        fontWeight: FontWeight.w800,
      ),
      checkmarkColor: const Color(0xFF21453F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    );
  }
}

class _HelpPanel extends StatelessWidget {
  const _HelpPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to play',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF203B35),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Chatty-Pet is a small local-first care toy. You place items on the stage, step time forward, and help Chatty stay fed, rested, tidy, and cheerful.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        const _SupportBullet(
          title: '1. Pick care items',
          body:
              'Use the care shelf to place snacks, toys, cozy spots, and tidy-up tools on the stage.',
        ),
        const _SupportBullet(
          title: '2. Pick a target',
          body:
              'Tap an item on the stage to select it. The compact action controls work on the selected stage item.',
        ),
        const _SupportBullet(
          title: '3. Move Chatty over',
          body:
              'Use Scoot to bring Chatty toward the selected item. When Chatty is close enough, the item is ready to inspect or use.',
        ),
        const _SupportBullet(
          title: '4. Care for needs',
          body:
              'Use Inspect for a closer look, Use to trigger the selected item, and Next to step the world forward when Chatty is already in place.',
        ),
        const _SupportBullet(
          title: '5. Use the utility controls',
          body:
              'Make adds a custom local item, Mute toggles sound, Reset asks for confirmation before clearing the current world, and Help, Privacy, and About stay available from the same utility row.',
        ),
        const _SupportBullet(
          title: '6. Watch for unlocks',
          body:
              'Good care builds affection, unlocks new items, and changes Chatty\'s mood and little lines.',
        ),
      ],
    );
  }
}

class _PrivacyPanel extends StatelessWidget {
  const _PrivacyPanel({required this.theme});

  final ThemeData theme;

  Future<void> _openPrivacyPolicy() async {
    final uri = Uri.parse(_chattyPetPrivacyUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Privacy',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF203B35),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'This build of Chatty-Pet is designed as a local-first toy. It does not require an account, and it does not rely on ads or in-app purchases.',
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        const _SupportBullet(
          title: 'No account required',
          body: 'You can open and use the app without signing in.',
        ),
        const _SupportBullet(
          title: 'No ads or purchases',
          body: 'The app does not include ad flows or in-app purchase flows.',
        ),
        const _SupportBullet(
          title: 'Local save data',
          body:
              'Gameplay, progression, and save data stay local on the device. This build does not depend on a cloud narration service.',
        ),
        const _SupportBullet(
          title: 'External privacy page',
          body:
              'The full public privacy policy for this release is also available on the FMI website.',
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _openPrivacyPolicy,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open full privacy policy'),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            foregroundColor: const Color(0xFF2A8C82),
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutPanel extends StatelessWidget {
  const _AboutPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.height < 420;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'About Chatty-Pet',
          style:
              (compact
                      ? theme.textTheme.headlineSmall
                      : theme.textTheme.headlineSmall)
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF203B35),
                  ),
        ),
        SizedBox(height: compact ? 8 : 12),
        Text(
          'Chatty-Pet is a deterministic tiny terrarium built for local-first play, reducer-owned truth, and honest child-safe interaction surfaces.',
          style:
              (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                  ?.copyWith(height: 1.4),
        ),
        SizedBox(height: compact ? 12 : 20),
        _BrandPanel(
          title: 'Fractal Media Infrastructure',
          assetPath: 'assets/branding/fmi-splash-wordmark.png',
          description:
              'Independent public-interest organization for local-first AI tooling, open research, and public education.',
          compact: compact,
        ),
        SizedBox(height: compact ? 10 : 12),
        _BrandPanel(
          title: 'RD Engine Doctrine',
          assetPath: 'assets/branding/rd-engine-logo.png',
          description:
              'Reducer-governed truth model behind Chatty-Pet\'s deterministic state, event flow, and gameplay integrity.',
          compact: compact,
        ),
        SizedBox(height: compact ? 12 : 16),
        Text(
          'Release identity',
          style:
              (compact
                      ? theme.textTheme.titleSmall
                      : theme.textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: compact ? 6 : 8),
        const _AboutLine(label: 'App ID', value: 'io.instance001.chattypet'),
        const _AboutLine(
          label: 'Steward',
          value: 'Fractal Media Infrastructure (FMI)',
        ),
        const _AboutLine(label: 'Site', value: 'instance001.github.io'),
        const _AboutLine(label: 'License', value: 'AGPL-3.0-or-later'),
        const _AboutLine(
          label: 'Release lane',
          value: 'Android / Google Play App Bundle (.aab)',
        ),
      ],
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final compact = mediaQuery.size.height < 440;
    final veryCompact = mediaQuery.size.height < 380;
    final cardPadding = compact ? 16.0 : 24.0;
    final spacing = compact ? 10.0 : 16.0;
    final titleStyle =
        (compact
                ? theme.textTheme.headlineSmall
                : theme.textTheme.headlineMedium)
            ?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF203B35),
            );
    final bodyStyle =
        (compact ? theme.textTheme.bodyMedium : theme.textTheme.bodyLarge)
            ?.copyWith(color: const Color(0xFF47615B), height: 1.3);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F4EA), Color(0xFFE7F2EC), Color(0xFFD4E6DF)],
          ),
        ),
        child: SafeArea(
          child: InkWell(
            onTap: onContinue,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: compact ? 520 : 560,
                    minHeight:
                        mediaQuery.size.height -
                        mediaQuery.padding.vertical -
                        48,
                  ),
                  child: Center(
                    child: Card(
                      elevation: 0,
                      color: Colors.white.withValues(alpha: 0.88),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(compact ? 26 : 32),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(cardPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Chatty-Pet',
                              style: titleStyle,
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: compact ? 6 : 8),
                            Text(
                              'Tiny deterministic terrarium for Android.',
                              textAlign: TextAlign.center,
                              style: bodyStyle,
                            ),
                            SizedBox(height: spacing),
                            Image.asset(
                              'assets/branding/fmi-splash-wordmark.png',
                              fit: BoxFit.contain,
                              height: veryCompact
                                  ? 52
                                  : compact
                                  ? 60
                                  : 74,
                            ),
                            SizedBox(height: spacing),
                            Image.asset(
                              'assets/branding/rd-engine-logo.png',
                              fit: BoxFit.contain,
                              height: veryCompact
                                  ? 56
                                  : compact
                                  ? 66
                                  : 86,
                            ),
                            SizedBox(height: spacing),
                            Text(
                              'Published under Fractal Media Infrastructure and built on RD Engine reducer doctrine.',
                              textAlign: TextAlign.center,
                              style:
                                  (compact
                                          ? theme.textTheme.bodySmall
                                          : theme.textTheme.bodyMedium)
                                      ?.copyWith(
                                        height: 1.35,
                                        color: const Color(0xFF4C615C),
                                      ),
                            ),
                            SizedBox(height: compact ? 12 : 18),
                            FilledButton(
                              onPressed: onContinue,
                              style: FilledButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: compact ? 16 : 18,
                                  vertical: compact ? 10 : 14,
                                ),
                              ),
                              child: const Text('Continue'),
                            ),
                            SizedBox(height: compact ? 6 : 8),
                            Text(
                              'Tap anywhere to continue',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF6B7A76),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotateDeviceScreen extends StatelessWidget {
  const _RotateDeviceScreen({required this.portraitLike});

  final bool portraitLike;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8F4EA), Color(0xFFE7F2EC), Color(0xFFD4E6DF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Card(
                  elevation: 0,
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          portraitLike
                              ? Icons.screen_rotation_alt
                              : Icons.open_in_full,
                          size: 54,
                          color: const Color(0xFF2A8C82),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          portraitLike
                              ? 'Turn Chatty-Pet Sideways'
                              : 'Make The Window Wider',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF203B35),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          portraitLike
                              ? 'Chatty-Pet is designed for landscape play so the whole toy room stays visible at once.'
                              : 'Chatty-Pet works best in a wide landscape window so nothing important gets pushed offscreen.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF47615B),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6F3EC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFD7D0C1)),
                          ),
                          child: Text(
                            portraitLike
                                ? 'Rotate your phone or tablet to landscape to keep the map, care shelf, and status panel visible together.'
                                : 'Stretch the app wider until the full game layout appears.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF3A514B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.title,
    required this.assetPath,
    required this.description,
    this.compact = false,
  });

  final String title;
  final String assetPath;
  final String description;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F3EC),
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: Border.all(color: const Color(0xFFD7D0C1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                (compact
                        ? theme.textTheme.bodyMedium
                        : theme.textTheme.titleSmall)
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF203B35),
                    ),
          ),
          SizedBox(height: compact ? 6 : 10),
          Center(
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              height: compact ? 40 : 56,
            ),
          ),
          SizedBox(height: compact ? 6 : 10),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.4,
              color: const Color(0xFF51645F),
              fontSize: compact ? 11 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportBullet extends StatelessWidget {
  const _SupportBullet({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Icon(Icons.circle, size: 10, color: Color(0xFF2A8C82)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF3A514B),
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutLine extends StatelessWidget {
  const _AboutLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF3A514B),
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
