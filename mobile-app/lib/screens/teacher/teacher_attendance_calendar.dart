import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherAttendanceCalendar extends StatefulWidget {
  const TeacherAttendanceCalendar({super.key});

  @override
  State<TeacherAttendanceCalendar> createState() =>
      _TeacherAttendanceCalendarState();
}

class _TeacherAttendanceCalendarState extends State<TeacherAttendanceCalendar> {
  static const Color primaryGreen = Color(0xFF16A34A);
  static const Color secondaryGreen = Color(0xFF22C55E);

  List<dynamic> _stats = [];
  Map<String, Map<String, dynamic>> _statsMap = {};
  bool _isLoading = true;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String? _selectedDate;
  String? _inchargeClass;
  String? _inchargeSection;

  final List<String> _monthNames = [
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

  @override
  void initState() {
    super.initState();
    _loadInchargeInfo().then((_) => _fetchStats());
  }

  Future<void> _loadInchargeInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://sghps-backend.onrender.com/api/teacher/check-incharge'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _inchargeClass = data['incharge_class'];
          _inchargeSection = data['incharge_section'];
        });
      }
    } catch (e) {
      print('Error loading incharge info: $e');
    }
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    if (_inchargeClass == null || _inchargeSection == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://sghps-backend.onrender.com/api/attendance/class-stats?class=$_inchargeClass&section=$_inchargeSection&month=$_selectedMonth&year=$_selectedYear'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = data['stats'] as List;

        Map<String, Map<String, dynamic>> map = {};
        for (var s in stats) {
          map[s['date']] = {
            'total': s['total'] ?? 0,
            'present': s['present'] ?? 0,
            'absent': s['absent'] ?? 0,
            'late': s['late'] ?? 0,
          };
        }

        setState(() {
          _stats = stats;
          _statsMap = map;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
      _selectedDate = null;
    });
    _fetchStats();
  }

  Color _getDateColor(String? dateStr) {
    if (dateStr == null) return Colors.transparent;
    final stat = _statsMap[dateStr];
    if (stat == null) return Colors.transparent;

    final total = stat['total'] ?? 0;
    final present = stat['present'] ?? 0;

    if (total == 0) return Colors.transparent;

    final percentage = (present / total) * 100;
    if (percentage >= 90) return const Color(0xFF16A34A);
    if (percentage >= 75) return const Color(0xFFF59E0B);
    return const Color(0xFFDC2626);
  }

  Map<String, dynamic>? get _selectedDateStats {
    if (_selectedDate == null) return null;
    return _statsMap[_selectedDate!];
  }

  bool _isToday(String dateStr) {
    final today = DateTime.now().toIso8601String().split('T')[0];
    return dateStr == today;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Attendance History'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
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
                    child: Row(
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 50)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Class Attendance',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              Text(
                                '${_inchargeClass ?? ''} - ${_inchargeSection ?? ''}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_stats.length} days recorded',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // ========== VIEW ONLY BADGE ==========
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF3498DB).withOpacity(0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.visibility,
                            color: Color(0xFF3498DB), size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'View only - To edit today\'s attendance, go to Mark Attendance screen.',
                            style: TextStyle(
                                fontSize: 11, color: Color(0xFF3498DB)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ========== MONTH NAVIGATION ==========
                  Container(
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left,
                              color: primaryGreen, size: 30),
                          onPressed: () => _changeMonth(-1),
                        ),
                        Text(
                          '${_monthNames[_selectedMonth - 1]} $_selectedYear',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right,
                              color: primaryGreen, size: 30),
                          onPressed: () => _changeMonth(1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ========== CALENDAR ==========
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                              .map((day) => Expanded(
                                    child: Center(
                                      child: Text(
                                        day,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        _buildCalendarGrid(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ========== LEGEND ==========
                  Container(
                    padding: const EdgeInsets.all(16),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _legendItem('≥90%', const Color(0xFF16A34A)),
                        _legendItem('≥75%', const Color(0xFFF59E0B)),
                        _legendItem('<75%', const Color(0xFFDC2626)),
                        _legendItem('No Data', const Color(0xFFE5E7EB)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ========== SELECTED DATE DETAILS ==========
                  if (_selectedDate != null && _selectedDateStats != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Attendance: $_selectedDate',
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937)),
                            ),
                            if (_isToday(_selectedDate!)) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text('TODAY',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _selectedDate = null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _detailStat(
                            'Total',
                            '${_selectedDateStats!['total']}',
                            Icons.people,
                            const Color(0xFF3498DB),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _detailStat(
                            'Present',
                            '${_selectedDateStats!['present']}',
                            Icons.check_circle,
                            const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _detailStat(
                            'Absent',
                            '${_selectedDateStats!['absent']}',
                            Icons.cancel,
                            const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _detailStat(
                            'Late',
                            '${_selectedDateStats!['late']}',
                            Icons.schedule,
                            const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ========== RECENT RECORDS ==========
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Recent Records',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'View Only',
                          style: const TextStyle(
                              color: primaryGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_stats.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.event_busy, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('No attendance records',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  else
                    ..._stats.reversed.take(10).map((s) {
                      final total = s['total'] ?? 0;
                      final present = s['present'] ?? 0;
                      final percentage =
                          total > 0 ? ((present / total) * 100).round() : 0;

                      final color = percentage >= 90
                          ? const Color(0xFF16A34A)
                          : percentage >= 75
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFDC2626);

                      final isToday = _isToday(s['date']);

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = s['date']),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: isToday
                                ? Border.all(color: primaryGreen, width: 2)
                                : null,
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
                                child: Icon(Icons.calendar_today,
                                    color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          s['date'],
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        if (isToday) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: primaryGreen,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text('TODAY',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${s['present']} present • ${s['absent']} absent • ${s['late']} late',
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
                                  '$percentage%',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;

    List<Widget> dayWidgets = [];

    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr =
          '$_selectedYear-${_selectedMonth.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final hasData = _statsMap.containsKey(dateStr);
      final isSelected = _selectedDate == dateStr;
      final isToday = _isToday(dateStr);
      final color = hasData ? _getDateColor(dateStr) : Colors.grey.shade300;

      dayWidgets.add(
        GestureDetector(
          onTap: hasData
              ? () {
                  setState(() {
                    _selectedDate = isSelected ? null : dateStr;
                  });
                }
              : null,
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryGreen
                  : hasData
                      ? color.withOpacity(0.15)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday
                  ? Border.all(color: primaryGreen, width: 2)
                  : isSelected
                      ? Border.all(color: primaryGreen, width: 2)
                      : !hasData
                          ? Border.all(color: Colors.grey.shade200)
                          : null,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : hasData
                              ? color
                              : Colors.black87,
                      fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (isToday && !isSelected)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1,
      children: dayWidgets,
    );
  }

  Widget _detailStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
