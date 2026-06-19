import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:http/http.dart' as http;
import 'package:spanx/core/local/local_data.dart';
import 'package:spanx/core/services/iap/purchase_processing_dialog.dart';

class PremiumService {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  final InAppPurchase iap = InAppPurchase.instance;

  // Allow dynamic product IDs
  late List<String> productIds = ['monthly'];

  StreamSubscription<List<PurchaseDetails>>? _sub;

  List<ProductDetails> products = [];
  ProductDetails? premiumProduct;

  Future<bool> init({
    required Future<void> Function({
      required bool isPremium,
      required String? expiryTime, // optional
    })
    onStatusFromServer,
    required String backendVerifyUrl,
    required String packageName,
    required String userId,
    List<String>? productIdList, // Allow custom product IDs
  }) async {
    // Set product IDs if provided
    if (productIdList != null && productIdList.isNotEmpty) {
      productIds = productIdList;
    }

    final available = await iap.isAvailable();
    if (!available) {
      log('IAP not available');
      return false;
    }

    // Only setup listener once
    if (_sub == null) {
      _sub = iap.purchaseStream.listen((purchases) async {
        for (final p in purchases) {
          if (p.status == PurchaseStatus.purchased ||
              p.status == PurchaseStatus.restored) {
            final shouldCompletePurchase = p.pendingCompletePurchase;
            final shouldShowProcessing =
                p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored;
            try {
              // Android token is typically carried here
              final tokenOrPayload = p.verificationData.serverVerificationData;

              final product = getProductById(p.productID);
              final amount = product?.rawPrice;

              final subscriptionStart =
                  _parseTransactionDate(p.transactionDate)?.toUtc() ??
                  DateTime.now().toUtc();
              final subscriptionEnd = _inferSubscriptionEnd(
                productId: p.productID,
                subscriptionStart: subscriptionStart,
              );

              log("======== Data from Play Store ========");
              log("Product ID: ${p.productID}");
              log("Token: ${_maskToken(tokenOrPayload)}");
              log("Purchase ID: ${p.purchaseID}");
              log("Purchase Status: ${p.status}");
              log("Transaction Date: ${p.transactionDate}");

              if (shouldShowProcessing) {
                // Show during backend verification. Avoid stacking multiple dialogs.
                if (Get.isDialogOpen != true) {
                  // Not awaited on purpose; it will remain open until `hide()`.
                  PurchaseProcessingDialog.show();
                }
              }

              final result = await _verifyWithBackend(
                url: backendVerifyUrl,
                userId: userId,
                packageName: packageName,
                productId: p.productID,
                token: tokenOrPayload,
                // New payload keys (requested)
                subscriptionId: p.productID,
                amount: amount,
                planPurchaseToken: tokenOrPayload,
                platform: Platform.isIOS ? 'ios' : 'android',
                subscriptionStart: subscriptionStart,
                subscriptionEnd: subscriptionEnd,
              );

              await onStatusFromServer(
                isPremium: result.isPremium,
                expiryTime: result.expiryTime,
              );
            } catch (e, st) {
              log('Error verifying purchase: $e\n$st');
              // Let controller decide what to show; you can pass error callback if needed
            } finally {
              if (shouldShowProcessing) {
                PurchaseProcessingDialog.hide();
              }
              // Acknowledge/finish (important on Play). Keep this outside verification so
              // temporary backend/network errors don't leave the purchase stuck.
              if (shouldCompletePurchase) {
                try {
                  await iap.completePurchase(p);
                } catch (e, st) {
                  log('Error completing purchase: $e\n$st');
                }
              }
            }
          } else if (p.status == PurchaseStatus.error) {
            log('Purchase error: ${p.error}');
          } else if (p.status == PurchaseStatus.pending) {
            log('Purchase pending: ${p.productID}');
          }
        }
      });
    }

    // Always query products
    try {
      final resp = await iap.queryProductDetails(productIds.toSet());
      if (resp.productDetails.isNotEmpty) {
        products = resp.productDetails;
        premiumProduct = resp.productDetails.first;
        log('✓ Loaded ${products.length} products from Play Store');
        for (var product in products) {
          log('  - ${product.id}: ${product.title} (${product.price})');
        }
      } else {
        log('✗ No products found. Check product IDs: $productIds');
        return false;
      }
    } catch (e) {
      log('Error querying products: $e');
      return false;
    }

    // Handle any pending purchases from previous sessions (iOS)
    try {
      await iap.restorePurchases();
    } catch (e) {
      log('Error restoring purchases: $e');
    }

    return true;
  }

