import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../models/powerup.dart';
import '../models/chest.dart';
import '../widgets/skill_bar.dart';
import '../widgets/chest_card.dart';
import '../widgets/game_dashboard.dart';
import '../widgets/game_button.dart';
import '../widgets/chest_opening_dialog.dart';
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
      fly: 7,
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

    // Show opening dialog with animation
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ChestOpeningDialog(
          chest: chest,
          onComplete: () {
            // Update player coins and mark chest as opened
            setState(() {
              chest.isOpened = true;
              player.coins += chest.reward;
            });
          },
        ),
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
            "🏆 Skill Champs",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
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
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // 👤 GAME DASHBOARD
                  GameDashboard(player: player),

                  const SizedBox(height: 20),

                  // ⚡ ACTIVE POWER-UP CARD
                  if (widget.powerUp != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.amber.shade300,
                            Colors.amber.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade700.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Text(
                            "⚡",
                            style: TextStyle(fontSize: 36),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.powerUp!.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Active in next race • +${widget.powerUp!.value} boost",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),

                  // 🎯 SKILLS SECTION
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          "⚙️ Your Skills",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                      const SizedBox(height: 10),
                      SkillBar(
                        skillName: "⛰️ Climb",
                        level: player.climb,
                        color: Colors.green.shade500,
                        onUpgrade: () => setState(() {
                          player.upgradeClimb();
                        }),
                        canUpgrade: player.coins >= 20,
                      ),
                      const SizedBox(height: 10),
                      SkillBar(
                        skillName: "🏊 Swim",
                        level: player.swim,
                        color: Colors.blue.shade500,
                        onUpgrade: () => setState(() {
                          player.upgradeSwim();
                        }),
                        canUpgrade: player.coins >= 20,
                      ),
                      const SizedBox(height: 10),
                      SkillBar(
                        skillName: "✈️ Fly",
                        level: player.fly,
                        color: Colors.purple.shade500,
                        onUpgrade: () => setState(() {
                          player.upgradeFly();
                        }),
                        canUpgrade: player.coins >= 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 🎮 START MATCH BUTTON
                  GameButton(
                    label: "Start Match",
                    emoji: "🎮",
                    onPressed: isMatchRunning ? () {} : _startMatch,
                    color: Colors.green.shade500,
                    enabled: !isMatchRunning,
                    height: 56,
                  ),

                  const SizedBox(height: 16),

                  // 📢 RESULT MESSAGE
                  if (resultMessage.isNotEmpty)
                    ScaleTransition(
                      scale: AlwaysStoppedAnimation(1.0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: resultMessage.contains("Victory")
                                ? [Colors.green.shade400, Colors.green.shade600]
                                : [Colors.red.shade400, Colors.red.shade600],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            resultMessage,
                            style: const TextStyle(
                              fontSize: 16,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            "🎁 Your Treasure Chests",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "🎁",
                              style: TextStyle(fontSize: 40),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "No chests yet!",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Win matches to earn treasure chests",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
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
}
