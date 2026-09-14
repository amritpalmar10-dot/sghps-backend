import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantAddStudent extends StatefulWidget {
  const AccountantAddStudent({super.key});

  @override
  State<AccountantAddStudent> createState() => _AccountantAddStudentState();
}

class _AccountantAddStudentState extends State<AccountantAddStudent> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _admissionController = TextEditingController();
  final _rollController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _selectedClass = 'XII';
  String _selectedSection = 'A';
  bool _isLoading = false;

  final List<String> _classes = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII'
  ];
  final List<String> _sections = ['A', 'B', 'C', 'D'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _admissionController.dispose();
    _rollController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _addStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/student'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'admission_no': _admissionController.text.trim(),
          'class': _selectedClass,
          'section': _selectedSection,
          'roll_no': _rollController.text.trim(),
          'parent_name': _parentNameController.text.trim(),
          'parent_phone': _parentPhoneController.text.trim(),
          'address': _addressController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Student added successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${data['message'] ?? 'Error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Connection error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Add New Student'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== HEADER ==========
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryPurple, secondaryPurple],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryPurple.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Text('👨‍🎓', style: TextStyle(fontSize: 50)),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add Student',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                          Text('New Registration',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ========== PERSONAL INFO ==========
              _sectionHeader('Personal Information'),
              const SizedBox(height: 12),

              _inputField(
                controller: _nameController,
                label: 'Full Name',
                icon: Icons.person,
                hint: 'Enter student name',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),

              _inputField(
                controller: _phoneController,
                label: 'Phone Number',
                icon: Icons.phone,
                hint: '10-digit mobile number',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone is required';
                  if (v.length < 10) return 'Enter valid phone number';
                  return null;
                },
              ),

              _inputField(
                controller: _emailController,
                label: 'Email (Optional)',
                icon: Icons.email,
                hint: 'student@example.com',
                keyboardType: TextInputType.emailAddress,
              ),

              _inputField(
                controller: _addressController,
                label: 'Address',
                icon: Icons.home,
                hint: 'Full address',
                maxLines: 2,
              ),

              const SizedBox(height: 20),

              // ========== ACADEMIC INFO ==========
              _sectionHeader('Academic Information'),
              const SizedBox(height: 12),

              _inputField(
                controller: _admissionController,
                label: 'Admission Number',
                icon: Icons.badge,
                hint: 'e.g., SGHPS-2024-001',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Admission number required' : null,
              ),

              // Class & Section Row
              Row(
                children: [
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedClass,
                        decoration: InputDecoration(
                          labelText: 'Class',
                          prefixIcon:
                              const Icon(Icons.class_, color: primaryPurple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: primaryPurple, width: 2),
                          ),
                        ),
                        items: _classes
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedClass = v!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSection,
                        decoration: InputDecoration(
                          labelText: 'Section',
                          prefixIcon:
                              const Icon(Icons.group, color: primaryPurple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: primaryPurple, width: 2),
                          ),
                        ),
                        items: _sections
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSection = v!),
                      ),
                    ),
                  ),
                ],
              ),

              _inputField(
                controller: _rollController,
                label: 'Roll Number',
                icon: Icons.numbers,
                hint: 'e.g., 01',
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 20),

              // ========== PARENT INFO ==========
              _sectionHeader('Parent/Guardian Information'),
              const SizedBox(height: 12),

              _inputField(
                controller: _parentNameController,
                label: 'Parent Name',
                icon: Icons.family_restroom,
                hint: 'Father/Mother name',
              ),

              _inputField(
                controller: _parentPhoneController,
                label: 'Parent Phone',
                icon: Icons.phone_android,
                hint: '10-digit mobile number',
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 25),

              // ========== INFO BOX ==========
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryPurple.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline,
                        color: primaryPurple, size: 20),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Fee structure will be auto-assigned based on class. You can modify it later from the student detail page.',
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // ========== SUBMIT BUTTON ==========
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addStudent,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(_isLoading ? 'Adding...' : 'Add Student'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: primaryPurple,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryPurple, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
