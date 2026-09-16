import 'item_template.dart';

sealed class PetAction {
  const PetAction();
}

class StartNewGame extends PetAction {
  const StartNewGame();
}

class Tick extends PetAction {
  const Tick();
}

class SpawnItem extends PetAction {
  const SpawnItem(this.templateId);

  final String templateId;
}

class PetInspect extends PetAction {
  const PetInspect([this.itemId]);

  final String? itemId;
}

class PetGreet extends PetAction {
  const PetGreet();
}

class PetUseItem extends PetAction {
  const PetUseItem([this.itemId]);

  final String? itemId;
}

class SelectItem extends PetAction {
  const SelectItem(this.itemId);

  final String itemId;
}

class RemoveStageItem extends PetAction {
  const RemoveStageItem(this.itemId);

  final String itemId;
}

class CreateCustomTemplate extends PetAction {
  const CreateCustomTemplate(this.template);

  final ItemTemplate template;
}

class AdvanceToSelectedItem extends PetAction {
  const AdvanceToSelectedItem();
}

class UseSelectedItemWhenReady extends PetAction {
  const UseSelectedItemWhenReady();
}

class InspectSelectedItemWhenReady extends PetAction {
  const InspectSelectedItemWhenReady();
}

class ClearSpeech extends PetAction {
  const ClearSpeech();
}

class ClearStage extends PetAction {
  const ClearStage();
}

class CompleteQueuedTransformation extends PetAction {
  const CompleteQueuedTransformation();
}
