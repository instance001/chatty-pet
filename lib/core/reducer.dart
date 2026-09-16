import 'dart:math';

import 'actions.dart';
import 'chatty_activity_moment.dart';
import 'chatty_forms.dart';
import 'chatty_life_state.dart';
import 'events.dart';
import 'game_state.dart';
import 'grid.dart';
import 'item_instance.dart';
import 'item_template.dart';
import 'line_picker.dart';
import 'pet_rules.dart';
import 'pet_state.dart';
import 'reducer_result.dart';

class ChattyPetReducer {
  static ReducerResult reduce(
    GameState state,
    PetAction action, {
    Random? random,
  }) {
    return switch (action) {
      StartNewGame() => _withAppend(
        _refreshPetState(
          state.copyWith(
            pet: state.pet.copyWith(
              currentSpeech: 'Chatty is awake and ready to play!',
            ),
            activityMoment: buildIdleActivityMoment(
              serial: state.activityMoment.serial + 1,
              timeOfDay: state.timeOfDay,
              caption: 'Chatty is awake and ready to play!',
            ),
          ),
        ),
        const [
          GameStarted(),
          SpeechChanged('Chatty is awake and ready to play!'),
        ],
        const ['Chatty is awake and ready to play!'],
      ),
      Tick() => _handleTick(state, random: random),
      AdvanceToSelectedItem() => _handleAdvanceToSelectedItem(state),
      UseSelectedItemWhenReady() => _handleUseSelectedItemWhenReady(state),
      InspectSelectedItemWhenReady() => _handleInspectSelectedItemWhenReady(
        state,
      ),
      SpawnItem(:final templateId) => _handleSpawn(state, templateId),
      CreateCustomTemplate(:final template) => _handleCreateCustomTemplate(
        state,
        template,
      ),
      PetInspect(:final itemId) => _handleInspect(state, itemId),
      PetGreet() => _handlePetGreet(state),
      PetUseItem(:final itemId) => _handleUse(state, itemId),
      SelectItem(:final itemId) => _handleSelectItem(state, itemId),
      RemoveStageItem(:final itemId) => _handleRemoveStageItem(state, itemId),
      ClearStage() => _handleClearStage(state),
      CompleteQueuedTransformation() => _completeQueuedTransformation(state),
      ClearSpeech() => _withAppend(
        state.copyWith(pet: state.pet.copyWith(currentSpeech: null)),
        const [],
        const [],
      ),
    };
  }

  static ReducerResult _handleSpawn(GameState state, String templateId) {
    final template = state.templates[templateId];
    if (template == null) {
      return _reject(state, 'Unknown item template: $templateId');
    }
    if (!state.unlockedTemplateIds.contains(templateId)) {
      return _reject(state, '${template.displayName} is not unlocked yet.');
    }

    final spot = _nextOpenCell(state, templateId);
    if (spot == null) {
      return _reject(state, 'No empty grid cell is available.');
    }

    final itemId = 'item_${state.nextItemId}';
    final item = ItemInstance(
      id: itemId,
      templateId: templateId,
      position: spot,
    );
    final speech = _pickLine(
      template.noticeLines,
      state.tickCount + state.nextItemId,
      fallback: 'Oh! A little surprise for Chatty.',
    );
    final nextState = _refreshPetState(
      state.copyWith(
        items: [...state.items, item],
        nextItemId: state.nextItemId + 1,
        pet: state.pet.copyWith(currentSpeech: speech),
      ),
    );

    return _withAppend(
      nextState,
      [ItemSpawned(itemId, templateId), SpeechChanged(speech)],
      ['Spawned ${template.displayName}.', speech],
    );
  }

  static ReducerResult _handleCreateCustomTemplate(
    GameState state,
    ItemTemplate template,
  ) {
    if (state.templates.containsKey(template.id)) {
      return _reject(state, '${template.displayName} already exists.');
    }

    final line = '${template.displayName} joined Chatty\'s toy box!';
    return _withAppend(
      _refreshPetState(
        state.copyWith(
          templates: {...state.templates, template.id: template},
          unlockedTemplateIds: {...state.unlockedTemplateIds, template.id},
          pet: state.pet.copyWith(currentSpeech: line),
          activityMoment: buildCelebrateActivityMoment(
            serial: state.activityMoment.serial + 1,
            timeOfDay: state.timeOfDay,
            caption: line,
            propEmoji: template.emoji,
          ),
        ),
      ),
      [
        CustomTemplateCreated(template.id),
        UnlockEarned(template.id),
        SpeechChanged(line),
      ],
      [line],
    );
  }

