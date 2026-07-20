# Bodi Flutter app

See the [repository README](../README.md) for the product overview and
[docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) for how this app is built.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Omit the defines to run fully offline (no sync, no AI).

- `lib/core` — theme, router, storage, shared widgets, DI
- `lib/domain` — Freezed models and the pure health engines
- `lib/data` — repositories, sync queue, Supabase/AI/health services
- `lib/features` — feature-first screens and controllers
- `test/` — unit, repository and widget tests (`flutter test`)
