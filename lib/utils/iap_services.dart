// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:get/get.dart'; // Import Get for service locator
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics

import 'app_keys.dart';
import '../services/credit_service.dart'; // Import CreditService

class IapService {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  final CreditService _creditService = Get.find<CreditService>(); // Get CreditService instance

  List<PurchaseDetails> purchases = <PurchaseDetails>[];
  List<ProductDetails> availableProducts = <ProductDetails>[];

  bool purchasePending = false;
  // autoConsume is set to true in buyConsumable, which is the plugin's default for Play Store.
  // For iOS, purchases are non-consumable by default and finishTransaction makes them available again.
  // The plugin abstracts this.

  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Future<List<ProductDetails>> initStoreInfo({
    required List<String> productIDsToQuery,
  }) async {
    bool isPlatformAvailable = await _inAppPurchase.isAvailable();
    log("IAP Service: Platform available: $isPlatformAvailable");

    if (!isPlatformAvailable) {
      availableProducts = [];
      return [];
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    log("IAP Service: Querying product details for IDs: ${productIDsToQuery.join(', ')}");
    try {
      final ProductDetailsResponse productDetailsResponse =
          await _inAppPurchase.queryProductDetails(productIDsToQuery.toSet());

      if (productDetailsResponse.productDetails.isNotEmpty) {
        availableProducts = productDetailsResponse.productDetails;
        for (var pd in availableProducts) {
          log('IAP Service: Found product: ${pd.id} - ${pd.title} - ${pd.description} - ${pd.price}');
        }
      } else {
        availableProducts = [];
        log('IAP Service: No product details found for IDs: ${productIDsToQuery.join(', ')}');
      }

      if (productDetailsResponse.notFoundIDs.isNotEmpty) {
        log('IAP Service: Not found IDs: ${productDetailsResponse.notFoundIDs.join(', ')}');
      }
      if (productDetailsResponse.error != null) {
        log('IAP Service: Error querying products: ${productDetailsResponse.error!.code} - ${productDetailsResponse.error!.message}');
        availableProducts = [];
      }
    } catch (e) {
      log('IAP Service: Generic error querying products: $e');
      availableProducts = [];
    }

    log("IAP Service: Returning ${availableProducts.length} available products.");
    return availableProducts;
  }

  List<ProductDetails> getFetchedProducts() {
    return availableProducts;
  }

  void initializeListeners() {
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      (List<PurchaseDetails> purchaseDetailsList) {
        _handlePurchaseUpdates(purchaseDetailsList);
      },
      onDone: () {
        log("IAP Service: Purchase stream completed.");
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        log("IAP Service: Error on purchase stream: $error");
      },
    );
  }

  Future<void> buyCreditPack(ProductDetails productDetails) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    try {
      // For consumable products, buyConsumable is appropriate.
      // autoConsume is true by default for Play Store. For iOS, this is like a non-consumable
      // that then gets completed. The plugin handles the platform differences.
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam, autoConsume: true);
      log("IAP Service: buyConsumable call initiated for ${productDetails.id}");
    } catch (e) {
      log("IAP Service: Error on buyConsumable call: $e");
      // Handle error, e.g., show a message to the user
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (PurchaseDetails purchaseDetails in purchaseDetailsList) {
      log("IAP Service: Processing purchase update for ${purchaseDetails.productID}, status: ${purchaseDetails.status}");

      if (purchaseDetails.status == PurchaseStatus.purchased) {
        log("IAP Service: Purchase successful for ${purchaseDetails.productID}");
        log("IAP Service: Purchase ID: ${purchaseDetails.purchaseID}");
        log("IAP Service: Server Verification Data: ${purchaseDetails.verificationData.serverVerificationData}");

        // Client-side validation is assumed here.
        // For robust validation, `purchaseDetails.verificationData.serverVerificationData`
        // should be sent to your server for validation with App Store/Play Store server APIs.

        double creditsToGrant = 0;
        // Determine credits based on product ID
        switch (purchaseDetails.productID) {
          case credits5GooglePlay:
          case credits5IOS: // Added iOS product IDs
          case credits5Amazon:
            creditsToGrant = 5.0;
            break;
          case credits10GooglePlay:
          case credits10IOS: // Added iOS product IDs
          case credits10Amazon:
            creditsToGrant = 10.0;
            break;
          case credits20GooglePlay:
          case credits20IOS: // Added iOS product IDs
          case credits20Amazon:
            creditsToGrant = 20.0;
            break;
          default:
            log("IAP Service: Unknown product ID purchased: ${purchaseDetails.productID}");
            // Handle unknown product ID, maybe show an error or log extensively.
            break;
        }

        if (creditsToGrant > 0) {
          // Log analytics event BEFORE granting credits
          ProductDetails? purchasedProductDetails = availableProducts.firstWhereOrNull(
            (pd) => pd.id == purchaseDetails.productID
          );

          FirebaseAnalytics.instance.logEvent(
            name: 'credit_pack_purchased',
            parameters: {
              'product_id': purchaseDetails.productID,
              'price': purchasedProductDetails?.price ?? 'unknown',
              'currency': purchasedProductDetails?.currencyCode ?? 'unknown',
              'credits_awarded': creditsToGrant,
              'user_id': _creditService.currentUserCredit.value?.userId ?? 'unknown_user',
            },
          );
          log("IAP Service: Logged credit_pack_purchased event for ${purchaseDetails.productID}.");

          bool creditsAdded = await _creditService.addCredits(creditsToGrant);
          if (creditsAdded) {
            log("IAP Service: Successfully granted $creditsToGrant credits to user for product ${purchaseDetails.productID}.");
          } else {
            log("IAP Service: Failed to grant $creditsToGrant credits for product ${purchaseDetails.productID}. User might not be logged in or another issue occurred.");
            // This is a critical issue: purchase was made but credits not granted.
            // Implement retry logic or manual adjustment process.
          }
        }

        // Complete the purchase. This is crucial for all platforms.
        // For Android, if autoConsume:true was used with buyConsumable, this also consumes it.
        // For iOS, this finishes the transaction.
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
          log("IAP Service: Purchase completed in Firestore for ${purchaseDetails.productID}.");
        } else {
           log("IAP Service: Purchase for ${purchaseDetails.productID} did not require explicit completion call (pendingCompletePurchase was false).");
        }

      } else if (purchaseDetails.status == PurchaseStatus.error) {
        log("IAP Service: Purchase error for ${purchaseDetails.productID}: ${purchaseDetails.error?.message}");
        // Show error to user (e.g., via a GetX controller state update or a callback)
      } else if (purchaseDetails.status == PurchaseStatus.canceled) {
        log("IAP Service: Purchase canceled for ${purchaseDetails.productID}");
        // Update UI if needed
      } else if (purchaseDetails.status == PurchaseStatus.pending) {
        log("IAP Service: Purchase pending for ${purchaseDetails.productID}");
        // Update UI to show pending state
      }
      // Restored and other statuses can be handled here if necessary
    }
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }
}

class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
