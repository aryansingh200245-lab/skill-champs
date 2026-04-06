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
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  List<Color> _getChestColors(ChestType type) {
    switch (type) {
      case ChestType.silver:
        return [Colors.grey.shade300, Colors.grey.shade700];
      case ChestType.gold:
        return [Colors.amber.shade300, Colors.amber.shade700];
      case ChestType.epic:
        return [Colors.purple.shade300, Colors.purple.shade700];
    }
  }

  void _handleOpen() {
    _scaleController.forward().then((_) {
      widget.onOpen();
      _scaleController.reverse();
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = widget.chest.isReady();
    final isOpened = widget.chest.isOpened;
    final remainingTime =
        widget.chest.unlockTime.difference(DateTime.now()).inSeconds;

    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
      ),
      child: Card(
        elevation: 6,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getChestColors(widget.chest.type),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Chest Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: Center(
                    child: Text(
                      isOpened ? "✅" : "📦",
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Chest Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chest.getName(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isOpened)
                        const Text(
                          "🎉 Opened! +coins collected",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        )
                      else if (isReady)
                        const Text(
                          "✨ Ready to open!",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          "⏳ $remainingTime seconds",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),

                // Open Button
                SizedBox(
                  height: 45,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReady && !isOpened
                          ? Colors.white
                          : Colors.grey.shade400,
                      foregroundColor: isReady && !isOpened
                          ? Colors.green.shade700
                          : Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isReady && !isOpened
                        ? _handleOpen
                        : null,
                    icon: const Icon(Icons.card_giftcard, size: 16),
                    label: Text(
                      isOpened ? "Opened" : "Open",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
