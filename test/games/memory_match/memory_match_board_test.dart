import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaming_adda/games/memory_match/memory_match_board.dart';
import 'package:gaming_adda/games/memory_match/memory_match_logic.dart';
import 'package:gaming_adda/games/memory_match/memory_match_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('board paints face-up and face-down cards without throwing',
      (tester) async {
    final game = MemoryMatchGame(pairs: 9, seed: 1)..revealAll();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 420,
            height: 560,
            child: MemoryMatchBoard(
              game: game,
              columns: 6,
              onTap: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.byType(Image), findsWidgets);

    game.hideUnmatched();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });

  test('theme exposes 18 generated face assets plus a card back', () {
    expect(MemoryMatchTheme.faces.length, 18);
    expect(MemoryMatchTheme.cardBackAsset, contains('card_back'));
    for (final face in MemoryMatchTheme.faces) {
      expect(face.asset, startsWith('assets/memory_match/faces/'));
    }
  });
}
