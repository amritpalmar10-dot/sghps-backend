import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantEditTeacher extends StatefulWidget {
  final int? teacherId;

  const AccountantEditTeacher({
    super.key,
    this.teacherId,
  });

  @override
  State<AccountantEditTeacher> createState() => _AccountantEditTeacherState();
}

class _AccountantEditTeacherState extends State<AccountantEditTeacher> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _salaryController = TextEditingController();
  final _reasonController = TextEditingController();

  String _selectedSubject = 'Mathematics';
  String _selectedDesignation = 'Teacher';
  bool _isClassIncharge = false;
  String _selectedClass = 'XII';
  String _selectedSection = 'A';
  bool _originalIncharge = false;
  String _originalClass = '';
  String _originalSection = '';
  bool _isLoading = true;
  bool _isSaving = false;
  int? _actualTeacherId;

  final List<String> _subjects = [
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'Hindi',
    'Punjabi',
    'Computer Science',
    'Social Studies',
    'Physical Education',
    'Arts',
  ];

  final List<String> _designations = [
    'Teacher',
    'Senior Teacher',
    'Head of Department',
    'Assistant Teacher',
    'Lecturer',
  ];

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
      _resolveTeacherId();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _salaryController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  void _resolveTeacherId() {
    final args = ModalRoute.of(context)?.settings.arguments;

    print('🔍 Edit Teacher - Arguments: $args');
    print('🔍 Widget teacherId: ${widget.teacherId}');

    if (args != null && args is Map && args['id'] != null) {
      _actualTeacherId = args['id'] as int;
    } else if (widget.teacherId != null) {
      _actualTeacherId = widget.teacherId;
    }

    print('🔍 Actual teacher ID: $_actualTeacherId');

    if (_actualTeacherId != null) {
      _fetchTeacher();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchTeacher() async {
    if (_actualTeacherId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/teacher/$_actualTeacherId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final t = data['teacher'] ?? {};
        print('📥 Fetched for edit: ${t['name']}');

        setState(() {
          _nameController.text = t['name'] ?? '';
          _phoneController.text = t['phone'] ?? '';
          _emailController.text = t['email'] ?? '';
          _salaryController.text = (t['salary'] ?? 0).toString();
          _selectedSubject = t['subject'] ?? 'Mathematics';
          _selectedDesignation = t['designation'] ?? 'Teacher';
          _isClassIncharge = t['is_class_incharge'] == 1;
          _originalIncharge = _isClassIncharge;
          _selectedClass = t['incharge_class'] ?? 'XII';
          _selectedSection = t['incharge_section'] ?? 'A';
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

  bool get _inchargeChanged =>
      _isClassIncharge != _originalIncharge ||
      (_isClassIncharge &&
          (_selectedClass != _originalClass ||
              _selectedSection != _originalSection));

  Future<void> _saveTeacher() async {
    if (!_formKey.currentState!.validate()) return;

    if (_inchargeChanged && _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please provide reason for incharge change'),
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
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/teacher/$_actualTeacherId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'subject': _selectedSubject,
          'designation': _selectedDesignation,
          'is_class_incharge': _isClassIncharge,
          'incharge_class': _isClassIncharge ? _selectedClass : null,
          'incharge_section': _isClassIncharge ? _selectedSection : null,
          'salary': _salaryController.text.isEmpty
              ? 0
              : double.tryParse(_salaryController.text) ?? 0,
          'reason': _reasonController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Teacher updated successfully!'),
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
    String message = 'Are you sure you want to save these changes?';
    if (_inchargeChanged) {
      if (_originalIncharge && !_isClassIncharge) {
        message =
            'You are removing Class Incharge status.\n\nTeacher will lose access to mark attendance and approve leaves.';
      } else if (!_originalIncharge && _isClassIncharge) {
        message =
            'You are making this teacher Class Incharge of $_selectedClass-$_selectedSection.\n\nTeacher will gain access to mark attendance and approve leaves.';
      } else {
        message =
            'You are changing Class Incharge from $_originalClass-$_originalSection to $_selectedClass-$_selectedSection.';
      }
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Changes'),
        content: Text(message),
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

    if (confirm == true) _saveTeacher();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Edit Teacher'),
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
                                Text('Edit Teacher',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                Text('Update Details',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
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
                          v == null || v.isEmpty ? 'Name is required' : null,
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

                    const SizedBox(height: 20),

                    // ========== PROFESSIONAL ==========
                    _sectionHeader('Professional Information'),
                    const SizedBox(height: 12),

                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _selectedSubject,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          prefixIcon:
                              const Icon(Icons.book, color: primaryPurple),
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
                        items: _subjects
                            .map((s) =>
                                DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSubject = v!),
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: _selectedDesignation,
                        decoration: InputDecoration(
                          labelText: 'Designation',
                          prefixIcon: const Icon(Icons.workspace_premium,
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
                        items: _designations
                            .map((d) =>
                                DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedDesignation = v!),
                      ),
                    ),

                    _inputField(
                      controller: _salaryController,
                      label: 'Monthly Salary (₹)',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 20),

                    // ========== CLASS INCHARGE ==========
                    _sectionHeader('Class Incharge Assignment'),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _inchargeChanged
                              ? Colors.orange
                              : (_isClassIncharge
                                  ? const Color(0xFFF59E0B)
                                  : Colors.grey.shade300),
                          width: _inchargeChanged || _isClassIncharge ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFF59E0B).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.star,
                                    color: Color(0xFFF59E0B), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Class Incharge Status',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15)),
                                    SizedBox(height: 2),
                                    Text(
                                      'Can mark attendance & approve leaves',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isClassIncharge,
                                activeColor: const Color(0xFFF59E0B),
                                onChanged: (v) =>
                                    setState(() => _isClassIncharge = v),
                              ),
                            ],
                          ),
                          if (_isClassIncharge) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFFF59E0B).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedClass,
                                      decoration: InputDecoration(
                                        labelText: 'Class',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                      ),
                                      items: _classes
                                          .map((c) => DropdownMenuItem(
                                              value: c, child: Text(c)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _selectedClass = v!),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedSection,
                                      decoration: InputDecoration(
                                        labelText: 'Section',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 8),
                                      ),
                                      items: _sections
                                          .map((s) => DropdownMenuItem(
                                              value: s, child: Text(s)))
                                          .toList(),
                                      onChanged: (v) =>
                                          setState(() => _selectedSection = v!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (_inchargeChanged) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning,
                                      color: Colors.orange, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _originalIncharge && !_isClassIncharge
                                          ? 'Removing incharge status! Reason required.'
                                          : 'Class Incharge changed! Reason required.',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (_inchargeChanged) ...[
                      const SizedBox(height: 12),
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _reasonController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Reason for Change',
                            hintText:
                                'Why is the incharge status being changed?',
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
                              'All changes are recorded in audit logs.',
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
