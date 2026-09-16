/// Long-term, deliberately player-invisible memories for Chatty.
///
/// Needs remain the immediate, visible care loop. This state is only used to
/// make future manifestations and date events feel like part of a life lived
/// together, rather than a list of unlock recipes.
class ChattyLifeState {
  const ChattyLifeState({
    this.activeFormId = baseFormId,
    this.discoveredFormIds = const {baseFormId},
    this.encounteredEventIds = const {},
    this.playfulMoments = 0,
    this.calmMoments = 0,
    this.nourishingMoments = 0,
    this.tidyMoments = 0,
    this.companionMoments = 0,
    this.caredForDays = 0,
    this.variedCareDays = 0,
    this.lastCareDay = 0,
    this.careKindsToday = const {},
    this.lastTransformationDay = 0,
    this.ordinaryTransformationEligible = false,
    this.pendingTransformationFormId,
    this.pendingCalendarEventKey,
    this.pendingFormBeforeCalendarEventId,
    this.activeCalendarEventKey,
    this.formBeforeCalendarEventId,
    this.adoptionDateKey,
    this.lastObservedLocalDateKey,
  });

  static const baseFormId = 'chatty';

  /// The current manifestation. This stays Chatty; forms are not upgrades.
  final String activeFormId;

  /// Encountered-only memories for the future scrapbook. There is no total.
  final Set<String> discoveredFormIds;
  final Set<String> encounteredEventIds;

  final int playfulMoments;
  final int calmMoments;
  final int nourishingMoments;
  final int tidyMoments;
  final int companionMoments;
  final int caredForDays;
  final int variedCareDays;
  final int lastCareDay;
  final Set<ChattyCareKind> careKindsToday;

  /// Used by the future manifestation roll and its cooldown, never rendered.
  final int lastTransformationDay;
  final bool ordinaryTransformationEligible;
  final String? pendingTransformationFormId;
  final String? pendingCalendarEventKey;
  final String? pendingFormBeforeCalendarEventId;
  final String? activeCalendarEventKey;
  final String? formBeforeCalendarEventId;

  /// First local day this world was opened, for a quiet annual surprise.
  final String? adoptionDateKey;

  /// A local `yyyy-MM-dd` key. It never contains calendar, contact, or
  /// location data; it lets later date-event code avoid replaying an event.
  final String? lastObservedLocalDateKey;

  int get totalCareMoments =>
      playfulMoments +
      calmMoments +
      nourishingMoments +
      tidyMoments +
      companionMoments;

  ChattyLifeState recordCare(ChattyCareKind kind, {required int dayCount}) {
    final isNewCareDay = lastCareDay != dayCount;
    final kindsToday = isNewCareDay
        ? <ChattyCareKind>{kind}
        : {...careKindsToday, kind};
    final becameVaried =
        !isNewCareDay && careKindsToday.length < 2 && kindsToday.length >= 2;
    final next = copyWith(
      playfulMoments: playfulMoments + (kind == ChattyCareKind.playful ? 1 : 0),
      calmMoments: calmMoments + (kind == ChattyCareKind.calm ? 1 : 0),
      nourishingMoments:
          nourishingMoments + (kind == ChattyCareKind.nourishing ? 1 : 0),
      tidyMoments: tidyMoments + (kind == ChattyCareKind.tidy ? 1 : 0),
      companionMoments:
          companionMoments + (kind == ChattyCareKind.companion ? 1 : 0),
      caredForDays: caredForDays + (isNewCareDay ? 1 : 0),
      variedCareDays: variedCareDays + (becameVaried ? 1 : 0),
      lastCareDay: dayCount,
      careKindsToday: kindsToday,
    );
    return next.copyWith(
      ordinaryTransformationEligible: next._canConsiderOrdinaryForm(dayCount),
    );
  }

  ChattyLifeState reviewEligibility({required int dayCount}) => copyWith(
    ordinaryTransformationEligible: _canConsiderOrdinaryForm(dayCount),
  );

  /// Stores a surprise before its animation is shown. The UI will complete it
  /// later, which prevents an interrupted animation from losing the moment.
  ChattyLifeState queueOrdinaryTransformation(String formId) =>
      copyWith(pendingTransformationFormId: formId);

