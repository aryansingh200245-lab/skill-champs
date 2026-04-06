enum PetType { cat, dog, dragon, phoenix }

class Pet {
  String id;
  String name;
  PetType type;
  int level;
  int xp;
  int maxXp;
  int happiness; // 0-100
  int hunger; // 0-100
  DateTime lastFedTime;
  DateTime lastPlayedTime;
  int totalMatches;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    this.level = 1,
    this.xp = 0,
    this.maxXp = 100,
    this.happiness = 100,
    this.hunger = 50,
    DateTime? lastFedTime,
    DateTime? lastPlayedTime,
    this.totalMatches = 0,
  })  : lastFedTime = lastFedTime ?? DateTime.now(),
        lastPlayedTime = lastPlayedTime ?? DateTime.now();

  String get emoji {
    switch (type) {
      case PetType.cat:
        return '🐱';
      case PetType.dog:
        return '🐕';
      case PetType.dragon:
        return '🐉';
      case PetType.phoenix:
        return '🔥';
    }
  }

  String get displayName {
    switch (type) {
      case PetType.cat:
        return 'Luna (Cat)';
      case PetType.dog:
        return 'Max (Dog)';
      case PetType.dragon:
        return 'Blaze (Dragon)';
      case PetType.phoenix:
        return 'Ember (Phoenix)';
    }
  }

  void addXp(int amount) {
    xp += amount;
    while (xp >= maxXp) {
      xp -= maxXp;
      level += 1;
      maxXp = (maxXp * 1.1).toInt();
    }
  }

  void feed() {
    hunger = (hunger - 30).clamp(0, 100);
    happiness = (happiness + 10).clamp(0, 100);
    lastFedTime = DateTime.now();
  }

  void play() {
    happiness = (happiness + 30).clamp(0, 100);
    hunger = (hunger + 20).clamp(0, 100);
    lastPlayedTime = DateTime.now();
  }

  void updateHappiness() {
    final hoursSincePlay = DateTime.now().difference(lastPlayedTime).inHours;
    if (hoursSincePlay > 2) {
      happiness = (happiness - 5).clamp(0, 100);
    }

    final hoursSinceFed = DateTime.now().difference(lastFedTime).inHours;
    if (hoursSinceFed > 4) {
      hunger = (hunger + 5).clamp(0, 100);
      happiness = (happiness - 10).clamp(0, 100);
    }
  }

  int get bonusMultiplier {
    return 1 + (level ~/ 5);
  }

  bool get isHappy => happiness >= 70;
  bool get isHungry => hunger >= 70;
}

// Create default pet
Pet createDefaultPet(PetType type) {
  return Pet(
    id: 'pet_${type.toString()}',
    name: 'Your Pet',
    type: type,
  );
}
