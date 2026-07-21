# Privacy Policy

**Sanora — Know Your Body**, published by Ndjock Michel Junior under the name
Innovation Cameroon.

- Effective date: 21 July 2026
- Applies to: Sanora mobile app version 1.0.0 and later

## 1. In short

Sanora is a personal health companion. It is built offline-first: you can use it
without an account, and in that case nothing you enter ever leaves your phone.

If you create an account, your health data is synchronised to our database so
you can recover it on a new device. That database is hosted in France and every
row is locked to you by row-level security — no other user, and no unauthorised
service, can read it.

Some features send data to Google's Gemini API so an AI model can answer you. We tell you
exactly which ones below, in section 6.

We do not sell your data. We do not use it for advertising. We do not build
profiles for anyone other than you.

## 2. Who is responsible for your data

Sanora is built and operated by **Ndjock Michel Junior**, an individual
developer based in Cameroon, who is the data controller — the *responsable du
traitement* — for the personal data described in this policy. Innovation
Cameroon is the name Sanora is published under; it is not a separate legal
entity.

- Data controller: Ndjock Michel Junior, individual developer, Cameroon
- Privacy contact and data requests: ndjockjunior@gmail.com
- Data protection officer: none appointed. Sanora is run by one person, who
  handles every request to this address personally.

Cameroonian law applies to this processing: Law No. 2024/017 of 23 December
2024 on the protection of personal data covers, under its Article 2, any
processing carried out by a controller established in Cameroon and any
processing of the data of a person established, resident or in transit in
Cameroon. Where you are in the European Economic Area or the United Kingdom,
the GDPR applies to you in addition, and we honour it.

If you write to the address above about your data, you will get an answer
within 30 days.

## 3. Using Sanora without an account

Sanora runs fully offline. Until you sign in:

- Everything you record is stored only in a local database on your device.
- No health data is transmitted anywhere.
- AI features are unavailable, because they require a signed-in request to our
  backend.

If you never sign in, sections 5 to 8 of this policy do not apply to you. The
only way to erase your data in that case is to use **Delete my data** in the app
or to uninstall Sanora.

## 4. What Sanora collects

### 4.1 Account data

- Email address and password. Your password is handled by Supabase Auth and
  stored only as a hash; we never see it.
- Account identifier, sign-up date and sign-in timestamps.
- Email confirmation and password-reset messages sent to your address.

### 4.2 Health and profile data you enter

This is health data. Under the GDPR it is a special category of personal data
and receives the extra protections described in section 9.

Profile:

- Name (optional), age, sex, height, weight
- Waist and hip circumference, body fat percentage
- Occupation, work schedule, country, language
- Activity level, exercise days per week, typical sleep hours, stress level
- Medical conditions, medications, allergies
- Food preferences and favourite foods
- Goals (for example fat loss, better sleep, disease prevention) and target
  weight, waist, body fat and target date

Measurements you log over time, each with a value, an optional note and a
timestamp:

- Weight, waist, hip, body fat percentage
- Blood pressure (systolic and diastolic), blood sugar
- Resting heart rate
- Sleep duration
- Mood, stress, energy
- Water intake, steps
- Symptoms and medication taken

Meals:

- Meal name, meal type, and how it was logged (photo, text, voice, food
  database or a saved favourite)
- Identified food components and quantities
- Derived nutrition: calories, protein, fat, carbohydrate, fibre, sugar,
  sodium and selected micronutrients
- The AI's confidence score, its notes, and any suggested healthier swaps
- Whether you marked the meal as a favourite, and when you ate it

Habits, workouts and reminders:

- Habit names, emoji, descriptions, schedules, daily targets, and each
  completion you log
- Workouts: name, category, difficulty, duration, estimated calories, the
  exercise list, and whether you completed it
- Reminders: kind, title, body text, time of day, days of the week, and whether
  the reminder is enabled

Coach conversations:

- Every message you send to the AI coach and every reply it gives, with
  timestamps.

### 4.3 Data Sanora calculates about you

Sanora derives a health profile from what you enter. These derived values are
stored alongside your profile and are also health data:

