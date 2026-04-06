import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/powerup.dart';
import '../models/chest.dart';
import '../services/match_service.dart';
import 'race_result_screen.dart';

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

class _RaceScreenState extends State<RaceScreen> {
  late Player opponent;
  late RaceEngine raceEngine;
  late Timer raceTickTimer;

  // Race state
  List<double> playerProgress = [0.0, 0.0];
  List<double> segmentProgress = [0.0, 0.0];
  int leaderIndex = 0;
  int? winnerIndex;
  bool raceStarted = false;
  bool raceFinished = false;
  bool overtakeHappened = false;
  List<double> previousProgress = [0.0, 0.0];

  static const List<String> segmentEmojis = ['🏃', '⛰️', '🏊', '✈️'];
  static const List<String> segmentNames = ['Run', 'Climb', 'Swim', 'Fly'];

  @override
  void initState() {
    super.initState();
    _setupRace();
  }

  void _setupRace() {
    // Create AI opponent
    opponent = Player(
      name: "Opponent",
      speed: 7 + (widget.player.level ~/ 2),
      climb: 7 + (widget.player.level ~/ 2),
      swim: 7 + (widget.player.level ~/ 2),
      fly: 7 + (widget.player.level ~/ 2),
      level: widget.player.level,
    );

    // Create real race engine
    raceEngine = MatchService.createRaceEngine(
      [widget.player, opponent],
      widget.powerUp,
    );

    previousProgress = [0.0, 0.0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRaceAnimation();
    });
  }

  void _startRaceAnimation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        raceStarted = true;
      });

      HapticFeedback.lightImpact();

      // Tick the race engine at 60 FPS
      raceTickTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        bool isComplete = raceEngine.simulateTick();

        // Check for overtakes
        List<double> currentProgress = raceEngine.getProgress();
        bool hadOvertake = raceEngine.checkOvertake(previousProgress);

        setState(() {
          playerProgress = currentProgress;
          segmentProgress = raceEngine.getSegmentProgress();
          leaderIndex = raceEngine.getLeaderIndex();
          overtakeHappened = hadOvertake;
          previousProgress = List.from(currentProgress);

          if (hadOvertake) {
            HapticFeedback.mediumImpact();
          }
        });

        if (isComplete) {
          timer.cancel();
          _onRaceComplete();
        }
      });
    });
  }

  Future<void> _onRaceComplete() async {
    if (!mounted) return;

    winnerIndex = raceEngine.winnerIndex;

    setState(() {
      raceFinished = true;
    });

    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // Calculate rewards
    bool playerWon = winnerIndex == 0;
    int coinsEarned = playerWon ? 30 : 5;
    int xpEarned = playerWon ? 50 : 10;
    Chest? chestEarned;

    if (playerWon && (DateTime.now().millisecondsSinceEpoch % 100) < 40) {
      chestEarned = generateChest();
    }

    // Create result screen
    Player playerDisplay = Player(
      name: widget.player.name,
      speed: widget.player.speed,
      climb: widget.player.climb,
      swim: widget.player.swim,
      fly: widget.player.fly,
      coins: widget.player.coins,
      level: widget.player.level,
      xp: widget.player.xp,
    );

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RaceResultScreen(
            playerWon: playerWon,
            player: playerDisplay,
            coinsEarned: coinsEarned,
            xpEarned: xpEarned,
            chestEarned: chestEarned,
            onContinue: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 100), () {
                widget.onRaceComplete(winnerIndex!);
              });
            },
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    raceTickTimer.cancel();
    super.dispose();
  }

  Color _getPlayerColor(int index) {
    if (index == leaderIndex && raceStarted) {
      return Colors.amber.shade400; // Highlight leader in gold
    }
    return index == 0 ? Colors.purple.shade500 : Colors.blue.shade500;
  }

  String _getPlayerName(int index) {
    return index == 0 ? widget.player.name : opponent.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 16),

              // Segment indicators
              _buildSegmentIndicators(),
              const SizedBox(height: 20),

              // Race track
              Expanded(child: _buildRaceTrack()),
              const SizedBox(height: 16),

              // Bottom info
              _buildBottomInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String headerText = !raceStarted
        ? "🏁 Ready..."
        : raceFinished
            ? "🏁 Race Complete!"
            : "🏁 Racing - ${segmentNames[raceEngine.currentSegmentIndex]}";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        headerText,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: Colors.purple.shade900,
        ),
      ),
    );
  }

  Widget _buildSegmentIndicators() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          bool isActive = raceEngine.currentSegmentIndex == index;
          bool isCompleted = raceEngine.currentSegmentIndex > index;

          return AnimatedScale(
            scale: isActive ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? Colors.purple.shade500
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.purple.shade500.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    segmentEmojis[index],
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    segmentNames[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCompleted || isActive
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildRaceTrack() {
    const double trackHeight = 100.0;
    const double playerSize = 64.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Player 0 (Human)
        _buildPlayer(0, trackHeight, playerSize),
        const SizedBox(height: 50),

        // Player 1 (Opponent)
        _buildPlayer(1, trackHeight, playerSize),
      ],
    );
  }

  Widget _buildPlayer(int index, double trackHeight, double playerSize) {
    final isWinner = raceFinished && index == winnerIndex;
    final isLeader = index == leaderIndex && raceStarted;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPlayerColor(index),
                  boxShadow: isLeader
                      ? [
                          BoxShadow(
                            color: _getPlayerColor(index).withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    index == 0 ? "👤" : "🤖",
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPlayerName(index),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isLeader)
                      Text(
                        "🥇 Leading",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (isWinner)
                const Text(
                  "🏆",
                  style: TextStyle(fontSize: 32),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Track visualization
          Container(
            height: trackHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPlayerColor(index).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // Segment dividers
                Row(
                  children: List.generate(
                    4,
                    (i) => Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            right: i < 3
                                ? BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  )
                                : BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Player progress indicator
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Align(
                    alignment: Alignment(
                      (playerProgress[index] * 2) - 1,
                      0,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: playerSize,
                      height: trackHeight - 16,
                      decoration: BoxDecoration(
                        color: _getPlayerColor(index),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: isWinner
                            ? [
                                BoxShadow(
                                  color: Colors.amber.withOpacity(0.6),
                                  blurRadius: 12,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              index == 0 ? "👤" : "🤖",
                              style: const TextStyle(fontSize: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${(playerProgress[index] * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Finish line
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 6,
                    height: trackHeight,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    if (!raceStarted) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Get ready to race!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your stats: Speed ${widget.player.speed} | Climb ${widget.player.climb} | Swim ${widget.player.swim} | Fly ${widget.player.fly}",
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    if (raceFinished) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          winnerIndex == 0
              ? "🎉 You Won! Great racing!"
              : "💪 Good effort! Keep training!",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: winnerIndex == 0
                ? Colors.green.shade600
                : Colors.orange.shade600,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatBubble(
            "🏃 Speed",
            "${MatchService.getStageRelevantStat(widget.player, RaceStage.run, widget.powerUp, true).toStringAsFixed(1)} vs ${MatchService.getStageRelevantStat(opponent, RaceStage.run, widget.powerUp, false).toStringAsFixed(1)}",
          ),
          _buildStatBubble(
            "⛰️ Climb",
            "${MatchService.getStageRelevantStat(widget.player, RaceStage.climb, widget.powerUp, true).toStringAsFixed(1)} vs ${MatchService.getStageRelevantStat(opponent, RaceStage.climb, widget.powerUp, false).toStringAsFixed(1)}",
          ),
        ],
      ),
    );
  }

  Widget _buildStatBubble(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
