import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class FirebaseService {
  /// Copy all cards from users/{uid}/cards subcollection to a top-level 'cards' collection.
  Future<void> copyUserCardsToGlobalCollection(String uid) async {
    final cardsSnapshot = await _firestore.collection('users').doc(uid).collection('cards').get();
    for (final doc in cardsSnapshot.docs) {
      await _firestore.collection('cards').doc(doc.id).set(doc.data());
    }
  }
  /// Create a flag for a transaction by copying relevant data to 'flags' collection.
  Future<void> createFlagFromTransaction({
    required String transactionId,
    required String userId,
    required String cardId,
    required List<String> reasons,
  }) async {
    final txDoc = await _firestore.collection('transactions').doc(transactionId).get();
    final tx = txDoc.data();
    if (tx == null) throw Exception('Transaction not found');
    await _firestore.collection('flags').add({
      'userId': userId,
      'transactionId': transactionId,
      'cardId': cardId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
      'reasons': reasons,
      'merchant': tx['merchant'],
      'amount': tx['amount'],
    });
  }
  /// Add a transaction to the 'transactions' collection in Firestore.
  Future<void> addTransaction({
  required String merchant,
  required String cardNumber,
  required String cvv,
  required double amount,
  required String currency,
  required DateTime timestamp,
  required bool flagged,
  List<String>? flagReasons,
  }) async {
    // Simple rules for flagging suspicious transactions
    List<String> reasons = flagReasons ?? [];
    bool isFlagged = flagged;
    if (amount > 1000) {
      isFlagged = true;
      reasons.add('Large amount');
    }
    if (merchant.toLowerCase().contains('test')) {
      isFlagged = true;
      reasons.add('Test merchant');
    }
    final txRef = await _firestore.collection('transactions').add({
      'merchant': merchant,
      'cardNumber': cardNumber,
      'cvv': cvv,
      'amount': amount,
      'currency': currency,
      'timestamp': Timestamp.fromDate(timestamp),
      'flagged': isFlagged,
      'flag_reasons': reasons,
    });
    // If flagged, create a flag and an alert document for fraud alert feature
    if (isFlagged) {
      final user = _auth.currentUser;
      // Create flag
      await _firestore.collection('flags').add({
        'userId': user?.uid ?? '',
        'transactionId': txRef.id,
        'cardId': '', // If you have cardId, pass it here
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'reasons': reasons,
        'merchant': merchant,
        'amount': amount,
      });
      // Create alert
      await _firestore.collection('alerts').add({
        'userId': user?.uid ?? '',
        'transactionId': txRef.id,
        'cardId': '',
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'suspicious_transaction',
        'status': 'unread',
        'reasons': reasons,
        'merchant': merchant,
        'amount': amount,
      });
    }
  }
  /// Store a credit card in the user's cards subcollection in Firestore.
  Future<void> addCreditCard(Map<String, String> card) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');
    await _firestore.collection('users').doc(user.uid).collection('cards').add(card);
  }
  /// Fetch user data from Firestore by uid.
  Future<Map<String, dynamic>> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }
  /// Logs in a user with email and password using Firebase Auth.
  Future<UserCredential> loginWithEmail({required String email, required String password}) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Returns true if username exists in 'users' collection.
  Future<bool> usernameExists(String username) async {
    final snapshot = await _firestore
        .collection('users')
        .where('username', isEqualTo: username)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Registers a user in Firebase Auth and creates a Firestore doc with extra fields.
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
  }) async {
    // Create user in Firebase Auth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final uid = cred.user!.uid;

    final user = AppUser(
      uid: uid,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
    );

    await _firestore.collection('users').doc(uid).set(user.toMap());

    // Optionally update displayName on Auth user
    try {
      await cred.user!.updateDisplayName(username);
    } catch (_) {}

    return user;
  }
}
