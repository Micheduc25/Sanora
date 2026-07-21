// GENERATED — DO NOT EDIT BY HAND.
//
// Verbatim copies of the Markdown sources in docs/legal/, which are the
// canonical documents. This file exists only because those documents are not
// bundled as Flutter assets, and because the app deliberately carries no
// Markdown rendering dependency.
//
// After editing any document in docs/legal/, regenerate this file:
//
//     python3 docs/legal/generate_legal_content.py
//
// An in-app policy that has drifted from the published one is a compliance
// problem, not a cosmetic one.
//
// Rendered by LegalScreen, which understands a small Markdown subset:
// `##` / `###` headings, `-` bullets, numbered lists, blank-line paragraph
// breaks, `**bold**` and backtick code spans. Keep new content within it.

abstract final class LegalContent {
  /// Mirrors docs/legal/privacy-policy.md.
  static const privacyPolicy = r'''
# Privacy Policy

**Sanora — Know Your Body**, published by Ndjock Michel Junior under the name
Innovation Cameroon.

- Effective date: 21 July 2026
- Applies to: Sanora mobile app version 1.0.0 and later

## 1. In short

Sanora is a personal health companion. It is built offline-first: you can use it
without an account, and in that case nothing you enter ever leaves your phone.

If you create an account, your health data is synchronised to our database so
you can recover it on a new device. That database is hosted in Ireland and every
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
database hosted in the **eu-west-1 (Ireland)** region. Supabase also
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
- **Ireland (eu-west-1)** — Supabase database, authentication, storage and
  backend functions.
- **United States** — Google processes AI requests via the Gemini API. Sentry, where enabled, may
  process crash data outside the EU.

Transfers outside the European Economic Area rely on the European Commission's
Standard Contractual Clauses in our agreements with those providers.

If you are in Cameroon, note that your data is stored outside Cameroon, in
Ireland, and that AI requests and crash reports are processed in the United
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
''';

