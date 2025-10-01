import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends StatefulWidget {
  final VoidCallback onBackToLogin;

  const RegisterPage({required this.onBackToLogin, Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _fnameController = TextEditingController();
  final _lnameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final AuthController _authController = AuthController();

  double passwordStrength = 0;
  Map<String, bool> passwordChecklist = {
    'len': false,
    'upper': false,
    'lower': false,
    'num': false,
    'special': false
  };

  bool _isSubmitting = false;

  void checkPasswordStrength(String password) {
    final len = password.length >= 8;
    final upper = RegExp(r'[A-Z]').hasMatch(password);
    final lower = RegExp(r'[a-z]').hasMatch(password);
    final num = RegExp(r'[0-9]').hasMatch(password);
    final special = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    setState(() {
      passwordChecklist['len'] = len;
      passwordChecklist['upper'] = upper;
      passwordChecklist['lower'] = lower;
      passwordChecklist['num'] = num;
      passwordChecklist['special'] = special;

      final score = [len, upper, lower, num, special].where((v) => v).length;
      passwordStrength = score / 5.0;
    });
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fname = _fnameController.text.trim();
    final lname = _lnameController.text.trim();

    final error = await _authController.register(
      username: username,
      email: email,
      password: password,
      firstName: fname,
      lastName: lname,
    );

    setState(() => _isSubmitting = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User registered successfully!')));
  widget.onBackToLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _fnameController.dispose();
    _lnameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBackToLogin,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username *"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter username';
                  return null;
                },
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email *"),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter email';
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return 'Enter a valid email';
                  return null;
                },
              ),
              TextFormField(
                controller: _fnameController,
                decoration: const InputDecoration(labelText: "First Name *"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter first name';
                  return null;
                },
              ),
              TextFormField(
                controller: _lnameController,
                decoration: const InputDecoration(labelText: "Last Name *"),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Please enter last name';
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password *"),
                obscureText: true,
                onChanged: checkPasswordStrength,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter password';
                  if (passwordStrength < 1.0) return 'Password does not meet requirements';
                  return null;
                },
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: passwordStrength,
                valueColor: AlwaysStoppedAnimation<Color>(
                  passwordStrength < 0.4
                      ? Colors.red
                      : passwordStrength < 1.0
                          ? Colors.orange
                          : Colors.green,
                ),
                backgroundColor: Colors.grey.shade300,
                minHeight: 6,
              ),
              const SizedBox(height: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(passwordChecklist['len']! ? "✔ At least 8 characters" : "❌ At least 8 characters"),
                  Text(passwordChecklist['upper']! ? "✔ One uppercase letter" : "❌ One uppercase letter"),
                  Text(passwordChecklist['lower']! ? "✔ One lowercase letter" : "❌ One lowercase letter"),
                  Text(passwordChecklist['num']! ? "✔ One number" : "❌ One number"),
                  Text(passwordChecklist['special']! ? "✔ One special character" : "❌ One special character"),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: "Confirm Password *"),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _isSubmitting
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Register'),
                    ),
              TextButton(
                onPressed: widget.onBackToLogin,
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