  Future<void> buyPremium() async {
    if (premiumProduct == null) throw Exception("Product not loaded");
    try {
      final param = PurchaseParam(productDetails: premiumProduct!);
      await iap.buyNonConsumable(purchaseParam: param);
    } catch (e) {
      log('Error initiating purchase: $e');
      rethrow;
    }
  }

  /// Get list of available product IDs (for debugging)
  List<ProductDetails> getAvailableProducts() => products;

  /// Get product by ID
  ProductDetails? getProductById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> restore() async => iap.restorePurchases();

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  Future<_VerifyResult> _verifyWithBackend({
    required String url,
    required String userId,
    required String packageName,
    required String productId,
    required String token,
    double? amount,
    String? subscriptionId,
    String? planPurchaseToken,
    String? platform,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
  }) async {
    final authToken = await LocalService().getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      // Backend expects raw token (not "Bearer <token>")
      if (authToken != null && authToken.isNotEmpty) 'Authorization': authToken,
    };

    final resp = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        // New keys (as requested by client payload)
        "subscriptionId": subscriptionId ?? productId,
        "amount": amount,
        "planPurchaseToken": planPurchaseToken ?? token,
        "platform": platform,
        "subscriptionStart": subscriptionStart?.toUtc().toIso8601String(),
        "subscriptionEnd": subscriptionEnd?.toUtc().toIso8601String(),

        // // Existing keys (backward compatible)
        // "userId": userId,
        // "packageName": packageName,
        // "productId": productId,
        // "purchaseToken": token,
      }),
    );

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw Exception("Verify failed: ${resp.statusCode} ${resp.body}");
    }

    final json = jsonDecode(resp.body) as Map<String, dynamic>;

    // Expected backend response example:
    // {"success":true,"message":"...","data":{"subscriptionEnd":"..."}}
    final success = json["success"] == true;
    final data = json["data"];
    final expiryTime = (data is Map)
        ? (data["subscriptionEnd"] ??
                  data["expiryTime"] ??
                  data["expiresAt"] ??
                  data["expiry"])
              ?.toString()
        : null;

    return _VerifyResult(isPremium: success, expiryTime: expiryTime);
  }

  DateTime? _parseTransactionDate(String? transactionDate) {
    if (transactionDate == null || transactionDate.isEmpty) return null;
    final ms = int.tryParse(transactionDate);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
  }

  DateTime? _inferSubscriptionEnd({
    required String productId,
    required DateTime subscriptionStart,
  }) {
    final days = _inferDurationDays(productId);
    if (days == null) return null;
    return subscriptionStart.add(Duration(days: days));
  }

  int? _inferDurationDays(String productId) {
    final id = productId.toLowerCase();
    if (id.contains('year')) return 365;
    if (id.contains('annual')) return 365;
    if (id.contains('month')) return 30;
    if (id.contains('weekly') || id.contains('week')) return 7;
    if (id.contains('daily') || id.contains('day')) return 1;
    return null;
  }

  String _maskToken(String v) {
    if (v.length <= 14) return '***';
    final head = v.substring(0, 6);
    final tail = v.substring(v.length - 4);
    return '$head...$tail';
  }
}

class _VerifyResult {
  final bool isPremium;
  final String? expiryTime;
  _VerifyResult({required this.isPremium, required this.expiryTime});
}
