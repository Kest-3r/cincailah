import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/nav.dart';
import 'home.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  String? _error;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ Navigate to Home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Home()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email input
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Enter email" : null,
                ),
                const SizedBox(height: 16),

                // Password input
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (value) =>
                  value == null || value.length < 6
                      ? "Min 6 characters"
                      : null,
                ),
                const SizedBox(height: 24),

                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),

                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _signUp,
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
      //bottomNavigationBar: const Nav(), // ✅ Keep the nav bar
    );
  }
}