- Body mass index and BMI category
- Estimated body fat percentage
- Basal metabolic rate and total daily energy expenditure
- Daily calorie, protein, carbohydrate, fat and water targets
- Step goal, weekly exercise minutes, sleep goal
- Healthy weight range
- Waist-to-height and waist-to-hip ratios
- Visceral fat risk band, metabolic health score and lifestyle risk score

These are estimates from published formulas, not diagnoses. See the Health
Disclaimer.

### 4.4 Meal photos

Meal photos are treated differently from everything else.

- The photo file is saved **only on your device**. It is never uploaded to our
  database or our file storage, and it is never included in a sync.
- However, when you ask Sanora to analyse a meal from a photo, the image is
  transmitted for that single request to our backend and on to Google, so the
  model can identify the food. Along with the image we send your country, your
  allergies and your food preferences, so the estimate fits what you actually
  eat.
- Neither we nor Google store the image after the request completes. What is
  saved afterwards is only the derived nutrition described in section 4.2.

If you would rather no image ever leave the device, describe the meal in text
or pick it from the food database instead of using the camera.

### 4.5 Data from Apple Health and Health Connect

If you connect Sanora to Apple Health (iOS) or Health Connect (Android), Sanora
reads:

- Steps
- Active energy burned
- Heart rate
- Sleep
- Distance

Sanora only reads from these stores; it does not write anything back to them.
Connecting is optional and you can revoke it at any time in your platform's
health settings — Sanora then falls back to what you log manually. Data read this
way is used to fill in your dashboard and your weekly report.

Health Connect and Apple Health data is never sent to advertisers or sold, and
is used only to provide the features described in this policy.

### 4.6 Community data

If you use the community features, other users can see a limited amount of
information:

- Friend requests you send or accept, and the accounts involved
- Groups you create or join, their name and description, and the member list
- Challenges you create or join, and your progress figure in each challenge
  you have joined

Your measurements, meals, coach conversations and health profile are **never**
shared with friends or groups.

### 4.7 Technical and usage data

- A daily counter of how many AI requests your account has made, used only to
  enforce the free-tier allowance.
- Your subscription tier and its expiry date.
- Crash and error reports, if crash reporting is enabled in the build you
  installed. See section 6.3.

### 4.8 Device permissions Sanora may ask for

- **Camera and photo library** — to photograph or pick a meal image.
- **Microphone and speech recognition** — to describe a meal by voice. Speech is
  transcribed by your operating system's speech recognition. Depending on your
  device and platform settings, your OS may process that audio on its own
  servers under Apple's or Google's privacy policy rather than ours.
- **Notifications** — to deliver the reminders you create.
- **Physical activity** — to read step data.

Each of these is optional, requested only when you first use the feature, and
revocable in your device settings.

## 5. What Sanora does not collect

- We do not collect your precise location, and Sanora requests no location
  permission.
- We do not use advertising identifiers, advertising SDKs or third-party
  analytics or tracking SDKs.
- We do not sell, rent or share personal data with data brokers.
- We do not use your health data to train any AI model, and we do not permit
  our AI provider to do so.

## 6. Who your data is shared with

We use a small number of processors. Each acts on our instructions only.

### 6.1 Supabase — database, authentication, file storage and backend functions

Your account and every synchronised row live in a Supabase-managed PostgreSQL
database hosted in the **eu-west-3 (Paris, France)** region. Supabase also
provides authentication and runs our backend functions.

Every table containing personal data is protected by PostgreSQL row-level
security policies that restrict access to the owning user, enforced by the
database itself rather than by the app.

### 6.2 Google (Gemini API) — AI features

Four features call Google's Gemini API. The request is always made by our
backend, never by the app: the app never holds a Gemini key, and Google never
sees your email address or your account identifier.

Your **name is removed from your profile by our backend before the request
leaves it**, along with any e-mail address, phone number or account identifier
the profile might carry. The stripping happens on the server rather than on
your phone, so it applies to every version of the app. What Google receives is
a health profile without a person's name attached to it.

What is sent, per feature:

- **AI coach** — your profile, your calculated health profile, a summary of
  today's activity, and up to the last 20 messages of the conversation.
- **Meal analysis** — the meal photo and/or your text description, plus your
  country, allergies and food preferences.
- **Insight generation** — your recent metrics and logged activity.
- **Workout generation** — your profile, your calculated health profile, and the
  workout category and duration you chose.

