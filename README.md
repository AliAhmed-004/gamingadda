# Gaming Adda

Casual board games and arcade classics in one Flutter app — Checkers, Ludo, Sudoku, Connect 4, Card Match, Stack, and Tic-Tac-Toe.

## Play on the web

Marketing site + playable Flutter web app deploy to GitHub Pages:

- Landing: `https://aliahmed-004.github.io/gaming-adda/`
- App: `https://aliahmed-004.github.io/gaming-adda/play/`

After merging to `main`, the **Deploy GitHub Pages** workflow builds and publishes. In the repo settings, set **Pages → Source** to **GitHub Actions**.

## Local

```bash
flutter pub get
flutter run -d chrome
```

Landing preview (static):

```bash
cd website && python3 -m http.server 8080
```

## Design

Visual language follows `design-system/gaming-adda/` (claymorphism, teal brand, Fredoka + Nunito).
