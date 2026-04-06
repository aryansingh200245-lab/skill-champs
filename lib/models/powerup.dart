enum PowerUpRarity { common, rare, epic, legendary }

class PowerUp {
  String id;
  String name;
  String type; // speed, climb, swim, luck, shield, double_coins
  int value;
  PowerUpRarity rarity;
  int cooldown; // seconds before next use
  bool isActive;
  DateTime? activatedAt;

  PowerUp({
    required this.id,
    required this.name,
    required this.type,
    required this.value,
    this.rarity = PowerUpRarity.common,
    this.cooldown = 0,
    this.isActive = false,
    this.activatedAt,
  });

  String get emoji {
    switch (type) {
      case 'speed':
        return '⚡';
      case 'climb':
        return '🧗';
      case 'swim':
        return '🏊';
      case 'luck':
        return '🍀';
      case 'shield':
        return '🛡️';
      case 'double_coins':
        return '💎';
      default:
        return '✨';
    }
  }

  String get rarityText {
    switch (rarity) {
      case PowerUpRarity.common:
        return 'Common';
      case PowerUpRarity.rare:
        return 'Rare';
      case PowerUpRarity.epic:
        return 'Epic';
      case PowerUpRarity.legendary:
        return 'Legendary';
    }
  }

  bool get isOnCooldown {
    if (activatedAt == null) return false;
    final elapsed = DateTime.now().difference(activatedAt!).inSeconds;
    return elapsed < cooldown;
  }

  int get remainingCooldown {
    if (activatedAt == null) return 0;
    final elapsed = DateTime.now().difference(activatedAt!).inSeconds;
    return (cooldown - elapsed).clamp(0, cooldown);
  }

  void activate() {
    isActive = true;
    activatedAt = DateTime.now();
  }

  void deactivate() {
    isActive = false;
  }
}

// Generate sample power-ups with different rarities
List<PowerUp> generatePowerUps() {
  return [
    // Common
    PowerUp(
      id: 'speed_1',
      name: 'Quick Feet',
      type: 'speed',
      value: 3,
      rarity: PowerUpRarity.common,
      cooldown: 30,
    ),
    // Rare
    PowerUp(
      id: 'speed_2',
      name: 'Lightning Boots',
      type: 'speed',
      value: 8,
      rarity: PowerUpRarity.rare,
      cooldown: 45,
    ),
    // Epic
    PowerUp(
      id: 'speed_3',
      name: 'Sonic Speed',
      type: 'speed',
      value: 15,
      rarity: PowerUpRarity.epic,
      cooldown: 60,
    ),
    // Common
    PowerUp(
      id: 'climb_1',
      name: 'Strong Grip',
      type: 'climb',
      value: 3,
      rarity: PowerUpRarity.common,
      cooldown: 30,
    ),
    // Rare
    PowerUp(
      id: 'climb_2',
      name: 'Mountain Master',
      type: 'climb',
      value: 8,
      rarity: PowerUpRarity.rare,
      cooldown: 45,
    ),
    // Epic
    PowerUp(
      id: 'climb_3',
      name: 'Sky Climber',
      type: 'climb',
      value: 15,
      rarity: PowerUpRarity.epic,
      cooldown: 60,
    ),
    // Common
    PowerUp(
      id: 'swim_1',
      name: 'Water Wings',
      type: 'swim',
      value: 3,
      rarity: PowerUpRarity.common,
      cooldown: 30,
    ),
    // Rare
    PowerUp(
      id: 'swim_2',
      name: 'Dolphin Mode',
      type: 'swim',
      value: 8,
      rarity: PowerUpRarity.rare,
      cooldown: 45,
    ),
    // Epic
    PowerUp(
      id: 'swim_3',
      name: 'Ocean King',
      type: 'swim',
      value: 15,
      rarity: PowerUpRarity.epic,
      cooldown: 60,
    ),
    // Special - Luck
    PowerUp(
      id: 'luck_1',
      name: 'Lucky Charm',
      type: 'luck',
      value: 5,
      rarity: PowerUpRarity.rare,
      cooldown: 60,
    ),
    // Special - Shield
    PowerUp(
      id: 'shield_1',
      name: 'Protection Shield',
      type: 'shield',
      value: 10,
      rarity: PowerUpRarity.epic,
      cooldown: 90,
    ),
    // Legendary - Double Coins
    PowerUp(
      id: 'double_coins_1',
      name: 'Golden Hour',
      type: 'double_coins',
      value: 2,
      rarity: PowerUpRarity.legendary,
      cooldown: 120,
    ),
  ];
}