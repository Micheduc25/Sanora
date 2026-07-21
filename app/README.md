# Bodi Flutter app

See the [repository README](../README.md) for the product overview and
[docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) for how this app is built.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=dart_defines/dev.json
```

Omit the defines to run fully offline (no sync, no AI) — but omit them by
choice, not by accident: a build without them cannot reach the AI features at
all, and the app says so only once you try to use one. The `Bodi (dev
backend)` VS Code launch configuration passes the file for you.

- `lib/core` — theme, router, storage, shared widgets, DI
- `lib/domain` — Freezed models and the pure health engines
- `lib/data` — repositories, sync queue, Supabase/AI/health services
- `lib/features` — feature-first screens and controllers
- `test/` — unit, repository and widget tests (`flutter test`)
