import '../models/player.dart';
import '../models/powerup.dart';

enum RaceStage { run, climb, swim, finished }

class RaceData {
  List<double> progress; // 0.0 to 1.0 for each player
  RaceStage stage;
  int? winnerIndex;

  RaceData({
    required this.progress,
    required this.stage,
    this.winnerIndex,
  });
}

class MatchService {
  static int getWinnerIndex(List<Player> players, PowerUp powerUp, {String difficulty = 'Normal'}) {
    int bestScore = -1;
    int winnerIndex = 0;

    for (int i = 0; i < players.length; i++) {
      Player p = players[i];

      int score = p.speed + p.climb + p.swim;

      if (i == 0) {
        if (powerUp.type == "speed") score += powerUp.value;
        if (powerUp.type == "climb") score += powerUp.value;
        if (powerUp.type == "swim") score += powerUp.value;
        if (powerUp.type == "shield") score += powerUp.value;
        if (powerUp.type == "luck") score += (powerUp.value ~/ 2);
      }

      if (score > bestScore) {
        bestScore = score;
        winnerIndex = i;
      }
    }

    return winnerIndex;
  }

  // Get stage scores for each player (returns speed for run, climb, swim)
  static List<double> getStageScore(List<Player> players, RaceStage stage, PowerUp powerUp) {
    return List.generate(players.length, (i) {
      Player p = players[i];
      double score = 0;

      if (stage == RaceStage.run) {
        score = p.speed.toDouble();
        if (i == 0 && powerUp.type == "speed") score += powerUp.value;
      } else if (stage == RaceStage.climb) {
        score = p.climb.toDouble();
        if (i == 0 && powerUp.type == "climb") score += powerUp.value;
      } else if (stage == RaceStage.swim) {
        score = p.swim.toDouble();
        if (i == 0 && powerUp.type == "swim") score += powerUp.value;
      }

      return score;
    });
  }

  // Create AI opponent with difficulty scaling
  static Player createAIOpponent(int playerLevel, String difficulty) {
    int baseSkill = 7 + (playerLevel ~/ 2);

    int aiSkillMultiplier = 1;
    if (difficulty == 'Easy') aiSkillMultiplier = 0; // No scaling
    if (difficulty == 'Normal') aiSkillMultiplier = 1; // +1 per level
    if (difficulty == 'Hard') aiSkillMultiplier = 2; // +2 per level

    return Player(
      name: 'AI Bot',
      speed: baseSkill + (playerLevel ~/ aiSkillMultiplier).clamp(0, 20),
      climb: baseSkill + (playerLevel ~/ aiSkillMultiplier).clamp(0, 20),
      swim: baseSkill + (playerLevel ~/ aiSkillMultiplier).clamp(0, 20),
      level: playerLevel,
    );
  }

  // Simulate race and return winner
  static int simulateRace(List<Player> players, PowerUp powerUp, {String difficulty = 'Normal'}) {
    return getWinnerIndex(players, powerUp, difficulty: difficulty);
  }

  // Calculate match rewards based on difficulty
  static Map<String, int> calculateRewards(bool playerWon, String difficulty, int playerLevel, int petBonusMultiplier) {
    int baseCoins = playerWon ? 30 : 10;
    int baseXp = playerWon ? 50 : 15;

    // Difficulty multiplier
    double difficultyMultiplier = 1.0;
    if (difficulty == 'Easy') difficultyMultiplier = 0.8;
    if (difficulty == 'Normal') difficultyMultiplier = 1.0;
    if (difficulty == 'Hard') difficultyMultiplier = 1.5;

    // Level scaling
    double levelMultiplier = 1.0 + (playerLevel * 0.05);

    int finalCoins = ((baseCoins * difficultyMultiplier * levelMultiplier) * petBonusMultiplier).toInt();
    int finalXp = ((baseXp * difficultyMultiplier * levelMultiplier) * petBonusMultiplier).toInt();

    return {
      'coins': finalCoins,
      'xp': finalXp,
    };
  }
}
