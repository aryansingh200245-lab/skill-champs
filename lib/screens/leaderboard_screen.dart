import 'package:flutter/material.dart';
import '../models/leaderboard.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String selectedTab = 'Global';
  List<LeaderboardEntry> leaderboardData = [];

  @override
  void initState() {
    super.initState();
    _updateLeaderboard();
  }

  void _updateLeaderboard() {
    if (selectedTab == 'Global') {
      leaderboardData = LeaderboardService.getGlobalLeaderboard();
    } else if (selectedTab == 'Friends') {
      leaderboardData = LeaderboardService.getFriendsLeaderboard();
    } else if (selectedTab == 'Weekly') {
      leaderboardData = LeaderboardService.getWeeklyLeaderboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.purple.shade700,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade50, Colors.blue.shade50],
          ),
        ),
        child: Column(
          children: [
            // TAB SELECTOR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildTabButton('Global'),
                    _buildTabButton('Friends'),
                    _buildTabButton('Weekly'),
                  ],
                ),
              ),
            ),

            // LEADERBOARD LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: leaderboardData.length,
                itemBuilder: (context, index) {
                  final entry = leaderboardData[index];
                  bool isTopThree = entry.rank <= 3;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLeaderboardCard(entry, isTopThree),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String tabName) {
    bool isSelected = selectedTab == tabName;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedTab = tabName;
            _updateLeaderboard();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purple.shade600 : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              tabName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntry entry, bool isTopThree) {
    Color rankColor = Colors.grey;
    String rankEmoji = '${entry.rank}️⃣';

    if (entry.rank == 1) {
      rankColor = Colors.amber;
      rankEmoji = '🥇';
    } else if (entry.rank == 2) {
      rankColor = Colors.grey.shade400;
      rankEmoji = '🥈';
    } else if (entry.rank == 3) {
      rankColor = Colors.orange.shade700;
      rankEmoji = '🥉';
    }

    return Card(
      elevation: isTopThree ? 8 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isTopThree
                ? [rankColor.withValues(alpha: 0.3), rankColor.withValues(alpha: 0.1)]
                : [Colors.blue.shade300, Colors.blue.shade500],
          ),
          borderRadius: BorderRadius.circular(16),
          border: isTopThree
              ? Border.all(color: rankColor, width: 2)
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Rank Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor.withValues(alpha: 0.3),
              ),
              child: Center(
                child: Text(
                  rankEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Player Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        entry.avatar,
                        style: const TextStyle(fontSize: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.playerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatChip('⭐ ${entry.level}', Colors.amber),
                      const SizedBox(width: 8),
                      _buildStatChip('🏆 ${entry.wins}W', Colors.green),
                    ],
                  ),
                ],
              ),
            ),

            // Score
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Score',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.score.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: rankColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
