import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantLoginScreen extends StatefulWidget {
  const AccountantLoginScreen({super.key});

  @override
  State<AccountantLoginScreen> createState() => _AccountantLoginScreenState();
}

class _AccountantLoginScreenState extends State<AccountantLoginScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('http://192.168.31.27:5001/api/auth/accountant/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'accountant_code': _codeController.text,
          'password': _passwordController.text,
        }),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', 'accountant');
        await prefs.setString('user', json.encode(data['user']));
        if (mounted)
          Navigator.pushReplacementNamed(context, '/accountant-dashboard');
      } else {
        setState(() {
          _error = data['message'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Accountant Login'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.person_2_rounded, size: 80, color: Colors.purple),
            const SizedBox(height: 20),
            const Text('Accountant Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                  labelText: 'Accountant Code',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Demo: ACC-001 / ACC-001',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
