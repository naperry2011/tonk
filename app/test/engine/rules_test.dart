import 'package:flutter_test/flutter_test.dart';
import 'package:tonk/engine/engine.dart';

Player playerWithPoints(String name, List<String> ranks) =>
    Player(name)..addCards(ranks.map((r) => Card(Suit.hearts, r)));

void main() {
  test('hasInitialTonk is true only for 49 and 50 points', () {
    expect(hasInitialTonk(48), isFalse);
    expect(hasInitialTonk(49), isTrue);
    expect(hasInitialTonk(50), isTrue);
    expect(hasInitialTonk(51), isFalse);
  });

  test('canKnock allows knocking at any point total (no threshold)', () {
    expect(canKnock(0), isTrue);
    expect(canKnock(50), isTrue);
  });

  group('determineKnockWinner', () {
    test('picks the player with the lowest hand points', () {
      final low = playerWithPoints('Low', ['A', '2']);
      final high = playerWithPoints('High', ['K', 'Q']);
      expect(determineKnockWinner([high, low]), same(low));
    });

    test('breaks ties in favor of the first player listed', () {
      final first = playerWithPoints('First', ['5']);
      final second = playerWithPoints('Second', ['5']);
      expect(determineKnockWinner([first, second]), same(first));
    });

    test('returns null for an empty list', () {
      expect(determineKnockWinner([]), isNull);
    });
  });

  group('constants', () {
    test('deals 5 cards regardless of player count', () {
      expect(getCardsPerPlayer(2), cardsPerPlayer);
      expect(getCardsPerPlayer(4), cardsPerPlayer);
      expect(cardsPerPlayer, 5);
    });

    test('plays matches to 100 points', () {
      expect(matchPointLimit, 100);
    });

    test('defines the betting structure', () {
      expect(Betting.startingChips, greaterThan(0));
      expect(Betting.anteAmount, greaterThan(0));
      expect(Betting.raiseOptions, isNotEmpty);
    });

    test('phase and win condition values match the JS strings', () {
      expect(Phase.startOfTurn.value, 'start-of-turn');
      expect(WinCondition.stockEmpty.value, 'stock-empty');
      expect(Phase.fromValue('game-over'), Phase.gameOver);
    });
  });
}
