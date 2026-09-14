import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantStudentDetail extends StatefulWidget {
  final int? studentId;

  const AccountantStudentDetail({
    super.key,
    this.studentId,
  });

  @override
  State<AccountantStudentDetail> createState() =>
      _AccountantStudentDetailState();
}

class _AccountantStudentDetailState extends State<AccountantStudentDetail> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  Map<String, dynamic> _student = {};
  Map<String, dynamic> _fees = {};
  List<dynamic> _payments = [];
  bool _isLoading = true;
  int? _actualStudentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveStudentId();
    });
  }

  void _resolveStudentId() {
    // Priority 1: Get from arguments
    final args = ModalRoute.of(context)?.settings.arguments;

    print('🔍 Arguments received: $args');
    print('🔍 Widget studentId: ${widget.studentId}');

    if (args != null && args is Map && args['id'] != null) {
      _actualStudentId = args['id'] as int;
    } else if (widget.studentId != null) {
      _actualStudentId = widget.studentId;
    }

    print('🔍 Actual student ID: $_actualStudentId');

    if (_actualStudentId != null) {
      _fetchDetail();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDetail() async {
    if (_actualStudentId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://sghps-backend.onrender.com/api/accountant/student/$_actualStudentId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📥 Fetched: ${data['student']['name']}');
        setState(() {
          _student = data['student'] ?? {};
          _fees = data['fees'] ?? {};
          _payments = data['payments'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
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

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return const Color(0xFF16A34A);
      case 'partially_paid':
        return const Color(0xFFF59E0B);
      case 'overdue':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF3498DB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = (_fees['total_amount'] ?? 0).toDouble();
    final paid = (_fees['paid_amount'] ?? 0).toDouble();
    final due = total - paid;
    final statusColor = _statusColor(_fees['status'] as String?);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_actualStudentId != null) {
                await Navigator.pushNamed(
                  context,
                  '/accountant-edit-student',
                  arguments: {'id': _actualStudentId},
                );
                _fetchDetail();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _student.isEmpty
              ? const Center(
                  child: Text('Student not found',
                      style: TextStyle(color: Colors.grey)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========== STUDENT HEADER ==========
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
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(Icons.person,
                                  size: 45, color: Colors.white),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _student['name'] ?? 'Student',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class ${_student['class'] ?? ''}-${_student['section'] ?? ''} • Roll ${_student['roll_no'] ?? 'N/A'}',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _student['admission_no'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ========== FEE SUMMARY ==========
                      const Text('Fee Summary',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Fee',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                                Text(_formatCurrency(total),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Color(0xFF16A34A), size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Paid',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey)),
                                  ],
                                ),
                                Text(_formatCurrency(paid),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A))),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.pending,
                                        color: statusColor, size: 18),
                                    const SizedBox(width: 8),
                                    const Text('Due Amount',
                                        style: TextStyle(
                                            fontSize: 14, color: Colors.grey)),
                                  ],
                                ),
                                Text(_formatCurrency(due),
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: total > 0 ? paid / total : 0,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation(statusColor),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${total > 0 ? ((paid / total) * 100).round() : 0}% paid',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: statusColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (_fees['status'] ?? 'due')
                                        .toString()
                                        .toUpperCase()
                                        .replaceAll('_', ' '),
                                    style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ========== ACTION BUTTONS ==========
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (_actualStudentId != null) {
                                  await Navigator.pushNamed(
                                    context,
                                    '/accountant-record-payment',
                                    arguments: {'student_id': _actualStudentId},
                                  );
                                  _fetchDetail();
                                }
                              },
                              icon: const Icon(Icons.payment, size: 18),
                              label: const Text('Record Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryPurple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📱 Reminder sent!'),
                                    backgroundColor: primaryPurple,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.message, size: 18),
                              label: const Text('Send Reminder'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryPurple,
                                side: const BorderSide(color: primaryPurple),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ========== STUDENT INFO ==========
                      const Text('Student Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      const SizedBox(height: 12),

                      _infoTile(
                          Icons.email, 'Email', _student['email'] ?? 'N/A'),
                      _infoTile(
                          Icons.phone, 'Phone', _student['phone'] ?? 'N/A'),
                      _infoTile(Icons.family_restroom, 'Parent Name',
                          _student['parent_name'] ?? 'N/A'),
                      _infoTile(Icons.phone_android, 'Parent Phone',
                          _student['parent_phone'] ?? 'N/A'),
                      _infoTile(
                          Icons.home, 'Address', _student['address'] ?? 'N/A'),

                      const SizedBox(height: 20),

                      // ========== PAYMENT HISTORY ==========
                      const Text('Payment History',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      const SizedBox(height: 12),

                      if (_payments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.receipt_long,
                                  size: 50, color: Colors.grey),
                              SizedBox(height: 10),
                              Text('No payments yet',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      else
                        ..._payments.map((p) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade200,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.check_circle,
                                      color: Color(0xFF16A34A), size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatCurrency(
                                            (p['amount'] ?? 0).toDouble()),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Color(0xFF16A34A)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${p['method'] ?? 'Cash'} • ${p['receipt_number'] ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                      Text(
                                        _formatDate(p['payment_date']),
                                        style: const TextStyle(
                                            fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.download,
                                      color: primaryPurple, size: 22),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('📄 Receipt download'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryPurple, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