  static ReducerResult _handleTick(GameState state, {Random? random}) {
    final item =
        _resolveTargetItem(state, state.selectedItemId) ??
        _resolveTargetItem(state, state.pet.targetItemId) ??
        _nearestItem(state);
    final nextTickCount = state.tickCount + 1;
    final nextDayCount =
        state.dayCount + (nextTickCount % PetRules.ticksPerDay == 0 ? 1 : 0);
    final nextTimeOfDay = PetRules.timeOfDayForTick(nextTickCount);
    var pet = _decayNeeds(state.pet, nextTickCount);
    final events = <PetEvent>[];
    final lines = <String>[];

    if (nextDayCount != state.dayCount) {
      events.add(DayAdvanced(nextDayCount));
      lines.add(_dayAdvanceLine(nextDayCount));
    }

    if (item == null) {
      final wanderedPosition = _idleWanderPosition(state);
      final moved = wanderedPosition != state.pet.position;
      final form = ChattyForms.byId(state.life.activeFormId);
      final idleLine = ChattyForms.idleFor(
        form,
        pet.mood.name,
        nextTickCount + state.activityMoment.serial,
      );
      pet = pet.copyWith(
        position: wanderedPosition,
        currentSpeech: idleLine,
        targetItemId: null,
      );
      if (moved) {
        events.add(PetMoved(wanderedPosition.toString()));
      }
      events.add(SpeechChanged(idleLine));
      lines.add(idleLine);
      return _finishTick(
        previousState: state,
        nextState: _syncActivityPhase(
          _refreshPetState(
            state.copyWith(
              tickCount: nextTickCount,
              dayCount: nextDayCount,
              timeOfDay: nextTimeOfDay,
              pet: pet,
            ),
          ),
          nextTimeOfDay,
        ),
        events: events,
        lines: lines,
        random: random ?? Random(),
      );
    }

    final distance = pet.position.manhattanDistanceTo(item.position);
    if (distance > 1) {
      final nextPosition = pet.position.stepToward(item.position);
      pet = pet.copyWith(
        position: nextPosition,
        targetItemId: item.id,
        currentSpeech: 'Chatty scoots closer.',
      );
      events.add(PetMoved(nextPosition.toString()));
      events.add(const SpeechChanged('Chatty scoots closer.'));
      lines.add('Chatty scoots closer.');
    } else {
      final template = state.templates[item.templateId]!;
      final line = _pickLine(
        template.noticeLines,
        nextTickCount + item.position.x + item.position.y,
        fallback: 'Oh! ${template.displayName} showed up!',
      );
      pet = pet.copyWith(targetItemId: item.id, currentSpeech: line);
      events.add(PetNoticedItem(item.id));
      events.add(SpeechChanged(line));
      lines.add(line);
    }

    return _finishTick(
      previousState: state,
      nextState: _syncActivityPhase(
        _refreshPetState(
          state.copyWith(
            tickCount: nextTickCount,
            dayCount: nextDayCount,
            timeOfDay: nextTimeOfDay,
            pet: pet,
          ),
        ),
        nextTimeOfDay,
      ),
      events: events,
      lines: lines,
      random: random ?? Random(),
    );
  }

  static ReducerResult _handlePetGreet(GameState state) {
    final form = ChattyForms.byId(state.life.activeFormId);
    final line = ChattyForms.greetingFor(
      form,
      state.pet.mood.name,
      state.tickCount + state.activityMoment.serial,
    );
    return _withAppend(
      state.copyWith(
        pet: state.pet.copyWith(currentSpeech: line),
        activityMoment: buildGreetingActivityMoment(
          serial: state.activityMoment.serial + 1,
          timeOfDay: state.timeOfDay,
          caption: line,
          formEmoji: form.emoji,
        ),
      ),
      [const PetGreeted(), SpeechChanged(line)],
      [line],
    );
  }

