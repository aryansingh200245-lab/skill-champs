import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chest.dart';

class ChestOpeningDialog extends StatefulWidget {
  final Chest chest;
  final VoidCallback onComplete;

  const ChestOpeningDialog({
    super.key,
    required this.chest,
    required this.onComplete,
  });

  @override
  State<ChestOpeningDialog> createState() => _ChestOpeningDialogState();
}

class _ChestOpeningDialogState extends State<ChestOpeningDialog>
    with TickerProviderStateMixin {
  late AnimationController _chestController;
  late AnimationController _explosionController;
  late AnimationController _coinController;
  late Animation<double> _chestRotation;
  late Animation<double> _chestScale;
  late Animation<double> _explosionScale;
  late Animation<double> _coinFloat;

  bool _isOpen = false;

  @override
  void initState() {
    super.initState();

    // Chest opening animation
    _chestController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _chestRotation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(parent: _chestController, curve: Curves.elasticInOut),
    );

    _chestScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _chestController, curve: Curves.easeOut),
    );

    // Explosion/sparkle animation
    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _explosionScale = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _explosionController, curve: Curves.easeOut),
    );

    // Coin float animation
    _coinController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _coinFloat = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _coinController, curve: Curves.easeOut),
    );

    _startAnimation();
  }

  Future<void> _startAnimation() async {
    // Open chest
    await _chestController.forward();
    await HapticFeedback.heavyImpact();

    if (mounted) {
      setState(() {
        _isOpen = true;
      });

      // Show explosion
      _explosionController.forward();
      await HapticFeedback.mediumImpact();

      // Float coins
      await Future.delayed(const Duration(milliseconds: 200));
      _coinController.forward();
      await HapticFeedback.lightImpact();

      // Wait for coin animation
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        // Close dialog
        Navigator.pop(context);
        widget.onComplete();
      }
    }
  }

  @override
  void dispose() {
    _chestController.dispose();
    _explosionController.dispose();
    _coinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Chest
          ScaleTransition(
            scale: _chestScale,
            child: RotationTransition(
              turns: _chestRotation,
              child: GestureDetector(
                child: Center(
                  child: _buildChestContent(),
                ),
              ),
            ),
          ),

          // Explosion effect
          if (_isOpen)
            ScaleTransition(
              scale: _explosionScale,
              child: SizedBox(
                width: 300,
                height: 300,
                child: _buildExplosion(),
              ),
            ),

          // Floating coins
          if (_isOpen)
            ScaleTransition(
              scale: _coinFloat,
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: _buildFloatingCoins(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChestContent() {
    return Container(
      width: 200,
      height: 160,
      decoration: BoxDecoration(
        color: _getChestBackgroundColor(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getChestColor().withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(
          color: _getChestColor(),
          width: 3,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _isOpen ? '✨ OPEN!' : '📦',
            style: TextStyle(
              fontSize: _isOpen ? 60 : 80,
              color: _getChestColor(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.chest.getName(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getChestColor(),
              letterSpacing: 1,
            ),
          ),
          if (!_isOpen) ...[
            const SizedBox(height: 12),
            Text(
              'Click to Open',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplosion() {
    return Stack(
      alignment: Alignment.center,
      children: List.generate(12, (index) {
        final offsetX = 100 * (index % 2 == 0 ? 1 : -1);
        final offsetY = 100 * (index % 3 == 0 ? 1 : -1);

        return Positioned(
          left: 150 + offsetX * _explosionScale.value,
          top: 150 + offsetY * _explosionScale.value,
          child: Opacity(
            opacity: 1 - _explosionScale.value,
            child: Text(
              ['✨', '⭐', '💫', '🌟'][index % 4],
              style: const TextStyle(fontSize: 24),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFloatingCoins() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
          '+${widget.chest.reward} Coins!',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.amber.shade600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -30 * (1 - _coinFloat.value)),
                child: Opacity(
                  opacity: _coinFloat.value,
                  child: const Text(
                    '💰',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getChestColor() {
    switch (widget.chest.type) {
      case ChestType.silver:
        return Colors.grey.shade400;
      case ChestType.gold:
        return Colors.amber.shade600;
      case ChestType.epic:
        return Colors.purple.shade600;
    }
  }

  Color _getChestBackgroundColor() {
    switch (widget.chest.type) {
      case ChestType.silver:
        return Colors.grey.shade100;
      case ChestType.gold:
        return Colors.amber.shade50;
      case ChestType.epic:
        return Colors.purple.shade50;
    }
  }
}
