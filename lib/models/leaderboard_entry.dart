class LeaderboardEntry {
  final String guestId;
  final String playerName;
  final int score;

  const LeaderboardEntry({
    required this.guestId,
    required this.playerName,
    required this.score,
  });

  factory LeaderboardEntry.fromMap(String id, Map<String, dynamic> data) {
    return LeaderboardEntry(
      guestId: id,
      playerName: (data['playerName'] as String?)?.trim().isNotEmpty == true
          ? data['playerName'] as String
          : 'Jungle Hopper',
      score: (data['score'] as num?)?.toInt() ?? 0,
    );
  }
}