  static ReducerResult _finishTick({
    required GameState previousState,
    required GameState nextState,
    required List<PetEvent> events,
    required List<String> lines,
    required Random random,
  }) {
    var settledState = nextState;
    if (nextState.dayCount != previousState.dayCount) {
      final life = nextState.life.reviewEligibility(
        dayCount: nextState.dayCount,
      );
      settledState = nextState.copyWith(life: life);
      if (life.ordinaryTransformationEligible &&
          life.pendingTransformationFormId == null &&
          random.nextInt(100) < 35) {
        final form = ChattyForms.chooseOrdinary(life, random: random);
        settledState = settledState.copyWith(
          life: life.queueOrdinaryTransformation(form.id),
        );
        events.add(ChattyTransformationQueued(form.id));
      }
    }
    return _withAppend(settledState, events, lines);
  }

  static ReducerResult _completeQueuedTransformation(GameState state) {
    final formId = state.life.pendingTransformationFormId;
    if (formId == null) {
      return ReducerResult(state: state, events: const [], lines: const []);
    }
    final form = ChattyForms.byId(formId);
    final line =
        'A little sparkle settles. ${ChattyForms.greetingFor(form, state.pet.mood.name, state.activityMoment.serial + 1)}';
    return _withAppend(
      state.copyWith(
        life: state.life.completeQueuedTransformation(dayCount: state.dayCount),
        pet: state.pet.copyWith(currentSpeech: line),
        activityMoment: buildCelebrateActivityMoment(
          serial: state.activityMoment.serial + 1,
          timeOfDay: state.timeOfDay,
          caption: line,
          propEmoji: form.emoji,
        ),
      ),
      [ChattyTransformed(form.id), SpeechChanged(line)],
      [line],
    );
  }

  static ReducerResult _handleAdvanceToSelectedItem(GameState state) {
    final selectedItem = _resolveTargetItem(state, state.selectedItemId);
    if (selectedItem == null) {
      return _handleTick(state);
    }

    final initialDistance = state.pet.position.manhattanDistanceTo(
      selectedItem.position,
    );
    if (initialDistance <= 1) {
      return _handleTick(state);
    }

    var rollingState = state;
    final allEvents = <PetEvent>[];
    final allLines = <String>[];
    final maxSteps = state.gridWidth + state.gridHeight + 4;

    for (var step = 0; step < maxSteps; step++) {
      final currentItem = _resolveTargetItem(
        rollingState,
        rollingState.selectedItemId,
      );
      if (currentItem == null) {
        break;
      }

      final currentDistance = rollingState.pet.position.manhattanDistanceTo(
        currentItem.position,
      );
      if (currentDistance <= 1) {
        break;
      }

      final tickResult = _handleTick(rollingState);
      rollingState = tickResult.state;
      allEvents.addAll(tickResult.events);
      allLines.addAll(tickResult.lines);
    }

    final finalItem = _resolveTargetItem(
      rollingState,
      rollingState.selectedItemId,
    );
    if (finalItem != null &&
        rollingState.pet.position.manhattanDistanceTo(finalItem.position) <=
            1) {
      final arrivalLine = 'Chatty hustles over, all set and curious.';
      final arrivalTemplate = rollingState.selectedItemId == null
          ? null
          : rollingState.templates[_resolveTargetItem(
                  rollingState,
                  rollingState.selectedItemId,
                )?.templateId ??
                ''];
      return _withAppend(
        _refreshPetState(
          rollingState.copyWith(
            pet: rollingState.pet.copyWith(currentSpeech: arrivalLine),
            activityMoment: buildScootActivityMoment(
              serial: rollingState.activityMoment.serial + 1,
              timeOfDay: rollingState.timeOfDay,
              caption: arrivalLine,
              propEmoji: arrivalTemplate?.emoji,
            ),
          ),
        ),
        [...allEvents, SpeechChanged(arrivalLine)],
        [...allLines, arrivalLine],
      );
    }

    return ReducerResult(
      state: rollingState,
      events: allEvents,
      lines: allLines,
    );
  }

  static ReducerResult _handleUseSelectedItemWhenReady(GameState state) {
    final selectedItemId = state.selectedItemId;
    if (selectedItemId == null) {
      return _reject(
        state,
        'Pick a stage item first so Chatty knows what to use.',
      );
    }

    final candidate = _resolveInteractionCandidate(state, selectedItemId);
    if (candidate.item != null) {
      return _handleUse(state, selectedItemId);
    }

    final moveResult = _handleAdvanceToSelectedItem(state);
    final movedState = moveResult.state;
    final movedCandidate = _resolveInteractionCandidate(
      movedState,
      movedState.selectedItemId,
    );
    if (movedCandidate.item == null) {
      return moveResult;
    }

    final useResult = _handleUse(movedState, movedState.selectedItemId);
    return ReducerResult(
      state: useResult.state,
      events: [...moveResult.events, ...useResult.events],
      lines: [...moveResult.lines, ...useResult.lines],
    );
  }

