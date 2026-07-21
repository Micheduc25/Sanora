import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'premium_products.dart';
import 'purchase_service.dart';

/// Why nothing can be bought on this device, or [none] when it can.
///
/// The controller has no `BuildContext`, so it names the situation and the
/// paywall says it in the reader's language.
enum PremiumUnavailable {
  none,

  /// Web or desktop: neither store has an implementation here.
  unsupportedPlatform,

  /// The store itself is unreachable or signed out.
  storeUnavailable,

  /// `queryProductDetails` failed; the store's own words are in
  /// [PremiumState.unavailableDetail].
  planQueryFailed,

  /// The store answered, but knows nothing about the Sanora plans.
  noPlans,
}

/// The last thing that happened, or [none] when there is nothing to say.
enum PremiumNotice {
  none,

  /// The store refused to open the purchase sheet.
  purchaseNotStarted,

  /// A restore is in flight.
  lookingForPurchases,

  /// The restore call never reached the store.
  restoreUnreachable,

  /// The restore finished and found nothing to restore.
  noSubscription,

  /// The store is still settling the payment.
  awaitingPayment,

  /// The receipt is with the server.
  checkingPurchase,

  /// The store gave up on the purchase without saying why.
  purchaseNotCompleted,

  /// The receipt was rejected.
  purchaseNotConfirmed,

  /// Premium needs an account, and there is none signed in.
  signInRequired,

  /// A purchase arrived without a receipt to verify.
  noReceipt,

  /// The receipt could not reach Sanora. Nothing is lost.
  verificationOffline,

  /// The session expired mid-verification.
  sessionExpired,

  /// The store or server explained itself — [PremiumState.noticeDetail] holds
  /// its own words, which are shown verbatim.
  storeMessage,
}

class PremiumState {
  const PremiumState({
    this.loading = true,
    this.busy = false,
    this.products = const [],
    this.unavailable = PremiumUnavailable.none,
    this.unavailableDetail = '',
    this.notice = PremiumNotice.none,
    this.noticeDetail = '',
    this.premium = false,
    this.validUntil,
  });

  /// The opening store round trip is still in flight.
  final bool loading;

  /// A purchase, restore or verification is in flight.
  final bool busy;

  final List<ProductDetails> products;

  /// Why nothing can be bought here, or [PremiumUnavailable.none] when it can.
  final PremiumUnavailable unavailable;

  /// The store's own explanation, when [unavailable] carries one.
  final String unavailableDetail;

  /// The last thing that happened — pending payment, a store error, the result
  /// of a restore.
  final PremiumNotice notice;

  /// The store's or server's own words, when [notice] carries them.
  final String noticeDetail;

  final bool premium;
  final DateTime? validUntil;

  PremiumState copyWith({
    bool? loading,
    bool? busy,
    List<ProductDetails>? products,
    PremiumUnavailable? unavailable,
    String? unavailableDetail,
    PremiumNotice? notice,
    String? noticeDetail,
    bool? premium,
    DateTime? validUntil,
  }) => PremiumState(
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    products: products ?? this.products,
    unavailable: unavailable ?? this.unavailable,
    unavailableDetail: unavailableDetail ?? this.unavailableDetail,
    notice: notice ?? this.notice,
    noticeDetail: noticeDetail ?? this.noticeDetail,
    premium: premium ?? this.premium,
    validUntil: validUntil ?? this.validUntil,
  );
}

class PremiumController extends Notifier<PremiumState> {
  /// Set when the purchase stream delivers something during a restore, so
  /// [restore] knows whether the stream already owns the outcome.
  bool _sawPurchase = false;

  @override
  PremiumState build() {
    final service = ref.watch(purchaseServiceProvider);
    if (PurchaseService.isSupportedPlatform) {
      // Subscribed before the first query so a transaction the store replays
      // at launch — an interrupted purchase from a previous session — is not
      // dropped on the floor.
      final subscription = service.purchaseStream.listen(_onStoreUpdate);
      ref.onDispose(subscription.cancel);
    }
    // Nothing may write `state` until `build` has returned.
    Future.microtask(refresh);
    return const PremiumState();
  }

