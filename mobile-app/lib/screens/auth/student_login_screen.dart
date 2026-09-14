import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentLoginScreen extends StatefulWidget {
  const StudentLoginScreen({super.key});

  @override
  State<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends State<StudentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _admissionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;
  int? _userId;
  String? _error;

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('https://sghps-backend.onrender.com/api/auth/student/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'admission_no': _admissionController.text,
          'phone': _phoneController.text,
        }),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          _userId = data['userId'];
          _otpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('📱 OTP: ${data['testOtp']}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 10)),
        );
      } else {
        setState(() {
          _error = data['message'] ?? 'Login failed';
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

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      setState(() => _error = 'Please enter OTP');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await http.post(
        Uri.parse('https://sghps-backend.onrender.com/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': _userId, 'otp': _otpController.text}),
      );
      final data = json.decode(response.body);
      if (data['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        await prefs.setString('role', 'student');
        await prefs.setString('user', json.encode(data['user']));
        if (mounted)
          Navigator.pushReplacementNamed(context, '/student-dashboard');
      } else {
        setState(() {
          _error = data['message'] ?? 'Invalid OTP';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Verification failed';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Student Login'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.person, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('Student Login',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 30),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red.shade700)),
                ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _admissionController,
                      decoration: const InputDecoration(
                          labelText: 'Admission Number',
                          prefixIcon: Icon(Icons.numbers),
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      enabled: !_otpSent,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                      enabled: !_otpSent,
                    ),
                    const SizedBox(height: 20),
                    if (_otpSent) ...[
                      TextFormField(
                        controller: _otpController,
                        decoration: const InputDecoration(
                            labelText: 'Enter OTP',
                            prefixIcon: Icon(Icons.security),
                            border: OutlineInputBorder()),
                        maxLength: 6,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Verify OTP',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ] else ...[
                      ElevatedButton(
                        onPressed: _isLoading ? null : _sendOTP,
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Send OTP',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Demo: SGHPS-2024-001 / 9876543210',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
