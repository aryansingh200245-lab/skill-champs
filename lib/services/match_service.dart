import '../models/player.dart';
import '../models/powerup.dart';
import 'race_engine.dart';

export 'race_engine.dart' show RaceStage, RaceEngine, PlayerRaceState;

/// Match service handles game logic and race simulation
class MatchService {
  /// Get stage-specific stat for a player (used for info display)
  static double getStageRelevantStat(Player player, RaceStage stage, PowerUp powerUp, bool isPlayer) {
    double stat = 0;

    switch (stage) {
      case RaceStage.run:
        stat = player.speed.toDouble();
        break;
      case RaceStage.climb:
        stat = player.climb.toDouble();
        break;
      case RaceStage.swim:
        stat = player.swim.toDouble();
        break;
      case RaceStage.fly:
        stat = player.fly.toDouble();
        break;
      case RaceStage.finished:
        stat = 0;
        break;
    }

    // Apply power-up if player is human and has relevant stage bonus
    if (isPlayer) {
      if (powerUp.type == "speed" && stage == RaceStage.run) {
        stat += powerUp.value;
      } else if (powerUp.type == "climb" && stage == RaceStage.climb) {
        stat += powerUp.value;
      } else if (powerUp.type == "swim" && stage == RaceStage.swim) {
        stat += powerUp.value;
      } else if (powerUp.type == "fly" && stage == RaceStage.fly) {
        stat += powerUp.value;
      } else if (powerUp.type == "shield") {
        stat += (powerUp.value * 0.5); // Shield gives half bonus to all stages
      }
    }

    return stat;
  }

  /// Create a real race engine for simulation
  static RaceEngine createRaceEngine(List<Player> players, PowerUp powerUp) {
    return RaceEngine(
      players: players,
      powerUp: powerUp,
    );
  }

  /// Simulate complete race and return winner
  /// WARNING: This advances race to completion instantly
  static int simulateRaceToEnd(List<Player> players, PowerUp powerUp) {
    RaceEngine engine = RaceEngine(
      players: players,
      powerUp: powerUp,
    );
    return engine.simulateToEnd();
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