Google processes these requests as our processor via the Gemini API. Data
sent through the paid Gemini API is not used to train Google's models.

If you never use the coach, meal photo or text analysis, insights or workout
generation, no data is sent to Google.

### 6.3 Sentry — crash reporting (conditional)

Crash reporting is a build-time option. It is active only in builds where a
Sentry DSN was configured; in local, debug and unconfigured builds it is
entirely off and no crash data is transmitted.

Where it is active:

- We explicitly disable the sending of personally identifiable information.
- Crash reports contain the error, a stack trace, and device and app version
  information — not request bodies, not your entries and not your
  conversations.
- Roughly one in five sessions is sampled for performance tracing.

### 6.4 App stores and platform providers

Apple and Google operate the app stores through which you install Sanora and
handle any purchase you make. Their handling of that transaction is governed by
their own privacy policies, not this one.

### 6.5 Legal disclosure

We may disclose data where we are legally required to do so by a valid order
from a competent authority, or where it is necessary to establish, exercise or
defend legal claims. We will not disclose more than the request requires.

## 7. Why we process your data, and on what legal basis

- **To provide the app's core features** — recording your data, computing your
  targets, showing your dashboard, syncing across devices. Basis: performance of
  our contract with you (GDPR Art. 6(1)(b)), and for health data your explicit
  consent (Art. 9(2)(a)), given when you enter that data during onboarding.
- **To run AI coaching, meal analysis, insights and workouts.** Basis: your
  explicit consent (Art. 9(2)(a)) and performance of the contract. These
  features are optional and only run when you invoke them.
- **To manage your account, authenticate you and reset your password.** Basis:
  performance of the contract.
- **To enforce the free-tier AI allowance and manage subscriptions.** Basis:
  performance of the contract and our legitimate interest in preventing abuse
  and controlling cost (Art. 6(1)(f)).
- **To keep the app working and diagnose crashes.** Basis: our legitimate
  interest in a reliable, secure product (Art. 6(1)(f)).
- **To provide community features you opt into.** Basis: your consent, given by
  choosing to send a friend request, join a group or join a challenge.

You can withdraw consent at any time by deleting your account (section 11), by
disconnecting Apple Health or Health Connect, or by simply not using the
optional features. Withdrawing consent does not affect processing that already
happened.

## 8. Where your data is processed

- **On your device** — always. Sanora's local database is the primary copy.
- **France (eu-west-3)** — Supabase database, authentication, storage and
  backend functions.
- **United States** — Google processes AI requests via the Gemini API. Sentry, where enabled, may
  process crash data outside the EU.

Transfers outside the European Economic Area rely on the European Commission's
Standard Contractual Clauses in our agreements with those providers.

If you are in Cameroon, note that your data is stored outside Cameroon, in
France, and that AI requests and crash reports are processed in the United
States.

Cameroonian law treats that as an international transfer. Under Article 32 of
Law No. 2024/017 of 23 December 2024, transferring personal data to a foreign
State or an international organisation requires prior authorisation from the
Autorité de protection des données à caractère personnel, which must satisfy
itself that the destination offers sufficient protection and that the parties
have signed the standard contractual clauses it issues.

That Authority is created by Article 53 of the same law, and Article 53(2)
leaves its creation, organisation and functioning to a decree of the President
of the Republic. At the effective date of this policy that decree has not been
published, so the Authority is not yet able to receive an application, publish
its standard clauses or grant the authorisation. We will apply for it as soon
as it can be applied for. Until then we rely on your consent, we transfer only
what the features you use require, and our agreements with Supabase, Google and
Sentry bind them to process the data solely on our instructions.

We will tell you in the app if this position changes.

## 9. Special protection for health data

Because Sanora handles health data, we apply the following in addition to
everything above:

- Row-level security on every personal table, verified by an isolation test
  that runs in our continuous integration pipeline on every change to the
  database schema.
- All traffic between the app, our backend and our processors is encrypted in
  transit with TLS.
- Data at rest is encrypted by our hosting provider.
- The Gemini API key exists only in the backend function environment. A copy of
  the app, decompiled, contains no key and cannot call Google directly.
