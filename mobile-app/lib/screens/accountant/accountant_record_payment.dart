import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantRecordPayment extends StatefulWidget {
  final int? preSelectedStudentId;

  const AccountantRecordPayment({
    super.key,
    this.preSelectedStudentId,
  });

  @override
  State<AccountantRecordPayment> createState() =>
      _AccountantRecordPaymentState();
}

class _AccountantRecordPaymentState extends State<AccountantRecordPayment> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();

  String _selectedMethod = 'Cash';
  int? _selectedStudentId;
  Map<String, dynamic>? _selectedStudent;
  Map<String, dynamic>? _feeInfo;
  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _methods = [
    'Cash',
    'Online Transfer',
    'Cheque',
    'Card',
    'UPI',
  ];

  @override
  void initState() {
    super.initState();
    _fetchStudents().then((_) {
      if (widget.preSelectedStudentId != null) {
        _selectStudent(widget.preSelectedStudentId!);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://sghps-backend.onrender.com/api/accountant/students'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _students = data['students'] ?? [];
          _filteredStudents = _students;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _searchStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = _students;
      } else {
        final q = query.toLowerCase();
        _filteredStudents = _students.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          final admission = (s['admission_no'] ?? '').toString().toLowerCase();
          return name.contains(q) || admission.contains(q);
        }).toList();
      }
    });
  }

  Future<void> _selectStudent(int studentId) async {
    setState(() {
      _selectedStudentId = studentId;
      _selectedStudent = null;
      _feeInfo = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://sghps-backend.onrender.com/api/accountant/student/$studentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _selectedStudent = data['student'];
          _feeInfo = data['fees'];
        });
      }
    } catch (e) {
      print('Error loading student fee: $e');
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedStudentId = null;
      _selectedStudent = null;
      _feeInfo = null;
      _amountController.clear();
      _transactionIdController.clear();
      _notesController.clear();
      _searchController.clear();
      _filteredStudents = _students;
    });
  }

  String _formatCurrency(num amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  Future<void> _recordPayment() async {
    if (_selectedStudentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select a student'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final totalFee = (_feeInfo?['total_amount'] ?? 0).toDouble();
    final alreadyPaid = (_feeInfo?['paid_amount'] ?? 0).toDouble();
    final currentDue = totalFee - alreadyPaid;

    if (amount > currentDue) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('⚠️ Amount exceeds due'),
          content: Text(
            'Current due is ${_formatCurrency(currentDue)}.\nYou entered ${_formatCurrency(amount)}.\n\nThis will create extra credit. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSaving = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.post(
        Uri.parse('https://sghps-backend.onrender.com/api/accountant/payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'student_id': _selectedStudentId,
          'amount': amount,
          'method': _selectedMethod,
          'transaction_id': _transactionIdController.text.trim(),
          'notes': _notesController.text.trim(),
        }),
      );

      final data = json.decode(response.body);

      if (data['success']) {
        if (mounted) {
          _showSuccessDialog(data);
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

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 30),
            SizedBox(width: 10),
            Text('Payment Recorded!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _successRow('Receipt No', data['receipt_number'] ?? 'N/A'),
            _successRow('Student', _selectedStudent?['name'] ?? 'N/A'),
            _successRow('Amount Paid',
                _formatCurrency((data['new_paid'] ?? 0).toDouble())),
            _successRow(
                'New Due', _formatCurrency((data['new_due'] ?? 0).toDouble())),
            _successRow(
                'Status', (data['status'] ?? 'N/A').toString().toUpperCase()),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.notifications_active,
                      color: Color(0xFF16A34A), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Student dashboard updated automatically',
                      style: TextStyle(fontSize: 11, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text('Done'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('📄 Receipt downloaded')),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Receipt'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
          ),
        ],
      ),
    );
  }

  Widget _successRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Record Payment'),
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
                          Text('💳', style: TextStyle(fontSize: 50)),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Record Payment',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                                Text('Fee Collection',
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

                    // ========== SELECT STUDENT TITLE ==========
                    _sectionHeader('Select Student'),
                    const SizedBox(height: 12),

                    // ========== SEARCH BAR ==========
                    if (_selectedStudentId == null) ...[
                      TextField(
                        controller: _searchController,
                        onChanged: _searchStudents,
                        decoration: InputDecoration(
                          hintText: 'Search student by name or admission...',
                          prefixIcon:
                              const Icon(Icons.search, color: primaryPurple),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchStudents('');
                                  },
                                )
                              : null,
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
                      ),
                      const SizedBox(height: 12),

                      // ========== STUDENTS LIST ==========
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: _filteredStudents.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(30),
                                child: Center(
                                  child: Text('No students found',
                                      style: TextStyle(color: Colors.grey)),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: _filteredStudents.length,
                                itemBuilder: (context, index) {
                                  final s = _filteredStudents[index];
                                  return InkWell(
                                    onTap: () => _selectStudent(s['id'] as int),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade200,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  primaryPurple,
                                                  secondaryPurple
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Center(
                                              child: Text(
                                                (s['name'] ?? 'S')
                                                    .toString()
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  s['name'] ?? '',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: Color(0xFF1F2937),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Class ${s['class'] ?? ''}-${s['section'] ?? ''} • Roll: ${s['roll_no'] ?? 'N/A'}',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: Colors.grey),
                                                ),
                                                Text(
                                                  'Admission: ${s['admission_no'] ?? ''}',
                                                  style: const TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios,
                                              size: 14, color: Colors.grey),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ========== SELECTED STUDENT FULL DETAILS ==========
                    if (_selectedStudentId != null &&
                        _selectedStudent != null &&
                        _selectedStudent!.isNotEmpty) ...[
                      // Clear/Change button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _sectionHeader('Student Details'),
                          TextButton.icon(
                            onPressed: _clearSelection,
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Change Student',
                                style: TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primaryPurple, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Header
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [primaryPurple, secondaryPurple],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      (_selectedStudent!['name'] ?? 'S')
                                          .toString()
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedStudent!['name'] ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: primaryPurple.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          _selectedStudent!['admission_no'] ??
                                              'N/A',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: primaryPurple,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Info Grid
                            Row(
                              children: [
                                Expanded(
                                  child: _studentInfoItem(
                                    Icons.class_,
                                    'Class',
                                    _selectedStudent!['class'] ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _studentInfoItem(
                                    Icons.group,
                                    'Section',
                                    _selectedStudent!['section'] ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _studentInfoItem(
                                    Icons.numbers,
                                    'Roll No',
                                    _selectedStudent!['roll_no'] ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _studentInfoItem(
                                    Icons.email,
                                    'Email',
                                    _selectedStudent!['email'] ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _studentInfoItem(
                                    Icons.phone,
                                    'Phone',
                                    _selectedStudent!['phone'] ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _studentInfoItem(
                                    Icons.family_restroom,
                                    'Parent Name',
                                    _selectedStudent!['parent_name'] ?? 'N/A',
                                  ),
                                ),
                                Expanded(
                                  child: _studentInfoItem(
                                    Icons.phone_android,
                                    'Parent Phone',
                                    _selectedStudent!['parent_phone'] ?? 'N/A',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ========== FEE INFO ==========
                    if (_selectedStudent != null && _feeInfo != null) ...[
                      _sectionHeader('Fee Details'),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryPurple.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _feeRow(
                              'Total Fee',
                              _formatCurrency(
                                  (_feeInfo!['total_amount'] ?? 0).toDouble()),
                              Colors.black87,
                            ),
                            const Divider(height: 16),
                            _feeRow(
                              'Already Paid',
                              _formatCurrency(
                                  (_feeInfo!['paid_amount'] ?? 0).toDouble()),
                              const Color(0xFF16A34A),
                            ),
                            const Divider(height: 16),
                            _feeRow(
                              'Current Due',
                              _formatCurrency(
                                ((_feeInfo!['total_amount'] ?? 0) -
                                        (_feeInfo!['paid_amount'] ?? 0))
                                    .toDouble(),
                              ),
                              const Color(0xFFDC2626),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ========== PAYMENT DETAILS ==========
                    if (_selectedStudentId != null) ...[
                      _sectionHeader('Payment Details'),
                      const SizedBox(height: 12),

                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: 'Amount (₹)',
                            hintText: '0.00',
                            prefixIcon: const Icon(Icons.currency_rupee,
                                color: primaryPurple),
                            prefixText: '₹ ',
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
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Amount is required';
                            }
                            final amount = double.tryParse(v);
                            if (amount == null || amount <= 0) {
                              return 'Enter valid amount';
                            }
                            return null;
                          },
                        ),
                      ),

                      // Quick amount buttons
                      if (_feeInfo != null) ...[
                        const Text('Quick amounts:',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _quickAmountChip(
                              'Full Due',
                              ((_feeInfo!['total_amount'] ?? 0) -
                                      (_feeInfo!['paid_amount'] ?? 0))
                                  .toDouble(),
                            ),
                            _quickAmountChip('₹5,000', 5000),
                            _quickAmountChip('₹10,000', 10000),
                            _quickAmountChip('₹25,000', 25000),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Payment Method
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          value: _selectedMethod,
                          decoration: InputDecoration(
                            labelText: 'Payment Method',
                            prefixIcon:
                                const Icon(Icons.payment, color: primaryPurple),
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
                          items: _methods
                              .map((m) =>
                                  DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedMethod = v!),
                        ),
                      ),

                      // Transaction ID
                      if (_selectedMethod != 'Cash')
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: TextFormField(
                            controller: _transactionIdController,
                            decoration: InputDecoration(
                              labelText: 'Transaction/Cheque ID',
                              prefixIcon: const Icon(Icons.receipt,
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
                          ),
                        ),

                      // Notes
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: TextFormField(
                          controller: _notesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Notes (Optional)',
                            hintText: 'Any additional notes...',
                            prefixIcon:
                                const Icon(Icons.notes, color: primaryPurple),
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
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Auto-calc info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF16A34A).withOpacity(0.2),
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Color(0xFF16A34A), size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Auto Calculation',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Payment will automatically deduct from dues.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _recordPayment,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check_circle),
                          label: Text(
                              _isSaving ? 'Recording...' : 'Record Payment'),
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
                  ],
                ),
              ),
            ),
    );
  }

  Widget _studentInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: primaryPurple),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _quickAmountChip(String label, double amount) {
    return GestureDetector(
      onTap: () {
        _amountController.text = amount.toStringAsFixed(0);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: primaryPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryPurple.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: primaryPurple,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _feeRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
}
