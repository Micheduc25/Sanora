import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/app_providers.dart';
import '../../data/supabase_service.dart';
import 'premium_products.dart';

/// What the server says this account is entitled to.
class Entitlement {
  const Entitlement({required this.premium, this.validUntil});

  const Entitlement.free() : premium = false, validUntil = null;

  final bool premium;
  final DateTime? validUntil;
}

/// Why a receipt could not be turned into an entitlement.
///
/// A reason rather than a sentence: the copy lives in the ARB files and is
/// resolved where a `BuildContext` exists, so the message reaches the user in
/// their own language.
enum PurchaseErrorReason {
  /// Nobody is signed in, so there is no account to attach Premium to.
  signedOut,

  /// The store handed over a purchase with no receipt to verify.
  noReceipt,

  /// Sanora could not be reached; the purchase is still safe with the store.
  network,

  /// The session expired mid-verification.
  sessionExpired,

  /// The server refused the receipt.
  notConfirmed,

  /// The server explained itself — [PurchaseFailure.detail] is its own words.
  serverMessage,
}

class PurchaseFailure implements Exception {
  const PurchaseFailure(this.reason, [this.detail = '']);

  final PurchaseErrorReason reason;

  /// Text from the server, already meant for a human. Empty unless [reason] is
  /// [PurchaseErrorReason.serverMessage].
  final String detail;

  @override
  String toString() => 'PurchaseFailure($reason, $detail)';
}

/// The store side of Premium: `in_app_purchase` plus the `verify-purchase`
/// edge function.
///
/// Nothing here decides that someone is premium. The store hands us a receipt,
/// the edge function checks it with Apple or Google and writes the
/// `subscriptions` row, and the app reads that row back. A device that cannot
/// reach the server stays on the free tier rather than optimistically
/// unlocking — the AI allowance is metered server-side anyway, so a local
/// "yes" would buy nothing but a lie in the UI.
class PurchaseService {
  PurchaseService(this._supabase);

  final SupabaseService _supabase;

  /// `in_app_purchase` only registers a platform implementation on iOS, macOS
  /// and Android. Sanora also builds for web, where touching
  /// `InAppPurchase.instance` throws a `LateInitializationError` rather than
  /// returning something empty — so every entry point checks this first.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS ||
      TargetPlatform.macOS ||
      TargetPlatform.android => true,
      _ => false,
    };
  }

  static String get _platformKey =>
      defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';

  Stream<List<PurchaseDetails>> get purchaseStream => isSupportedPlatform
      ? InAppPurchase.instance.purchaseStream
      : const Stream.empty();

  Future<bool> isStoreAvailable() async =>
      isSupportedPlatform && await InAppPurchase.instance.isAvailable();

  Future<ProductDetailsResponse> queryProducts() =>
      InAppPurchase.instance.queryProductDetails(PremiumProducts.ids);

  /// Auto-renewing subscriptions are non-consumables as far as this plugin is
  /// concerned. Returns whether the store accepted the request; the outcome
  /// arrives on [purchaseStream].
  Future<bool> buy(ProductDetails product) => InAppPurchase.instance
      .buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));

  Future<void> restore() => InAppPurchase.instance.restorePurchases();

  Future<void> complete(PurchaseDetails purchase) =>
      InAppPurchase.instance.completePurchase(purchase);

  /// Sends one receipt to `verify-purchase` and returns what the server
  /// granted. Throws a [PurchaseFailure] — it never returns a premium
  /// entitlement it did not hear from the server.
  Future<Entitlement> verify(PurchaseDetails purchase) async {
    final client = _supabase.client;
    if (client == null || !_supabase.isSignedIn) {
      throw const PurchaseFailure(PurchaseErrorReason.signedOut);
    }

    final receipt = purchase.verificationData.serverVerificationData;
    if (receipt.isEmpty) {
      throw const PurchaseFailure(PurchaseErrorReason.noReceipt);
    }

    try {
      final response = await client.functions.invoke(
        'verify-purchase',
        body: {
          'platform': _platformKey,
          'product_id': purchase.productID,
          'transaction_id': purchase.purchaseID,
          'receipt': receipt,
        },
      );
      final data = response.data;
      if (data is! Map) {
        throw const PurchaseFailure(PurchaseErrorReason.notConfirmed);
      }
      return Entitlement(
        premium: data['tier'] == 'premium',
        validUntil: DateTime.tryParse(data['valid_until'] as String? ?? ''),
      );
    } on FunctionException catch (e) {
      throw _translate(e);
    } on PurchaseFailure {
      rethrow;
    } catch (_) {
      throw const PurchaseFailure(PurchaseErrorReason.network);
    }
  }

  /// The subscription row as the server currently sees it. RLS restricts this
  /// to the caller's own row.
  Future<Entitlement> current() async {
    final client = _supabase.client;
    final userId = _supabase.userId;
    if (client == null || userId == null) return const Entitlement.free();

    try {
      final row = await client
          .from('subscriptions')
          .select('tier, valid_until')
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return const Entitlement.free();
      final validUntil = DateTime.tryParse(row['valid_until'] as String? ?? '');
      final active = validUntil == null || validUntil.isAfter(DateTime.now());
      return Entitlement(
        premium: row['tier'] == 'premium' && active,
        validUntil: validUntil,
      );
    } catch (_) {
      // Offline or signed out mid-flight: absence of proof is not proof of
      // premium.
      return const Entitlement.free();
    }
  }

  /// The edge functions answer errors as `{"error": "..."}`.
  PurchaseFailure _translate(FunctionException e) {
    final details = e.details;
    final message = details is Map && details['error'] is String
        ? details['error'] as String
        : null;
    if (message != null) {
      return PurchaseFailure(PurchaseErrorReason.serverMessage, message);
    }
    return switch (e.status) {
      401 || 403 => const PurchaseFailure(PurchaseErrorReason.sessionExpired),
      _ => const PurchaseFailure(PurchaseErrorReason.notConfirmed),
    };
  }
}

final purchaseServiceProvider = Provider(
  (ref) => PurchaseService(ref.watch(supabaseServiceProvider)),
);
