import 'dart:math';
import '../models/player.dart';
import '../models/powerup.dart';

enum RaceStage { run, climb, swim, fly, finished }

/// Represents a player's state during a race segment
class PlayerRaceState {
  double position; // 0.0 to 1.0 for segment progress
  double segmentStartPos; // Position when segment started
  RaceStage currentStage;
  bool segmentCompleted;
  double currentVelocity; // Distance per tick

  PlayerRaceState({
    required this.position,
    required this.segmentStartPos,
    required this.currentStage,
    required this.segmentCompleted,
    this.currentVelocity = 0.0,
  });

  /// Reset for next segment
  void nextSegment(RaceStage stage) {
    segmentStartPos = position;
    currentStage = stage;
    segmentCompleted = false;
    currentVelocity = 0.0;
  }

  /// Get total race progress (combining all segments)
  double getTotalProgress(int stageIndex) {
    return (stageIndex * 0.25) + (position * 0.25);
  }
}

/// Real-time race simulation engine
class RaceEngine {
  final List<Player> players;
  final PowerUp powerUp;
  final Random random = Random();

  // Race state
  late List<PlayerRaceState> playerStates;
  late int currentSegmentIndex;
  late RaceStage currentStage;
  double raceTime = 0.0; // Total time elapsed
  int? winnerIndex;
  bool raceComplete = false;

  // Configuration
  static const double TICK_RATE = 0.016; // ~60 FPS (16ms per tick)
  static const double SEGMENT_DISTANCE = 1.0; // Each segment is 1.0 units
  static const double BASE_VELOCITY = 0.5; // Base movement per tick
  static const double VELOCITY_VARIANCE = 0.15; // Random velocity variance
  static const double OVERTAKE_MARGIN = 0.03; // How close before overtake is possible

  RaceEngine({
    required this.players,
    required this.powerUp,
  }) {
    _initializeRace();
  }

  void _initializeRace() {
    // Create player race states
    playerStates = List.generate(
      players.length,
      (i) => PlayerRaceState(
        position: 0.0,
        segmentStartPos: 0.0,
        currentStage: RaceStage.run,
        segmentCompleted: false,
      ),
    );

    currentSegmentIndex = 0;
    currentStage = RaceStage.run;
  }

  /// Get stat for current stage
  int _getStatForStage(Player player, RaceStage stage) {
    switch (stage) {
      case RaceStage.run:
        return player.speed;
      case RaceStage.climb:
        return player.climb;
      case RaceStage.swim:
        return player.swim;
      case RaceStage.fly:
        return player.fly;
      case RaceStage.finished:
        return 0;
    }
  }

  /// Apply power-up bonus to player 0 (the human player)
  double _applyPowerUpBonus(int playerIndex, double baseStat) {
    if (playerIndex != 0) return baseStat;

    double bonus = 0.0;
    if (powerUp.type == "speed" && currentStage == RaceStage.run) {
      bonus = powerUp.value.toDouble();
    } else if (powerUp.type == "climb" && currentStage == RaceStage.climb) {
      bonus = powerUp.value.toDouble();
    } else if (powerUp.type == "swim" && currentStage == RaceStage.swim) {
      bonus = powerUp.value.toDouble();
    } else if (powerUp.type == "fly" && currentStage == RaceStage.fly) {
      bonus = powerUp.value.toDouble();
    } else if (powerUp.type == "shield") {
      bonus = (powerUp.value * 0.5).toDouble(); // Shield gives half bonus to all
    }

    return baseStat + bonus;
  }

  /// Calculate velocity for a player in current segment
  double _calculateVelocity(int playerIndex) {
    Player player = players[playerIndex];
    int baseStat = _getStatForStage(player, currentStage);
    double statWithBonus = _applyPowerUpBonus(playerIndex, baseStat.toDouble());

    // Higher stat = higher velocity
    // Normalize around base (10 is average)
    double statRatio = statWithBonus / 10.0;

    // Calculate velocity: higher stats move faster
    double baseVel = BASE_VELOCITY * statRatio;

    // Add slight randomness for realism and tension
    double variance = VELOCITY_VARIANCE * random.nextDouble() - (VELOCITY_VARIANCE / 2);
    double finalVel = baseVel + variance;

    // Clamp to reasonable values
    return finalVel.clamp(0.05, 2.0);
  }