  static ReducerResult _handleInspectSelectedItemWhenReady(GameState state) {
    final selectedItemId = state.selectedItemId;
    if (selectedItemId == null) {
      return _reject(
        state,
        'Pick a stage item first so Chatty knows what to inspect.',
      );
    }

    final candidate = _resolveInteractionCandidate(state, selectedItemId);
    if (candidate.item != null) {
      return _handleInspect(state, selectedItemId);
    }

    final moveResult = _handleAdvanceToSelectedItem(state);
    final movedState = moveResult.state;
    final movedCandidate = _resolveInteractionCandidate(
      movedState,
      movedState.selectedItemId,
    );
    if (movedCandidate.item == null) {
      return moveResult;
    }

    final inspectResult = _handleInspect(movedState, movedState.selectedItemId);
    return ReducerResult(
      state: inspectResult.state,
      events: [...moveResult.events, ...inspectResult.events],
      lines: [...moveResult.lines, ...inspectResult.lines],
    );
  }

  static ReducerResult _handleInspect(GameState state, String? requestedId) {
    final candidate = _resolveInteractionCandidate(state, requestedId);
    final item = candidate.item;
    if (item == null) {
      return _reject(
        state,
        candidate.reason ?? 'Inspect requires a nearby item.',
      );
    }

    final template = state.templates[item.templateId]!;
    final line = _pickLine(
      template.inspectLines,
      state.tickCount + item.position.x + item.position.y,
      fallback: 'Chatty leans in for a closer look at ${template.displayName}.',
    );
    return _withAppend(
      _refreshPetState(
        state.copyWith(
          pet: state.pet.copyWith(currentSpeech: line, targetItemId: item.id),
          activityMoment: buildInspectActivityMoment(
            serial: state.activityMoment.serial + 1,
            timeOfDay: state.timeOfDay,
            template: template,
            caption: line,
          ),
        ),
      ),
      [PetInspectedItem(item.id), SpeechChanged(line)],
      [line],
    );
  }

  static ReducerResult _handleUse(GameState state, String? requestedId) {
    final candidate = _resolveInteractionCandidate(state, requestedId);
    final item = candidate.item;
    if (item == null) {
      return _reject(state, candidate.reason ?? 'Use requires a nearby item.');
    }

    final template = state.templates[item.templateId]!;
    final baseLine = _pickLine(
      template.useLines,
      state.tickCount + item.position.x + item.position.y + state.pet.affection,
      fallback: 'Chatty gives ${template.displayName} a proper try.',
    );
    final form = ChattyForms.byId(state.life.activeFormId);
    final flourish = ChattyForms.interactionFlourishFor(
      form,
      template.kind,
      state.pet.mood.name,
      state.tickCount + state.activityMoment.serial + item.position.x,
    );
    final line = '$baseLine $flourish';
    final nextItems = state.items
        .where((entry) => entry.id != item.id)
        .toList();
    final updatedPet = _applyTemplateEffects(
      state.pet,
      template,
    ).copyWith(currentSpeech: line, targetItemId: null);

    switch (template.kind) {
      case ItemKind.food:
        return _withAppendedProgress(
          nextState: state.copyWith(
            items: nextItems,
            selectedItemId: state.selectedItemId == item.id
                ? null
                : state.selectedItemId,
            pet: updatedPet,
            activityMoment: buildUseActivityMoment(
              serial: state.activityMoment.serial + 1,
              timeOfDay: state.timeOfDay,
              template: template,
              caption: line,
              actorEmoji: form.emoji,
            ),
          ),
          events: [PetAteItem(item.id), SpeechChanged(line)],
          lines: [line],
        );
      case ItemKind.toy:
        return _withAppendedProgress(
          nextState: state.copyWith(
            items: nextItems,
            selectedItemId: state.selectedItemId == item.id
                ? null
                : state.selectedItemId,
            pet: updatedPet,
            activityMoment: buildUseActivityMoment(
              serial: state.activityMoment.serial + 1,
              timeOfDay: state.timeOfDay,
              template: template,
              caption: line,
              actorEmoji: form.emoji,
            ),
          ),
          events: [PetPlayedWithItem(item.id), SpeechChanged(line)],
          lines: [line],
        );
      case ItemKind.restItem:
        return _withAppendedProgress(
          nextState: state.copyWith(
            items: nextItems,
            selectedItemId: state.selectedItemId == item.id
                ? null
                : state.selectedItemId,
            pet: updatedPet,
            activityMoment: buildUseActivityMoment(
              serial: state.activityMoment.serial + 1,
              timeOfDay: state.timeOfDay,
              template: template,
              caption: line,
              actorEmoji: form.emoji,
            ),
          ),
          events: [PetRested(item.id), SpeechChanged(line)],
          lines: [line],
        );
      case ItemKind.cleanItem:
        return _withAppendedProgress(
          nextState: state.copyWith(
            items: nextItems,
            selectedItemId: state.selectedItemId == item.id
                ? null
                : state.selectedItemId,
            pet: updatedPet,
            activityMoment: buildUseActivityMoment(
              serial: state.activityMoment.serial + 1,
              timeOfDay: state.timeOfDay,
              template: template,
              caption: line,
              actorEmoji: form.emoji,
            ),
          ),
          events: [PetCleaned(item.id), SpeechChanged(line)],
          lines: [line],
        );
      case ItemKind.curiosity:
      case ItemKind.comfort:
        return _withAppendedProgress(
          nextState: state.copyWith(
            items: nextItems,
            selectedItemId: state.selectedItemId == item.id
                ? null
                : state.selectedItemId,
            pet: updatedPet,
            activityMoment: buildUseActivityMoment(
              serial: state.activityMoment.serial + 1,
              timeOfDay: state.timeOfDay,
              template: template,
              caption: line,
              actorEmoji: form.emoji,
            ),
          ),
          events: [PetInspectedItem(item.id), SpeechChanged(line)],
          lines: [line],
        );
    }
  }

