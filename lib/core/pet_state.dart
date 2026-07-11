import 'grid.dart';
import 'pet_rules.dart';

class PetState {
  const PetState({
    required this.id,
    required this.name,
    required this.position,
    required this.mood,
    this.targetItemId,
    this.currentSpeech,
    this.fullness = 4,
    this.fun = 4,
    this.rest = 4,
    this.cleanliness = 4,
    this.affection = 0,
  });

  final String id;
  final String name;
  final GridCoord position;
  final PetMood mood;
  final String? targetItemId;
  final String? currentSpeech;
  final int fullness;
  final int fun;
  final int rest;
  final int cleanliness;
  final int affection;

  PetState copyWith({
    String? id,
    String? name,
    GridCoord? position,
    PetMood? mood,
    Object? targetItemId = _sentinel,
    Object? currentSpeech = _sentinel,
    int? fullness,
    int? fun,
    int? rest,
    int? cleanliness,
    int? affection,
  }) {
    return PetState(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      mood: mood ?? this.mood,
      targetItemId: targetItemId == _sentinel
          ? this.targetItemId
          : targetItemId as String?,
      currentSpeech: currentSpeech == _sentinel
          ? this.currentSpeech
          : currentSpeech as String?,
      fullness: fullness ?? this.fullness,
      fun: fun ?? this.fun,
      rest: rest ?? this.rest,
      cleanliness: cleanliness ?? this.cleanliness,
      affection: affection ?? this.affection,
    );
  }
}

const _sentinel = Object();