  Future<void> refresh() async {
    final service = ref.read(purchaseServiceProvider);
    state = state.copyWith(loading: true);

    final entitlement = await service.current();
    state = state.copyWith(
      premium: entitlement.premium,
      validUntil: entitlement.validUntil,
    );

    if (!PurchaseService.isSupportedPlatform) {
      state = state.copyWith(
        loading: false,
        unavailable: PremiumUnavailable.unsupportedPlatform,
        unavailableDetail: '',
      );
      return;
    }

    if (!await service.isStoreAvailable()) {
      state = state.copyWith(
        loading: false,
        unavailable: PremiumUnavailable.storeUnavailable,
        unavailableDetail: '',
      );
      return;
    }

    final response = await service.queryProducts();
    if (response.error != null) {
      state = state.copyWith(
        loading: false,
        unavailable: PremiumUnavailable.planQueryFailed,
        unavailableDetail: response.error!.message,
      );
      return;
    }
    if (response.productDetails.isEmpty) {
      state = state.copyWith(
        loading: false,
        unavailable: PremiumUnavailable.noPlans,
        unavailableDetail: '',
      );
      return;
    }

    // Monthly first, then yearly; anything unrecognised sorts last.
    final order = PremiumProducts.ids.toList();
    final products = [...response.productDetails]
      ..sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));

    state = state.copyWith(
      loading: false,
      products: products,
      unavailable: PremiumUnavailable.none,
      unavailableDetail: '',
    );
  }

  Future<void> buy(ProductDetails product) async {
    if (state.busy) return;
    state = state.copyWith(
      busy: true,
      notice: PremiumNotice.none,
      noticeDetail: '',
    );
    try {
      final started = await ref.read(purchaseServiceProvider).buy(product);
      if (!started) {
        state = state.copyWith(
          busy: false,
          notice: PremiumNotice.purchaseNotStarted,
          noticeDetail: '',
        );
      }
    } catch (e) {
      state = state.copyWith(
        busy: false,
        notice: PremiumNotice.purchaseNotStarted,
        noticeDetail: '$e',
      );
    }
  }

  Future<void> restore() async {
    if (state.busy) return;
    _sawPurchase = false;
    state = state.copyWith(
      busy: true,
      notice: PremiumNotice.lookingForPurchases,
      noticeDetail: '',
    );
    try {
      await ref.read(purchaseServiceProvider).restore();
    } catch (_) {
      state = state.copyWith(
        busy: false,
        notice: PremiumNotice.restoreUnreachable,
        noticeDetail: '',
      );
      return;
    }
    // Restored purchases arrive on the stream, not from that call. If one did,
    // the stream handler owns what the screen says next.
    if (_sawPurchase) return;
    state = state.copyWith(
      busy: false,
      notice: PremiumNotice.noSubscription,
      noticeDetail: '',
    );
  }

  Future<void> _onStoreUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      var deliverable = false;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          state = state.copyWith(
            busy: true,
            notice: PremiumNotice.awaitingPayment,
            noticeDetail: '',
          );
        case PurchaseStatus.canceled:
          state = state.copyWith(
            busy: false,
            notice: PremiumNotice.none,
            noticeDetail: '',
          );
        case PurchaseStatus.error:
          final message = purchase.error?.message;
          state = state.copyWith(
            busy: false,
            notice: message == null
                ? PremiumNotice.purchaseNotCompleted
                : PremiumNotice.storeMessage,
            noticeDetail: message ?? '',
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _sawPurchase = true;
          deliverable = await _verify(purchase);
      }

      // Finishing a transaction tells the store it was delivered. Errors and
      // cancellations are finished unconditionally — there is nothing to
      // deliver and leaving them queued blocks the next attempt. A paid
      // transaction is only finished once the server has actually granted
      // Premium; if verification failed, leaving it unfinished is what makes
      // the store replay it on the next launch instead of the user paying for
      // nothing.
      final settled =
          purchase.status == PurchaseStatus.error ||
          purchase.status == PurchaseStatus.canceled;
      if (purchase.pendingCompletePurchase && (deliverable || settled)) {
        await ref.read(purchaseServiceProvider).complete(purchase);
      }
    }
  }

  Future<bool> _verify(PurchaseDetails purchase) async {
    state = state.copyWith(
      busy: true,
      notice: PremiumNotice.checkingPurchase,
      noticeDetail: '',
    );
    try {
      final entitlement = await ref
          .read(purchaseServiceProvider)
          .verify(purchase);
      state = state.copyWith(
        busy: false,
        premium: entitlement.premium,
        validUntil: entitlement.validUntil,
        notice: entitlement.premium
            ? PremiumNotice.none
            : PremiumNotice.purchaseNotConfirmed,
        noticeDetail: '',
      );
      return entitlement.premium;
    } on PurchaseFailure catch (f) {
      state = state.copyWith(
        busy: false,
        notice: switch (f.reason) {
          PurchaseErrorReason.signedOut => PremiumNotice.signInRequired,
          PurchaseErrorReason.noReceipt => PremiumNotice.noReceipt,
          PurchaseErrorReason.network => PremiumNotice.verificationOffline,
          PurchaseErrorReason.sessionExpired => PremiumNotice.sessionExpired,
          PurchaseErrorReason.notConfirmed =>
            PremiumNotice.purchaseNotConfirmed,
          PurchaseErrorReason.serverMessage => PremiumNotice.storeMessage,
        },
        noticeDetail: f.detail,
      );
      return false;
    }
  }
}

final premiumControllerProvider =
    NotifierProvider<PremiumController, PremiumState>(PremiumController.new);
