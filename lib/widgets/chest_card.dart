import 'package:flutter/material.dart';
import '../models/chest.dart';

class ChestCard extends StatefulWidget {
  final Chest chest;
  final VoidCallback onOpen;
  final bool canOpen;

  const ChestCard({
    super.key,
    required this.chest,
    required this.onOpen,
    required this.canOpen,
  });

  @override
  State<ChestCard> createState() => _ChestCardState();
}

class _ChestCardState extends State<ChestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  String _getChestEmoji(ChestType type) {
    switch (type) {
      case ChestType.silver:
        return "🏶";
      case ChestType.gold:
        return "🏆";
      case ChestType.epic:
        return "💎";
    }
  }

  List<Color> _getChestColors(ChestType type) {
    switch (type) {
      case ChestType.silver:
        return [Colors.grey.shade400, Colors.grey.shade700];
      case ChestType.gold:
        return [Colors.amber.shade300, Colors.amber.shade700];
      case ChestType.epic:
        return [Colors.purple.shade300, Colors.purple.shade700];
    }
  }

  Color _getRarityColor(ChestType type) {
    switch (type) {
      case ChestType.silver:
        return Colors.grey.shade600;
      case ChestType.gold:
        return Colors.amber.shade600;
      case ChestType.epic:
        return Colors.purple.shade600;
    }
  }

  void _handleOpen() {
    _animationController.forward().then((_) {
      widget.onOpen();
      _showRewardPopup();
      _animationController.reverse();
    });
  }

  void _showRewardPopup() {
    showDialog(
      context: context,
      builder: (context) => RewardPopup(
        reward: widget.chest.reward,
        chestType: widget.chest.type,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = widget.chest.isReady();
    final isOpened = widget.chest.isOpened;
    final remainingTime =
        widget.chest.unlockTime.difference(DateTime.now()).inSeconds;

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.06).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _getChestColors(widget.chest.type),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _getRarityColor(widget.chest.type).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Animated Chest Icon
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.15).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.elasticOut,
                    ),
                  ),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isOpened
                            ? "✅"
                            : _getChestEmoji(widget.chest.type),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Chest Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.chest.getName(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "+${widget.chest.reward} 🪙",
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Status Text
                      if (isOpened)
                        const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Opened & Collected!",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      else if (isReady)
                        const Row(
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amberAccent,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Ready to open!",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "⏳ $remainingTime sec",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Open Button
                SizedBox(
                  height: 48,
                  width: 100,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReady && !isOpened
                          ? Colors.white
                          : Colors.grey.shade300,
                      foregroundColor: isReady && !isOpened
                          ? Colors.blue.shade600
                          : Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: isReady && !isOpened ? 4 : 0,
                    ),
                    onPressed: isReady && !isOpened
                        ? _handleOpen
                        : null,
                    child: Text(
                      isOpened ? "✓ Opened" : "Open",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🎁 Reward Popup Widget
class RewardPopup extends StatefulWidget {
  final int reward;
  final ChestType chestType;

  const RewardPopup({
    super.key,
    required this.reward,
    required this.chestType,
  });

  @override
  State<RewardPopup> createState() => _RewardPopupState();
}

class _RewardPopupState extends State<RewardPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getChestRarity() {
    switch (widget.chestType) {
      case ChestType.silver:
        return "Silver";
      case ChestType.gold:
        return "Gold";
      case ChestType.epic:
        return "Epic";
    }
  }

  Color _getRarityColor() {
    switch (widget.chestType) {
      case ChestType.silver:
        return Colors.grey.shade600;
      case ChestType.gold:
        return Colors.amber.shade600;
      case ChestType.epic:
        return Colors.purple.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.5, end: 1.0).animate(
        CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
      ),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration Title
              Text(
                "🎉 Chest Opened!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade900,
                ),
              ),
              const SizedBox(height: 16),

              // Reward Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getRarityColor().withValues(alpha: 0.2),
                      _getRarityColor().withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getRarityColor().withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _getChestRarity(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getRarityColor(),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "+${widget.reward}",
                          style: const TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "🪙",
                          style: TextStyle(fontSize: 40),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Awesome!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
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
}
