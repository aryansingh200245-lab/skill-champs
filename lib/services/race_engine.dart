import 'dart:math';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/powerup.dart';

enum RaceStage { run, climb, swim, fly, finished }

/// Represents a player's state during a race segment with momentum physics
class PlayerRaceState {
  double position; // 0.0 to 1.0 for segment progress
  double segmentStartPos; // Position when segment started
  RaceStage currentStage;
  bool segmentCompleted;
  double currentVelocity; // Distance per tick
  
  // Physics properties for dynamic racing
  double acceleration = 0.0; // How fast they're speeding up/down
  double momentum = 0.0; // Current momentum factor
  int positionHistory = 0; // Track position changes for momentum
  bool recovering = false; // Are they recovering from a bad segment start?
  double tension = 0.0; // How tense the race is (0-1)

  PlayerRaceState({
    required this.position,
    required this.segmentStartPos,
    required this.currentStage,
    required this.segmentCompleted,
    this.currentVelocity = 0.0,
  });

  /// Reset for next segment with momentum carryover
  void nextSegment(RaceStage stage) {
    segmentStartPos = position;
    currentStage = stage;
    segmentCompleted = false;
    // Keep some momentum from previous segment (0.3x carryover)
    momentum = momentum * 0.3;
    tension = 0.0;
    recovering = false;
  }

  /// Get total race progress (combining all segments)
  double getTotalProgress(int stageIndex) {
    return (stageIndex * 0.25) + (position * 0.25);
  }
}

/// Real-time race simulation engine with dynamic competitive physics
class RaceEngine {
  final List<Player> players;
  final PowerUp powerUp;
  final Random random = Random();

  // Race state
  late List<PlayerRaceState> playerStates;
  late int currentSegmentIndex;
  late RaceStage currentStage;
  double raceTime = 0.0;
  int? winnerIndex;
  bool raceComplete = false;
  
  // Dynamic race state
  int previousLeaderIndex = 0;
  int leaderChangeCount = 0; // Track how many times lead has changed
  List<double> segmentStartProgress = [0.0, 0.0]; // Progress at start of segment

  // Configuration with more dynamic values
  static const double tickRate = 0.016; // 60 FPS
  static const double segmentDistance = 1.0;
  static const double baseVelocity = 0.5;
  
  // Enhanced physics for competitive racing
  static const double velocityVariance = 0.20; // Increased from 0.15 for more unpredictability
  static const double momentumBoost = 0.15; // Momentum acceleration from previous segment
  static const double recoveryFactor = 0.08; // How fast late starters catch up
  static const double overtakeMargin = 0.03;
  static const double dragFactor = 0.05; // Slight drag on leads to allow comebacks
  static const double accelerationFactor = 0.12; // How fast acceleration changes

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

  /// Calculate velocity for a player with dynamic momentum physics
  double _calculateVelocity(int playerIndex) {
    Player player = players[playerIndex];
    PlayerRaceState state = playerStates[playerIndex];
    RaceStage stage = currentStage;

    // 1. Base stat for current segment
    int baseStat = _getStatForStage(player, stage);
    double statWithBonus = _applyPowerUpBonus(playerIndex, baseStat.toDouble());
    double statRatio = statWithBonus / 10.0;

    // 2. Calculate base velocity from stat
    double baseVel = baseVelocity * statRatio;

    // 3. Add momentum from previous segment performance
    double momentumAdjustment = state.momentum * momentumBoost;

    // 4. Apply recovery factor if falling behind
    double recoveryAdjustment = 0.0;
    if (state.position < (segmentDistance * 0.4)) {
      // If early in segment and not the leader, boost slightly
      int leaderIdx = getLeaderIndex();
      if (playerIndex != leaderIdx && state.position < playerStates[leaderIdx].position) {
        recoveryAdjustment = recoveryFactor * (playerStates[leaderIdx].position - state.position);
      }
    }

    // 5. Apply drag if way ahead (to create tension)
    double dragAdjustment = 0.0;
    if (state.position > (segmentDistance * 0.7)) {
      int leaderIdx = getLeaderIndex();
      if (playerIndex == leaderIdx) {
        // Leader feels slight drag near the end
        double marginToSecond = playerStates[leaderIdx].position - 
            playerStates[(leaderIdx + 1) % playerStates.length].position;
        if (marginToSecond > 0.1) {
          dragAdjustment = -dragFactor * marginToSecond;
        }
      }
    }

    // 6. Add significant randomness for unpredictability
    double randomVariance = velocityVariance * (random.nextDouble() - 0.5) * 2;
    
    // 7. Apply acceleration smoothing for momentum feel
    double targetVelocity = baseVel + momentumAdjustment + recoveryAdjustment + dragAdjustment;
    state.acceleration = (targetVelocity - state.currentVelocity) * accelerationFactor;
    double finalVel = state.currentVelocity + state.acceleration + randomVariance;

    // Clamp to reasonable range
    return finalVel.clamp(0.05, 2.0);
  }

  /// Simulate one tick with enhanced dynamic physics
  bool simulateTick() {
    if (raceComplete) return true;

    raceTime += tickRate;

    // Store leader index for change detection
    int prevLeader = getLeaderIndex();

    // Update each player's position with dynamic velocity
    for (int i = 0; i < playerStates.length; i++) {
      if (playerStates[i].segmentCompleted) continue;

      double velocity = _calculateVelocity(i);
      playerStates[i].currentVelocity = velocity;
      playerStates[i].position += velocity * tickRate;

      // Check segment completion
      if (playerStates[i].position >= segmentDistance) {
        playerStates[i].position = segmentDistance;
        playerStates[i].segmentCompleted = true;
        
        // Store momentum for next segment (how hard they were pushing)
        playerStates[i].momentum = (velocity / 2.0).clamp(0.0, 1.0);
      }
    }

    // Check for overtakes and update tension
    int currentLeader = getLeaderIndex();
    if (currentLeader != prevLeader) {
      leaderChangeCount++;
      previousLeaderIndex = prevLeader;
      // Apply haptic feedback for overtakes
      HapticFeedback.mediumImpact();
    }

    // Calculate race tension (0 = predictable, 1 = very close)
    double margin = (playerStates[0].position - playerStates[1].position).abs();
    for (var state in playerStates) {
      state.tension = 1.0 - (margin / 0.5).clamp(0.0, 1.0);
    }

    // Check if all players completed current segment
    bool allCompleted = playerStates.every((state) => state.segmentCompleted);

    if (allCompleted) {
      if (currentSegmentIndex < 3) {
        // Move to next segment
        currentSegmentIndex++;
        currentStage = RaceStage.values[currentSegmentIndex];
        segmentStartProgress = List.from(playerStates.map((s) => s.getTotalProgress(currentSegmentIndex)));

        for (var state in playerStates) {
          state.nextSegment(currentStage);
        }
      } else {
        // Race complete - determine winner
        raceComplete = true;
        currentStage = RaceStage.finished;

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
        bool veryClose = (currentProgress[i] - currentProgress[j]).abs() < overtakeMargin;

        if (wasLeading && !isLeading && veryClose) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get player race states for UI feedback
  List<PlayerRaceState> getPlayerStates() {
    return playerStates;
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
