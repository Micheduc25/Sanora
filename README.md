# Sanora — Know Your Body

Sanora is an AI-powered personal health companion. It turns a two-minute
onboarding into a personal health profile, then helps you eat better, move
more, sleep better and build habits — with first-class support for African
foods and food cultures.

Sanora is **not** a calorie counter. It is offline-first, kind by design, and
uses AI to remove effort instead of adding numbers.

## What's in this repository

| Path | Contents |
| --- | --- |
| `app/` | Flutter application (Android + iOS) |
| `supabase/` | Database migrations, RLS policies, seed data, edge functions |
| `.github/workflows/` | CI (analyze, tests, SQL validation, Deno typecheck), releases, Supabase deploys |
| `docs/` | Architecture and deployment guides |

## Feature overview

- **Onboarding → AI Health Profile** — age, body measurements, lifestyle,
  medical background, food culture and goals produce computed targets:
  BMI, estimated body fat (Relative Fat Mass), BMR (Mifflin-St Jeor /
  Katch-McArdle), daily energy needs, calorie/protein/water targets, step
  and sleep goals, healthy weight range, visceral fat risk, metabolic
  health score and lifestyle risk score. Recomputed on every data change.
- **Home dashboard** — daily health score ring (movement, nutrition,
  hydration, sleep, habits), weight/waist/body-fat trends, live tiles for
  steps, calories, protein, water, sleep and heart rate, the day's habits,
  an AI insight, and quick actions.
- **Meal intelligence** — log by photo, voice, text or database search.
  AI vision estimates components, portions, macros, micros and a confidence
  score, and suggests culturally-respectful healthier swaps. A bundled
  98-food African-first database (eru, ndolé, achu, koki, fufu, jollof,
  ugali, injera, banku, sadza…) keeps text logging working fully offline.
- **AI coach** — streaming chat grounded in the user's own profile, meals,
  metrics and habits. Proactive, kind, and aware of medical conditions.
- **Health tracking** — weight, waist, hip, body fat, blood pressure, blood
  sugar, heart rate, sleep, mood, stress, energy, water and steps, with
  sparkline charts. Body measurements re-run the health engine.
- **Activity** — HealthKit / Health Connect integration for steps, active
  energy, heart rate and sleep, merging with manual logs.
- **Habits** — one-tap habits with weekday scheduling, streaks and starter
  suggestions.
- **Insights** — a deterministic on-device rules engine (late-night eating,
  protein gaps, sodium, sugar, weekend patterns, sleep debt, hydration,
  weight trends) plus an AI edge function for free-form pattern analysis.
- **Workouts** — AI-generated workouts by category with an offline
  coach-curated template library; every exercise ships with form cues.
- **Smart reminders** — water, movement, meals, medication, sleep and
  custom reminders as weekly local notifications.
- **Reports** — weekly report with charts and a shareable PDF export.
- **Community** — add friends by email, create private or public groups, and
  run step/workout/habit/water challenges with a live leaderboard. Friend
  and group data is served through `SECURITY DEFINER` RPCs that only reveal a
  member's display name to people they're actually connected to, so the
  owner-only RLS on `profiles` is never widened.
- **Premium & metering** — AI calls are metered server-side (free daily
  allowance, unlimited for premium subscribers).

## Getting started

```bash
cd app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run --dart-define-from-file=dart_defines/dev.json
```

Run without the defines for **local-only mode**: everything except the AI
features works offline, storing data on-device in Hive. A plain `flutter run`
gets you local-only mode, so pass the file (or use the `Sanora (dev backend)`
VS Code launch configuration) whenever you mean to exercise sync or AI.

Run the tests:

```bash
cd app && flutter test
```

## Backend

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for standing up the Supabase
project (migrations, seed, RLS, edge functions and secrets), and
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for how the pieces fit
together.

## Privacy & safety

- All personal tables are protected by Postgres Row Level Security —
  owner-only access, verified by an isolation test in CI's migration job.
- Gemini keys and prompts live exclusively in edge functions; the app only
  ever talks to Supabase with the user's own JWT.
- Meal photo *files* stay on-device and are stripped from sync — only derived
  nutrition is stored. Photo analysis does send the image to the
  `meal-analyze` edge function, which forwards it to the Gemini API and
  persists nothing; log by text or food search to keep images off the network
  entirely.
- Sanora presents estimates as guidance, never medical advice.
