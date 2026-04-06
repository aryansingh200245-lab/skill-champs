import 'package:flutter/material.dart';
import '../models/powerup.dart';
import 'home_screen.dart';

class PowerUpScreen extends StatefulWidget {
  const PowerUpScreen({super.key});

  @override
  State<PowerUpScreen> createState() => _PowerUpScreenState();
}

class _PowerUpScreenState extends State<PowerUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final List<PowerUp> powers = [
    PowerUp(
      id: 'speed_shoes',
      name: "Speed Shoes",
      type: "speed",
      value: 5,
      rarity: PowerUpRarity.common,
    ),
    PowerUp(
      id: 'climb_gloves',
      name: "Climb Gloves",
      type: "climb",
      value: 5,
      rarity: PowerUpRarity.common,
    ),
    PowerUp(
      id: 'swim_fins',
      name: "Swim Fins",
      type: "swim",
      value: 5,
      rarity: PowerUpRarity.common,
    ),
  ];

  String getDescription(String type) {
    switch (type) {
      case "speed":
        return "Boost your running shoes! +5 speed bonus.";
      case "climb":
        return "Enhanced climbing gear! +5 climbing bonus.";
      case "swim":
        return "Pro swimming fins! +5 swimming bonus.";
      default:
        return "Special boost!";
    }
  }

  Color getColor(String type) {
    switch (type) {
      case "speed":
        return Colors.orange;
      case "climb":
        return Colors.green;
      case "swim":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _selectPowerUp(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Delay navigation to show animation
    Future.delayed(const Duration(milliseconds: 300), () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(powerUp: powers[index]),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade700, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🎮 HEADER
              Padding(
                padding: const EdgeInsets.all(20),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -1),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "⚡ Choose Your Weapon",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Pick a power-up to boost your next race!",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              // 🎯 POWER-UP CARDS
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: powers.length,
                  itemBuilder: (context, index) {
                    final power = powers[index];
                    final isSelected = _selectedIndex == index;
                    final delay = index * 100;

                    return SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            delay / 800,
                            (delay + 300) / 800,
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () => _selectPowerUp(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                getColor(power.type),
                                getColor(power.type).withValues(alpha: 0.6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: getColor(power.type)
                                    .withValues(alpha: isSelected ? 0.8 : 0.4),
                                blurRadius: isSelected ? 20 : 12,
                                spreadRadius: isSelected ? 2 : 0,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Emoji Icon
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                  child: Center(
                                    child: Text(
                                      power.emoji,
                                      style: const TextStyle(fontSize: 44),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              power.name,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              power.rarityText,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        getDescription(power.type),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "+${power.value} to ${power.type.toUpperCase()} stat",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Checkmark
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ℹ️ FOOTER INFO
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Pick wisely! Your choice will affect the entire race outcome.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
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