import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantTeacherDetail extends StatefulWidget {
  final int? teacherId;

  const AccountantTeacherDetail({
    super.key,
    this.teacherId,
  });

  @override
  State<AccountantTeacherDetail> createState() =>
      _AccountantTeacherDetailState();
}

class _AccountantTeacherDetailState extends State<AccountantTeacherDetail> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  Map<String, dynamic> _teacher = {};
  bool _isLoading = true;
  int? _actualTeacherId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _resolveTeacherId();
    });
  }

  void _resolveTeacherId() {
    final args = ModalRoute.of(context)?.settings.arguments;

    print('🔍 Teacher Detail - Arguments: $args');
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
        print('📥 Fetched teacher: ${data['teacher']['name']}');
        setState(() {
          _teacher = data['teacher'] ?? {};
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

  @override
  Widget build(BuildContext context) {
    final isIncharge = _teacher['is_class_incharge'] == 1;
    final inchargeColor =
        isIncharge ? const Color(0xFFF59E0B) : const Color(0xFF3498DB);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Teacher Details'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              if (_actualTeacherId != null) {
                await Navigator.pushNamed(
                  context,
                  '/accountant-edit-teacher',
                  arguments: {'id': _actualTeacherId},
                );
                _fetchTeacher();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _teacher.isEmpty
              ? const Center(
                  child: Text('Teacher not found',
                      style: TextStyle(color: Colors.grey)),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ========== HEADER CARD ==========
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
                              _teacher['name'] ?? 'Teacher',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_teacher['designation'] ?? 'Teacher'} • ${_teacher['subject'] ?? ''}',
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
                                _teacher['staff_code'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isIncharge) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Class Incharge: ${_teacher['incharge_class'] ?? ''}-${_teacher['incharge_section'] ?? ''}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ========== INCHARGE STATUS ==========
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: inchargeColor.withOpacity(0.15),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: inchargeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isIncharge ? Icons.star : Icons.person,
                                color: inchargeColor,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isIncharge
                                        ? 'Class Incharge'
                                        : 'Subject Teacher',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: inchargeColor,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    isIncharge
                                        ? 'Can mark attendance & approve leaves'
                                        : 'Regular subject teacher',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ========== INFO ==========
                      const Text('Personal Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      const SizedBox(height: 12),

                      _infoTile(
                          Icons.email, 'Email', _teacher['email'] ?? 'N/A'),
                      _infoTile(
                          Icons.phone, 'Phone', _teacher['phone'] ?? 'N/A'),

                      const SizedBox(height: 20),

                      const Text('Professional Information',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      const SizedBox(height: 12),

                      _infoTile(Icons.badge, 'Staff Code',
                          _teacher['staff_code'] ?? 'N/A'),
                      _infoTile(
                          Icons.book, 'Subject', _teacher['subject'] ?? 'N/A'),
                      _infoTile(Icons.workspace_premium, 'Designation',
                          _teacher['designation'] ?? 'N/A'),
                      _infoTile(
                          Icons.attach_money,
                          'Monthly Salary',
                          _formatCurrency(
                              (_teacher['salary'] ?? 0).toDouble())),

                      if (isIncharge) ...[
                        const SizedBox(height: 20),
                        const Text('Class Incharge Details',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937))),
                        const SizedBox(height: 12),
                        _infoTile(
                          Icons.class_,
                          'Incharge Class',
                          '${_teacher['incharge_class'] ?? ''}-${_teacher['incharge_section'] ?? ''}',
                        ),
                      ],

                      const SizedBox(height: 25),

                      // ========== ACTIONS ==========
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (_actualTeacherId != null) {
                                  await Navigator.pushNamed(
                                    context,
                                    '/accountant-edit-teacher',
                                    arguments: {'id': _actualTeacherId},
                                  );
                                  _fetchTeacher();
                                }
                              },
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
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
                                    content: Text('📞 Calling teacher...'),
                                    backgroundColor: primaryPurple,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('Contact'),
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
                    ],
                  ),
                ),
    );
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
