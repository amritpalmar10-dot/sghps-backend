import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantEditStudent extends StatefulWidget {
  final int? studentId;

  const AccountantEditStudent({
    super.key,
    this.studentId,
  });

  @override
  State<AccountantEditStudent> createState() => _AccountantEditStudentState();
}

class _AccountantEditStudentState extends State<AccountantEditStudent> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _rollController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedClass = 'XII';
  String _selectedSection = 'A';
  String _originalClass = 'XII';
  String _originalSection = 'A';
  bool _isLoading = true;
  bool _isSaving = false;
  int? _actualStudentId;

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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveStudentId();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _rollController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _addressController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _resolveStudentId() {
    final args = ModalRoute.of(context)?.settings.arguments;

    print('🔍 Edit Student - Arguments: $args');
    print('🔍 Widget studentId: ${widget.studentId}');

    if (args != null && args is Map && args['id'] != null) {
      _actualStudentId = args['id'] as int;
    } else if (widget.studentId != null) {
      _actualStudentId = widget.studentId;
    }

    print('🔍 Actual student ID: $_actualStudentId');

    if (_actualStudentId != null) {
      _fetchStudent();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchStudent() async {
    if (_actualStudentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/student/$_actualStudentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final student = data['student'] ?? {};
        print('📥 Fetched student for edit: ${student['name']}');

        setState(() {
          _nameController.text = student['name'] ?? '';
          _phoneController.text = student['phone'] ?? '';
          _emailController.text = student['email'] ?? '';
          _rollController.text = student['roll_no'] ?? '';
          _parentNameController.text = student['parent_name'] ?? '';
          _parentPhoneController.text = student['parent_phone'] ?? '';
          _addressController.text = student['address'] ?? '';
          _selectedClass = student['class'] ?? 'XII';
          _selectedSection = student['section'] ?? 'A';
          _originalClass = _selectedClass;
          _originalSection = _selectedSection;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool get _classChanged =>
      _selectedClass != _originalClass || _selectedSection != _originalSection;

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_classChanged && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please provide reason for class change'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.put(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/student/$_actualStudentId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'class': _selectedClass,
          'section': _selectedSection,
          'roll_no': _rollController.text.trim(),
          'parent_name': _parentNameController.text.trim(),
          'parent_phone': _parentPhoneController.text.trim(),
          'address': _addressController.text.trim(),
          'reason': _reasonController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Student updated successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() => _isSaving = false);
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
      setState(() => _isSaving = false);
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

  Future<void> _confirmSave() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Save Changes?'),
        content: Text(_classChanged
            ? 'You are about to change the student\'s class from $_originalClass-$_originalSection to $_selectedClass-$_selectedSection.\n\nThis will affect attendance, timetable, and class teacher.'
            : 'Are you sure you want to save these changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _saveStudent();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Student'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            color: primaryPurple.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Text('✏️', style: TextStyle(fontSize: 50)),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Edit Student',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                Text('Update Details',
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
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Name required' : null,
                    ),

                    _inputField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),

                    _inputField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    _inputField(
                      controller: _addressController,
                      label: 'Address',
                      icon: Icons.home,
                      maxLines: 2,
                    ),

                    const SizedBox(height: 20),

                    // ========== ACADEMIC INFO ==========
                    _sectionHeader('Academic Information'),
                    const SizedBox(height: 12),

                    Container(
                      padding: _classChanged
                          ? const EdgeInsets.all(12)
                          : EdgeInsets.zero,
                      decoration: _classChanged
                          ? BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            )
                          : null,
                      child: Column(
                        children: [
                          if (_classChanged)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 10),
                              child: Row(
                                children: [
                                  Icon(Icons.warning,
                                      color: Colors.orange, size: 18),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Class/Section changed! Reason required below.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedClass,
                                    decoration: InputDecoration(
                                      labelText: 'Class',
                                      prefixIcon: const Icon(Icons.class_,
                                          color: primaryPurple),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: primaryPurple, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: _classes
                                        .map((c) => DropdownMenuItem(
                                            value: c, child: Text(c)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedClass = v!),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedSection,
                                    decoration: InputDecoration(
                                      labelText: 'Section',
                                      prefixIcon: const Icon(Icons.group,
                                          color: primaryPurple),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: primaryPurple, width: 2),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    items: _sections
                                        .map((s) => DropdownMenuItem(
                                            value: s, child: Text(s)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _selectedSection = v!),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    _inputField(
                      controller: _rollController,
                      label: 'Roll Number',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                    ),

                    if (_classChanged) ...[
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Reason for Change',
                            hintText: 'Why is the class/section being changed?',
                            prefixIcon:
                                const Icon(Icons.notes, color: Colors.orange),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                  color: Colors.orange, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.orange.shade50,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ========== PARENT INFO ==========
                    _sectionHeader('Parent Information'),
                    const SizedBox(height: 12),

                    _inputField(
                      controller: _parentNameController,
                      label: 'Parent Name',
                      icon: Icons.family_restroom,
                    ),

                    _inputField(
                      controller: _parentPhoneController,
                      label: 'Parent Phone',
                      icon: Icons.phone_android,
                      keyboardType: TextInputType.phone,
                    ),

                    const SizedBox(height: 20),

                    // ========== INFO BOX ==========
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryPurple.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryPurple.withOpacity(0.2),
                        ),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline,
                              color: primaryPurple, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'All changes are recorded in audit logs for tracking.',
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

                    // ========== SAVE ==========
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _confirmSave,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
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
