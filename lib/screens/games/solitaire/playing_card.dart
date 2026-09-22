import 'dart:math';

enum CardSuit { hearts, diamonds, clubs, spades }

extension CardSuitX on CardSuit {
  bool get isRed => this == CardSuit.hearts || this == CardSuit.diamonds;
  String get symbol => switch (this) {
        CardSuit.hearts => '♥',
        CardSuit.diamonds => '♦',
        CardSuit.clubs => '♣',
        CardSuit.spades => '♠',
      };
}

class PlayingCard {
  final CardSuit suit;
  final int rank; // 1 = A ... 11 = J, 12 = Q, 13 = K
  bool faceUp;

  PlayingCard(this.suit, this.rank, {this.faceUp = false});

  bool get isRed => suit.isRed;

  String get rankLabel => switch (rank) {
        1 => 'A',
        11 => 'J',
        12 => 'Q',
        13 => 'K',
        _ => '$rank',
      };
}

List<PlayingCard> buildShuffledDeck([int? seed]) {
  final deck = <PlayingCard>[
    for (final suit in CardSuit.values)
      for (var rank = 1; rank <= 13; rank++) PlayingCard(suit, rank),
  ];
  deck.shuffle(Random(seed));
  return deck;
}
