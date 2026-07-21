/// The store product identifiers behind Bodi Premium.
///
/// Nothing in this repository creates these products. They have to exist,
/// under exactly these ids, in both stores before the paywall can sell
/// anything:
///
/// * **App Store Connect** → your app → Subscriptions → one subscription
///   group containing two auto-renewable subscriptions with Product IDs
///   [monthly] and [yearly].
/// * **Google Play Console** → Monetise → Subscriptions → two subscriptions
///   with the same two product ids, each with an active base plan, and a
///   build uploaded to at least the internal test track.
///
/// Until then the stores answer `queryProductDetails` with these ids in
/// `notFoundIDs`, and the paywall says so instead of pretending to sell.
///
/// The same list is duplicated in `supabase/functions/verify-purchase/
/// index.ts` — a receipt for anything else is not a Premium receipt.
abstract final class PremiumProducts {
  static const monthly = 'bodi_premium_monthly';
  static const yearly = 'bodi_premium_yearly';

  static const ids = {monthly, yearly};

  /// Mirrors `FREE_DAILY_AI_CALLS` in `supabase/functions/_shared/mod.ts`.
  /// The server is the authority; this copy is only what the paywall says out
  /// loud, so it has to keep matching.
  static const freeDailyAiCalls = 20;
}
