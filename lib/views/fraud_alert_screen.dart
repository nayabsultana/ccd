import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FraudAlertScreen extends StatelessWidget {
  const FraudAlertScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view fraud alerts.')),
      );
    }
     return Scaffold(
     appBar: AppBar(title: const Text('Fraud Alerts')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .where('userId', isEqualTo: user.uid)
            .where('type', isEqualTo: 'suspicious_transaction')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No fraud alerts found.'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final alert = docs[i].data() as Map<String, dynamic>;
              // final alertId = docs[i].id;
              // final flagId = alert['flagId'] ?? '';
              // final cardId = alert['cardId'] ?? '';
              final txnId = alert['transactionId'] ?? '';
              final reasons = List<String>.from(alert['reasons'] ?? []);
              final status = alert['status'] ?? 'unread';
              final decision = alert['decision'] ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text('Alert: $txnId'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reasons: ${reasons.join(", ")}'),
                      Text('Status: $status'),
                      if (decision.isNotEmpty) Text('Decision: $decision'),
                    ],
                  ),
                  trailing: status == 'handled'
                      ? const Text('Handled', style: TextStyle(color: Colors.green))
                      : const Icon(Icons.notification_important, color: Colors.orange),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