  /// Simulate one tick of the race
  /// Returns true if race is complete
  bool simulateTick() {
    if (raceComplete) return true;

    raceTime += TICK_RATE;

    // Update each player's position
    for (int i = 0; i < playerStates.length; i++) {
      if (playerStates[i].segmentCompleted) continue;

      // Calculate velocity for this tick
      double velocity = _calculateVelocity(i);
      playerStates[i].currentVelocity = velocity;

      // Move player
      playerStates[i].position += velocity * TICK_RATE;

      // Check if segment completed
      if (playerStates[i].position >= SEGMENT_DISTANCE) {
        playerStates[i].position = SEGMENT_DISTANCE;
        playerStates[i].segmentCompleted = true;
      }
    }

    // Check if all players completed current segment
    bool allCompleted =
        playerStates.every((state) => state.segmentCompleted);

    if (allCompleted) {
      // Move to next segment
      if (currentSegmentIndex < 3) {
        currentSegmentIndex++;
        currentStage = RaceStage.values[currentSegmentIndex];

        // Reset segment progress
        for (var state in playerStates) {
          state.nextSegment(currentStage);
        }
      } else {
        // Race complete!
        raceComplete = true;
        currentStage = RaceStage.finished;

        // Determine winner (last player to finish total race)
        double maxTotal = -1;
        for (int i = 0; i < playerStates.length; i++) {
          double total = playerStates[i].getTotalProgress(4);
          if (total > maxTotal) {
            maxTotal = total;
            winnerIndex = i;
          }
        }

        return true;
      }
    }

    return false;
  }

  /// Get current race progress for all players (0.0 to 1.0)
  List<double> getProgress() {
    return List.generate(
      playerStates.length,
      (i) => playerStates[i].getTotalProgress(currentSegmentIndex),
    );
  }

  /// Get segment-specific progress (0.0 to 1.0 within current segment)
  List<double> getSegmentProgress() {
    return List.generate(
      playerStates.length,
      (i) => playerStates[i].position,
    );
  }

  /// Get who is leading
  int getLeaderIndex() {
    List<double> progress = getProgress();
    int leader = 0;
    double maxProgress = progress[0];

    for (int i = 1; i < progress.length; i++) {
      if (progress[i] > maxProgress) {
        maxProgress = progress[i];
        leader = i;
      }
    }

    return leader;
  }

  /// Check if there's been an overtake
  bool checkOvertake(List<double> previousProgress) {
    List<double> currentProgress = getProgress();

    for (int i = 0; i < previousProgress.length; i++) {
      for (int j = 0; j < previousProgress.length; j++) {
        if (i == j) continue;

        bool wasLeading = previousProgress[i] > previousProgress[j];
        bool isLeading = currentProgress[i] > currentProgress[j];
        bool veryClose = (currentProgress[i] - currentProgress[j]).abs() < OVERTAKE_MARGIN;

        if (wasLeading && !isLeading && veryClose) {
          return true;
        }
      }
    }

    return false;
  }

  /// Simulate entire race and return winner (for instant result if needed)
  int simulateToEnd() {
    while (!raceComplete) {
      simulateTick();
    }
    return winnerIndex ?? 0;
  }

  /// Get race statistics
  Map<String, dynamic> getRaceStats() {
    return {
      'currentSegment': currentSegmentIndex,
      'currentStage': currentStage,
      'raceTime': raceTime,
      'isComplete': raceComplete,
      'winner': winnerIndex,
      'leaderIndex': getLeaderIndex(),
    };
  }
}
