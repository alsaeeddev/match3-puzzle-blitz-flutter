import 'dart:async';
import 'package:flutter/foundation.dart';
import 'iap_service.dart';

// Stub implementation of [IapService] providing offline/testing catalog
// and simulated checkout flows.
class StubIapService implements IapService {
  final StreamController<PurchaseUpdate> _purchaseController =
      StreamController<PurchaseUpdate>.broadcast();

  static const List<IapProduct> _stubProducts = [
    IapProduct(
      id: 'remove_ads',
      title: 'Remove Ads',
      description: 'Remove all banners and interstitial ads permanently',
      price: '\$2.99',
    ),
    IapProduct(
      id: 'booster_pack_1',
      title: 'Starter Pack',
      description: '3 Hammers and 2 Shuffles to boost your game',
      price: '\$0.99',
    ),
    IapProduct(
      id: 'booster_pack_2',
      title: 'Pro Puzzler Pack',
      description: '5 Hammers, 5 Shuffles, and 3 Extra Moves',
      price: '\$2.99',
    ),
    IapProduct(
      id: 'booster_pack_3',
      title: 'Ultimate Blitz Bundle',
      description: '10 of every booster and unlimited lives for 2 hours',
      price: '\$4.99',
    ),
  ];

  @override
  Stream<PurchaseUpdate> get purchaseUpdates => _purchaseController.stream;

  @override
  Future<void> init() async {
    debugPrint('[StubIapService] Initialized stub IAP service');
  }

  @override
  Future<List<IapProduct>> getProducts() async {
    return _stubProducts;
  }

  @override
  Future<bool> purchaseProduct(String productId) async {
    debugPrint(
      '[StubIapService] purchaseProduct called for $productId (stub always returns false)',
    );
    _purchaseController.add(
      PurchaseFailed(productId, 'Purchases disabled in stub mode'),
    );
    return false;
  }

  @override
  Future<void> restorePurchases() async {
    debugPrint('[StubIapService] restorePurchases called (no-op in stub mode)');
    _purchaseController.add(const PurchaseRestored([]));
  }

  void dispose() {
    _purchaseController.close();
  }
}
