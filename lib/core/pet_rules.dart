enum PetMood {
  happy,
  hungry,
  sleepy,
  playful,
  messy,
  curious,
  grumpy,
  cozy,
}

enum TimeOfDay {
  morning,
  afternoon,
  evening,
  night,
}

class PetRules {
  static const int maxNeedValue = 5;
  static const int maxAffection = 20;
  static const int ticksPerDay = 24;

  static int clampNeed(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > maxNeedValue) {
      return maxNeedValue;
    }
    return value;
  }

  static int clampAffection(int value) {
    if (value < 0) {
      return 0;
    }
    if (value > maxAffection) {
      return maxAffection;
    }
    return value;
  }

  static TimeOfDay timeOfDayForTick(int tickCount) {
    switch (tickCount % ticksPerDay) {
      case 0:
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
        return TimeOfDay.morning;
      case 6:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
        return TimeOfDay.afternoon;
      case 12:
      case 13:
      case 14:
      case 15:
      case 16:
      case 17:
        return TimeOfDay.evening;
      case 18:
      case 19:
      case 20:
      case 21:
      case 22:
      case 23:
        return TimeOfDay.night;
      default:
        return TimeOfDay.morning;
    }
  }

  static PetMood deriveMood({
    required int fullness,
    required int fun,
    required int rest,
    required int cleanliness,
  }) {
    if (fullness <= 1) {
      return PetMood.hungry;
    }
    if (rest <= 1) {
      return PetMood.sleepy;
    }
    if (cleanliness <= 1) {
      return PetMood.messy;
    }
    if (fun <= 1) {
      return PetMood.grumpy;
    }
    if (fullness >= 4 && fun >= 4 && rest >= 4 && cleanliness >= 4) {
      return PetMood.happy;
    }
    if (rest >= 4 && cleanliness >= 4) {
      return PetMood.cozy;
    }
    if (fun >= 4) {
      return PetMood.playful;
    }
    return PetMood.curious;
  }
}
