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

class _RaceScreenState extends State<RaceScreen> with TickerProviderStateMixin {
  late AnimationController _raceController;
  late List<Animation<double>> _playerAnimations;

  late List<Player> opponents;
  int? winnerIndex;
  bool raceFinished = false;
  RaceStage currentStage = RaceStage.run;

  // Race tracking
  List<double> playerProgress = [0.0, 0.0];
  int currentSegmentIndex = 0; // 0 = Run, 1 = Climb, 2 = Swim, 3 = Fly
  
  static const List<String> segmentNames = ['🏃 Run', '⛰️ Climb', '🏊 Swim', '✈️ Fly'];
  static const List<String> segmentEmojis = ['🏃', '⛰️', '🏊', '✈️'];

  @override
  void initState() {
    super.initState();
    _setupRace();
  }

  void _setupRace() {
    // Create AI opponent
    opponents = [
      widget.player,
      Player(
        name: "Opponent",
        speed: 7 + (widget.player.level ~/ 2),
        climb: 7 + (widget.player.level ~/ 2),
        swim: 7 + (widget.player.level ~/ 2),
        fly: 7 + (widget.player.level ~/ 2),
        level: widget.player.level,
      ),
    ];

    // Determine winner BEFORE animation starts
    winnerIndex = MatchService.simulateRace(opponents, widget.powerUp);

    // Create main race animation (6 seconds for 4 stages smooth racing)
    _raceController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    );

