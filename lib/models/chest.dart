import 'dart:math';

enum ChestType { silver, gold, epic }

class Chest {
  bool isOpened;
  DateTime unlockTime;
  int reward;
  ChestType type;

  Chest({
    required this.isOpened,
    required this.unlockTime,
    required this.reward,
    required this.type,
  });

  bool isReady() {
    return DateTime.now().isAfter(unlockTime);
  }

  String getName() {
    switch (type) {
      case ChestType.silver:
        return "Silver Chest";
      case ChestType.gold:
        return "Gold Chest";
      case ChestType.epic:
        return "Epic Chest";
    }
  }
}

// ✅ OUTSIDE class (IMPORTANT)
Chest generateChest() {
  int rand = Random().nextInt(100);

  if (rand < 60) {
    return Chest(
      isOpened: false,
      unlockTime: DateTime.now().add(const Duration(seconds: 5)),
      reward: 10 + Random().nextInt(10),
      type: ChestType.silver,
    );
  } else if (rand < 90) {
    return Chest(
      isOpened: false,
      unlockTime: DateTime.now().add(const Duration(seconds: 10)),
      reward: 25 + Random().nextInt(15),
      type: ChestType.gold,
    );
  } else {
    return Chest(
      isOpened: false,
      unlockTime: DateTime.now().add(const Duration(seconds: 15)),
      reward: 50 + Random().nextInt(30),
      type: ChestType.epic,
    );
  }
}