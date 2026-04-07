import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SkillBar extends StatefulWidget {
  final String skillName;
  final int level;
  final int maxLevel;
  final Color color;
  final VoidCallback onUpgrade;
  final bool canUpgrade;
  final int upgradeCost;

  const SkillBar({
    super.key,
    required this.skillName,
    required this.level,
    this.maxLevel = 30,
    required this.color,
    required this.onUpgrade,
    required this.canUpgrade,
    this.upgradeCost = 20,
  });

  @override
  State<SkillBar> createState() => _SkillBarState();
}

class _SkillBarState extends State<SkillBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _justUpgraded = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _handleUpgrade() {
    HapticFeedback.mediumImpact();
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
    
    setState(() => _justUpgraded = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _justUpgraded = false);
      }
    });

    widget.onUpgrade();
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.level / widget.maxLevel;
    bool isMaxLevel = widget.level >= widget.maxLevel;

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.02).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _justUpgraded
                ? [widget.color.withValues(alpha: 0.15), widget.color.withValues(alpha: 0.08)]
                : [Colors.white, Colors.grey.shade50],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _justUpgraded 
                ? widget.color.withValues(alpha: 0.6)
                : Colors.grey.shade200,
            width: _justUpgraded ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _justUpgraded 
                  ? widget.color.withValues(alpha: 0.3)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: _justUpgraded ? 12 : 4,
              spreadRadius: _justUpgraded ? 2 : 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Skill name and level badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.skillName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: widget.color.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        "${widget.level}/${widget.maxLevel}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: widget.color,
                        ),
                      ),
                    ),
                    if (_justUpgraded)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          "✨ +1",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Progress bar section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar with animation
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom row: Cost info and upgrade button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isMaxLevel)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "🏅 Max Level",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      )
                    else
                      Text(
                        "💰 Cost: ${widget.upgradeCost} coins",
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.canUpgrade 
                              ? Colors.green.shade600
                              : Colors.red.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    SizedBox(
                      height: 32,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMaxLevel
                              ? Colors.grey
                              : widget.canUpgrade
                                  ? widget.color
                                  : Colors.grey.shade300,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: widget.canUpgrade && !isMaxLevel ? 2 : 0,
                        ),
                        onPressed: (widget.canUpgrade && !isMaxLevel)
                            ? _handleUpgrade
                            : null,
                        child: Text(
                          isMaxLevel ? "Maxed" : "Upgrade",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
