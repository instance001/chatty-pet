# Reducer Spec

## Current Actions

- `StartNewGame`
- `Tick`
- `SpawnItem(templateId)`
- `PetInspect(itemId?)`
- `PetUseItem(itemId?)`
- `SelectItem(itemId)`
- `ClearSpeech`

## Current Events

- `GameStarted`
- `ItemSpawned`
- `PetMoved`
- `PetNoticedItem`
- `PetInspectedItem`
- `PetAteItem`
- `PetPlayedWithItem`
- `SpeechChanged`
- `ItemSelected`
- `ActionRejected`

## Rules

- impossible actions reject honestly
- item templates define what a thing is
- item instances define what exists on the stage right now
- speech comes from reducer-confirmed outcomes
- UI selection is represented in structured state, not hidden in widget-only memory
