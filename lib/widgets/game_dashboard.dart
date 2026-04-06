import 'package:flutter/material.dart';
import '../models/player.dart';

class GameDashboard extends StatelessWidget {
  final Player player;

  const GameDashboard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade600,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Level ${player.level} Player',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade300,
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '👑',
                  style: TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bars
          Column(
            children: [
              _buildProgressRow(
                label: 'XP Progress',
                current: player.xp,
                max: player.maxXp,
                color: Colors.amber,
              ),
              const SizedBox(height: 8),
              _buildProgressRow(
                label: 'Total Power',
                current: player.totalPower,
                max: 100,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats grid
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatBox('Wins', '${player.wins}', Colors.green.shade400),
              _buildStatBox(
                'Win Rate',
                '${(player.winRate * 100).toStringAsFixed(0)}%',
                Colors.blue.shade400,
              ),
              _buildStatBox(
                'Matches',
                '${player.totalMatches}',
                Colors.orange.shade400,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressRow({
    required String label,
    required int current,
    required int max,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: current / max,
            minHeight: 8,
            backgroundColor: Colors.black.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$current / $max',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