- Crash reports are configured never to carry personal data.
- Meal photographs are never persisted on our servers.

## 10. How long we keep your data

- **Your health, profile, meal, habit, workout, reminder and coach data**: kept
  until you delete it, or until you delete your account. We do not apply an
  automatic expiry, because your history is the point of a health app — a
  two-year-old weight reading is what makes a trend meaningful.
- **Account records**: kept for as long as the account exists.
- **AI usage counters**: one row per account per day.
- **Crash reports**: retained according to our crash reporting provider's
  default retention period, typically 90 days.
- **On-device data**: stays on your device until you delete your account, use
  **Delete my data**, or uninstall the app.
- **Backups**: our hosting provider takes routine encrypted backups. Deleted
  data may persist in a backup for a short period before that backup rotates
  out, but it is not restored to the live system.

- **Subscription records**: the store transaction identifier and expiry date we
  use to know whether your account is Premium, kept while the account exists.
  We hold no billing record beyond that — Apple and Google take the payment,
  issue the invoice and keep the accounting record, each under their own
  retention rules.

## 11. Your rights, and how to use them

You have the right to access your data, to correct it, to erase it, to receive
it in a portable format, to restrict or object to processing, and to withdraw
consent. Some of these are built directly into the app.

### Access and correction

Everything Sanora holds about you is visible in the app: your profile, your
measurement history, your meals, your habits, your workouts and your coach
conversations. You can edit your profile and measurements at any time.

### Export

**Reports → share** generates a weekly health report as a PDF you can save or
send anywhere.

For a complete machine-readable export of everything in your account, contact
us at the privacy address in section 2. We will send it within 30 days, free of
charge.

### Erasure

Sanora has a real, in-app, self-service delete. Go to **You → Delete my data** and
confirm.

That runs, in this order:

1. A `delete_account` function inside our database, which first deletes any file
   stored under your account's folder in our meal photo storage bucket, then
   deletes your authentication record. Every table holding your data references
   that record with `on delete cascade`, so your profile, measurements, meals,
   habits, habit logs, coach messages, reminders, workouts, AI usage counters,
   subscription record, friendships, group memberships and challenge entries are
   all removed by the database in the same transaction.
2. Sign-out.
3. A wipe of the local database on your device.

The server side runs first on purpose: if it fails, you are told, and nothing is
wiped locally, so you are never left with a wiped phone and a live account.

This is irreversible. There is no recovery and no grace period. Export anything
you want to keep first.

### Complaints

If you believe we have handled your data improperly, please contact us first —
we would rather fix it. You also have the right to complain to a supervisory
authority, and contacting us first is not a precondition for doing so.

- **In Cameroon**, that is the Autorité de protection des données à caractère
  personnel, created by Article 53 of Law No. 2024/017 of 23 December 2024,
  which handles complaints from data subjects. As explained in section 8, the
  decree establishing it had not been published at this policy's effective
  date; Article 62 of the same law also lets you go directly to the competent
  court, including on an urgent basis, if your rights are seriously affected.
- **In the EEA or the UK**, the data protection authority of the country where
  you live or work.

## 12. Children

Sanora is intended for adults. It is not for anyone under 18, it is listed for
an adult audience in the app stores, and we do not knowingly collect data
from children. Sanora's calculations — BMI categories, calorie targets, body fat
estimates — are derived from formulas validated in adults and are not
appropriate for children or adolescents.

If you believe a child has created an account, contact us and we will delete it.

## 13. Automated decision-making

Sanora calculates scores and targets automatically, and the AI coach generates
personalised suggestions. None of this produces a legal or similarly significant
effect on you within the meaning of GDPR Art. 22: nothing here decides your
access to credit, employment, insurance, care or any service. It is
informational guidance you are free to ignore, and it is not medical advice.

## 14. Changes to this policy

If we change how we handle your data in a way that materially affects you, we
will notify you in the app before the change takes effect and update the
effective date above. Continuing to use Sanora after that means you accept the
updated policy.

## 15. Contact

- Privacy enquiries and data requests: ndjockjunior@gmail.com
- Postal address: available on request to the address above
- Online version of this policy: https://micheduc25.github.io/Sanora/privacy/
- Request account deletion: https://micheduc25.github.io/Sanora/delete-account/
