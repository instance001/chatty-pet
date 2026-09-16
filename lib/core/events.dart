sealed class PetEvent {
  const PetEvent();
}

class GameStarted extends PetEvent {
  const GameStarted();
}

class ItemSpawned extends PetEvent {
  const ItemSpawned(this.itemId, this.templateId);

  final String itemId;
  final String templateId;
}

class PetMoved extends PetEvent {
  const PetMoved(this.toPosition);

  final String toPosition;
}

class PetNoticedItem extends PetEvent {
  const PetNoticedItem(this.itemId);

  final String itemId;
}

class PetInspectedItem extends PetEvent {
  const PetInspectedItem(this.itemId);

  final String itemId;
}

class PetGreeted extends PetEvent {
  const PetGreeted();
}

class PetAteItem extends PetEvent {
  const PetAteItem(this.itemId);

  final String itemId;
}

class PetPlayedWithItem extends PetEvent {
  const PetPlayedWithItem(this.itemId);

  final String itemId;
}

class PetRested extends PetEvent {
  const PetRested(this.itemId);

  final String itemId;
}

class PetCleaned extends PetEvent {
  const PetCleaned(this.itemId);

  final String itemId;
}

class SpeechChanged extends PetEvent {
  const SpeechChanged(this.line);

  final String line;
}

class ItemSelected extends PetEvent {
  const ItemSelected(this.itemId);

  final String itemId;
}

class StageItemRemoved extends PetEvent {
  const StageItemRemoved(this.itemId);

  final String itemId;
}

class CustomTemplateCreated extends PetEvent {
  const CustomTemplateCreated(this.templateId);

  final String templateId;
}

class ActionRejected extends PetEvent {
  const ActionRejected(this.reason);

  final String reason;
}

class DayAdvanced extends PetEvent {
  const DayAdvanced(this.dayCount);

  final int dayCount;
}

class UnlockEarned extends PetEvent {
  const UnlockEarned(this.templateId);

  final String templateId;
}

class StageCleared extends PetEvent {
  const StageCleared(this.clearedCount);

  final int clearedCount;
}

/// A form has been privately chosen and is waiting for the presentation layer
/// to stage its surprise animation.
class ChattyTransformationQueued extends PetEvent {
  const ChattyTransformationQueued(this.formId);

  final String formId;
}

class ChattyTransformed extends PetEvent {
  const ChattyTransformed(this.formId);

  final String formId;
}
