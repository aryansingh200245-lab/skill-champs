import 'package:flutter/material.dart';
import '../models/player.dart';
import '../services/match_service.dart';

class RaceStatsComparison extends StatelessWidget {
  final Player player;
  final Player opponent;
  final RaceStage currentStage;
  final List<double> playerProgress;
  final int leaderIndex;
  final bool raceStarted;

  const RaceStatsComparison({
    super.key,
    required this.player,
    required this.opponent,
    required this.currentStage,
    required this.playerProgress,
    required this.leaderIndex,
    required this.raceStarted,
  });

  @override
  Widget build(BuildContext context) {
    if (!raceStarted) {
      return const SizedBox.shrink();
    }

    // Get relevant stats for current stage
    int playerStat = _getStageStat(player, currentStage);
    int opponentStat = _getStageStat(opponent, currentStage);

    double maxStat = [player.speed, player.climb, player.swim, player.fly,
                      opponent.speed, opponent.climb, opponent.swim, opponent.fly]
        .reduce((a, b) => a > b ? a : b)
        .toDouble() + 5;

    double playerPercent = (playerStat / maxStat).clamp(0.0, 1.0);
    double opponentPercent = (opponentStat / maxStat).clamp(0.0, 1.0);

    // Calculate margin
    double margin = (playerProgress[0] - playerProgress[1]).abs();
    bool playerLeading = playerProgress[0] > playerProgress[1];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stage indicator
          Text(
            "Current Stage: ${_getStageName(currentStage)}",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 10),

          // Stat comparison
          Row(
            children: [
              // Player stat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "👤 Your ${_getStatName(currentStage)}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: playerPercent,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.purple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$playerStat",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Margin indicator
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: playerLeading
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      "${(margin * 100).toStringAsFixed(1)}%",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: playerLeading
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    playerLeading ? "▲" : "▼",
                    style: TextStyle(
                      fontSize: 18,
                      color: playerLeading
                          ? Colors.green.shade600
                          : Colors.red.shade600,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // Opponent stat
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "🤖 Opponent ${_getStatName(currentStage)}",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: opponentPercent,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$opponentStat",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getStageStat(Player player, RaceStage stage) {
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
        return player.totalPower;
    }
  }

  String _getStageName(RaceStage stage) {
    switch (stage) {
      case RaceStage.run:
        return "🏃 Run";
      case RaceStage.climb:
        return "⛰️ Climb";
      case RaceStage.swim:
        return "🏊 Swim";
      case RaceStage.fly:
        return "✈️ Fly";
      case RaceStage.finished:
        return "🏁 Finished";
    }
  }

  String _getStatName(RaceStage stage) {
    switch (stage) {
      case RaceStage.run:
        return "Speed";
      case RaceStage.climb:
        return "Climb";
      case RaceStage.swim:
        return "Swim";
      case RaceStage.fly:
        return "Fly";
      case RaceStage.finished:
        return "Power";
    }
  }
}
