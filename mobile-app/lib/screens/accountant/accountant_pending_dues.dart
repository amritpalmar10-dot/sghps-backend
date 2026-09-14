import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantPendingDues extends StatefulWidget {
  const AccountantPendingDues({super.key});

  @override
  State<AccountantPendingDues> createState() => _AccountantPendingDuesState();
}

class _AccountantPendingDuesState extends State<AccountantPendingDues> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  List<dynamic> _dues = [];
  List<dynamic> _filteredDues = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'Amount';
  String _filterRange = 'All';

  @override
  void initState() {
    super.initState();
    _fetchDues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDues() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/pending-dues'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _dues = data['pending'] ?? [];
          _applySortAndFilter();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _applySortAndFilter() {
    List<dynamic> base = _dues;

    // Search
    if (_searchController.text.isNotEmpty) {
      final q = _searchController.text.toLowerCase();
      base = base.where((d) {
        final name = (d['name'] ?? '').toString().toLowerCase();
        final admission = (d['admission_no'] ?? '').toString().toLowerCase();
        return name.contains(q) || admission.contains(q);
      }).toList();
    }

    // Filter by range
    if (_filterRange == 'High') {
      base = base.where((d) => (d['due_amount'] ?? 0) > 20000).toList();
    } else if (_filterRange == 'Medium') {
      base = base
          .where((d) =>
              (d['due_amount'] ?? 0) >= 10000 &&
              (d['due_amount'] ?? 0) <= 20000)
          .toList();
    } else if (_filterRange == 'Low') {
      base = base.where((d) => (d['due_amount'] ?? 0) < 10000).toList();
    }

    // Sort
    base = List.from(base);
    if (_sortBy == 'Amount') {
      base.sort(
          (a, b) => (b['due_amount'] ?? 0).compareTo(a['due_amount'] ?? 0));
    } else if (_sortBy == 'Name') {
      base.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_sortBy == 'Class') {
      base.sort((a, b) => (a['class'] ?? '').compareTo(b['class'] ?? ''));
    }

    setState(() => _filteredDues = base);
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

  double get _totalPending {
    double total = 0;
    for (var d in _filteredDues) {
      total += (d['due_amount'] ?? 0).toDouble();
    }
    return total;
  }

  Future<void> _sendReminder(dynamic due) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.message, color: primaryPurple),
            SizedBox(width: 8),
            Text('Send Reminder'),
          ],
        ),
        content: Text(
          'Send fee reminder to:\n\n${due['name']}\n${due['phone'] ?? 'N/A'}\n\nAmount Due: ${_formatCurrency((due['due_amount'] ?? 0).toDouble())}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send'),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Reminder sent to ${due['name']}'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Future<void> _sendBulkReminder() async {
    if (_filteredDues.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Bulk Reminders?'),
        content: Text(
          'Send fee reminders to all ${_filteredDues.length} students with pending dues?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
            child: const Text('Send All'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ ${_filteredDues.length} reminders sent successfully!'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  Color _urgencyColor(double dueAmount) {
    if (dueAmount > 20000) return const Color(0xFFDC2626);
    if (dueAmount > 10000) return const Color(0xFFF59E0B);
    return const Color(0xFF3498DB);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Pending Dues'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            tooltip: 'Send Bulk Reminders',
            onPressed: _sendBulkReminder,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ========== HEADER ==========
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryPurple, secondaryPurple],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('⚠️', style: TextStyle(fontSize: 45)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Pending',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 13)),
                            Text(
                              _formatCurrency(_totalPending),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_filteredDues.length} students with dues',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== SEARCH + FILTERS ==========
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Search
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => _applySortAndFilter(),
                        decoration: InputDecoration(
                          hintText: 'Search by name or admission no...',
                          prefixIcon:
                              const Icon(Icons.search, color: primaryPurple),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _applySortAndFilter();
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

                      // Filter row
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filterRange,
                                  isExpanded: true,
                                  icon: const Icon(Icons.filter_alt,
                                      size: 18, color: primaryPurple),
                                  items: [
                                    'All',
                                    'High', // >20K
                                    'Medium', // 10K-20K
                                    'Low', // <10K
                                  ]
                                      .map((r) => DropdownMenuItem(
                                          value: r,
                                          child: Text('Dues: $r',
                                              style: const TextStyle(
                                                  fontSize: 12))))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _filterRange = v!);
                                    _applySortAndFilter();
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _sortBy,
                                  isExpanded: true,
                                  icon: const Icon(Icons.sort,
                                      size: 18, color: primaryPurple),
                                  items: ['Amount', 'Name', 'Class']
                                      .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text('Sort: $s',
                                              style: const TextStyle(
                                                  fontSize: 12))))
                                      .toList(),
                                  onChanged: (v) {
                                    setState(() => _sortBy = v!);
                                    _applySortAndFilter();
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ========== STATS SUMMARY ==========
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: primaryPurple.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: primaryPurple, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_filteredDues.length} results',
                        style: const TextStyle(
                          color: primaryPurple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _sendBulkReminder,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryPurple,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.send, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text('Remind All',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== DUES LIST ==========
                Expanded(
                  child: _filteredDues.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 80, color: Color(0xFF16A34A)),
                              SizedBox(height: 12),
                              Text('No pending dues! 🎉',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDues.length,
                          itemBuilder: (context, index) {
                            final d = _filteredDues[index];
                            final due = (d['due_amount'] ?? 0).toDouble();
                            final total = (d['total_amount'] ?? 0).toDouble();
                            final paid = (d['paid_amount'] ?? 0).toDouble();
                            final color = _urgencyColor(due);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.15),
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
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              color,
                                              color.withValues(alpha: 0.7),
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            (d['name'] ?? 'S')
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
                                              d['name'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Class ${d['class'] ?? ''}-${d['section'] ?? ''} • ${d['admission_no'] ?? ''}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _formatCurrency(due),
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Progress
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Paid: ${_formatCurrency(paid)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            ),
                                            Text(
                                              'Total: ${_formatCurrency(total)}',
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: LinearProgressIndicator(
                                            value: total > 0 ? paid / total : 0,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation(color),
                                            minHeight: 5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _sendReminder(d),
                                          icon: const Icon(Icons.message,
                                              size: 16),
                                          label: const Text('Remind'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: primaryPurple,
                                            side: const BorderSide(
                                                color: primaryPurple),
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            await Navigator.pushNamed(
                                              context,
                                              '/accountant-record-payment',
                                              arguments: {
                                                'student_id': d['id']
                                              },
                                            );
                                            _fetchDues();
                                          },
                                          icon: const Icon(Icons.payment,
                                              size: 16),
                                          label: const Text('Pay'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryPurple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