    // Create animations for each player that will be updated per segment
    _playerAnimations = List.generate(
      2,
      (i) => Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _raceController, curve: Curves.linear),
      ),
    );

    _startRace();
  }

  Future<void> _startRace() async {
    // Small delay before race starts
    await Future.delayed(const Duration(milliseconds: 300));

    // Run the 4 segments with smooth animation
    for (int segment = 0; segment < 4; segment++) {
      currentStage = RaceStage.values[segment];

      // Get scores for this segment
      List<double> scores = MatchService.getStageScore(
        opponents,
        currentStage,
        widget.powerUp,
      );

      // Normalize scores to get speed multiplier
      double maxScore = scores.reduce((a, b) => a > b ? a : b);

      // Calculate segment duration based on difficulty
      // Segment 1: 1.5 sec, Segment 2: 1.5 sec, Segment 3: 1.5 sec, Segment 4: 1.5 sec = 6 sec total
      const int segmentDurationMs = 1500;

      // Create segment-specific animation
      List<Animation<double>> segmentAnimations = List.generate(
        2,
        (i) {
          double speedMultiplier = scores[i] / maxScore;
          double segmentDistance = 0.25; // Each segment is 1/4 of track

          return Tween<double>(
            begin: playerProgress[i],
            end: playerProgress[i] + (segmentDistance * speedMultiplier),
          ).animate(
            CurvedAnimation(
              parent: _raceController,
              curve: Interval(
                segment / 4.0,
                (segment + 1) / 4.0,
                curve: Curves.easeInOut,
              ),
            ),
          );
        },
      );

      // Update player animations
      _playerAnimations = segmentAnimations;

      // Haptic feedback for segment start
      if (segment < 4) {
        await HapticFeedback.lightImpact();
      }

      // Let this segment play
      await Future.delayed(const Duration(milliseconds: segmentDurationMs));

      // Update displayed progress
      if (mounted) {
        setState(() {
          for (int i = 0; i < 2; i++) {
            playerProgress[i] = _playerAnimations[i].value;
          }
          currentSegmentIndex = segment + 1;
        });
      }

      // Small delay between segments
      if (segment < 3) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    // Race complete
    if (mounted) {
      setState(() {
        raceFinished = true;
        currentStage = RaceStage.finished;
      });

      // Strong haptic for completion
      await HapticFeedback.heavyImpact();

      // Wait before showing result
      await Future.delayed(const Duration(seconds: 1));

      // Calculate rewards based on result
      bool playerWon = winnerIndex == 0;
      int coinsEarned = playerWon ? 30 : 5;
      int xpEarned = playerWon ? 50 : 10;
      Chest? chestEarned;

      if (playerWon) {
        // 40% chance to earn a chest on win
        if ((DateTime.now().millisecondsSinceEpoch % 100) < 40) {
          chestEarned = generateChest();
        }
      }

      // Navigate to result screen
      if (mounted) {
        // Create a copy of the player for result display
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
                // Pop result screen
                Navigator.pop(context);
                // Wait a tiny bit then return to home with final result
                Future.delayed(const Duration(milliseconds: 100), () {
                  widget.onRaceComplete(winnerIndex!);
                });
              },
            ),
          ),
        );
      }
    }
  }

  Color _getPlayerColor(int index) {
    return index == 0 ? Colors.purple.shade500 : Colors.blue.shade500;
  }

  String _getPlayerName(int index) {
    return index == 0 ? opponents[0].name : "Opponent";
  }

  @override
  void dispose() {
    _raceController.dispose();
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
            colors: [Colors.purple.shade50, Colors.blue.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HEADER
              _buildHeader(),

              const SizedBox(height: 24),

              // SEGMENT INDICATORS
              _buildSegmentIndicators(),

              const SizedBox(height: 20),

              // RACE TRACK
              Expanded(
                child: _buildRaceTrack(),
              ),

              const SizedBox(height: 16),

              // BOTTOM INFO
              _buildBottomInfo(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            raceFinished ? "🏁 Race Complete!" : "🏁 RACING...",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade900,
            ),
          ),
          if (!raceFinished) const SizedBox(height: 8),
          if (!raceFinished)
            Text(
              segmentNames[currentSegmentIndex.clamp(0, 3)],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
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
          bool isActive = currentSegmentIndex == index;
          bool isCompleted = currentSegmentIndex > index;

          return AnimatedScale(
            scale: isActive ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? Colors.purple.shade500
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.purple.shade500.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    segmentEmojis[index],
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    segmentNames[index].split(' ')[1],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
    const double trackHeight = 120.0;
    const double playerSize = 60.0;
    const double trackPadding = 16.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // PLAYER 1 (Human Player)
        _buildPlayerRaceRow(
          index: 0,
          trackHeight: trackHeight,
          playerSize: playerSize,
          trackPadding: trackPadding,
        ),
        const SizedBox(height: 40),

        // PLAYER 2 (Opponent)
        _buildPlayerRaceRow(
          index: 1,
          trackHeight: trackHeight,
          playerSize: playerSize,
          trackPadding: trackPadding,
        ),
      ],
    );
  }

  Widget _buildPlayerRaceRow({
    required int index,
    required double trackHeight,
    required double playerSize,
    required double trackPadding,
  }) {
    final isWinner = raceFinished && index == winnerIndex;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: trackPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player name and stats
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getPlayerColor(index),
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.6),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    index == 0 ? "🏆" : "🤖",
                    style: const TextStyle(fontSize: 28),
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
                    Text(
                      "Level ${opponents[index].level}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isWinner)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "1st Place",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              else if (raceFinished)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "2nd Place",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Race track with animated player position
          Container(
            height: trackHeight,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
              border: Border.all(
                color: Colors.grey.shade400,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: AnimatedBuilder(
              animation: _playerAnimations[index],
              builder: (context, child) {
                double progress = _playerAnimations[index].value.clamp(0.0, 1.0);

                return Stack(
                  children: [
                    // Segment dividers inside track
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border(
                                right: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(child: Container()),
                      ],
                    ),

                    // Animated player position
                    Positioned(
                      left: progress * (MediaQuery.of(context).size.width - 48),
                      top: (trackHeight - 50) / 2,
                      child: ScaleTransition(
                        scale: isWinner && raceFinished
                            ? Tween<double>(begin: 1.0, end: 1.15).animate(
                                CurvedAnimation(
                                  parent: _raceController,
                                  curve: const Interval(0.85, 1.0,
                                      curve: Curves.elasticOut),
                                ),
                              )
                            : const AlwaysStoppedAnimation(1.0),
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getPlayerColor(index),
                            boxShadow: [
                              BoxShadow(
                                color: _getPlayerColor(index).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              index == 0 ? "🏃" : "🤖",
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Finish line (rightmost)
                    if (progress >= 0.95)
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 4,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade500.withValues(alpha: 0.6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // Progress percentage
          const SizedBox(height: 8),
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
    );
  }

  Widget _buildBottomInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  "Player",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${(playerProgress[0] * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.grey.shade300,
            ),
            Column(
              children: [
                Text(
                  "Opponent",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${(playerProgress[1] * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
