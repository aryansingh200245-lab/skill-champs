class LeaderboardEntry {
  final int rank;
  final String playerName;
  final int score;
  final int level;
  final int wins;
  final String avatar;

  LeaderboardEntry({
    required this.rank,
    required this.playerName,
    required this.score,
    required this.level,
    required this.wins,
    required this.avatar,
  });
}

class LeaderboardService {
  // Mock data - ready for Firebase integration
  static List<LeaderboardEntry> getGlobalLeaderboard() {
    return [
      LeaderboardEntry(
        rank: 1,
        playerName: 'SkyWalker99',
        score: 45230,
        level: 42,
        wins: 156,
        avatar: '👑',
      ),
      LeaderboardEntry(
        rank: 2,
        playerName: 'LunaQuest',
        score: 43120,
        level: 40,
        wins: 148,
        avatar: '🌙',
      ),
      LeaderboardEntry(
        rank: 3,
        playerName: 'PhoenixRise',
        score: 41500,
        level: 39,
        wins: 142,
        avatar: '🔥',
      ),
      LeaderboardEntry(
        rank: 4,
        playerName: 'StormChaser',
        score: 39800,
        level: 38,
        wins: 135,
        avatar: '⚡',
      ),
      LeaderboardEntry(
        rank: 5,
        playerName: 'SilentNinja',
        score: 38200,
        level: 37,
        wins: 130,
        avatar: '🥷',
      ),
    ];
  }

  static List<LeaderboardEntry> getFriendsLeaderboard() {
    return [
      LeaderboardEntry(
        rank: 1,
        playerName: 'You',
        score: 12450,
        level: 15,
        wins: 48,
        avatar: '🏆',
      ),
      LeaderboardEntry(
        rank: 2,
        playerName: 'John',
        score: 11200,
        level: 14,
        wins: 42,
        avatar: '😎',
      ),
      LeaderboardEntry(
        rank: 3,
        playerName: 'Sarah',
        score: 10800,
        level: 14,
        wins: 40,
        avatar: '✨',
      ),
    ];
  }

  static List<LeaderboardEntry> getWeeklyLeaderboard() {
    return [
      LeaderboardEntry(
        rank: 1,
        playerName: 'GrindMaster',
        score: 5420,
        level: 20,
        wins: 35,
        avatar: '💪',
      ),
      LeaderboardEntry(
        rank: 2,
        playerName: 'FastRunner',
        score: 5120,
        level: 19,
        wins: 32,
        avatar: '🏃',
      ),
      LeaderboardEntry(
        rank: 3,
        playerName: 'WinStreak',
        score: 4980,
        level: 19,
        wins: 31,
        avatar: '🎯',
      ),
    ];
  }
}
