# Google Play — App content answers (Sanora, `cm.sanora.app`)

Every answer below is derived from the code, not from assumption. Where the
code and the drafted privacy policy disagree, that is called out rather than
smoothed over — a Data Safety form that contradicts the app is what gets a
listing suspended.

Read **§0 Blockers** first. Four of them stop the submission outright.

---

## 0. Blockers — resolve before filing

| # | Blocker | Evidence |
|---|---|---|
| 1 | **No publicly hosted privacy policy URL.** Play requires a live URL; Health Connect review requires one that explicitly covers Health Connect data. The policy exists as in-app text only. | `docs/legal/privacy-policy.md:425` (TODO), `app/lib/features/legal/legal_content.dart:446,448` |
| 2 | **No web account-deletion URL.** Required for any app that allows account creation, in addition to the in-app path (which exists and works). | No such URL anywhere in repo |
| 3 | **Privacy policy contradicts the code.** The policy states Google "never sees your email address, your account identifier or your name". The coach function sends the entire profile JSON — which contains `name` — straight to Gemini. Either strip identifiers server-side or correct the policy. | Policy: `app/lib/features/legal/legal_content.dart:245-246`. Code: `app/lib/data/ai/ai_service.dart:120` → `supabase/functions/ai-coach/index.ts:31` (`JSON.stringify(body.profile)`), name at `app/lib/domain/models/user_profile.dart:12` |
| 4 | **Legal entity, address and contact emails are still `TODO`** in the policy and terms. | `docs/legal/privacy-policy.md:32-35`, `docs/legal/terms-of-service.md:18-20,239-240` |
| 5 | No reviewer test account exists yet (needed for App access — see §2). | — |
| 6 | **The `.aab`/`.ipa` built on 21 Jul have no Supabase credentials** — built without `--dart-define-from-file`, so `AppConfig.hasSupabase` is false and the build is offline-only: no account, no community, no AI. Rebuild before uploading. | `app/lib/core/config/app_config.dart:7-11`, `docs/DEPLOYMENT.md:100` |

Non-blocking but worth fixing: `flutter_secure_storage` is a declared dependency
that is never used (`app/pubspec.yaml:37`); the Supabase session token lives in
SharedPreferences (`app/lib/main.dart:54-65`). **Do not claim secure/encrypted
storage at rest anywhere on these forms.**

---

## 1. Facts the answers rest on

**Permissions in the shipped bundle** (read from the merged release manifest,
`app/build/app/intermediates/merged_manifest/release/.../AndroidManifest.xml`,
which is what Google parses — not the source manifest):

```
INTERNET, ACCESS_NETWORK_STATE, VIBRATE, POST_NOTIFICATIONS,
RECEIVE_BOOT_COMPLETED, RECORD_AUDIO, ACTIVITY_RECOGNITION,
health.READ_STEPS, health.READ_ACTIVE_CALORIES_BURNED,
health.READ_HEART_RATE, health.READ_SLEEP
```

Consequences, all verified against that list:

- **No `com.google.android.gms.permission.AD_ID`** → advertising ID is not collected.
- **No `READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`** → the Photo and Video
  Permissions declaration does not apply (`image_picker` 1.x uses the Android
  Photo Picker).
- No `SCHEDULE_EXACT_ALARM`, no `FOREGROUND_SERVICE` → neither declaration applies.

**Build:** `applicationId cm.sanora.app`, `minSdk 26`, `targetSdk 35`,
version `1.0.0+1` (`app/android/app/build.gradle.kts:37-42`, `app/pubspec.yaml:4`).