  ChattyLifeState queueCalendarTransformation({
    required String formId,
    required String eventKey,
  }) => copyWith(
    pendingTransformationFormId: formId,
    pendingCalendarEventKey: eventKey,
    pendingFormBeforeCalendarEventId: activeCalendarEventKey == null
        ? activeFormId
        : formBeforeCalendarEventId,
  );

  ChattyLifeState completeQueuedTransformation({required int dayCount}) {
    final formId = pendingTransformationFormId;
    if (formId == null) return this;
    final calendarEventKey = pendingCalendarEventKey;
    return copyWith(
      activeFormId: formId,
      discoveredFormIds: {...discoveredFormIds, formId},
      lastTransformationDay: dayCount,
      ordinaryTransformationEligible: false,
      pendingTransformationFormId: null,
      pendingCalendarEventKey: null,
      pendingFormBeforeCalendarEventId: null,
      activeCalendarEventKey: calendarEventKey,
      formBeforeCalendarEventId: calendarEventKey == null
          ? null
          : pendingFormBeforeCalendarEventId,
    );
  }

  ChattyLifeState finishCalendarEvent() {
    if (activeCalendarEventKey == null) return this;
    return copyWith(
      activeFormId: formBeforeCalendarEventId ?? baseFormId,
      activeCalendarEventKey: null,
      formBeforeCalendarEventId: null,
    );
  }

