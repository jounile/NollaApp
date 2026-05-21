# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
flutter pub get          # Install dependencies
flutter analyze          # Lint (analysis_options.yaml enforces prefer_const_constructors, prefer_final_locals, avoid_print)
flutter test             # Run all tests (no device required)
flutter run              # Run on default connected device/emulator
flutter devices          # List available devices
```

**Build targets:**
```bash
flutter build apk --debug
flutter build ios --simulator --debug
flutter build web --release --base-href /NollaApp/
```

## Architecture

**Flutter mobile app** for the [nolla.net](https://nolla.net) community platform. No external state management — pure `StatefulWidget` + `setState()` throughout.

**Layer structure:**

| Layer | Path | Responsibility |
|---|---|---|
| Screens | `lib/screens/` | UI; each screen owns its local state |
| Services | `lib/services/` | HTTP calls to nolla.net API, return typed result objects |
| Models | `lib/models/` | JSON parsing (flexible, handles multiple API response shapes) |

**Navigation:** `MainScreen` wraps three tabs in an `IndexedStack` (preserves scroll/state on tab switch) + bottom `NavigationBar`. Login is a separate route pushed before `MainScreen`.

**Auth flow:** `AuthService` POSTs to `https://nolla.net/auth/api/login` and returns a JWT token, which is passed down to services that need it (no global store — token is held in `MainScreen` state and forwarded).

**Map / geolocation (`SpotsScreen`):**
- `geolocator` for device position; falls back to Helsinki (60.1699, 24.9384) on failure.
- Map pan triggers `SpotService` fetch after a 600 ms debounce.
- Zoom level is mapped to a radius parameter (50 km → 100 m) for the API query.
- Only the top 100 nearest spots are rendered as markers.

**Media upload (`MediaScreen`):**
- `image_picker` for photo/video selection; images are compressed to max 1920×1920 at 85% quality before upload.
- `MediaService` sends a multipart POST to `https://nolla.net/media/api/upload` with a 5-minute timeout.
- CORS preflight failures on Flutter Web are detected and surfaced with a specific error message.

**In-app logging (`AppLogger`):**
- Singleton ring buffer (max 300 timestamped entries).
- Accessible in `SpotsScreen` and `MediaScreen` via a terminal icon → modal bottom sheet.
- Use this instead of `print()` (which is linted away).

## CI/CD

`.github/workflows/build.yml` runs on every push/PR:
- `flutter test` gates all builds.
- Builds Android APK, iOS simulator binary, and Web on every PR.
- Web previews are deployed to `gh-pages` at `/pr-{number}/`; main branch deploys to `/`.
- PRs receive automated comments with APK download links and web preview URLs.
- Merges to `main` create a GitHub Release with the APK attached.
- Branch name is injected at build time via `--dart-define=BRANCH_NAME`.
