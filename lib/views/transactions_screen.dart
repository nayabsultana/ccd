import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import 'add_dummy_transaction_button.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _amountController = TextEditingController();
  final _currencyController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _merchantController.dispose();
    _cardNumberController.dispose();
    _cvvController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await FirebaseService().addTransaction(
        merchant: _merchantController.text.trim(),
        cardNumber: _cardNumberController.text.trim(),
        cvv: _cvvController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        currency: _currencyController.text.trim(),
        timestamp: DateTime.now(),
        flagged: false,
        flagReasons: [],
      );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction added!')));
      _merchantController.clear();
      _cardNumberController.clear();
      _cvvController.clear();
      _amountController.clear();
      _currencyController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 12),
            child: Align(
              alignment: Alignment.topLeft,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
          // Add dummy transaction button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: AddDummyTransactionButton(),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _merchantController,
                    decoration: const InputDecoration(labelText: 'Merchant'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter merchant' : null,
                  ),
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(labelText: 'Card Number'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter card number';
                      final digitsOnly = RegExp(r'^\d{13,19}$');
                      if (!digitsOnly.hasMatch(v.trim())) return 'Card number must be 13-19 digits';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter CVV';
                      final digitsOnly = RegExp(r'^\d{3,4}$');
                      if (!digitsOnly.hasMatch(v.trim())) return 'CVV must be 3 or 4 digits';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter amount';
                      final digitsOnly = RegExp(r'^\d+(\.\d{1,2})?$');
                      if (!digitsOnly.hasMatch(v.trim())) return 'Amount must be digits only';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _currencyController,
                    decoration: const InputDecoration(labelText: 'Currency'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter currency' : null,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _addTransaction,
                    child: _isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Add Transaction'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final merchant = data['merchant'] ?? 'Unknown';
                    final amount = data['amount'] ?? 0;
                    final currency = data['currency'] ?? '';
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    final flagged = data['flagged'] == true;
                    final flagReasons = List<String>.from(data['flag_reasons'] ?? []);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(merchant, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Amount: $amount $currency'),
                            if (timestamp != null)
                              Text('Date: ${DateFormat.yMMMd().add_jm().format(timestamp)}'),
                            flagged
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('⚠ Suspicious', style: TextStyle(color: Colors.red)),
                                    ...flagReasons.map((r) => Text('- $r', style: const TextStyle(color: Colors.redAccent)))
                                  ],
                                )
                              : const Text('✓ Safe', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
