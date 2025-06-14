import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:chat_gpt/utils/iap_services.dart'; // Adjust path if needed
import 'package:chat_gpt/utils/app_keys.dart';   // Adjust path if needed
import 'package:chat_gpt/services/credit_service.dart'; // Adjust path if needed

class BuyCreditsScreen extends StatefulWidget {
  const BuyCreditsScreen({super.key});

  @override
  State<BuyCreditsScreen> createState() => _BuyCreditsScreenState();
}

class _BuyCreditsScreenState extends State<BuyCreditsScreen> {
  // It's good practice to initialize Get.find in onInit or a similar lifecycle method
  // for GetxControllers, but for simple Get.find for services, here is okay,
  // assuming IapService and CreditService are already registered.
  late final IapService _iapService;
  late final CreditService _creditService;

  bool _isLoadingProducts = true;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;


  @override
  void initState() {
    super.initState();
    // Initialize services here if not using GetxController's onInit
    _iapService = Get.find<IapService>();
    _creditService = Get.find<CreditService>();
    _loadProducts();

    // Listen to purchase updates
    _purchaseSubscription = _iapService.inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) {
        _iapService.listenToPurchaseUpdated( // Directly calling the method from IapService
            purchaseDetailsList: purchaseDetailsList,
            updatePlan: () { // This updatePlan callback might need adjustment based on IapService
                // This callback was originally for subscriptions.
                // For consumables, we might refresh credits or UI.
                print("BuyCreditsScreen: Purchase updated, potentially refresh UI or credits.");
                if (mounted) {
                  setState(() {}); // Rebuild to reflect new credit balance
                }
            });
      },
      onDone: () {
        _purchaseSubscription?.cancel();
      },
      onError: (error) {
        // Handle error here
        print("BuyCreditsScreen: Purchase Stream Error: $error");
      },
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingProducts = true;
    });

    List<String> productIdsToQuery;
    if (Platform.isAndroid) {
      // Here, you might want to differentiate between Google Play and Amazon
      // For simplicity, using consumableCreditProductsAndroid for all Android.
      // If Amazon Appstore has different product IDs, you'd need a way to check
      // which store is being used (e.g., using a package like `flutter_fgb_platform_type`).
      // For now, we assume consumableCreditProductsAndroid covers general Android (Google Play).
      // If `consumableCreditProductsAmazon` should be used for Amazon devices, that logic needs to be added.
      productIdsToQuery = consumableCreditProductsAndroid;
    } else if (Platform.isIOS) {
      productIdsToQuery = consumableCreditProductsIOS;
    } else {
      productIdsToQuery = [];
      print("BuyCreditsScreen: Unsupported platform for IAP.");
    }

    if (productIdsToQuery.isNotEmpty) {
      try {
        // The initStoreInfo now returns List<ProductDetails>, so direct assignment is fine.
        _products = await _iapService.initStoreInfo(productIDsToQuery: productIdsToQuery);
      } catch (e) {
        print("BuyCreditsScreen: Error loading products: $e");
        _products = []; // Ensure products list is empty on error
      }
    } else {
      _products = [];
    }

    if (mounted) {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buy Credits'),
        actions: [
          // Reactive credit display from CreditService
          Obx(() => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Center(
              child: Text(
                'Credits: ${_creditService.currentUserCredit.value?.balance?.toStringAsFixed(1) ?? "0.0"}',
                style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge?.color),
              )
            ),
          )),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoadingProducts) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No credit packs available at the moment.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadProducts, // Retry loading products
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(product.description),
            trailing: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white, // Text color
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
              ),
              onPressed: () {
                // Ensure IAP service's buyCreditPack is called.
                // The IAP plugin should handle platform specifics for consumables.
                _iapService.buyCreditPack(product);
              },
              child: Text(product.price),
            ),
          ),
        );
      },
    );
  }
}
