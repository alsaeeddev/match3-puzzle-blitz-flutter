import 'package:flutter/foundation.dart';

// Product representation available in the game store.
@immutable
class IapProduct {
  final String id;
  final String title;
  final String description;
  final String price;

  const IapProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IapProduct &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, title, description, price);

  @override
  String toString() => 'IapProduct($id, $title, $price)';
}

// Sealed hierarchy of transaction status updates.
sealed class PurchaseUpdate {
  const PurchaseUpdate();
}

// Successful purchase transaction.
final class PurchaseSuccess extends PurchaseUpdate {
  final String productId;
  const PurchaseSuccess(this.productId);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseSuccess &&
          runtimeType == other.runtimeType &&
          productId == other.productId;

  @override
  int get hashCode => productId.hashCode;

  @override
  String toString() => 'PurchaseSuccess($productId)';
}

// Transaction failure.
final class PurchaseFailed extends PurchaseUpdate {
  final String productId;
  final String error;
  const PurchaseFailed(this.productId, this.error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseFailed &&
          runtimeType == other.runtimeType &&
          productId == other.productId &&
          error == other.error;

  @override
  int get hashCode => Object.hash(productId, error);

  @override
  String toString() => 'PurchaseFailed($productId, error: $error)';
}

// Restored previous non-consumable transactions.
final class PurchaseRestored extends PurchaseUpdate {
  final List<String> productIds;
  const PurchaseRestored(this.productIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseRestored &&
          runtimeType == other.runtimeType &&
          listEquals(productIds, other.productIds);

  @override
  int get hashCode => Object.hashAll(productIds);

  @override
  String toString() => 'PurchaseRestored($productIds)';
}

// Abstract interface for In-App Purchases and store transactions.
abstract interface class IapService {
  // Initializes the in-app billing client.
  Future<void> init();

  // Queries all available products from the store.
  Future<List<IapProduct>> getProducts();

  // Initiates a purchase flow for the specified product.
  Future<bool> purchaseProduct(String productId);

  // Restores previous purchases (e.g. Remove Ads).
  Future<void> restorePurchases();

  // Stream of asynchronous purchase updates and transaction receipts.
  Stream<PurchaseUpdate> get purchaseUpdates;
}