  /// Mirrors docs/legal/terms-of-service.md.
  static const termsOfService = r'''
# Terms of Service

**Sanora — Know Your Body**, published by Ndjock Michel Junior under the name
Innovation Cameroon.

- Effective date: 21 July 2026
- Applies to: Sanora mobile app version 1.0.0 and later

## 1. Agreement

These Terms are a contract between you and Ndjock Michel Junior ("we", "us")
covering your use of the Sanora mobile application and its backend services (the
"Service"). By installing or using Sanora you accept them. If you do not accept
them, do not use the Service.

- Publisher: Ndjock Michel Junior, an individual developer based in Cameroon,
  publishing under the name Innovation Cameroon, which is not a separate legal
  entity
- Contact: ndjockjunior@gmail.com
- Postal address: available on request to the address above

Our Privacy Policy and our Health Disclaimer form part of these Terms. Read
them; the Health Disclaimer in particular sets out limits on what Sanora's
numbers mean.

## 2. What Sanora is, and what it is not

Sanora is a personal health and wellness companion. It records what you tell it,
estimates nutrition, computes targets and scores from published formulas, and
generates AI coaching, insights and workout suggestions.

Sanora is **not** a medical device, a diagnostic tool, a clinical decision support
system, or a substitute for a healthcare professional. It is not regulated as a
medical device and makes no diagnostic claim. Nothing in the Service is medical
advice. See the Health Disclaimer.

## 3. Eligibility

You must be at least 16 years old to use Sanora, and legally capable of entering
into this contract. If you use Sanora on behalf of an organisation, you confirm
you are authorised to bind it.

## 4. Your account

- You may use Sanora entirely offline without an account. An account is required
  for cloud sync, AI features and community features.
- You are responsible for keeping your password secure and for everything done
  through your account.
- Give us an email address you control and keep it current — it is how we reach
  you about your account and how you reset your password.
- Tell us promptly if you believe your account has been compromised.
- You may delete your account at any time from within the app. Deletion is
  immediate and irreversible.

## 5. Your data

You own the health data you put into Sanora. We do not claim any ownership of it.

You grant us only the licence we need to run the Service for you: to store your
data, synchronise it to your devices, compute derived values from it, and
transmit the parts described in the Privacy Policy to our AI provider so the
features you invoke can answer you. That licence ends when you delete your
account.

You are responsible for the accuracy of what you enter. Sanora's estimates are
only as good as the height, weight, measurements and meal descriptions you give
it.

## 6. Acceptable use

You agree not to:

- Use Sanora to diagnose, treat, cure or prevent any disease, or to make clinical
  decisions for yourself or anyone else.
- Use Sanora to provide health, nutrition or fitness advice to third parties as if
  it were professional advice.
- Enter another person's health data without their informed consent, or
  impersonate anyone.
- Attempt to access data belonging to another user, to circumvent row-level
  security, authentication, rate limiting or the AI usage allowance, or to probe
  or attack our infrastructure.
- Reverse-engineer, decompile or attempt to extract credentials or prompts from
  the app or our backend, except where that right cannot lawfully be excluded.
- Use automated means to access the Service, resell it, or use our AI features
  to build a competing product or to generate training data.
- Post or transmit content in community features that is unlawful, abusive,
  harassing, hateful, sexually explicit, or that promotes self-harm, disordered
  eating, unsafe extreme fasting or unsafe rapid weight loss.
- Use community names, group names or descriptions to advertise, spam, or make
  health claims about products or supplements.
- Overload or interfere with the Service, or use it in a way that disrupts other
  users.

We may suspend or terminate an account that breaches this section. Where the
breach is not serious and can be fixed, we will normally warn you first.

## 7. AI features

- AI output is generated by a large language model and can be wrong,
  incomplete, or confidently mistaken. Nutrition estimates from a photo are
  approximations, not measurements.
- Do not rely on AI output for anything that matters to your health without
  confirming it with a qualified professional.
- The AI coach is instructed to refer you to a healthcare professional for
  symptoms, medication changes and warning signs. Please follow that referral.
- AI features depend on a third-party provider and an internet connection. They
  may be unavailable, slow, or changed without notice. The rest of Sanora keeps
  working offline.

## 8. Free tier, Premium and payment

Sanora is free to install and use. Recording, calculations, targets, reminders,
reports and offline use are free and remain free.

AI features are metered:

- **Free** accounts get a daily allowance of AI requests. At the time of
  writing, that allowance is 20 AI requests per calendar day, counted across the
  coach, meal analysis, insight generation and workout generation. When it is
  exhausted, AI features return an upgrade prompt until the next day. Everything
  else keeps working.
- **Premium** accounts get unlimited AI requests for the duration of their
  subscription.

We may change the free allowance. If we reduce it materially, we will tell you
in the app before the change takes effect.

Subscription terms:

- Premium is sold as a **monthly** or a **yearly** auto-renewing subscription.
  The price and the currency are the ones shown on the purchase screen in the
  app before you confirm, which are set per country by the store and may change
  over time. That screen, at the moment you buy, is the price you pay.
- Payment is taken **only through Apple's In-App Purchase or Google Play
  Billing**, depending on where you installed Sanora. We never see or handle
  your card, bank account or mobile money details, and we do not offer any
  other payment channel.
- Subscriptions **renew automatically** at the end of each period unless you
  cancel at least 24 hours before it ends. You cancel in your Apple ID or
  Google Play account settings — not in Sanora, which cannot cancel a
  subscription for you. Cancelling stops the next renewal; the current period
  runs to its end.
- **Refunds** are handled by the store that took the payment, under its own
  policy, and we cannot issue one directly. If you believe you are entitled to
  a refund, contact Apple Support or Google Play Support; write to us as well
  and we will support a fair request.
- Where the law of your country gives you a statutory right to withdraw from a
  distance contract, that right applies and nothing here removes it.

Where a purchase is made through the Apple App Store or Google Play, that
store's terms govern the transaction, billing, renewal and refunds, and you
manage or cancel the subscription in that store's account settings rather than
in Sanora.

If your subscription lapses, your account reverts to the free tier. Your data is
not deleted and stays fully accessible; only the unlimited AI allowance stops.

## 9. Availability and changes

We aim to keep the Service available but we do not guarantee uninterrupted
service. We may modify, suspend or discontinue any feature. If we discontinue a
paid feature you have paid for, we will refund the unused portion.

Because Sanora is offline-first, an outage of our backend does not lock you out of
your own data: recording, viewing and calculating all keep working on the
device, and queued changes sync when connectivity returns.

## 10. Disclaimers

To the maximum extent permitted by law:

- The Service is provided "as is" and "as available", without warranties of any
  kind, express or implied, including merchantability, fitness for a particular
  purpose, accuracy and non-infringement.
- We do not warrant that Sanora's estimates, scores, targets or AI output are
  accurate, complete, current, or suitable for you personally.
- We do not warrant that the Service will be uninterrupted, error-free, or free
  of data loss. Keep your own copy of anything you cannot afford to lose; the
  weekly PDF report exists partly for this reason.
- We are not responsible for data read from Apple Health or Health Connect, for
  the accuracy of third-party food or nutrition data, or for the availability or
  output of our AI provider.

Nothing here excludes a warranty or right that cannot lawfully be excluded,
including mandatory consumer rights.

## 11. Limitation of liability

To the maximum extent permitted by law:

- We are not liable for any indirect, incidental, special, consequential,
  exemplary or punitive damages, or for loss of profit, revenue, data, goodwill
  or anticipated savings, arising from your use of the Service.
- Our total aggregate liability arising out of or relating to the Service is
  limited to the greater of the amount you paid for the Service in the twelve
  months before the event giving rise to the claim, or XAF 30,000.
- We are not liable for any decision you make about your diet, exercise,
  medication or medical care based on Sanora's output. That is the substance of
  the Health Disclaimer and it is a condition of using the Service.

Nothing in this section limits liability for death or personal injury caused by
our negligence, for fraud or fraudulent misrepresentation, or for any other
liability that cannot lawfully be limited.

A limitation of liability does not always survive contact with consumer
protection law. In Cameroon, Framework Law No. 2011/012 of 6 May 2011 on
consumer protection prohibits terms that unfairly restrict a consumer's rights,
and in the EEA and the UK similar rules apply. Where a limitation in this
section is not enforceable against you, it simply does not apply to you, and
the rest of these Terms stand.

## 12. Indemnity

You agree to indemnify us against claims arising from your breach of these
Terms, your misuse of the Service, your entry of another person's data without
their consent, or your use of Sanora to advise third parties.

## 13. Termination

You may stop using Sanora at any time and delete your account from within the app.

We may suspend or terminate your access if you materially breach these Terms, if
required by law, or if we discontinue the Service. Except where a breach makes
it inappropriate, we will give you reasonable notice and an opportunity to
export your data first.

Sections 5, 10, 11, 12 and 15 survive termination.

## 14. Changes to these Terms

We may update these Terms. Material changes will be notified in the app before
they take effect. Continuing to use Sanora after that means you accept them. If
you do not, delete your account.

## 15. Governing law and disputes

These Terms are governed by the law of the **Republic of Cameroon**, and the
competent courts of Cameroon have jurisdiction over any dispute arising from
them. That is where the publisher is established.

Two things this does not do:

- It does not take away rights you have where you live. If you are a consumer,
  the mandatory consumer protection rules of your country of residence continue
  to apply to you, and you keep any right they give you to bring proceedings
  before your local courts.
- It does not force you into court first. If something goes wrong, write to
  ndjockjunior@gmail.com. Most disputes about a health app are a
  misunderstanding or a bug, and both are cheaper to fix by e-mail.

There is no arbitration clause and no mandatory pre-litigation step in these
Terms.

## 16. General

- If any provision of these Terms is held unenforceable, the rest remain in
  force.
- Our failure to enforce a provision is not a waiver of it.
- You may not assign these Terms. We may assign them to a successor in
  connection with a merger, acquisition or sale of assets.
- These Terms, together with the Privacy Policy and the Health Disclaimer, are
  the entire agreement between us about the Service.

## 17. Contact

- Support and general enquiries: ndjockjunior@gmail.com
- Legal notices: ndjockjunior@gmail.com; postal address on request
- Online version of these Terms: https://micheduc25.github.io/Sanora/terms/
- Privacy Policy: https://micheduc25.github.io/Sanora/privacy/
''';

