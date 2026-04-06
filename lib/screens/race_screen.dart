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
  late AnimationController _confettiController;

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
    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _initializeRace();
  }

  void _initializeRace() {
    opponents = [
      widget.player,
      Player(
        name: "Bot Challenger",
        speed: 7 + (widget.player.level ~/ 2),
        climb: 7 + (widget.player.level ~/ 2),
        swim: 7 + (widget.player.level ~/ 2),
        level: widget.player.level,
      ),
    ];

    _playerControllers = List.generate(
      opponents.length,
      (i) => AnimationController(
        duration: const Duration(seconds: 2),
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
    // Determine winner upfront
    winnerIndex = MatchService.simulateRace(opponents, widget.powerUp);

    // Brief delay before starting animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Run through 3 stages: Run -> Climb -> Swim
    for (int stage = 0; stage < 3; stage++) {
      currentStage = RaceStage.values[stage];

      // Get stage scores for both players
      List<double> scores = MatchService.getStageScore(
        opponents,
        currentStage,
        widget.powerUp,
      );
      double maxScore = scores.reduce((a, b) => a > b ? a : b);

      // Animate progress for this stage
      for (int i = 0; i < _playerControllers.length; i++) {
        _playerControllers[i].reset();
        double speedMultiplier = scores[i] / maxScore;
        double stageProgress = 0.33 * speedMultiplier;

        _playerAnimations[i] = Tween<double>(
          begin: playerProgress[i],
          end: playerProgress[i] + stageProgress,
        ).animate(
          CurvedAnimation(
            parent: _playerControllers[i],
            curve: Curves.easeInOut,
          ),
        );
      }

      // Run animations in parallel
      await Future.wait(_playerControllers.map((c) => c.forward()));

      // Update progress after stage completes
      setState(() {
        for (int i = 0; i < opponents.length; i++) {
          playerProgress[i] = _playerAnimations[i].value;
        }
        stageIndex = stage + 1;
      });

      // Haptic feedback at end of each stage
      if (stage < 2) {
        await HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }

    // Race finished - show result
    setState(() {
      currentStage = RaceStage.finished;
      raceFinished = true;
    });

    // Strong haptic for result
    await HapticFeedback.heavyImpact();

    // Show confetti animation for winner
    if (winnerIndex == 0) {
      _confettiController.forward();
    }

    // Wait before completing race
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      widget.onRaceComplete(winnerIndex!);
    }
  }

  String getPlayerAvatar(int index) {
    return index == 0 ? "🏆" : "🤖";
  }

  Color getPlayerColor(int index) {
    return index == 0 ? Colors.purple.shade500 : Colors.blue.shade500;
  }

  @override
  void dispose() {
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    _confettiController.dispose();
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
            colors: [Colors.purple.shade200, Colors.blue.shade200],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      raceFinished ? "🏁 Race Complete!" : "🏁 Racing...",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
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
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // RACE VISUALIZATION
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: List.generate(opponents.length, (index) {
                          final player = opponents[index];
                          final isWinner = raceFinished && index == winnerIndex;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: ScaleTransition(
                              scale: isWinner && raceFinished
                                  ? Tween<double>(begin: 1.0, end: 1.08)
                                      .animate(
                                        CurvedAnimation(
                                          parent: _confettiController,
                                          curve: Curves.elasticOut,
                                        ),
                                      )
                                  : AlwaysStoppedAnimation(1.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Player header
                                  Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: getPlayerColor(index),
                                          boxShadow: isWinner
                                              ? [
                                                  BoxShadow(
                                                    color: Colors.amber
                                                        .withValues(alpha: 0.8),
                                                    blurRadius: 16,
                                                    spreadRadius: 4,
                                                  ),
                                                ]
                                              : [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 4,
                                                  ),
                                                ],
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
                                            const SizedBox(height: 3),
                                            Text(
                                              "Level ${player.level}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (raceFinished && isWinner)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.amber,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            "🥇 Winner",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber.shade900,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  // Progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: playerProgress[index],
                                      minHeight: 16,
                                      backgroundColor: Colors.grey.shade300,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                            getPlayerColor(index),
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "${(playerProgress[index] * 100).toStringAsFixed(0)}%",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              // STAGE TRACKER
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    const Text(
                      "Stages",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (index) {
                        bool isCompleted = stageIndex > index;
                        bool isActive = stageIndex == index;

                        return Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isCompleted || isActive
                                    ? Colors.purple.shade500
                                    : Colors.grey.shade300,
                                boxShadow: isActive
                                    ? [
                                        BoxShadow(
                                          color: Colors.purple
                                              .withValues(alpha: 0.6),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Center(
                                child: AnimatedScale(
                                  scale: isActive ? 1.2 : 1.0,
                                  duration:
                                      const Duration(milliseconds: 200),
                                  child: Text(
                                    stageEmojis[index],
                                    style: const TextStyle(fontSize: 28),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stageNames[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
