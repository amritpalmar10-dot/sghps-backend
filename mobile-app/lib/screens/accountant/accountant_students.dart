import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantStudents extends StatefulWidget {
  const AccountantStudents({super.key});

  @override
  State<AccountantStudents> createState() => _AccountantStudentsState();
}

class _AccountantStudentsState extends State<AccountantStudents> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  List<dynamic> _students = [];
  List<dynamic> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/students'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _students = data['students'] ?? [];
          _filteredStudents = _students;
          _isLoading = false;
        });
        print('📋 Loaded ${_students.length} students');
        for (var s in _students) {
          print('   → ID: ${s['id']}, Name: ${s['name']}');
        }
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
        _filteredStudents = _students.where((s) {
          final name = (s['name'] ?? '').toString().toLowerCase();
          final admissionNo =
              (s['admission_no'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || admissionNo.contains(q);
        }).toList();
      }
      if (_filterStatus != 'All') {
        _filteredStudents = _filteredStudents
            .where((s) =>
                (s['fee_status'] ?? '').toString().toLowerCase() ==
                _filterStatus.toLowerCase())
            .toList();
      }
    });
  }

  void _applyFilter(String status) {
    setState(() {
      _filterStatus = status;
      if (status == 'All') {
        _filteredStudents = _students;
      } else {
        _filteredStudents = _students
            .where((s) =>
                (s['fee_status'] ?? '').toString().toLowerCase() ==
                status.toLowerCase())
            .toList();
      }
      if (_searchController.text.isNotEmpty) {
        _searchStudents(_searchController.text);
      }
    });
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

  String _statusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid':
        return 'PAID';
      case 'partially_paid':
        return 'PARTIAL';
      case 'overdue':
        return 'OVERDUE';
      default:
        return 'DUE';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('All Students'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ========== SEARCH BAR ==========
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _searchStudents,
                        decoration: InputDecoration(
                          hintText: 'Search by name or admission no...',
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('All', primaryPurple),
                            const SizedBox(width: 8),
                            _filterChip('Paid', const Color(0xFF16A34A)),
                            const SizedBox(width: 8),
                            _filterChip(
                                'Partially_paid', const Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            _filterChip('Due', const Color(0xFF3498DB)),
                            const SizedBox(width: 8),
                            _filterChip('Overdue', const Color(0xFFDC2626)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== STATS BAR ==========
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: primaryPurple.withOpacity(0.05),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: primaryPurple, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_filteredStudents.length} students found',
                        style: const TextStyle(
                          color: primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== STUDENTS LIST ==========
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              const Text('No students found',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final s = _filteredStudents[index];
                            final total = (s['total_amount'] ?? 0).toDouble();
                            final paid = (s['paid_amount'] ?? 0).toDouble();
                            final due = total - paid;
                            final statusColor =
                                _statusColor(s['fee_status'] as String?);
                            final studentId = s['id']; // ← IMPORTANT

                            return GestureDetector(
                              onTap: () {
                                print(
                                    '🎯 Clicked student: ${s['name']} (ID: $studentId)');
                                Navigator.pushNamed(
                                  context,
                                  '/accountant-student-detail',
                                  arguments: {'id': studentId},
                                ).then((_) => _fetchStudents());
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
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
                                                fontSize: 20,
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
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 3),
                                              Text(
                                                'Class ${s['class'] ?? ''}-${s['section'] ?? ''} • ${s['admission_no'] ?? ''}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: statusColor.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            _statusLabel(
                                                s['fee_status'] as String?),
                                            style: TextStyle(
                                              color: statusColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Paid: ${_formatCurrency(paid)}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'Due: ${_formatCurrency(due)}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: LinearProgressIndicator(
                                              value:
                                                  total > 0 ? paid / total : 0,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                      statusColor),
                                              minHeight: 6,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                'Total: ${_formatCurrency(total)}',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey),
                                              ),
                                              const Spacer(),
                                              Text(
                                                '${total > 0 ? ((paid / total) * 100).round() : 0}% paid',
                                                style: const TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/accountant-add-student');
          _fetchStudents();
        },
        backgroundColor: primaryPurple,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _filterChip(String label, Color color) {
    final isSelected = _filterStatus == label;
    final displayLabel =
        label.replaceAll('_', ' ').replaceAll('Partially paid', 'Partial');

    return GestureDetector(
      onTap: () => _applyFilter(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