  static ReducerResult _handleClearStage(GameState state) {
    if (state.items.isEmpty) {
      return _reject(state, 'There is nothing on the stage to clear.');
    }

    final clearedCount = state.items.length;
    const line = 'Stage cleared. The room feels open and tidy again.';
    return _withAppend(
      _refreshPetState(
        state.copyWith(
          items: const [],
          selectedItemId: null,
          pet: state.pet.copyWith(currentSpeech: line, targetItemId: null),
        ),
      ),
      [StageCleared(clearedCount), const SpeechChanged(line)],
      [line],
    );
  }

  static ReducerResult _handleRemoveStageItem(GameState state, String itemId) {
    final item = state.items.where((entry) => entry.id == itemId).firstOrNull;
    if (item == null) {
      return _reject(state, 'Cannot remove a missing stage item.');
    }

    final template = state.templates[item.templateId]!;
    final line = '${template.displayName} was tucked back onto the shelf.';
    return _withAppend(
      _refreshPetState(
        state.copyWith(
          items: state.items.where((entry) => entry.id != itemId).toList(),
          selectedItemId: state.selectedItemId == itemId
              ? null
              : state.selectedItemId,
          pet: state.pet.copyWith(
            currentSpeech: line,
            targetItemId: state.pet.targetItemId == itemId
                ? null
                : state.pet.targetItemId,
          ),
        ),
      ),
      [StageItemRemoved(itemId), SpeechChanged(line)],
      [line],
    );
  }

  static ReducerResult _handleSelectItem(GameState state, String itemId) {
    final item = state.items.where((entry) => entry.id == itemId).firstOrNull;
    if (item == null) {
      return _reject(state, 'Cannot select a missing item.');
    }

    final template = state.templates[item.templateId]!;
    final line = 'Chatty is looking at ${template.displayName}.';

    return _withAppend(
      _refreshPetState(
        state.copyWith(
          selectedItemId: itemId,
          pet: state.pet.copyWith(currentSpeech: line, targetItemId: itemId),
        ),
      ),
      [ItemSelected(itemId), SpeechChanged(line)],
      [line],
    );
  }

