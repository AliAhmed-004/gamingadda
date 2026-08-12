import '../models/game.dart';

const mockGames = <Game>[
  Game(
    id: 'block_race',
    title: 'Block Race',
    category: 'Strategy',
    description:
        'A 3D barricade race — roll the dice, hop your pawn along the path, and drop walls to block your rival. First to the goal wins.',
    thumbnailUrl: 'assets/icons/block_race.png',
    coverUrl: 'assets/icons/block_race.png',
    rating: 4.7,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'casino',
    title: 'Card Match',
    category: 'Card',
    description:
        'Draw from the deck and match by card number on the floor or opponent\'s collection. Play vs AI or a friend.',
    thumbnailUrl: 'assets/icons/card_match.png',
    coverUrl: 'assets/icons/card_match.png',
    rating: 4.6,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'checkers',
    title: 'Checkers',
    category: 'Strategy',
    description:
        'Classic American checkers. Capture opponents, crown kings on the far row, and outplay a built-in AI — all instant, no install.',
    thumbnailUrl: 'assets/icons/checkers.png',
    coverUrl: 'assets/icons/checkers.png',
    rating: 4.9,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'connect_four',
    title: 'Connect 4',
    category: 'Strategy',
    description:
        'Drop discs into the grid and connect four in a row — across, down, or diagonally. Climb 365 levels of ever-stronger AI, or pass-and-play with a friend.',
    thumbnailUrl: 'assets/icons/connect_four.png',
    coverUrl: 'assets/icons/connect_four.png',
    rating: 4.8,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'ludo',
    title: 'Ludo',
    category: 'Family',
    description:
        'Classic Ludo for 2–4 players. Roll the die, race four tokens home, capture rivals on the path — hotseat or vs computer.',
    thumbnailUrl: 'assets/icons/ludo.png',
    coverUrl: 'assets/icons/ludo.png',
    rating: 4.8,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'sudoku',
    title: 'Sudoku',
    category: 'Puzzle',
    description:
        'Start on a 4×4 grid and grow to 6×6 then full 9×9 across 365 levels. Fewer empties early, denser puzzles later — or Free Play Easy / Medium / Hard.',
    thumbnailUrl: 'assets/icons/sudoku.png',
    coverUrl: 'assets/icons/sudoku.png',
    rating: 4.8,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'stack',
    title: 'Stack',
    category: 'Action',
    description:
        'Time your taps to stack sliding blocks as high as you can. Perfect placements keep the tower wide — miss and it is game over.',
    thumbnailUrl: 'assets/icons/stack.png',
    coverUrl: 'assets/icons/stack.png',
    rating: 4.5,
    playUrl: '',
    featured: true,
  ),
  Game(
    id: 'tic_tac_toe',
    title: 'Tic-Tac-Toe',
    category: 'Strategy',
    description:
        'Classic X and O on a 3×3 grid. Beat a friend hotseat or challenge the AI — Easy, Medium, or Hard.',
    thumbnailUrl: 'assets/icons/tic_tac_toe.png',
    coverUrl: 'assets/icons/tic_tac_toe.png',
    rating: 4.7,
    playUrl: '',
    featured: true,
  ),
];

List<String> get mockCategories {
  final categories = mockGames.map((g) => g.category).toSet().toList()..sort();
  return ['All', ...categories];
}

List<Game> get featuredGames =>
    mockGames.where((g) => g.featured).toList(growable: false);
