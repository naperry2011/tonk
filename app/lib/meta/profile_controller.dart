import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/engine.dart';
import 'profile.dart';
import 'progression.dart';

/// What a finished round earned, for the round-end panel.
class RoundRewards {
  const RoundRewards({
    required this.xp,
    required this.breakdown,
    required this.oldLevel,
    required this.newLevel,
    required this.unlocks,
    required this.achievements,
    required this.bonusChips,
  });

  final int xp;
  final List<({String label, int xp})> breakdown;
  final int oldLevel;
  final int newLevel;
  final List<Unlock> unlocks;
  final List<Achievement> achievements;

  /// Extra bankroll chips (daily challenge win).
  final int bonusChips;

  bool get leveledUp => newLevel > oldLevel;
}

/// Owns the player's [Profile]: XP, bankroll, stats, streaks, achievements.
class ProfileController extends ChangeNotifier {
  ProfileController({
    SharedPreferencesAsync? prefs,
    bool persist = true,
    DateTime Function()? clock,
  }) : _prefs = persist ? (prefs ?? SharedPreferencesAsync()) : null,
       _clock = clock ?? DateTime.now;

  static const String key = 'tonk_profile';
  static const int buyInAmount = 1000;
  static const int dailyBonus = 300;
  static const int dailyWinChips = 300;

  final SharedPreferencesAsync? _prefs;
  final DateTime Function() _clock;

  Profile profile = Profile();

  int get level => levelForXp(profile.xp);
  int get bankroll => profile.bankroll;

  /// Progress through the current level, 0..1.
  double get levelProgress {
    final start = xpForLevel(level);
    final end = xpForLevel(level + 1);
    return ((profile.xp - start) / (end - start)).clamp(0.0, 1.0);
  }

  int get xpToNextLevel => xpForLevel(level + 1) - profile.xp;

  String get today => dayKey(_clock());

  bool unlocked(UnlockKind kind, String id) => isUnlocked(kind, id, level);

  Future<void> load() async {
    final raw = await _prefs?.getString(key);
    if (raw == null) return;
    try {
      profile = Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      notifyListeners();
    } on FormatException {
      // Corrupt profile: keep defaults rather than crash.
    }
  }

  void _save() {
    notifyListeners();
    _prefs?.setString(key, jsonEncode(profile.toJson()));
  }

  // ---------------------------------------------------------------------
  // Chips
  // ---------------------------------------------------------------------

  bool get canBuyIn => profile.bankroll >= buyInAmount;

  /// Takes the buy-in from the bankroll. Returns false if short.
  bool buyIn() {
    if (!canBuyIn) return false;
    profile.bankroll -= buyInAmount;
    _save();
    return true;
  }

  /// Returns a finished match's chips to the bankroll.
  void cashOut(int chips) {
    profile.bankroll += chips;
    _save();
  }

  /// Broke players are topped back up to one buy-in so nobody is locked out.
  void refill() {
    if (canBuyIn) return;
    profile
      ..bankroll = buyInAmount
      ..refills += 1;
    _save();
  }

  bool get bonusAvailable => profile.lastBonusDay != today;

  /// Free chips once per day. Returns the amount, or 0 if already claimed.
  int claimDailyBonus() {
    if (!bonusAvailable) return 0;
    profile
      ..bankroll += dailyBonus
      ..lastBonusDay = today;
    _save();
    return dailyBonus;
  }

  // ---------------------------------------------------------------------
  // Daily challenge
  // ---------------------------------------------------------------------

  bool get dailyPlayedToday => profile.lastDailyDay == today;

  /// Streak still alive if the last daily was today or yesterday.
  int get currentDailyStreak {
    final last = profile.lastDailyDay;
    if (last == null) return 0;
    final yesterday = dayKey(_clock().subtract(const Duration(days: 1)));
    return last == today || last == yesterday ? profile.dailyStreak : 0;
  }

  // ---------------------------------------------------------------------
  // Rounds
  // ---------------------------------------------------------------------

  RoundRewards applyRound(RoundFacts f) {
    final p = profile;
    final s = p.stats;
    final oldLevel = level;
    final before = {...p.achievements};

    s.roundsPlayed++;
    s.spreadsLaid += f.spreadsLaid;
    if (f.humanFolded) s.folds++;
    if (f.won) {
      s.roundsWon++;
      s.winStreak++;
      if (s.winStreak > s.bestWinStreak) s.bestWinStreak = s.winStreak;
      if (f.potWon > s.biggestPot) s.biggestPot = f.potWon;
      if (f.condition == WinCondition.tonk) s.tonks++;
      if (f.condition == WinCondition.knock && f.humanKnocked) s.knockWins++;
      if (f.condition == WinCondition.caught) s.catches++;
    } else {
      s.winStreak = 0;
      if (f.condition == WinCondition.caught && f.humanKnocked) {
        s.timesCaught++;
      }
    }
    if (f.matchEnded) s.matchesPlayed++;
    if (f.matchWon) s.matchesWon++;

    var bonusChips = 0;
    if (f.isDaily) {
      final yesterday = dayKey(_clock().subtract(const Duration(days: 1)));
      p.dailyStreak = p.lastDailyDay == yesterday ? p.dailyStreak + 1 : 1;
      p
        ..lastDailyDay = today
        ..lastDailyWon = f.won;
      if (f.won) {
        bonusChips = dailyWinChips;
        p.bankroll += bonusChips;
      }
    }

    final breakdown = xpBreakdown(f);
    final gained = breakdown.fold(0, (sum, e) => sum + e.xp);
    p.xp += gained;

    for (final a in achievements) {
      if (a.earned(p)) p.achievements.add(a.id);
    }
    _save();

    return RoundRewards(
      xp: gained,
      breakdown: breakdown,
      oldLevel: oldLevel,
      newLevel: level,
      unlocks: unlocksBetween(oldLevel, level),
      achievements: [
        for (final a in achievements)
          if (p.achievements.contains(a.id) && !before.contains(a.id)) a,
      ],
      bonusChips: bonusChips,
    );
  }
}