  /// Mirrors docs/legal/health-disclaimer.md.
  static const healthDisclaimer = r'''
# Health Disclaimer

**Sanora — Know Your Body**, published by Ndjock Michel Junior under the name
Innovation Cameroon.

- Effective date: 21 July 2026
- Applies to: Sanora mobile app version 1.0.0 and later

## 1. Read this first

Sanora is a wellness and self-tracking app. Everything it shows you — every score,
target, category and coaching message — is **informational guidance, not medical
advice**.

Sanora does not diagnose. It does not treat. It does not prescribe. It cannot
examine you, it cannot order a blood test, and it does not know anything about
you that you did not type in.

**Sanora is not a medical device** and is not certified, cleared or approved as
one by any regulator. No output should be read as a diagnosis or a clinical
finding.

**Always consult a qualified healthcare professional** before starting or
changing a diet, an exercise programme, a fasting regime, a supplement, or any
medication. Never delay seeking medical advice, or disregard advice you have
been given, because of something Sanora told you.

**If you have symptoms that worry you — chest pain, breathlessness, fainting,
severe or persistent pain, confusion, or any sudden change in your condition —
stop using the app for guidance and seek medical care immediately.** Sanora cannot
recognise an emergency and will not call anyone for you.

## 2. What Sanora calculates, and what those numbers actually are

Sanora computes the following from what you enter. Each is an estimate produced by
a published population-level formula. Population formulas describe averages;
they do not describe you.

**Body mass index (BMI) and BMI category.** Weight divided by height squared,
banded using WHO thresholds. BMI takes no account of muscle mass, bone density,
body composition or ethnicity. A muscular person is routinely classified
"overweight" by BMI, and the standard thresholds are known to perform
differently across ethnic groups, including African and South Asian populations.
Treat the category as a rough bucket, not a verdict.

**Estimated body fat percentage.** Estimated using Relative Fat Mass (Woolcott
and Bergman, 2018) when you have entered a waist measurement, and the Deurenberg
equation otherwise. This is an estimate from a tape measure and arithmetic, not
a DEXA scan, and individual error can be several percentage points. Accuracy
depends heavily on measuring your waist consistently and correctly.

**Basal metabolic rate (BMR) and total daily energy expenditure (TDEE).**
BMR uses Mifflin-St Jeor, or Katch-McArdle where a body fat percentage is known.
TDEE multiplies BMR by an activity factor you selected yourself. Real
individual metabolic rate commonly varies from these predictions by 10 percent
or more in either direction, and the activity multiplier is a self-assessment,
not a measurement.

**Calorie target.** Derived from your TDEE and your stated goal: a deficit of
20 percent capped at 500 kcal for fat loss, a surplus of 10 percent capped at
300 kcal for muscle gain, maintenance otherwise. A floor is applied — 1200 kcal
for women, 1500 kcal for men — so the app will not suggest a very-low-calorie
intake. Very-low-calorie diets can be appropriate in some clinical situations,
but only under medical supervision, and Sanora will not put you on one.

**Protein target.** 1.8 g per kg of reference body weight when you are losing
fat or building muscle, 1.2 g/kg otherwise, using the top of your healthy weight
range as the reference where your weight is above it. **If you have reduced
kidney function or any kidney disease, do not follow a protein target from this
app without speaking to your doctor.**

**Carbohydrate and fat targets.** Whatever the calorie budget has left once
protein is accounted for, split conventionally. These are not tailored to any
medical condition.

**Water target.** Roughly 35 ml per kg of body weight, bounded to a practical
1.5-4 litre range. **If you have heart failure, kidney disease, or have been
told to restrict your fluid intake, follow your clinician's instruction, not
this number.**

**Step goal, weekly exercise minutes and sleep goal.** Derived from your stated
activity level and goals, anchored on WHO general population guidance of 150-300
minutes of moderate activity per week. General population guidance is not an
exercise prescription for a person with a cardiac, joint, respiratory or
metabolic condition.

**Waist-to-height and waist-to-hip ratios, and the visceral fat risk band.**
Computed from measurements you took yourself, using WHO cut-offs. A "high" band
is a signal to discuss it with a clinician. It is not a diagnosis of visceral
adiposity or of any disease.

**Metabolic health score (0-100) and lifestyle risk score (0-100).** These are
Sanora's own composite indicators. They start from a baseline and apply weighted
adjustments for your BMI band, central adiposity, activity level, sleep hours,
stress level and any conditions you told us about. **They are not clinically
validated risk instruments.** They are not equivalent to, and must not be used
in place of, validated tools such as a cardiovascular risk calculator or a
diabetes risk score. Their purpose is to give you one number that moves in the
right direction when your habits improve — nothing more.

**Nutrition estimates from meals.** Calories and macronutrients from a photo or
a text description are AI estimates with a confidence score attached. Portion
size, cooking oil, preparation method and hidden ingredients are frequently
wrong. Do not use them to calculate a medication dose, to count carbohydrates
for insulin dosing, or to manage any condition where precise intake matters.

## 3. The AI coach

The coach is a large language model. It can be wrong, and it can be wrong
confidently and fluently. It has no clinical training, no licence, and no way to
verify anything you tell it.

It is instructed to refer you to a healthcare professional for symptoms,
medication changes and warning signs. Please act on that referral rather than
asking it to elaborate.

Do not ask the coach to interpret test results, adjust a medication, or tell you
whether a symptom is serious. It is not qualified to answer, and neither is the
app.

## 4. Speak to a clinician before using Sanora's targets if any of these apply

These are situations where a generic calorie, protein, water or exercise target
can cause real harm. This list is not exhaustive.

- **Pregnancy or breastfeeding.** Energy and nutrient requirements differ
  substantially and BMI categories do not apply. Sanora's targets are not
  designed for pregnancy and should not be followed during it.
- **An eating disorder, or any history of one.** Calorie targets, weight goals,
  body fat percentages and food logging can trigger or worsen anorexia, bulimia,
  binge eating disorder and orthorexia. If tracking numbers makes you feel
  worse, stop using those features and talk to someone — your doctor, a mental
  health professional, or someone close to you. If you are in immediate danger,
  go to the nearest hospital emergency department. We would rather you delete
  this app than use it to hurt yourself.
- **Diabetes, prediabetes, or any use of insulin or glucose-lowering
  medication.** Sanora's carbohydrate figures are estimates and are not safe for
  insulin dosing. Changing your intake or activity can change your glucose and
  your medication requirement.
- **Hypertension or any cardiovascular or cardiac condition.** Exercise
  intensity and sodium intake need individual medical guidance. Blood pressure
  values you log in Sanora are a record you keep, not a reading Sanora has verified
  or interpreted.
- **Kidney disease or reduced kidney function.** Protein and fluid targets can
  be actively harmful.
- **Liver disease, thyroid disease, or any other metabolic or endocrine
  condition.**
- **Any chronic illness, recent surgery, injury, or a condition that limits
  exercise.**
- **Any prescribed medication**, particularly where it interacts with food,
  fluid, weight or physical activity.
- **Anyone under 18.** Sanora's formulas are validated in adults. Adult BMI
  categories, calorie targets and body fat equations are not appropriate for
  children or adolescents, who need growth-chart-based assessment by a
  paediatric clinician.
- **Older adults**, where nutritional needs, sarcopenia and fall risk change the
  picture materially.

## 5. Data you record is a record, not a reading

When you log blood pressure, blood sugar, heart rate, weight, sleep, mood or a
symptom, Sanora stores what you typed. It does not measure it, verify it, or
interpret it clinically.

Data read from Apple Health or Health Connect comes from your device and its
sensors. Consumer wearables are not medical instruments; step counts, heart rate
and sleep staging from them are approximations.

Sanora does not monitor your data for danger. **It will not alert you, your
family, or any medical service if a value you enter is dangerous.** Do not use
Sanora as a safety net.

## 6. Your responsibility

By using Sanora you acknowledge that:

- You use its guidance at your own risk.
- You are responsible for decisions you make about your diet, exercise,
  medication and medical care.
- You will consult a qualified healthcare professional before acting on Sanora's
  output where your health or a medical condition is involved.
- Innovation Cameroon is not liable for outcomes arising from your reliance on
  the app's estimates, scores or AI output, to the extent permitted by law and
  as set out in the Terms of Service.

## 7. Questions

If something in Sanora does not seem right for your situation, trust your
clinician over the app.

- Contact: ndjockjunior@gmail.com
- Online version of this disclaimer: https://micheduc25.github.io/Sanora/health-disclaimer/
''';
}
