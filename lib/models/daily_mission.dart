class DailyMission {
  String id;
  String title;
  String description;
  String icon;
  int targetValue;
  int currentValue;
  int reward;
  bool isCompleted;
  DateTime resetTime;

  DailyMission({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    this.currentValue = 0,
    required this.reward,
    this.isCompleted = false,
    required this.resetTime,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  bool get isReady => isCompleted && !isReset;

  bool get isReset {
    return DateTime.now().isAfter(resetTime);
  }

  void completeReward() {
    isCompleted = true;
  }

  void addProgress(int amount) {
    if (!isCompleted) {
      currentValue += amount;
      if (currentValue >= targetValue) {
        currentValue = targetValue;
      }
    }
  }

  void reset() {
    currentValue = 0;
    isCompleted = false;
    resetTime = DateTime.now().add(const Duration(days: 1));
  }
}

// Generate daily missions
List<DailyMission> generateDailyMissions() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));

  return [
    DailyMission(
      id: 'win_3_matches',
      title: 'Triple Victory',
      description: 'Win 3 matches',
      icon: '🏆',
      targetValue: 3,
      reward: 50,
      resetTime: tomorrow,
    ),
    DailyMission(
      id: 'earn_100_coins',
      title: 'Rich Player',
      description: 'Earn 100 coins',
      icon: '💰',
      targetValue: 100,
      reward: 30,
      resetTime: tomorrow,
    ),
    DailyMission(
      id: 'open_2_chests',
      title: 'Treasure Hunter',
      description: 'Open 2 chests',
      icon: '🎁',
      targetValue: 2,
      reward: 40,
      resetTime: tomorrow,
    ),
    DailyMission(
      id: 'upgrade_5_skills',
      title: 'Skill Master',
      description: 'Upgrade skills 5 times',
      icon: '⭐',
      targetValue: 5,
      reward: 60,
      resetTime: tomorrow,
    ),
    DailyMission(
      id: 'complete_missions',
      title: 'Mission Master',
      description: 'Complete all daily missions',
      icon: '✅',
      targetValue: 4,
      reward: 100,
      resetTime: tomorrow,
    ),
  ];
}
