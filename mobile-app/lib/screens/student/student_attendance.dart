import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentAttendance extends StatefulWidget {
  const StudentAttendance({super.key});

  @override
  State<StudentAttendance> createState() => _StudentAttendanceState();
}

class _StudentAttendanceState extends State<StudentAttendance>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color secondaryGreen = Color(0xFF22C55E);

  late TabController _tabController;

  Map<String, dynamic> _todayAttendance = {};
  List<dynamic> _allRecords = [];
  Map<String, dynamic> _stats = {};
  bool _isLoadingToday = true;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchTodayAttendance();
    _fetchAllAttendance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ TODAY'S ATTENDANCE
  Future<void> _fetchTodayAttendance() async {
    setState(() => _isLoadingToday = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final response = await http.get(
        Uri.parse('https://sghps-backend.onrender.com/api/students/attendance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final records = data['attendance'] as List? ?? [];

        // Find today's record
        Map<String, dynamic> todayRecord = {};
        for (var r in records) {
          if (r['date'] == today) {
            todayRecord = r;
            break;
          }
        }

        setState(() {
          _todayAttendance = todayRecord;
          _isLoadingToday = false;
        });
      } else {
        setState(() => _isLoadingToday = false);
      }
    } catch (e) {
      setState(() => _isLoadingToday = false);
    }
  }

  // ✅ ALL ATTENDANCE (History + Stats)
  Future<void> _fetchAllAttendance() async {
    setState(() => _isLoadingHistory = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://sghps-backend.onrender.com/api/students/attendance'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allRecords = data['attendance'] ?? [];
          _stats = {
            'total': data['total'] ?? 0,
            'present': data['present'] ?? 0,
            'percentage': data['percentage'] ?? 0,
          };
          _isLoadingHistory = false;
        });
      } else {
        setState(() => _isLoadingHistory = false);
      }
    } catch (e) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'present':
        return const Color(0xFF16A34A);
      case 'absent':
        return const Color(0xFFDC2626);
      case 'late':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3498DB);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Attendance'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'TODAY', icon: Icon(Icons.today, size: 18)),
            Tab(text: 'HISTORY', icon: Icon(Icons.history, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // ========== TODAY TAB ==========
  Widget _buildTodayTab() {
    final today = DateTime.now();
    final dateStr = '${today.day}/${today.month}/${today.year}';
    final dayName = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][today.weekday - 1];

    if (_isLoadingToday) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasAttendance = _todayAttendance.isNotEmpty;
    final status = _todayAttendance['status'];
    final statusColor =
        hasAttendance ? _statusColor(status) : const Color(0xFFF59E0B);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Big Status Card
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: statusColor, width: 4),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasAttendance
                        ? status == 'present'
                            ? Icons.check_circle
                            : status == 'absent'
                                ? Icons.cancel
                                : Icons.schedule
                        : Icons.hourglass_empty,
                    color: statusColor,
                    size: 70,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasAttendance
                        ? status.toString().toUpperCase()
                        : 'NOT MARKED',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Date & Day
          Text(
            dayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            dateStr,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),

          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.calendar_today,
                          color: primaryGreen, size: 22),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Today\'s Status',
                              style:
                                  TextStyle(fontSize: 13, color: Colors.grey)),
                          Text(
                            hasAttendance
                                ? 'Marked by ${_todayAttendance['teacher_name'] ?? 'Teacher'}'
                                : 'Pending',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        hasAttendance ? 'COMPLETED' : 'WAITING',
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Message
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: hasAttendance
                  ? primaryGreen.withOpacity(0.08)
                  : const Color(0xFFF59E0B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasAttendance
                    ? primaryGreen.withOpacity(0.2)
                    : const Color(0xFFF59E0B).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasAttendance ? Icons.info_outline : Icons.access_time,
                  color: hasAttendance ? primaryGreen : const Color(0xFFF59E0B),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hasAttendance
                        ? "Today's attendance is marked. Check HISTORY tab for past records."
                        : "Attendance is not marked yet. Please wait for your teacher.",
                    style: TextStyle(
                      fontSize: 12,
                      color: hasAttendance
                          ? primaryGreen
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ========== HISTORY TAB ==========
  Widget _buildHistoryTab() {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryGreen, secondaryGreen],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryGreen.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text('Overall Attendance',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 10),
                Text(
                  '${_stats['percentage'] ?? 0}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_stats['present'] ?? 0} present out of ${_stats['total'] ?? 0} days',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Records List
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Attendance Records',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
          ),
          const SizedBox(height: 12),

          if (_allRecords.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Icon(Icons.event_busy, size: 60, color: Colors.grey),
                  SizedBox(height: 10),
                  Text('No attendance records',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          else
            ..._allRecords.map((record) {
              final status = record['status'] as String;
              final color = _statusColor(status);
              final date = record['date'] as String;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        status == 'present'
                            ? Icons.check_circle
                            : status == 'absent'
                                ? Icons.cancel
                                : Icons.schedule,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(date),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _getDayName(date),
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return 'Today';
      } else if (date.year == yesterday.year &&
          date.month == yesterday.month &&
          date.day == yesterday.day) {
        return 'Yesterday';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  String _getDayName(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][date.weekday - 1];
    } catch (e) {
      return '';
    }
  }
}
