class Player {
  String name;
  int speed;
  int climb;
  int swim;
  int coins;
  int level;
  int xp;
  int maxXp;
  int totalMatches;
  int wins;
  int losses;
  DateTime joinedDate;
  int skillUpgradeCount; // For daily mission tracking

  Player({
    required this.name,
    required this.speed,
    required this.climb,
    required this.swim,
    this.coins = 0,
    this.level = 1,
    this.xp = 0,
    this.maxXp = 100,
    this.totalMatches = 0,
    this.wins = 0,
    this.losses = 0,
    DateTime? joinedDate,
    this.skillUpgradeCount = 0,
  }) : joinedDate = joinedDate ?? DateTime.now();

  int get totalPower => speed + climb + swim;

  double get winRate => totalMatches == 0 ? 0 : (wins / totalMatches);

  int get playerScore => (level * 100) + (totalPower * 10) + coins;

  void addXp(int amount) {
    xp += amount;
    while (xp >= maxXp) {
      xp -= maxXp;
      level += 1;
      maxXp = (maxXp * 1.1).toInt();
    }
  }

  void recordWin() {
    totalMatches += 1;
    wins += 1;
  }

  void recordLoss() {
    totalMatches += 1;
    losses += 1;
  }

  void upgradeSpeed() {
    if (coins >= 20 && speed < 30) {
      speed += 1;
      coins -= 20;
      skillUpgradeCount += 1;
    }
  }

  void upgradeClimb() {
    if (coins >= 20 && climb < 30) {
      climb += 1;
      coins -= 20;
      skillUpgradeCount += 1;
    }
  }

  void upgradeSwim() {
    if (coins >= 20 && swim < 30) {
      swim += 1;
      coins -= 20;
      skillUpgradeCount += 1;
    }
  }

  void addCoins(int amount) {
    coins += amount;
  }

  int get daysActive {
    return DateTime.now().difference(joinedDate).inDays;
  }
}