**Third parties that receive data** (all as processors acting on Sanora's behalf):

| Party | Receives | Evidence |
|---|---|---|
| Supabase | The backend itself: profile, health metrics, meals, habits, workouts, reminders, AI chat history, community rows, subscription receipts | `app/lib/data/sync/sync_service.dart:56-116` |
| Google (Gemini API) | Profile JSON **incl. name**, computed health profile, coach chat turns, meal photo (base64) or description, 7-day meal/metric history | `supabase/functions/_shared/mod.ts:72,92`; `ai-coach/index.ts:31-32`; `meal-analyze/index.ts:115-118` |
| Sentry | Crash reports + 20 % performance traces, **only if `SENTRY_DSN` is compiled in** | `app/lib/main.dart:19-32` |
| Apple / Google Play | Purchase receipts (the store, not the app, handles payment) | `app/lib/features/premium/purchase_service.dart:119-133` |

**No analytics, ads, attribution or tracking SDK of any kind** — verified across
`pubspec.yaml`, `pubspec.lock` (no transitive hits) and the merged manifest.

---

## 2. App access

**Answer: "All or some functionality is restricted."**

The app is offline-first and usable without an account, but these need sign-in
and a reviewer cannot see them otherwise: AI coach, meal photo analysis,
insights, workout generation, all Community features (friends, groups,
challenges, invites, reporting), and cross-device sync.

Add one instruction set:

- **Name:** Full access (email + password)
- **Username:** `playreview@<yourdomain>` — **create this account and confirm its
  email first**; sign-up otherwise waits on email confirmation
  (`app/lib/features/auth/auth_screen.dart:39-45`)
- **Password:** *(set one)*
- **Any other instructions:**
  > Launch the app and complete or skip onboarding. Tap Profile → Sign in and
  > enter the credentials above. AI features (Coach, meal photo analysis,
  > Insights, workout generation) and the Community tab (friends, groups,
  > challenges) require this account. All other features — logging meals,
  > metrics, habits, reminders — work without signing in.
  > To see Community fully, a second account is useful: group invites are sent
  > to the email address another user signed up with.

Pre-seed that account with a group and a challenge, or the Community tab shows
only empty states.

---

## 3. Ads

**Answer: "No, my app does not contain ads."**

No ad SDK, no ad permission, no `AD_ID`. Nothing in the app displays third-party
advertising.

---

## 4. Content ratings (IARC questionnaire)

**Category:** Utility, Productivity, Communication or Other.
(Not "Social Networking" — community features are a secondary accountability
feature, not the app's purpose. Answer the interaction questions honestly below.)

| Question | Answer |
|---|---|
| Violence (realistic, fantasy, or otherwise) | No |
| Sexuality or nudity | No |
| Profanity or crude humour | No |
| Controlled substances — reference to drugs, alcohol or tobacco | **No.** Users may log their own medications as a private health metric (`MetricType.medication`), which is not a depiction, promotion or reference to drug use. |
| Horror or fear themes | No |
| Gambling or simulated gambling | No |
| Does the app allow users to interact or communicate with each other? | **Yes** — friends, groups, shared challenges and leaderboards |
| Can users exchange or share user-generated content? | **Yes**, limited free text: group name and description, challenge name, and the display name others see. **There is no user-to-user messaging and no user-to-user image sharing.** |
| Does the app share the user's location with other users? | No |
| Does the app allow users to share their personal information with third parties? | No |
| Does the app provide unrestricted internet access (in-app browser)? | No |
| Does the app allow the purchase of digital goods? | **Yes** — auto-renewing Premium subscription |
| Does the app contain user-generated content that is moderated? | **Yes** — in-app reporting (spam, harassment, hate, sexual content, other) and user blocking |

Expected outcome: IARC 3+ / ESRB Everyone / PEGI 3 / USK 0, with the
"Users Interact" and "Digital Purchases" interactive elements.

**Evidence for the UGC/moderation answers:** free text visible to others —
`app/lib/features/community/community_screen.dart:697-698,740-753` (group name,
description) and `group_detail_screen.dart:615-616` (challenge name). Display
names are gated to accepted friends and group-mates
(`supabase/migrations/20260721000006_community_hardening.sql:70-113`). Chat is
user↔AI only — `chat_messages.role` is constrained to `'user'|'assistant'`
(`supabase/migrations/20260720000001_initial_schema.sql:77`) and the table is
owner-only under RLS. Reporting: `20260721000007_content_reports.sql:45-86`.
Blocking: `20260721000006_community_hardening.sql:121-138`.

---

## 5. Target audience and content

| Question | Answer |
|---|---|
| Target age groups | **18 and over, only.** Do not tick any band below 18. |
| Is your app appealing to children? | No |
| Store listing / creative assets designed to attract children? | No |
| Do you want your app in the Designed for Families programme? | No |

Rationale to keep on file: the app collects and processes sensitive health
information including medical conditions and medications, sells an
auto-renewing subscription, and includes user-to-user social features. Selecting
any under-18 band pulls the app into the Families policy and requires a
children's privacy review it is not built for.

---

## 6. News apps

**Answer: "No, my app is not a news app."**

---

## 7. COVID-19 contact tracing and status apps

**Answer: "My app is not a publicly available COVID-19 contact tracing or status app."**

---

## 8. Government apps

**Answer: "No, my app is not a government app."**

---

## 9. Financial features

**Answer: "My app doesn't have any financial features."**

The Premium subscription is a digital-goods purchase through Play Billing, which
is not a "financial feature" for this questionnaire. The app never touches a
card, bank account, mobile-money account or crypto asset — only store-issued
receipts and transaction identifiers reach the backend
(`supabase/migrations/20260721000005_subscription_receipts.sql:10-24`).

---

## 10. Health apps

**Answer: Yes, the app has health features.**

| Question | Answer |
|---|---|
| Which health categories apply? | Health & fitness / wellness; nutrition tracking. **Not** mental health services, **not** telehealth, **not** pharmacy. |
| Is the app a medical device, or does it require regulatory approval (FDA/CE/MDR)? | **No.** It provides general wellness information, states so in an in-app health disclaimer (`docs/legal/health-disclaimer.md`), and makes no diagnostic or treatment claim. Keep it that way in the listing copy — "diagnose", "treat", "cure" and "medical advice" are the words that reclassify it. |
| Does the app conduct health research with human subjects? | No |
| Is the app subject to HIPAA? | No — Sanora is not a covered entity or business associate |
| Does it handle sensitive health data? | **Yes** |
| Does it sell or facilitate the sale of prescription drugs, alcohol, tobacco or cannabis? | No |
| Does it provide telehealth or connect users to clinicians? | No |

### Health Connect data-access declaration

Required because the app declares four Health Connect read permissions. Google
also requires the privacy policy to specifically address Health Connect data,
and the app already has the rationale intent-filters and the
`ViewPermissionUsageActivity` alias Google looks for
(`app/android/app/src/main/AndroidManifest.xml:44-66`).

Per-permission justification — accurate to what the code does
(`app/lib/data/activity/activity_service.dart:16-21,102-198`):

- **`READ_STEPS`** — Sanora shows the user's daily step count on the dashboard
  and in the weekly report, and uses it to compute the daily activity score.
- **`READ_ACTIVE_CALORIES_BURNED`** — shown on the dashboard as the day's active
  energy, and used in the daily activity score.
- **`READ_HEART_RATE`** — the most recent reading from the last 24 hours is shown
  on the health dashboard so the user can see their resting heart rate alongside
  their other metrics.
- **`READ_SLEEP`** — last night's sleep duration is shown and compared against
  the user's sleep goal.

Statements you can make truthfully, all verified in code:

- Health Connect data is **read on demand and displayed**; it is **not written to
  local storage, not uploaded to Sanora's servers, and not sent to the AI
  provider** (`ActivityService` performs no `LocalStore.put` of health values and
  no repository enqueues them for sync).
- It is never used for advertising and never sold or transferred to a third party.
- The app requests read access only; it writes nothing back to Health Connect.

> Housekeeping: `ios/Runner/Info.plist` carries `NSHealthUpdateUsageDescription`
> claiming the app can save workouts to Apple Health, but no write call exists.
> Remove that string or implement the write — a usage description for a
> capability you don't have invites questions on the Apple side.

---

## 11. Photo and video permissions

**Not applicable — this declaration should not appear.** The bundle requests
neither `READ_MEDIA_IMAGES` nor `READ_EXTERNAL_STORAGE`; meal photos come from
the camera or the Android Photo Picker. If the console shows the form anyway,
answer that the app does not request broad photo or video access.

---

## 12. Advertising ID

**Answer: "No, my app does not use advertising ID."**

Confirmed absent from the merged release manifest and from every dependency.

---

## 13. Data safety

### Security practices

| Question | Answer |
|---|---|
| Is all user data encrypted in transit? | **Yes** — every network call goes to `https://` Supabase endpoints; no cleartext endpoint exists anywhere in the code |
| Do you provide a way for users to request that their data be deleted? | **Yes** — in-app: Profile → Delete account (`app/lib/features/profile/profile_screen.dart:260-306` → `delete_account` RPC, `supabase/migrations/20260721000004_metering_and_account_deletion.sql:54-76`). **A web deletion URL is still required and does not exist — see §0.** |
| Has your app been independently reviewed against a security standard? | No |
| Committed to Play Families Policy | N/A (18+) |

Deletion is genuinely complete: every user-owned table cascades from
`auth.users`. One caveat worth knowing if asked — abuse reports *filed against*
a deleted user survive, because `content_reports.target_id` has no foreign key
(`20260721000007_content_reports.sql:14`). That is normal moderation retention;
state it in the privacy policy's retention section.

### Data types

"Collected" means transmitted off the device. Sanora only transmits when the
user signs in — the app is fully usable offline — so almost everything can
honestly be marked **optional** ("Users can choose whether this data is
collected"). Take that credit; it is accurate.

**On "shared":** Google's definition excludes transfers to a service provider
processing on your behalf. Supabase (your backend), Google's Gemini API (your
key, your prompt) and Sentry are all processors, so **"Shared" is No throughout**
— provided your DPAs say so and the privacy policy names them as processors. If
you would rather not lean on that exemption, the conservative alternative is to
mark the Gemini-bound types as shared; it is a defensible choice either way, but
be consistent with what the policy says.

| Data type | Collected | Shared | Optional? | Purposes | Notes / evidence |
|---|---|---|---|---|---|
| **Name** | Yes | No | Optional | App functionality, Personalisation, Account management | `profiles.data`; also reaches Gemini — see §0 blocker 3 |
| **Email address** | Yes | No | Optional | App functionality, Account management | Auth; also stored in `group_invites.invited_email` when a user invites someone |
| **User IDs** | Yes | No | Optional | App functionality, Account management | Supabase `auth.users` id |
| **Other personal info** | Yes | No | Optional | App functionality, Personalisation | Age and sex, collected in onboarding for BMR/TDEE (`onboarding_controller.dart:41`). Declaring these here is the conservative reading |
| **Purchase history** | Yes | No | Optional | App functionality, Fraud prevention & compliance, Account management | Product id, store transaction id, expiry — no payment instrument |
| **Health info** | Yes | No | Optional | App functionality, Personalisation | Weight, waist, hip, body fat, blood pressure, blood sugar, resting heart rate, sleep, mood, stress, symptoms, **medications**, **medical conditions**, allergies, meals and nutrition |
| **Fitness info** | Yes | No | Optional | App functionality, Personalisation | Steps, active calories, workouts, habits (the manually-logged and synced ones; Health Connect reads are not uploaded) |
| **Other in-app messages** | Yes | No | Optional | App functionality | The AI coach conversation is stored server-side in `chat_messages` and sent to Gemini. There is no user-to-user messaging |
| **Photos** | Yes | No | Optional | App functionality | Meal photo is base64'd into the `meal-analyze` request and forwarded to Gemini for recognition. **Tick "Data is processed ephemerally"** — it is not written to Supabase Storage; the local file path is stripped before sync (`meals_repository.dart:31`) |
| **Other user-generated content** | Yes | No | Optional | App functionality | Group names and descriptions, challenge names, abuse-report notes |
| **Crash logs** | Yes* | No | Optional | Analytics | *Only if `SENTRY_DSN` is compiled into the release. If you ship without it, answer No |
| **Diagnostics** | Yes* | No | Optional | Analytics | *Sentry performance traces, 20 % sample |
| **Device or other IDs** | Yes* | No | Optional | Analytics | *Sentry attaches device context and an installation identifier. Verify against your Sentry config; if in doubt, declare it |

**Explicitly NOT collected** — say No to all of these:

Approximate or precise location (country is self-selected text in the profile,
not device location) · Physical address · Phone number · Race and ethnicity ·
Political or religious beliefs · Sexual orientation · Payment info · Credit score ·
Other financial info · Contacts · Calendar · **Voice or sound recordings**
(speech-to-text is performed by the OS and returns text only; no audio reaches
the app — `log_meal_screen.dart:216-238`) · Music or other audio files · Videos ·
Files and docs (the PDF report is a user-initiated share, which is exempt) ·
Emails · SMS · App interactions · In-app search history · Installed apps ·
Web browsing history.

---

## 14. Store listing hygiene that these answers imply

- The listing must not describe Sanora as diagnosing, treating or providing
  medical advice, or the medical-device answer in §10 stops being true.
- The listing must not be styled to appeal to children (§5).
- Data Safety must match the privacy policy. Blocker 3 currently breaks that.
