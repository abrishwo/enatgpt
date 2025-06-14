import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async'; // Required for StreamSubscription
import 'package:firebase_analytics/firebase_analytics.dart'; // Import Firebase Analytics
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_credit.dart'; // Assuming user_credit.dart is in lib/models/

class CreditService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription? _creditSubscription; // To manage the listener

  final Rx<UserCredit?> currentUserCredit = Rx<UserCredit?>(null);

  // Method to get the current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Call this method when the user logs in
  Future<void> onUserLogin() async {
    await initializeUserCredits();
  }

  // Call this method when the user logs out
  Future<void> onUserLogout() async {
    print("CreditService: User logging out. Clearing credits and listener.");
    await _creditSubscription?.cancel();
    _creditSubscription = null;
    currentUserCredit.value = null;
  }

  Future<void> initializeUserCredits() async {
    // If there's an existing subscription, cancel it before starting a new one.
    await _creditSubscription?.cancel();

    final user = _auth.currentUser;
    if (user == null) {
      currentUserCredit.value = null;
      print("CreditService: No user logged in. Cannot initialize credits.");
      return;
    }
    final userId = user.uid;
    print("CreditService: Initializing credits for user $userId.");

    // Listen for real-time updates
    _creditSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('credits')
        .doc('wallet')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        try {
          print("CreditService: Received credit snapshot for user $userId.");
          currentUserCredit.value = UserCredit.fromJson(snapshot.data()!);
        } catch (e) {
          print("CreditService: Error parsing UserCredit from snapshot for user $userId: $e");
          currentUserCredit.value = null;
        }
      } else {
        print("CreditService: Credit wallet does not exist for user $userId.");
        // If document doesn't exist after initial check (or gets deleted),
        // we might want to recreate it or handle it.
        // For now, if it's missing during listening, it means it was deleted or not yet created.
        currentUserCredit.value = null;
      }
    }, onError: (error) {
      print("CreditService: Error listening to credit snapshots for user $userId: $error");
      currentUserCredit.value = null;
    });

    // Initial fetch or creation. The listener might be slightly delayed,
    // so an initial fetch helps ensure data is available sooner.
    try {
      final existingCredits = await _fetchUserCreditsFromFirestore(userId);
      if (existingCredits == null) {
        print("CreditService: No existing credits found for user $userId during initial fetch. Attempting to create document...");
        // Attempt to create, the listener will pick it up.
        // Or, assign directly if _createUserCreditDocument returns the created object and it's not null.
        UserCredit? newCreditDoc = await _createUserCreditDocument(userId);
        if (newCreditDoc != null) {
             // currentUserCredit.value = newCreditDoc; // Or let listener handle it
             print("CreditService: Document created for $userId, listener should pick it up.");
        } else {
            print("CreditService: Failed to create document for $userId during initialization.");
        }
      } else {
        // If listener hasn't fired yet, set it.
        if (currentUserCredit.value == null) {
            currentUserCredit.value = existingCredits;
        }
      }
    } catch (e) {
      print("CreditService: Error during initial fetch/create for user credits $userId: $e");
      currentUserCredit.value = null; // Ensure clean state on error
    }
  }

  Future<bool> addCredits(double amountToAdd) async {
    if (currentUserCredit.value == null) {
      print("CreditService: User credits not loaded. Cannot add credits.");
      return false;
    }
    if (amountToAdd <= 0) {
      print("CreditService: Amount to add must be positive.");
      return false;
    }

    final UserCredit currentCredits = currentUserCredit.value!;
    final String userId = currentCredits.userId;
    final double newBalance = currentCredits.balance + amountToAdd;
    final UserCredit updatedCredits = currentCredits.copyWith(balance: newBalance);

    try {
      await _updateCreditsInFirestore(updatedCredits);
      print("CreditService: Added $amountToAdd credits for user $userId. New balance: $newBalance");
      // Listener should update currentUserCredit.value, or update optimistically:
      // currentUserCredit.value = updatedCredits;
      return true;
    } catch (e) {
      print("CreditService: Error adding credits for user $userId: $e");
      return false;
    }
  }

  Future<void> grantDailyFreeCredits() async {
    if (currentUserCredit.value == null) {
      print("CreditService: User credits not loaded. Cannot grant daily credits.");
      return;
    }

    final UserCredit currentCredits = currentUserCredit.value!;
    final String userId = currentCredits.userId;

    Timestamp? lastClaimTimestamp = currentCredits.lastFreeCreditClaimedTimestamp;
    DateTime lastClaimDate;

    if (lastClaimTimestamp == null) {
      // If null, user is eligible (e.g., very old doc or new user who hasn't had it set by create explicitly)
      // Or, _createUserCreditDocument should ensure this is set to a server timestamp.
      // For robustness, let's assume eligibility if null.
      print("CreditService: grantDailyFreeCredits - lastFreeCreditClaimedTimestamp is null for user $userId. Assuming eligible.");
      lastClaimDate = DateTime(1970); // A very old date
    } else {
      lastClaimDate = lastClaimTimestamp.toDate().toLocal();
    }

    final DateTime currentDate = DateTime.now().toLocal();

    // Check if the last claim was on a previous day
    final bool isEligible = lastClaimDate.year < currentDate.year ||
        (lastClaimDate.year == currentDate.year && lastClaimDate.month < currentDate.month) ||
        (lastClaimDate.year == currentDate.year && lastClaimDate.month == currentDate.month && lastClaimDate.day < currentDate.day);

    if (isEligible) {
      print("CreditService: User $userId is eligible for daily credits. Attempting to grant.");
      final double newBalance = currentCredits.balance + 2.0;

      // Create a map for the update, so we can use FieldValue.serverTimestamp()
      final Map<String, dynamic> updatedCreditData = {
        'balance': newBalance,
        'lastFreeCreditClaimedTimestamp': FieldValue.serverTimestamp(),
      };

      try {
        final docRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('credits')
            .doc('wallet');
        await docRef.update(updatedCreditData);
        print("CreditService: Successfully granted 2.0 daily credits to user $userId. New balance will be reflected by listener.");

        // Log event to Firebase Analytics
        // We need the updated UserCredit object to get the new balance accurately,
        // but the listener will update currentUserCredit.value.
        // For simplicity here, we use the calculated newBalance.
        // A more robust way might be to fetch the UserCredit object after update or trust the listener.
        FirebaseAnalytics.instance.logEvent(
          name: 'daily_credit_claimed',
          parameters: {
            'user_id': userId, // userId is already defined in this scope
            'credits_awarded': 2.0,
            'new_balance': newBalance,
          },
        );
        print("CreditService: Logged daily_credit_claimed event for user $userId.");

      } catch (e) {
        print("CreditService: Error granting daily credits to user $userId during Firestore update: $e");
      }
    } else {
      print("CreditService: User $userId is not yet eligible for daily credits. Last claim: $lastClaimDate, Current: $currentDate");
    }
  }

  Future<bool> deductCredits(double amountToDeduct) async {
    if (currentUserCredit.value == null) {
      print("CreditService: User credits not loaded. Cannot deduct credits.");
      return false;
    }
    if (amountToDeduct <= 0) {
        print("CreditService: Amount to deduct must be positive.");
        return false;
    }

    final UserCredit currentCredits = currentUserCredit.value!;
    final String userId = currentCredits.userId;

    if (currentCredits.balance >= amountToDeduct) {
      final double newBalance = currentCredits.balance - amountToDeduct;
      final UserCredit updatedLocalCredits = currentCredits.copyWith(balance: newBalance);

      try {
        await _updateCreditsInFirestore(updatedLocalCredits);
        print("CreditService: Deducted $amountToDeduct credits from user $userId. New balance will be reflected by listener.");
        // The listener in initializeUserCredits should update currentUserCredit.value.
        // Optimistic update: currentUserCredit.value = updatedLocalCredits; (Be cautious with this if listener is source of truth)
        return true;
      } catch (e) {
        print("CreditService: Error deducting credits for user $userId during Firestore update: $e");
        return false;
      }
    } else {
      print("CreditService: Insufficient balance for user $userId to deduct $amountToDeduct. Current balance: ${currentCredits.balance}");
      return false;
    }
  }

  Future<void> _updateCreditsInFirestore(UserCredit userCredit) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userCredit.userId)
          .collection('credits')
          .doc('wallet');
      await docRef.update(userCredit.toJson());
    } catch (e) {
      print("CreditService: Error updating credits in Firestore for user ${userCredit.userId}: $e");
      rethrow;
    }
  }

  Future<UserCredit?> _fetchUserCreditsFromFirestore(String userId) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('credits')
          .doc('wallet');
      final docSnapshot = await docRef.get();

      if (docSnapshot.exists) {
        return UserCredit.fromJson(docSnapshot.data()!);
      } else {
        print("CreditService: _fetchUserCreditsFromFirestore - Document does not exist for $userId");
        return null;
      }
    } catch (e) {
      print("CreditService: Error fetching user credits for $userId in _fetchUserCreditsFromFirestore: $e");
      return null;
    }
  }

  Future<UserCredit?> _createUserCreditDocument(String userId) async {
    try {
      print("CreditService: Attempting to create user credit document for $userId.");
      final initialCreditData = {
        'userId': userId,
        'balance': 2.0,
        'lastFreeCreditClaimedTimestamp': FieldValue.serverTimestamp(),
      };

      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('credits')
          .doc('wallet');

      await docRef.set(initialCreditData);
      print("CreditService: Successfully set initial credit data for $userId.");

      // Fetch the document to return it with the server-generated timestamp.
      final snapshot = await docRef.get();
      if (snapshot.exists) {
        print("CreditService: Successfully fetched created document for $userId.");
        return UserCredit.fromJson(snapshot.data()!);
      } else {
        // This case should ideally not happen if set() was successful.
        print("CreditService: CRITICAL - Document not found immediately after creation for $userId.");
        return null;
      }
    } catch (e) {
      print("CreditService: Error creating user credit document for $userId: $e");
      return null; // Return null if creation failed
    }
  }
}
