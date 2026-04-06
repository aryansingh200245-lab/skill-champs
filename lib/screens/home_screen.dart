import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/powerup.dart';
import '../models/chest.dart';
import '../widgets/skill_bar.dart';
import '../widgets/chest_card.dart';
import 'race_screen.dart';

class HomeScreen extends StatefulWidget {
  final PowerUp? powerUp;

  const HomeScreen({super.key, this.powerUp});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Player player;
  List<Chest> chests = [];
  String resultMessage = "";
  bool isMatchRunning = false;

  @override
  void initState() {
    super.initState();
    player = Player(
      name: "Champion",
      speed: 10,
      climb: 8,
      swim: 6,
      coins: 50,
      level: 1,
    );
  }

  void _startMatch() async {
    if (isMatchRunning) return;

    setState(() {
      isMatchRunning = true;
      resultMessage = "";
    });

    PowerUp power =
        widget.powerUp ?? PowerUp(id: 'none', name: "None", type: "none", value: 0);

    // Navigate to Race Screen
    final result = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (context) => RaceScreen(
          player: player,
          powerUp: power,
          onRaceComplete: (winnerIndex) {
            Navigator.pop(context, winnerIndex);
          },
        ),
      ),
    );

    if (result != null) {
      // Process race result
      int winner = result;

      if (winner == 0) {
        // Player won
        player.coins += 30;
        player.addXp(50);

        if (chests.length < 3) {
          chests.add(generateChest());
        }

        setState(() {
          resultMessage = "🏆 Victory! +30 coins, +50 XP!";
        });

        await HapticFeedback.lightImpact();
      } else {
        // Player lost
        player.addXp(10);
        setState(() {
          resultMessage = "❌ Defeat! +10 XP! Better luck next time!";
        });

        await HapticFeedback.mediumImpact();
      }

      setState(() {
        isMatchRunning = false;
      });

      // Show result for 3 seconds then clear
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          resultMessage = "";
        });
      }
    }
  }

  void _openChest(int index) async {
    Chest chest = chests[index];

    if (chest.isOpened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ This chest is already opened!")),
      );
      return;
    }

    if (!chest.isReady()) {
      final remainingTime = chest.unlockTime
          .difference(DateTime.now())
          .inSeconds;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("⏳ Unlock in ${remainingTime}s"),
        ),
      );
      return;
    }

    setState(() {
      chest.isOpened = true;
      player.coins += chest.reward;
    });

    await HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("🎁 +${chest.reward} coins!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Skill Champs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
          backgroundColor: Colors.purple.shade700,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.purple.shade50, Colors.blue.shade50],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 👤 PLAYER PROFILE CARD
                  Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.purple.shade400,
                            Colors.purple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                            ),
                            child: const Center(
                              child: Text("🏆", style: TextStyle(fontSize: 48)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "Level ${player.level}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // XP Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Experience",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    "${player.xp}/${player.maxXp}",
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: player.xp / player.maxXp,
                                  minHeight: 8,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatBubble(
                                "💰",
                                "${player.coins}",
                                "Coins",
                              ),
                              _buildStatBubble(
                                "🔥",
                                "${player.totalPower}",
                                "Power",
                              ),
                              _buildStatBubble(
                                "⭐",
                                "${player.level * 10}",
                                "Score",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ⚡ ACTIVE POWER-UP
                  if (widget.powerUp != null)
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.amber.shade300,
                              Colors.amber.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.flash_on,
                              color: Colors.white,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.powerUp!.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "+${widget.powerUp!.value} boost active",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 🎯 SKILLS SECTION
                  const Text(
                    "Your Skills",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SkillBar(
                    skillName: "🏃 Speed",
                    level: player.speed,
                    color: Colors.orange.shade500,
                    onUpgrade: () => setState(() {
                      player.upgradeSpeed();
                    }),
                    canUpgrade: player.coins >= 20,
                  ),
                  const SizedBox(height: 12),
                  SkillBar(
                    skillName: "⛰️ Climb",
                    level: player.climb,
                    color: Colors.green.shade500,
                    onUpgrade: () => setState(() {
                      player.upgradeClimb();
                    }),
                    canUpgrade: player.coins >= 20,
                  ),
                  const SizedBox(height: 12),
                  SkillBar(
                    skillName: "🏊 Swim",
                    level: player.swim,
                    color: Colors.blue.shade500,
                    onUpgrade: () => setState(() {
                      player.upgradeSwim();
                    }),
                    canUpgrade: player.coins >= 20,
                  ),

                  const SizedBox(height: 24),

                  // 🎮 START MATCH BUTTON
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.shade700.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isMatchRunning ? null : _startMatch,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Text(
                            isMatchRunning ? "⏳ Running..." : "🎮 Start Match",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 📢 RESULT MESSAGE
                  if (resultMessage.isNotEmpty)
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade300,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            resultMessage,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // 📦 TREASURE CHESTS SECTION
                  if (chests.isNotEmpty)
                    Column(
                      children: [
                        const Text(
                          "🎁 Your Treasure Chests",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(chests.length, (index) {
                          return ChestCard(
                            chest: chests[index],
                            onOpen: () => _openChest(index),
                            canOpen: chests[index].isReady() &&
                                !chests[index].isOpened,
                          );
                        }),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            "🎁 No chests yet!",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Win matches to earn chests",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBubble(String emoji, String value, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
