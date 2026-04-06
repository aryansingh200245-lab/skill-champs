import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/powerup.dart';
import '../services/match_service.dart';

class RaceScreen extends StatefulWidget {
  final Player player;
  final PowerUp powerUp;
  final Function(int) onRaceComplete;

  const RaceScreen({
    super.key,
    required this.player,
    required this.powerUp,
    required this.onRaceComplete,
  });

  @override
  State<RaceScreen> createState() => _RaceScreenState();
}

class _RaceScreenState extends State<RaceScreen> with TickerProviderStateMixin {
  late List<AnimationController> _playerControllers;
  late List<Animation<double>> _playerAnimations;

  RaceStage currentStage = RaceStage.run;
  late List<Player> opponents;
  int? winnerIndex;
  bool raceFinished = false;

  List<double> playerProgress = [0.0, 0.0];
  List<String> stageEmojis = ['🏃', '⛰️', '🏊'];
  List<String> stageNames = ['Run', 'Climb', 'Swim'];
  int stageIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeRace();
  }

  void _initializeRace() {
    opponents = [
      widget.player,
      Player(
        name: "Bot",
        speed: 7 + (widget.player.level ~/ 2),
        climb: 7 + (widget.player.level ~/ 2),
        swim: 7 + (widget.player.level ~/ 2),
        level: widget.player.level,
      ),
    ];

    _playerControllers = List.generate(
      opponents.length,
      (i) => AnimationController(
        duration: const Duration(seconds: 3),
        vsync: this,
      ),
    );

    _playerAnimations = List.generate(
      opponents.length,
      (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _playerControllers[i],
          curve: Curves.easeInOut,
        ),
      ),
    );

    _startRace();
  }

  void _startRace() async {
    // Determine winner at start
    winnerIndex = MatchService.simulateRace(opponents, widget.powerUp);

    // Run through 3 stages: Run -> Climb -> Swim
    for (int stage = 0; stage < 3; stage++) {
      currentStage = RaceStage.values[stage];

      // Get stage scores
      List<double> scores =
          MatchService.getStageScore(opponents, currentStage, widget.powerUp);
      double maxScore = scores.reduce((a, b) => a > b ? a : b);

      // Set animation target based on score
      for (int i = 0; i < _playerControllers.length; i++) {
        _playerControllers[i].reset();
        // Slower players have slower animations
        double speedMultiplier = scores[i] / maxScore;
        _playerAnimations[i] = Tween<double>(begin: playerProgress[i], end: playerProgress[i] + (0.33 * speedMultiplier)).animate(
          CurvedAnimation(
            parent: _playerControllers[i],
            curve: Curves.easeInOut,
          ),
        );
      }

      // Run animations in parallel
      await Future.wait(_playerControllers.map((c) => c.forward()));

      // Update progress
      setState(() {
        for (int i = 0; i < opponents.length; i++) {
          playerProgress[i] = _playerAnimations[i].value;
        }
        stageIndex = stage + 1;
      });

      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Finish race
    setState(() {
      currentStage = RaceStage.finished;
      raceFinished = true;
    });

    // Haptic feedback
    await HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(seconds: 2));
    widget.onRaceComplete(winnerIndex!);
  }

  String getPlayerAvatar(int index) {
    if (index == 0) return "🏆"; // Player avatar
    return "🤖"; // AI avatar
  }

  Color getPlayerColor(int index) {
    return index == 0
        ? Colors.purple.shade500
        : Colors.blue.shade500;
  }

  @override
  void dispose() {
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade100, Colors.blue.shade100],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🎬 STAGE HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      raceFinished ? "🏁 Race Complete!" : "🏁 Racing...",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        !raceFinished && stageIndex < 3
                            ? "${stageEmojis[stageIndex]} ${stageNames[stageIndex]} Stage"
                            : "🏁 Final Results",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🏃 RACE VISUALIZATION
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress Bars
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: List.generate(opponents.length, (index) {
                          final player = opponents[index];
                          final isWinner = raceFinished && index == winnerIndex;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: getPlayerColor(index),
                                        boxShadow: isWinner
                                            ? [
                                          BoxShadow(
                                            color: Colors.amber,
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                            : null,
                                      ),
                                      child: Center(
                                        child: Text(
                                          getPlayerAvatar(index),
                                          style: const TextStyle(
                                            fontSize: 28,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            player.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isWinner
                                                ? "🥇 1st Place"
                                                : "🥈 2nd Place",
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isWinner
                                                  ? Colors.amber.shade700
                                                  : Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isWinner)
                                      const Text(
                                        "👑",
                                        style: TextStyle(fontSize: 24),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: playerProgress[index],
                                    minHeight: 12,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      getPlayerColor(index),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // 📊 STAGE PROGRESS
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "Stages",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        bool isCompleted = stageIndex > index;
                        bool isActive = stageIndex == index;

                        return Column(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted || isActive
                                    ? Colors.purple.shade500
                                    : Colors.grey.shade300,
                              ),
                              child: Center(
                                child: Text(
                                  stageEmojis[index],
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              stageNames[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                color: isActive
                                    ? Colors.purple.shade900
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
