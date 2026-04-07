import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/powerup.dart';
import '../models/chest.dart';
import '../services/match_service.dart';
import '../widgets/race_stats_comparison.dart';
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

class _RaceScreenState extends State<RaceScreen> with TickerProviderStateMixin {
  late Player opponent;
  late RaceEngine raceEngine;
  late Timer raceTickTimer;
  late AnimationController _animationController;

  // Race state
  List<double> playerProgress = [0.0, 0.0];
  List<double> segmentProgress = [0.0, 0.0];
  int leaderIndex = 0;
  int? winnerIndex;
  bool raceStarted = false;
  bool raceFinished = false;
  bool overtakeHappened = false;
  List<double> previousProgress = [0.0, 0.0];
  int leadChangeCount = 0;
  double playerMargin = 0.0;
  int currentSegment = 0;

  static const List<String> segmentEmojis = ['🏃', '⛰️', '🏊', '✈️'];
  static const List<String> segmentNames = ['Run', 'Climb', 'Swim', 'Fly'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
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
          currentSegment = raceEngine.currentSegmentIndex;
          
          // Calculate margin (difference in progress)
          playerMargin = (playerProgress[0] - playerProgress[1]).abs();
          
          // Track overtakes
          if (hadOvertake && previousProgress.isNotEmpty) {
            leadChangeCount++;
            HapticFeedback.mediumImpact();
          }
          
          previousProgress = List.from(currentProgress);
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
    _animationController.dispose();
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

  String _getSegmentName(int segment) {
    if (segment < 0 || segment >= segmentNames.length) return "Unknown";
    return segmentNames[segment];
  }

  String _getMarginEmoji() {
    if (playerMargin < 0.03) {
      return "🔥"; // Dead heat
    } else if (playerMargin < 0.08) {
      return "⚡"; // Close
    } else if (playerProgress[0] > playerProgress[1]) {
      return "🏃"; // Leading
    } else {
      return "🔄"; // Trailing
    }
  }

  String _getMarginStatus() {
    if (playerMargin < 0.03) {
      return "DEAD HEAT!";
    } else if (playerMargin < 0.08) {
      return "NECK AND NECK!";
    } else if (playerProgress[0] > playerProgress[1]) {
      return "You're Leading";
    } else {
      return "Catching Up";
    }
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
              const SizedBox(height: 16),

              // Real-time stat comparison
              RaceStatsComparison(
                player: widget.player,
                opponent: opponent,
                currentStage: raceEngine.currentStage,
                playerProgress: playerProgress,
                leaderIndex: leaderIndex,
                raceStarted: raceStarted,
              ),
              const SizedBox(height: 16),

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
            ? "� FINISH LINE!"
            : "🏁 ${segmentEmojis[raceEngine.currentSegmentIndex]} ${segmentNames[raceEngine.currentSegmentIndex]}";

    // Dynamic race story based on margin
    String storyText = "";
    if (raceStarted && !raceFinished) {
      double margin = (playerProgress[0] - playerProgress[1]).abs();
      if (margin > 0.2) {
        storyText = playerProgress[0] > playerProgress[1] 
            ? "You're dominating! 💪" 
            : "Opponent is crushing it! 😰";
      } else if (margin > 0.1) {
        storyText = playerProgress[0] > playerProgress[1]
            ? "You have the lead!"
            : "Opponent ahead...";
      } else if (margin > 0.03) {
        storyText = "Neck and neck! 🔥";
      } else {
        storyText = "DEAD HEAT! ⚡️";
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            headerText,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
          ),
          if (storyText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (playerProgress[0] > playerProgress[1] 
                    ? Colors.green : Colors.red).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                storyText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: playerProgress[0] > playerProgress[1]
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ],
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
          
          // Get which stat dominates in this segment
          int playerStat = 0, opponentStat = 0;
          if (index == 0) {
            playerStat = widget.player.speed;
            opponentStat = opponent.speed;
          } else if (index == 1) {
            playerStat = widget.player.climb;
            opponentStat = opponent.climb;
          } else if (index == 2) {
            playerStat = widget.player.swim;
            opponentStat = opponent.swim;
          } else {
            playerStat = widget.player.fly;
            opponentStat = opponent.fly;
          }
          
          // Strong advantage color - red if player weak, green if player strong
          Color indicatorColor = Colors.grey.shade300;
          if (isCompleted || isActive) {
            if ((playerStat - opponentStat).abs() > 5) {
              // Clear advantage to someone
              indicatorColor = playerStat > opponentStat 
                  ? Colors.green.shade500 
                  : Colors.red.shade500;
            } else {
              // Balanced - orange for tension
              indicatorColor = Colors.amber.shade500;
            }
          }

          return AnimatedScale(
            scale: isActive ? 1.3 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: indicatorColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: indicatorColor.withAlpha((0.7 * 255).toInt()),
                          blurRadius: 16,
                          spreadRadius: 3,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    segmentEmojis[index],
                    style: TextStyle(
                      fontSize: isActive ? 26 : 22,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    segmentNames[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (isCompleted || isActive) && indicatorColor != Colors.grey.shade300
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
    
    // Calculate velocity indicator
    List<PlayerRaceState> playerStates = raceEngine.getPlayerStates();
    double velocityPercent = (playerStates[index].currentVelocity / 2.0).clamp(0.0, 1.0);
    
    // Get status text based on position
    String statusText = "";
    if (raceStarted && !raceFinished) {
      double progress = playerProgress[index];
      double otherProgress = playerProgress[1 - index];
      
      if (progress > 0.95) {
        statusText = "🏁 ALMOST THERE!";
      } else if ((progress - otherProgress).abs() < 0.05) {
        statusText = "⚡ DEAD HEAT!";
      } else if (progress > otherProgress) {
        statusText = "💨 FAST!";
      } else {
        statusText = "🔥 CATCHING UP!";
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player header
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
                            color: _getPlayerColor(index).withAlpha((0.7 * 255).toInt()),
                            blurRadius: 18,
                            spreadRadius: 3,
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
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (statusText.isNotEmpty)
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isLeader ? Colors.amber.shade600 : Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (isWinner)
                const Text(
                  "🏆",
                  style: TextStyle(fontSize: 36),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Velocity indicator bar (showing how fast they're going)
          if (raceStarted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: velocityPercent,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              velocityPercent > 0.7
                                  ? Colors.red.shade500
                                  : velocityPercent > 0.4
                                      ? Colors.orange.shade500
                                      : Colors.blue.shade500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(velocityPercent * 100).toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Track visualization
          Container(
            height: trackHeight,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.5 * 255).toInt()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPlayerColor(index).withAlpha((0.3 * 255).toInt()),
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

                // Calculate progress difference for fighting animation
                Builder(
                  builder: (context) {
                    double otherProgress = playerProgress[1 - index];
                    double progressDiff = (playerProgress[index] - otherProgress).abs();
                    bool isNeckAndNeck = progressDiff < 0.08 && raceStarted && !raceFinished;

                    // Player progress indicator
                    return Padding(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment(
                          (playerProgress[index] * 2) - 1,
                          0,
                        ),
                        child: ScaleTransition(
                          scale: isNeckAndNeck
                              ? Tween<double>(begin: 0.95, end: 1.05).animate(
                                  CurvedAnimation(
                                    parent: _animationController,
                                    curve: Curves.easeInOut,
                                  ),
                                )
                              : AlwaysStoppedAnimation(1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 100),
                            width: playerSize,
                            height: trackHeight - 16,
                            decoration: BoxDecoration(
                              color: _getPlayerColor(index),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isNeckAndNeck
                                  ? [
                                      BoxShadow(
                                        color: _getPlayerColor(index)
                                            .withAlpha((0.6 * 255).toInt()),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : isWinner
                                      ? [
                                          BoxShadow(
                                            color: Colors.amber
                                                .withAlpha((0.6 * 255).toInt()),
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
                    );
                  },
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
      child: Column(
        children: [
          // Current segment and stage info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stage ${currentSegment + 1}",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getSegmentName(currentSegment),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
                // Tension indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Tension",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 120,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Builder(
                        builder: (context) {
                          List<PlayerRaceState> playerStates =
                              raceEngine.getPlayerStates();
                          double tension =
                              playerStates.isNotEmpty ? playerStates[0].tension : 0;
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: tension.clamp(0.0, 1.0),
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                tension > 0.7
                                    ? Colors.red.shade500
                                    : tension > 0.4
                                        ? Colors.orange.shade500
                                        : Colors.green.shade500,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Current margin and lead status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.amber.shade200,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      _getMarginEmoji(),
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getMarginStatus(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                        Text(
                          "${(playerMargin * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Overtake indicator
                if (leadChangeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "⚡",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$leadChangeCount overtakes",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
