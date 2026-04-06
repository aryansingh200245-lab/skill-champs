import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/chest.dart';

class RaceResultScreen extends StatefulWidget {
  final bool playerWon;
  final Player player;
  final int coinsEarned;
  final int xpEarned;
  final Chest? chestEarned;
  final VoidCallback onContinue;

  const RaceResultScreen({
    super.key,
    required this.playerWon,
    required this.player,
    required this.coinsEarned,
    required this.xpEarned,
    this.chestEarned,
    required this.onContinue,
  });

  @override
  State<RaceResultScreen> createState() => _RaceResultScreenState();
}

class _RaceResultScreenState extends State<RaceResultScreen>
    with TickerProviderStateMixin {
  late AnimationController _resultController;
  late AnimationController _rewardController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showReward = false;

  @override
  void initState() {
    super.initState();

    // Main result animation
    _resultController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Reward animation
    _rewardController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Scale animation for result badge
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeIn),
    );

    // Slide animation for rewards
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _rewardController, curve: Curves.easeOutBack),
    );

    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Show result badge
    _resultController.forward();

    // Haptic feedback
    await HapticFeedback.heavyImpact();

    // Wait before showing rewards
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      setState(() {
        _showReward = true;
      });

      // Show rewards
      _rewardController.forward();
      await HapticFeedback.mediumImpact();

      // Celebrate if won
      if (widget.playerWon) {
        await Future.delayed(const Duration(milliseconds: 500));
        await HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _resultController.dispose();
    _rewardController.dispose();
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
            colors: widget.playerWon
                ? [Colors.amber.shade50, Colors.orange.shade50]
                : [Colors.blue.shade50, Colors.indigo.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // RESULT BADGE
              Expanded(
                flex: 2,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Large emoji/icon
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.playerWon
                                  ? Colors.amber.shade400
                                  : Colors.blue.shade400,
                              boxShadow: [
                                BoxShadow(
                                  color: (widget.playerWon
                                          ? Colors.amber
                                          : Colors.blue)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.playerWon ? '🏆' : '💪',
                                style: const TextStyle(fontSize: 70),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Result text
                          Text(
                            widget.playerWon
                                ? 'VICTORY!'
                                : 'DEFEAT',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: widget.playerWon
                                  ? Colors.amber.shade700
                                  : Colors.blue.shade700,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Subtitle
                          Text(
                            widget.playerWon
                                ? "Race Completed!"
                                : "Keep Improving!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // REWARDS SECTION
              if (_showReward)
                SlideTransition(
                  position: _slideAnimation,
                  child: Expanded(
                    flex: 2,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Coins reward
                            _buildRewardCard(
                              icon: '💰',
                              label: 'Coins',
                              value: '+${widget.coinsEarned}',
                              color: Colors.yellow,
                            ),
                            const SizedBox(height: 12),

                            // XP reward
                            _buildRewardCard(
                              icon: '⭐',
                              label: 'Experience',
                              value: '+${widget.xpEarned} XP',
                              color: Colors.purple,
                            ),

                            // Chest reward (if won)
                            if (widget.playerWon && widget.chestEarned != null)
                              Column(
                                children: [
                                  const SizedBox(height: 12),
                                  _buildRewardCard(
                                    icon: '🎁',
                                    label: widget.chestEarned!.getName(),
                                    value: '+${widget.chestEarned!.reward} coins',
                                    color: _getChestColor(widget.chestEarned!),
                                  ),
                                ],
                              ),

                            // Stats preview
                            const SizedBox(height: 24),
                            _buildPlayerStatsPreview(),

                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  flex: 2,
                  child: Container(),
                ),

              // CONTINUE BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      widget.onContinue();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.playerWon
                          ? Colors.amber.shade400
                          : Colors.blue.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 8,
                      shadowColor: (widget.playerWon
                              ? Colors.amber
                              : Colors.blue)
                          .withValues(alpha: 0.5),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardCard({
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(width: 16),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Sparkle
          Icon(
            Icons.star,
            color: color.withValues(alpha: 0.6),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerStatsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Player Stats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Level ${widget.player.level}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Stat rows
          _statRow('Speed', widget.player.speed),
          const SizedBox(height: 8),
          _statRow('Climb', widget.player.climb),
          const SizedBox(height: 8),
          _statRow('Swim', widget.player.swim),
          const SizedBox(height: 12),

          // Total stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Power',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade700,
                  ),
                ),
                Text(
                  '${widget.player.totalPower}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$value',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Color _getChestColor(Chest chest) {
    switch (chest.type) {
      case ChestType.silver:
        return Colors.grey;
      case ChestType.gold:
        return Colors.amber;
      case ChestType.epic:
        return Colors.purple;
    }
  }
}
