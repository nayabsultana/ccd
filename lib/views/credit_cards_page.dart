import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_service.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({Key? key}) : super(key: key);

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final FocusNode _cvvFocusNode = FocusNode();

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isBack = false;

  List<Map<String, String>> _cards = [];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(_flipController);
    _cvvFocusNode.addListener(_handleCVVFocus);
    _numberController.addListener(() {
      setState(() {});
    });
    _nameController.addListener(() {
      setState(() {});
    });
  }

  void _handleCVVFocus() {
    if (_cvvFocusNode.hasFocus) {
      _flipController.forward();
      setState(() => _isBack = true);
    } else {
      _flipController.reverse();
      setState(() => _isBack = false);
    }
  }

  @override
  void dispose() {
    _flipController.dispose();
    _nameController.dispose();
    _numberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cvvFocusNode.dispose();
    super.dispose();
  }

  String _getCardType(String number) {
    if (number.startsWith('4')) return 'Visa';
    if (number.startsWith('5')) return 'MasterCard';
    if (number.startsWith('3')) {
      if (number.length > 1 && (number[1] == '4' || number[1] == '7')) return 'Amex';
      return 'Diners Club';
    }
    if (number.startsWith('6')) return 'Discover';
    if (number.startsWith('35')) return 'JCB';
    if (number.startsWith('62')) return 'UnionPay';
    return 'Other';
  }

  Color _getCardColor(String type) {
    switch (type) {
      case 'Visa': return Colors.blue.shade700;
      case 'MasterCard': return Colors.deepOrange.shade400;
      case 'Amex': return Colors.teal.shade400;
      case 'Discover': return Colors.orange.shade400;
      case 'Diners Club': return Colors.indigo.shade400;
      case 'JCB': return Colors.purple.shade400;
      case 'UnionPay': return Colors.green.shade700;
      default: return Colors.grey.shade400;
    }
  }

  IconData _getCardIcon(String type) {
    switch (type) {
      case 'Visa': return Icons.credit_card;
      case 'MasterCard': return Icons.credit_card;
      case 'Amex': return Icons.credit_card;
      default: return Icons.credit_card;
    }
  }

  String _maskNumber(String number) {
    number = number.padRight(16, '*');
    return number.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ');
  }

  Future<void> _addCard() async {
    if (_formKey.currentState?.validate() ?? false) {
      final card = {
        'ownerName': _nameController.text.trim(),
        'cardNumber': _numberController.text.trim(),
        'expiry': _expiryController.text.trim(),
        'cvv': _cvvController.text.trim(),
        'card_brand': _getCardType(_numberController.text.trim()),
        'status': 'active',
      };
      setState(() {
        _cards.add(card);
        _nameController.clear();
        _numberController.clear();
        _expiryController.clear();
        _cvvController.clear();
      });
      try {
        await FirebaseService().addCreditCard(card);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card saved to Firestore!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save card: $e')),
        );
      }
    }
  }

  void _deleteCard(int index) {
    setState(() {
      _cards.removeAt(index);
    });
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month),
      lastDate: DateTime(now.year + 20),
      helpText: 'Select Expiry Date',
      fieldLabelText: 'Expiry Date',
      builder: (context, child) => child ?? const SizedBox(),
    );
    if (picked != null) {
      setState(() {
        _expiryController.text = '${picked.month.toString().padLeft(2, '0')}/${picked.year % 100}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
  final cardType = _getCardType(_numberController.text);
  final cardColor = _getCardColor(cardType);
  final maskedNumber = _maskNumber(_numberController.text);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
        ),
        title: const Text('Add Credit Card'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 40),
                textStyle: const TextStyle(fontSize: 16),
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
            ),
            AnimatedBuilder(
              animation: _flipAnimation,
              builder: (context, child) {
                final angle = _flipAnimation.value * 3.1416;
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationY(angle),
                  child: _isBack
                      ? _buildCardBack(cardColor)
                      : _buildCardFront(cardColor, maskedNumber, cardType),
                );
              },
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Cardholder Name'),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter name' : null,
                  ),
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(labelText: 'Card Number'),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    maxLength: 16,
                    validator: (v) => v == null || v.length < 16 ? 'Enter 16 digits' : null,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                          readOnly: true,
                          validator: (v) => v == null || v.isEmpty ? 'Select expiry' : null,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: _pickExpiry,
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(labelText: 'CVV'),
                    obscureText: true,
                    maxLength: 4,
                    focusNode: _cvvFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (v) => v == null || v.length < 3 ? 'Enter 3-4 digits' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addCard,
                    child: const Text('Add Card'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_cards.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Saved Cards:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ..._cards.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final card = entry.value;
                    final type = _getCardType(card['number'] ?? '');
                    final color = _getCardColor(type);
                    final icon = _getCardIcon(type);
                    return Card(
                      color: color,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Icon(icon, color: Colors.white),
                        title: Text(_maskNumber(card['number'] ?? ''), style: const TextStyle(color: Colors.white)),
                        subtitle: Text('Exp: ${card['expiry']}', style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => _deleteCard(idx),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardFront(Color color, String maskedNumber, String type) {
    // Realistic card visual using only Flutter widgets
    String cardLabel;
    switch (type) {
      case 'Visa': cardLabel = 'VISA'; break;
      case 'MasterCard': cardLabel = 'MasterCard'; break;
      case 'Amex': cardLabel = 'AMERICAN EXPRESS'; break;
      case 'Discover': cardLabel = 'DISCOVER'; break;
      case 'Diners Club': cardLabel = 'DINERS CLUB'; break;
      case 'JCB': cardLabel = 'JCB'; break;
      case 'UnionPay': cardLabel = 'UNIONPAY'; break;
      default: cardLabel = 'CARD';
    }
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Colors.black.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Simulated chip
              Container(
                width: 40,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.white70, width: 2),
                ),
              ),
              Text(cardLabel,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(maskedNumber,
            style: const TextStyle(color: Colors.white, fontSize: 26, letterSpacing: 2, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  _nameController.text.isEmpty ? 'CARDHOLDER NAME' : _nameController.text.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 16),
              Text('Exp: ${_expiryController.text}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack(Color color) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Colors.black.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: double.infinity,
            height: 40,
            color: Colors.black,
          ),
          const SizedBox(height: 32),
          Text('CVV', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _cvvController.text.isEmpty ? '***' : _cvvController.text,
              style: const TextStyle(color: Colors.black, fontSize: 18, letterSpacing: 2),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
