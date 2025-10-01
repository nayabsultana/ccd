import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static Future<void> setupFCM(String uid) async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    final token = await fcm.getToken();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
    await userRef.update({'fcmTokens': FieldValue.arrayUnion([token])});
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      userRef.update({'fcmTokens': FieldValue.arrayUnion([newToken])});
    });
  }

  static Future<void> removeFCMToken(String uid) async {
    final token = await FirebaseMessaging.instance.getToken();
    await FirebaseFirestore.instance.collection('users').doc(uid)
      .update({'fcmTokens': FieldValue.arrayRemove([token])});
  }

  static void handleNotificationTap(Function(String alertId, String txnId) onTap) {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final alertId = message.data['alertId'];
      final txnId = message.data['txnId'];
      if (alertId != null && txnId != null) {
        onTap(alertId, txnId);
      }
    });
  }
}
