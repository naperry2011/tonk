/// Lifetime stats for the human player.
class Stats {
  int roundsPlayed = 0;
  int roundsWon = 0;
  int tonks = 0;
  int knockWins = 0;
  int catches = 0;
  int timesCaught = 0;
  int folds = 0;
  int matchesPlayed = 0;
  int matchesWon = 0;
  int winStreak = 0;
  int bestWinStreak = 0;
  int spreadsLaid = 0;
  int biggestPot = 0;

  Map<String, int> toJson() => {
    'roundsPlayed': roundsPlayed,
    'roundsWon': roundsWon,
    'tonks': tonks,
    'knockWins': knockWins,
    'catches': catches,
    'timesCaught': timesCaught,
    'folds': folds,
    'matchesPlayed': matchesPlayed,
    'matchesWon': matchesWon,
    'winStreak': winStreak,
    'bestWinStreak': bestWinStreak,
    'spreadsLaid': spreadsLaid,
    'biggestPot': biggestPot,
  };

  static Stats fromJson(Map<String, dynamic> json) {
    int v(String key) => json[key] as int? ?? 0;
    return Stats()
      ..roundsPlayed = v('roundsPlayed')
      ..roundsWon = v('roundsWon')
      ..tonks = v('tonks')
      ..knockWins = v('knockWins')
      ..catches = v('catches')
      ..timesCaught = v('timesCaught')
      ..folds = v('folds')
      ..matchesPlayed = v('matchesPlayed')
      ..matchesWon = v('matchesWon')
      ..winStreak = v('winStreak')
      ..bestWinStreak = v('bestWinStreak')
      ..spreadsLaid = v('spreadsLaid')
      ..biggestPot = v('biggestPot');
  }
}

/// Everything that persists about the player between matches.
class Profile {
  Profile({this.xp = 0, this.bankroll = startingBankroll, Stats? stats})
    : stats = stats ?? Stats();

  static const int startingBankroll = 2500;

  int xp;

  /// Chips carried between matches. Play money only; never sold.
  int bankroll;
  Stats stats;
  Set<String> achievements = {};

  /// Day keys (yyyy-mm-dd, local time).
  String? lastBonusDay;
  String? lastDailyDay;
  bool lastDailyWon = false;
  int dailyStreak = 0;
  int refills = 0;

  Map<String, dynamic> toJson() => {
    'version': 1,
    'xp': xp,
    'bankroll': bankroll,
    'stats': stats.toJson(),
    'achievements': achievements.toList(),
    'lastBonusDay': lastBonusDay,
    'lastDailyDay': lastDailyDay,
    'lastDailyWon': lastDailyWon,
    'dailyStreak': dailyStreak,
    'refills': refills,
  };

  static Profile fromJson(Map<String, dynamic> json) =>
      Profile(
          xp: json['xp'] as int? ?? 0,
          bankroll: json['bankroll'] as int? ?? startingBankroll,
          stats: Stats.fromJson(json['stats'] as Map<String, dynamic>? ?? {}),
        )
        ..achievements = (json['achievements'] as List? ?? const [])
            .cast<String>()
            .toSet()
        ..lastBonusDay = json['lastBonusDay'] as String?
        ..lastDailyDay = json['lastDailyDay'] as String?
        ..lastDailyWon = json['lastDailyWon'] as bool? ?? false
        ..dailyStreak = json['dailyStreak'] as int? ?? 0
        ..refills = json['refills'] as int? ?? 0;
}

/// Local calendar day as yyyy-mm-dd.
String dayKey(DateTime t) =>
    '${t.year.toString().padLeft(4, '0')}-'
    '${t.month.toString().padLeft(2, '0')}-'
    '${t.day.toString().padLeft(2, '0')}';

/// Seed for a day key (yyyy-mm-dd): the daily deal is the same for everyone.
int dailySeed(String day) => int.parse(day.replaceAll('-', ''));
