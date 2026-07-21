# Deploying Sanora

## 1. Supabase project

```bash
npm i -g supabase
supabase login
supabase link --project-ref <project-ref>

# Apply schema + RLS, then seed the food database
supabase db push
psql "$SUPABASE_DB_URL" -f supabase/seed.sql   # or: supabase db reset (local)

# Deploy the AI edge functions
supabase functions deploy ai-coach meal-analyze generate-workout generate-insights verify-purchase

# Server-side secrets (never shipped in the app)
supabase secrets set GEMINI_API_KEY=...
supabase secrets set GEMINI_MODEL=gemini-3.5-flash   # optional override
```

Enable **email auth** in the dashboard (Authentication → Providers). The
app uses email + password; confirmation emails are optional.

### Premium

`consume_ai_call()` meters free-tier AI calls (20/day) against `ai_usage`,
atomically. Premium is recorded in `subscriptions` (`tier = 'premium'`,
optional `valid_until`).

The in-app purchase flow writes that row via receipt verification. Until the
store product IDs and verification credentials are configured it cannot grant
premium — by design, it fails closed rather than trusting an unverified
receipt. To grant premium manually for testing, upsert `subscriptions` with
the service role.

## 2. Flutter app

Build-time configuration is injected with `--dart-define` — there are no
checked-in secrets:

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<publishable-key>
```

For day-to-day runs put the same values in `app/dart_defines/dev.json` (the
directory is gitignored) and pass them as a file instead:

```bash
flutter run --dart-define-from-file=dart_defines/dev.json
```

Without the defines the app runs in local-only mode (no sync, no AI) —
useful for review builds and demos. It fails silently by design, so if sync
looks dead, check these first.

### Platform notes

- **Android**: `minSdk 26` (required by `health`), `targetSdk 35`, core library
  desugaring on (required by `flutter_local_notifications`), R8 enabled with
  `app/android/app/proguard-rules.pro`.
  Release signing reads `app/android/key.properties`, which is gitignored
  along with `*.jks`. **Back up the keystore and its password somewhere
  durable — losing them means the app can never be updated on Play.**
  In CI the keystore is reconstructed from the `ANDROID_KEYSTORE_BASE64`
  secret. `fastlane internal` / `fastlane production` exist but are not wired
  into any workflow yet; they need `GOOGLE_PLAY_JSON_KEY` and a first AAB
  uploaded by hand.
- **iOS**: HealthKit entitlement lives in `ios/Runner/Runner.entitlements`,
  wired via `CODE_SIGN_ENTITLEMENTS` on all three Runner configurations.
  Deployment target is 14.0 (the `health` package requires it). Usage
  descriptions and
  `ITSAppUsesNonExemptEncryption` are in `Info.plist`.
  Note `flutter_native_splash:create` rewrites `Info.plist` — re-check the
  duplicate-key and encryption entries after running it.
  TestFlight uploads via `fastlane beta` (`app/ios/fastlane/`) need a seeded
  `match` repo before `readonly: true` can work.

## 3. CI/CD (GitHub Actions)

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` | PRs, pushes to `main` | Flutter analyze + tests with coverage; Deno typecheck of edge functions; migrations + seed applied to a real Postgres |
| `release.yml` | tags `v*` | Android AAB/APK (with dart-defines from secrets) + GitHub release; iOS no-codesign build |
| `deploy-supabase.yml` | `supabase/**` changes on `main` | `supabase db push` + `functions deploy` |

Repository secrets required:

- `SUPABASE_URL`, `SUPABASE_ANON_KEY` — baked into release builds. Both
  workflows fail fast if they are missing; without that guard a release
  silently ships a local-only-mode app.
- `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD` — backend deploys
- `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`,
  `ANDROID_KEY_PASSWORD` — release signing
- `SENTRY_DSN` — optional; crash reporting stays off when absent

`deploy-supabase.yml` targets the `production` GitHub environment. **Create
that environment with a required reviewer** — until you do, the
`environment:` key is decorative and merges to `main` deploy unattended.

## 4. Monitoring & crash reporting

Sentry initialises in `main()` only when a `SENTRY_DSN` is supplied at build
time; otherwise the app runs with the same global handlers logging to
`debugPrint`. `sendDefaultPii` is off — this app holds health data, and none
of it should ride along with a crash report.

Release builds use `--obfuscate --split-debug-info`, so crashes are
unreadable without the symbols uploaded as a CI artifact. Keep them for any
build you ship.

Edge function logs are available with `supabase functions logs <name>`, and
database health via the Supabase dashboard's advisors.