  static GridCoord? _nextOpenCell(GameState state, String templateId) {
    final openCells = <GridCoord>[];
    for (var y = 0; y < state.gridHeight; y++) {
      for (var x = 0; x < state.gridWidth; x++) {
        final coord = GridCoord(x, y);
        final occupiedByPet = state.pet.position == coord;
        final occupiedByItem = state.items.any(
          (item) => item.position == coord,
        );
        if (!occupiedByPet && !occupiedByItem) {
          openCells.add(coord);
        }
      }
    }

    if (openCells.isEmpty) {
      return null;
    }

    final templateSeed = templateId.codeUnits.fold<int>(
      0,
      (total, codeUnit) => total + codeUnit,
    );
    final seed =
        (state.tickCount * 31) +
        (state.nextItemId * 17) +
        (templateSeed * 7) +
        (state.pet.position.x * 13) +
        (state.pet.position.y * 7);
    return openCells[seed % openCells.length];
  }

  static GridCoord _idleWanderPosition(GameState state) {
    const offsets = <GridCoord>[
      GridCoord(0, -1),
      GridCoord(1, 0),
      GridCoord(0, 1),
      GridCoord(-1, 0),
    ];

    for (var index = 0; index < offsets.length; index++) {
      final offset = offsets[(state.tickCount + index) % offsets.length];
      final candidate = GridCoord(
        state.pet.position.x + offset.x,
        state.pet.position.y + offset.y,
      );
      final occupiedByItem = state.items.any(
        (item) => item.position == candidate,
      );
      if (candidate.isWithin(state.gridWidth, state.gridHeight) &&
          !occupiedByItem) {
        return candidate;
      }
    }

    return state.pet.position;
  }

  static ItemInstance? _nearestItem(GameState state) {
    final items = [...state.items];
    items.sort(
      (a, b) => state.pet.position
          .manhattanDistanceTo(a.position)
          .compareTo(state.pet.position.manhattanDistanceTo(b.position)),
    );
    return items.firstOrNull;
  }

  static ItemInstance? _resolveTargetItem(GameState state, String? itemId) {
    if (itemId == null) {
      return null;
    }
    return state.items.where((item) => item.id == itemId).firstOrNull;
  }

  static _InteractionCandidate _resolveInteractionCandidate(
    GameState state,
    String? requestedId,
  ) {
    final desiredId = requestedId ?? state.selectedItemId;
    final item =
        _resolveTargetItem(state, desiredId) ??
        (desiredId == null ? _nearestItem(state) : null);
    if (item == null) {
      return _InteractionCandidate(
        null,
        desiredId == null
            ? 'Pick something on the stage first so Chatty knows where to head.'
            : 'That selected item is not on the stage anymore.',
      );
    }

    final petPosition = state.pet.position;
    final closeEnough =
        petPosition == item.position || petPosition.isAdjacentTo(item.position);
    if (!closeEnough) {
      final template = state.templates[item.templateId]!;
      return _InteractionCandidate(
        null,
        '${template.displayName} is still a little too far away right now.',
      );
    }

    return _InteractionCandidate(item, null);
  }

  static ReducerResult _reject(GameState state, String reason) {
    return _withAppend(
      _refreshPetState(
        state.copyWith(
          pet: state.pet.copyWith(currentSpeech: 'Chatty blinks in confusion.'),
        ),
      ),
      [
        ActionRejected(reason),
        const SpeechChanged('Chatty blinks in confusion.'),
      ],
      ['Chatty blinks in confusion.', reason],
    );
  }

  static ReducerResult _withAppend(
    GameState state,
    List<PetEvent> events,
    List<String> lines,
  ) {
    final nextRecentLines = _appendRecentLines(state.recentLines, lines);

    return ReducerResult(
      state: state.copyWith(
        eventLog: [...state.eventLog, ...events],
        recentLines: nextRecentLines.length <= 8
            ? nextRecentLines
            : nextRecentLines.sublist(nextRecentLines.length - 8),
      ),
      events: events,
      lines: lines,
    );
  }

  static List<String> _appendRecentLines(
    List<String> existing,
    List<String> incoming,
  ) {
    final merged = <String>[...existing];
    for (final line in incoming) {
      if (merged.isNotEmpty && merged.last == line) {
        continue;
      }
      merged.add(line);
    }
    return merged;
  }