  ChattyLifeState copyWith({
    String? activeFormId,
    Set<String>? discoveredFormIds,
    Set<String>? encounteredEventIds,
    int? playfulMoments,
    int? calmMoments,
    int? nourishingMoments,
    int? tidyMoments,
    int? companionMoments,
    int? caredForDays,
    int? variedCareDays,
    int? lastCareDay,
    Set<ChattyCareKind>? careKindsToday,
    int? lastTransformationDay,
    bool? ordinaryTransformationEligible,
    Object? pendingTransformationFormId = _sentinel,
    Object? pendingCalendarEventKey = _sentinel,
    Object? pendingFormBeforeCalendarEventId = _sentinel,
    Object? activeCalendarEventKey = _sentinel,
    Object? formBeforeCalendarEventId = _sentinel,
    Object? adoptionDateKey = _sentinel,
    Object? lastObservedLocalDateKey = _sentinel,
  }) {
    return ChattyLifeState(
      activeFormId: activeFormId ?? this.activeFormId,
      discoveredFormIds: discoveredFormIds ?? this.discoveredFormIds,
      encounteredEventIds: encounteredEventIds ?? this.encounteredEventIds,
      playfulMoments: playfulMoments ?? this.playfulMoments,
      calmMoments: calmMoments ?? this.calmMoments,
      nourishingMoments: nourishingMoments ?? this.nourishingMoments,
      tidyMoments: tidyMoments ?? this.tidyMoments,
      companionMoments: companionMoments ?? this.companionMoments,
      caredForDays: caredForDays ?? this.caredForDays,
      variedCareDays: variedCareDays ?? this.variedCareDays,
      lastCareDay: lastCareDay ?? this.lastCareDay,
      careKindsToday: careKindsToday ?? this.careKindsToday,
      lastTransformationDay:
          lastTransformationDay ?? this.lastTransformationDay,
      ordinaryTransformationEligible:
          ordinaryTransformationEligible ?? this.ordinaryTransformationEligible,
      pendingTransformationFormId: pendingTransformationFormId == _sentinel
          ? this.pendingTransformationFormId
          : pendingTransformationFormId as String?,
      pendingCalendarEventKey: pendingCalendarEventKey == _sentinel
          ? this.pendingCalendarEventKey
          : pendingCalendarEventKey as String?,
      pendingFormBeforeCalendarEventId:
          pendingFormBeforeCalendarEventId == _sentinel
          ? this.pendingFormBeforeCalendarEventId
          : pendingFormBeforeCalendarEventId as String?,
      activeCalendarEventKey: activeCalendarEventKey == _sentinel
          ? this.activeCalendarEventKey
          : activeCalendarEventKey as String?,
      formBeforeCalendarEventId: formBeforeCalendarEventId == _sentinel
          ? this.formBeforeCalendarEventId
          : formBeforeCalendarEventId as String?,
      adoptionDateKey: adoptionDateKey == _sentinel
          ? this.adoptionDateKey
          : adoptionDateKey as String?,
      lastObservedLocalDateKey: lastObservedLocalDateKey == _sentinel
          ? this.lastObservedLocalDateKey
          : lastObservedLocalDateKey as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'activeFormId': activeFormId,
    'discoveredFormIds': discoveredFormIds.toList()..sort(),
    'encounteredEventIds': encounteredEventIds.toList()..sort(),
    'playfulMoments': playfulMoments,
    'calmMoments': calmMoments,
    'nourishingMoments': nourishingMoments,
    'tidyMoments': tidyMoments,
    'companionMoments': companionMoments,
    'caredForDays': caredForDays,
    'variedCareDays': variedCareDays,
    'lastCareDay': lastCareDay,
    'careKindsToday': careKindsToday.map((kind) => kind.name).toList()..sort(),
    'lastTransformationDay': lastTransformationDay,
    'ordinaryTransformationEligible': ordinaryTransformationEligible,
    'pendingTransformationFormId': pendingTransformationFormId,
    'pendingCalendarEventKey': pendingCalendarEventKey,
    'pendingFormBeforeCalendarEventId': pendingFormBeforeCalendarEventId,
    'activeCalendarEventKey': activeCalendarEventKey,
    'formBeforeCalendarEventId': formBeforeCalendarEventId,
    'adoptionDateKey': adoptionDateKey,
    'lastObservedLocalDateKey': lastObservedLocalDateKey,
  };

  static ChattyLifeState fromJson(Map<String, dynamic> json) => ChattyLifeState(
    activeFormId: json['activeFormId'] as String? ?? baseFormId,
    discoveredFormIds: {
      baseFormId,
      ...(json['discoveredFormIds'] as List<dynamic>? ?? const [])
          .whereType<String>(),
    },
    encounteredEventIds:
        (json['encounteredEventIds'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toSet(),
    playfulMoments: json['playfulMoments'] as int? ?? 0,
    calmMoments: json['calmMoments'] as int? ?? 0,
    nourishingMoments: json['nourishingMoments'] as int? ?? 0,
    tidyMoments: json['tidyMoments'] as int? ?? 0,
    companionMoments: json['companionMoments'] as int? ?? 0,
    caredForDays: json['caredForDays'] as int? ?? 0,
    variedCareDays: json['variedCareDays'] as int? ?? 0,
    lastCareDay: json['lastCareDay'] as int? ?? 0,
    careKindsToday: (json['careKindsToday'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(_careKindOrNull)
        .whereType<ChattyCareKind>()
        .toSet(),
    lastTransformationDay: json['lastTransformationDay'] as int? ?? 0,
    ordinaryTransformationEligible:
        json['ordinaryTransformationEligible'] as bool? ?? false,
    pendingTransformationFormId: json['pendingTransformationFormId'] as String?,
    pendingCalendarEventKey: json['pendingCalendarEventKey'] as String?,
    pendingFormBeforeCalendarEventId:
        json['pendingFormBeforeCalendarEventId'] as String?,
    activeCalendarEventKey: json['activeCalendarEventKey'] as String?,
    formBeforeCalendarEventId: json['formBeforeCalendarEventId'] as String?,
    adoptionDateKey: json['adoptionDateKey'] as String?,
    lastObservedLocalDateKey: json['lastObservedLocalDateKey'] as String?,
  );

  bool _canConsiderOrdinaryForm(int dayCount) =>
      totalCareMoments >= 9 &&
      caredForDays >= 3 &&
      variedCareDays >= 2 &&
      dayCount - lastTransformationDay >= 3;

  static ChattyCareKind? _careKindOrNull(String name) {
    for (final kind in ChattyCareKind.values) {
      if (kind.name == name) return kind;
    }
    return null;
  }
}

enum ChattyCareKind { playful, calm, nourishing, tidy, companion }

const _sentinel = Object();
