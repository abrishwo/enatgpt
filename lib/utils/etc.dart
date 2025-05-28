// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:in_app_purchase/in_app_purchase.dart';
//
// class MyApp extends StatefulWidget {
//   @override
//   _MyAppState createState() => _MyAppState();
// }
//
// class _MyAppState extends State<MyApp> {
//   final InAppPurchase _iap = InAppPurchase.instance;
//
//   late StreamSubscription<List<PurchaseDetails>> _subscription;
//
//   List<String> _products = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _initInAppPurchase();
//   }
//
//   @override
//   void dispose() {
//     _subscription.cancel();
//     super.dispose();
//   }
//
//   Future<void> _initInAppPurchase() async {
//     final bool available = await _iap.isAvailable();
//
//     if (!available) {
//       // In-app purchase is not available on this device
//       return;
//     }
//
//     await _getProducts();
//
//     _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdates);
//   }
//
//   Future<void> _getProducts() async {
//     Set<String> ids = {'product1', 'product2'};
//
//     ProductDetailsResponse response = await _iap.queryProductDetails(ids);
//     List<ProductDetails> products = response.productDetails;
//
//     setState(() {
//       _products = products.map((product) => product.id).toList();
//     });
//   }
//
//   void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
//     for (PurchaseDetails purchase in purchases) {
//       switch (purchase.status) {
//         case PurchaseStatus.pending:
//         // Handle pending status here
//           break;
//         case PurchaseStatus.purchased:
//           _verifyPurchase(purchase);
//           break;
//         case PurchaseStatus.error:
//         // Handle error here
//           break;
//         default:
//         // Handle unknown status here
//           break;
//       }
//     }
//   }
//
//   Future<void> _verifyPurchase(PurchaseDetails purchase) async {
//     // Verify the purchase here
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('In-App Purchase'),
//         ),
//         body: ListView.builder(
//           itemCount: _products.length,
//           itemBuilder: (context, index) {
//             final String productId = _products[index];
//
//             return ListTile(
//               title: Text(productId),
//               onTap: () {
//                 // Initiate the purchase flow
//               },
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
//
//
//
//
//
//
//
// // import 'dart:async';
// //
// // import 'package:in_app_purchase/in_app_purchase.dart';
// //
// // import 'app_keys.dart';
// //
// // class InAppPurchaseService {
// //   static const List<String> _productIds = [
// //     monthPlanAndroid,
// //     weekPlanAndroid,
// //     yearPlanAndroid,
// //   ];
// //
// //   final InAppPurchase _connection = InAppPurchase.instance;
// //   late StreamSubscription<List<PurchaseDetails>> _subscription;
// //
// //   void initialize() {
// //     _subscription = _connection.purchaseStream.listen((purchases) {
// //       _handlePurchaseUpdates(purchases);
// //     }, onDone: () {
// //       _subscription.cancel();
// //     }, onError: (error) {
// //       // handle error here
// //     });
// //
// //     _connection.isAvailable().then((available) {
// //       if (available) {
// //         _getProducts();
// //       } else {
// //         // handle error here
// //       }
// //     });
// //   }
// //
// //   void _getProducts() async {
// //     Set<String> ids = Set.from(_productIds);
// //     ProductDetailsResponse response = await _connection.queryProductDetails(ids);
// //     List<ProductDetails> products = response.productDetails;
// //
// //     for (ProductDetails product in products) {
// //       print('Product: ${product.title}, ${product.price}');
// //     }
// //   }
// //
// //   Future<void> buyProduct(String productId) async {
// //     final PurchaseParam purchaseParam = PurchaseParam(productDetails: _getProduct(productId));
// //     await _connection.buyNonConsumable(purchaseParam: purchaseParam);
// //   }
// //
// //   ProductDetails _getProduct(String productId) {
// //     final List<ProductDetails> products = _products as List<ProductDetails>;
// //     return products.firstWhere((product) => product.id == productId);
// //   }
// //
// //   void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
// //     for (PurchaseDetails purchase in purchases) {
// //       switch (purchase.status) {
// //         case PurchaseStatus.pending:
// //         // handle pending status here
// //           break;
// //         case PurchaseStatus.purchased:
// //           _verifyPurchase(purchase);
// //           break;
// //         case PurchaseStatus.error:
// //         // handle error here
// //           break;
// //         default:
// //         // handle unknown status here
// //           break;
// //       }
// //     }
// //   }
// //
// //   void _verifyPurchase(PurchaseDetails purchase) {
// //     if(purchase.status == PurchaseStatus.purchased){
// //
// //     }
// //     // verify purchase here
// //   }
// //
// //   Future<ProductDetailsResponse> get _products {
// //     return InAppPurchase.instance.queryProductDetails(Set.from(_productIds));
// //   }
// //
// //   void dispose() {
// //     _subscription.cancel();
// //   }
// // }