  static ReducerResult _withAppendedProgress({
    required GameState nextState,
    required List<PetEvent> events,
    required List<String> lines,
  }) {
    final refreshedState = _recordCareHistory(
      _refreshPetState(nextState),
      events,
    );
    final unlocks = _newUnlocks(refreshedState);
    if (unlocks.isEmpty) {
      return _withAppend(refreshedState, events, lines);
    }

    final updatedUnlocked = {...refreshedState.unlockedTemplateIds, ...unlocks};
    final unlockEvents = unlocks.map(UnlockEarned.new).toList();
    final unlockLines = unlocks
        .map((id) => '${refreshedState.templates[id]!.displayName} unlocked!')
        .toList();
    return _withAppend(
      refreshedState.copyWith(unlockedTemplateIds: updatedUnlocked),
      [...events, ...unlockEvents],
      [...lines, ...unlockLines],
    );
  }

  static GameState _recordCareHistory(GameState state, List<PetEvent> events) {
    ChattyCareKind? careKind;
    for (final event in events) {
      careKind = switch (event) {
        PetAteItem() => ChattyCareKind.nourishing,
        PetPlayedWithItem() => ChattyCareKind.playful,
        PetRested() => ChattyCareKind.calm,
        PetCleaned() => ChattyCareKind.tidy,
        PetInspectedItem() => ChattyCareKind.companion,
        _ => careKind,
      };
      if (careKind != null) break;
    }
    return careKind == null
        ? state
        : state.copyWith(
            life: state.life.recordCare(careKind, dayCount: state.dayCount),
          );
  }

  static GameState _refreshPetState(GameState state) {
    final nextMood = PetRules.deriveMood(
      fullness: state.pet.fullness,
      fun: state.pet.fun,
      rest: state.pet.rest,
      cleanliness: state.pet.cleanliness,
    );
    return state.copyWith(pet: state.pet.copyWith(mood: nextMood));
  }

  static GameState _syncActivityPhase(GameState state, TimeOfDay timeOfDay) {
    final nextPhase = skyPhaseForTimeOfDay(timeOfDay);
    if (state.activityMoment.phase == nextPhase) {
      return state;
    }
    return state.copyWith(
      activityMoment: state.activityMoment.copyWith(phase: nextPhase),
    );
  }

  static PetState _decayNeeds(PetState pet, int nextTickCount) {
    var fullness = pet.fullness;
    var fun = pet.fun;
    var rest = pet.rest;
    var cleanliness = pet.cleanliness;

    if (nextTickCount % 3 == 0) {
      fullness = PetRules.clampNeed(fullness - 1);
    }
    if (nextTickCount % 4 == 0) {
      fun = PetRules.clampNeed(fun - 1);
    }
    if (nextTickCount % 2 == 0) {
      rest = PetRules.clampNeed(rest - 1);
    }
    if (nextTickCount % 5 == 0) {
      cleanliness = PetRules.clampNeed(cleanliness - 1);
    }

    return pet.copyWith(
      fullness: fullness,
      fun: fun,
      rest: rest,
      cleanliness: cleanliness,
    );
  }

  static PetState _applyTemplateEffects(PetState pet, ItemTemplate template) {
    return pet.copyWith(
      fullness: PetRules.clampNeed(pet.fullness + template.fullnessDelta),
      fun: PetRules.clampNeed(pet.fun + template.funDelta),
      rest: PetRules.clampNeed(pet.rest + template.restDelta),
      cleanliness: PetRules.clampNeed(
        pet.cleanliness + template.cleanlinessDelta,
      ),
      affection: PetRules.clampAffection(
        pet.affection + template.affectionDelta,
      ),
    );
  }

  static List<String> _newUnlocks(GameState state) {
    return state.templates.values
        .where(
          (template) =>
              !state.unlockedTemplateIds.contains(template.id) &&
              template.unlockLevel > 0 &&
              state.pet.affection >= template.unlockLevel,
        )
        .map((template) => template.id)
        .toList()
      ..sort();
  }

  static String _pickLine(
    List<String> lines,
    int seed, {
    required String fallback,
  }) {
    return LinePicker.pick(lines, seed.abs(), fallback: fallback);
  }

  static String _dayAdvanceLine(int dayCount) {
    const lines = [
      'A new day begins for Chatty.',
      'Morning stretches into a fresh little day.',
      'Another cozy day starts for Chatty.',
      'Chatty wakes up to a brand new day.',
    ];
    return _pickLine(lines, dayCount, fallback: 'A new day begins for Chatty.');
  }
}

class _InteractionCandidate {
  const _InteractionCandidate(this.item, this.reason);

  final ItemInstance? item;
  final String? reason;
}
