import 'events.dart';
import 'game_state.dart';

class ReducerResult {
  const ReducerResult({
    required this.state,
    required this.events,
    required this.lines,
  });

  final GameState state;
  final List<PetEvent> events;
  final List<String> lines;
}
