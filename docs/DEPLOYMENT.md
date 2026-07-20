# Deploying Bodi

## 1. Supabase project

```bash
npm i -g supabase
supabase login
supabase link --project-ref <project-ref>

# Apply schema + RLS, then seed the food database
supabase db push
psql "$SUPABASE_DB_URL" -f supabase/seed.sql   # or: supabase db reset (local)

# Deploy the AI edge functions
supabase functions deploy ai-coach meal-analyze generate-workout generate-insights

# Server-side secrets (never shipped in the app)
supabase secrets set OPENAI_API_KEY=sk-...
supabase secrets set OPENAI_MODEL=gpt-5-mini   # optional override
```

Enable **email auth** in the dashboard (Authentication → Providers). The
app uses email + password; confirmation emails are optional.

### Premium

`ai_usage` meters free-tier AI calls (20/day). Mark a subscriber premium by
upserting into `subscriptions` (`tier = 'premium'`, optional
`valid_until`) from your payment webhook (service role).

## 2. Flutter app

Build-time configuration is injected with `--dart-define` — there are no
checked-in secrets:

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key>
```

Without the defines the app runs in local-only mode (no sync, no AI) —
useful for review builds and demos.

### Platform notes

- **Android**: Health Connect permissions and `POST_NOTIFICATIONS` are
  requested at runtime. For Play Store releases configure signing in
  `app/android` and use `fastlane internal` / `fastlane production`
  (`app/android/fastlane/`); provide `GOOGLE_PLAY_JSON_KEY_FILE`.
- **iOS**: add HealthKit entitlement + `NSHealthShareUsageDescription`,
  camera/microphone/speech usage descriptions in `Info.plist` before store
  submission. TestFlight uploads via `fastlane beta` (`app/ios/fastlane/`),
  using `match` for signing.

## 3. CI/CD (GitHub Actions)

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yml` | PRs, pushes to `main` | Flutter analyze + tests with coverage; Deno typecheck of edge functions; migrations + seed applied to a real Postgres |
| `release.yml` | tags `v*` | Android AAB/APK (with dart-defines from secrets) + GitHub release; iOS no-codesign build |
| `deploy-supabase.yml` | `supabase/**` changes on `main` | `supabase db push` + `functions deploy` |

Repository secrets required:

- `SUPABASE_URL`, `SUPABASE_ANON_KEY` — baked into release builds
- `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD` — backend deploys

## 4. Monitoring & crash reporting

The app logs sync failures with `debugPrint` and fails soft. For
production monitoring wire in your preferred crash reporter (Sentry or
Firebase Crashlytics both drop in at `main()`); edge function logs are
available with `supabase functions logs <name>`, and database health via
the Supabase dashboard's advisors.
