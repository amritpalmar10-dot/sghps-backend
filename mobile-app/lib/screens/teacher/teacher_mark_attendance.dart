import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class TeacherMarkAttendance extends StatefulWidget {
  const TeacherMarkAttendance({super.key});

  @override
  State<TeacherMarkAttendance> createState() => _TeacherMarkAttendanceState();
}

class _TeacherMarkAttendanceState extends State<TeacherMarkAttendance> {
  static const Color primaryGreen = Color(0xFF16A34A);

  String _inchargeClass = '';
  String _inchargeSection = '';
  bool _isLoading = false;
  bool _isFetching = true;
  bool _isEditMode = false;
  bool _attendanceAlreadyMarked = false;

  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  // ✅ STEP 1: Load Incharge Info + Today's Attendance
  Future<void> _initializeScreen() async {
    setState(() => _isFetching = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      // 1. Check incharge info
      final checkResponse = await http.get(
        Uri.parse(
            'https://sghps-backend.onrender.com/api/teacher/check-incharge'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (checkResponse.statusCode == 200) {
        final data = json.decode(checkResponse.body);

        if (data['is_class_incharge'] != true) {
          // ❌ Not a class incharge
          setState(() {
            _isFetching = false;
          });
          return;
        }

        setState(() {
          _inchargeClass = data['incharge_class'] ?? '';
          _inchargeSection = data['incharge_section'] ?? '';
        });

        // 2. Load today's attendance
        await _loadTodayAttendance(token);
      }
    } catch (e) {
      setState(() => _isFetching = false);
    }
  }

  // ✅ STEP 2: Load Today's Attendance
  Future<void> _loadTodayAttendance(String token) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final attResponse = await http.get(
        Uri.parse(
            'https://sghps-backend.onrender.com/api/attendance/by-date?date=$today&class=$_inchargeClass&section=$_inchargeSection'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (attResponse.statusCode == 200) {
        final data = json.decode(attResponse.body);
        final existing = data['attendance'] as List;

        if (existing.isNotEmpty) {
          // ✅ Already marked
          setState(() {
            _students = existing
                .map<Map<String, dynamic>>((a) => {
                      'id': a['student_id'],
                      'name': a['student_name'],
                      'roll': a['roll_no'],
                      'status': a['status'],
                    })
                .toList();
            _attendanceAlreadyMarked = true;
            _isEditMode = false;
            _isFetching = false;
          });
        } else {
          // ✅ Fresh slate - Load students
          await _loadStudentsForMarking(token);
        }
      }
    } catch (e) {
      setState(() => _isFetching = false);
    }
  }

  // ✅ STEP 3: Load Students for Fresh Marking
  Future<void> _loadStudentsForMarking(String token) async {
    final studentsResponse = await http.get(
      Uri.parse(
          'https://sghps-backend.onrender.com/api/principal/class/$_inchargeClass/$_inchargeSection'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (studentsResponse.statusCode == 200) {
      final data = json.decode(studentsResponse.body);
      final studentList = data['class_info']?['students'] as List? ?? [];

      setState(() {
        _students = studentList
            .map<Map<String, dynamic>>((s) => {
                  'id': s['id'],
                  'name': s['name'],
                  'roll': s['roll'],
                  'status': 'present',
                })
            .toList();
        _attendanceAlreadyMarked = false;
        _isFetching = false;
      });
    } else {
      setState(() => _isFetching = false);
    }
  }

  void _markAllPresent() {
    setState(() {
      for (var s in _students) {
        s['status'] = 'present';
      }
    });
  }

  void _markAllAbsent() {
    setState(() {
      for (var s in _students) {
        s['status'] = 'absent';
      }
    });
  }

  Future<void> _submitAttendance() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final today = DateTime.now().toIso8601String().split('T')[0];

    try {
      final response = await http.post(
        Uri.parse(
            'https://sghps-backend.onrender.com/api/teacher/mark-attendance'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'class': _inchargeClass,
          'section': _inchargeSection,
          'date': today,
          'attendance': _students
              .map((s) => {
                    'student_id': s['id'],
                    'status': s['status'],
                  })
              .toList(),
        }),
      );

      final data = json.decode(response.body);

      setState(() => _isLoading = false);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_attendanceAlreadyMarked
                  ? '✅ Attendance updated!'
                  : '✅ Attendance marked for today!'),
              backgroundColor: primaryGreen,
            ),
          );
          setState(() {
            _attendanceAlreadyMarked = true;
            _isEditMode = false;
          });
        }
      } else {
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
    if (_isFetching) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Mark Attendance'),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ❌ If not class incharge
    if (_inchargeClass.isEmpty || _inchargeSection.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text('Mark Attendance'),
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block,
                      size: 60, color: Color(0xFFDC2626)),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Only Class Incharge can mark attendance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Contact school admin for more information.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final presentCount =
        _students.where((s) => s['status'] == 'present').length;
    final absentCount = _students.where((s) => s['status'] == 'absent').length;
    final lateCount = _students.where((s) => s['status'] == 'late').length;

    final today = DateTime.now();
    final todayStr = '${today.day}/${today.month}/${today.year}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mark Attendance'),
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (_attendanceAlreadyMarked && !_isEditMode)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Attendance',
              onPressed: () {
                setState(() => _isEditMode = true);
              },
            ),
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel Edit',
              onPressed: () {
                _initializeScreen();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // ========== HEADER ==========
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Class Info (Fixed - No dropdown)
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [primaryGreen, Color(0xFF22C55E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.class_,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Class Incharge',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            'Class $_inchargeClass - $_inchargeSection',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _attendanceAlreadyMarked
                            ? const Color(0xFF16A34A).withOpacity(0.1)
                            : const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _attendanceAlreadyMarked
                                ? Icons.check_circle
                                : Icons.pending,
                            color: _attendanceAlreadyMarked
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFF59E0B),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _attendanceAlreadyMarked ? 'MARKED' : 'PENDING',
                            style: TextStyle(
                              color: _attendanceAlreadyMarked
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFF59E0B),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Date Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryGreen.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.today, color: primaryGreen, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        todayStr,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_students.length} students',
                        style: const TextStyle(
                          fontSize: 12,
                          color: primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _statChip(
                        'Present',
                        presentCount,
                        const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statChip(
                        'Absent',
                        absentCount,
                        const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _statChip(
                        'Late',
                        lateCount,
                        const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),

                // Edit Mode Actions
                if (_isEditMode) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _markAllPresent,
                          icon: const Icon(Icons.done_all, size: 16),
                          label: const Text('All Present'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF16A34A),
                            side: const BorderSide(color: Color(0xFF16A34A)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _markAllAbsent,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('All Absent'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFDC2626),
                            side: const BorderSide(color: Color(0xFFDC2626)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // ========== STUDENTS LIST ==========
          Expanded(
            child: _students.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 60, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('No students found',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _students.length,
                    itemBuilder: (context, index) {
                      final s = _students[index];
                      final isPresent = s['status'] == 'present';
                      final isLate = s['status'] == 'late';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
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
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: isPresent
                                    ? const Color(0xFF16A34A).withOpacity(0.1)
                                    : isLate
                                        ? const Color(0xFFF59E0B)
                                            .withOpacity(0.1)
                                        : const Color(0xFFDC2626)
                                            .withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  s['roll'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isPresent
                                        ? const Color(0xFF16A34A)
                                        : isLate
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s['name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w500),
                              ),
                            ),
                            if (_isEditMode) ...[
                              GestureDetector(
                                onTap: () =>
                                    setState(() => s['status'] = 'present'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isPresent
                                        ? const Color(0xFF16A34A)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    color:
                                        isPresent ? Colors.white : Colors.grey,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => s['status'] = 'late'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isLate
                                        ? const Color(0xFFF59E0B)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.schedule,
                                    color: isLate ? Colors.white : Colors.grey,
                                    size: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => s['status'] = 'absent'),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: !isPresent && !isLate
                                        ? const Color(0xFFDC2626)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: !isPresent && !isLate
                                        ? Colors.white
                                        : Colors.grey,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isPresent
                                      ? const Color(0xFF16A34A).withOpacity(0.1)
                                      : isLate
                                          ? const Color(0xFFF59E0B)
                                              .withOpacity(0.1)
                                          : const Color(0xFFDC2626)
                                              .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPresent
                                      ? 'PRESENT'
                                      : isLate
                                          ? 'LATE'
                                          : 'ABSENT',
                                  style: TextStyle(
                                    color: isPresent
                                        ? const Color(0xFF16A34A)
                                        : isLate
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFFDC2626),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // ========== SUBMIT BUTTON ==========
          if (_students.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isLoading || (_attendanceAlreadyMarked && !_isEditMode))
                          ? null
                          : _submitAttendance,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          _attendanceAlreadyMarked ? Icons.update : Icons.save),
                  label: Text(
                    _isLoading
                        ? 'Submitting...'
                        : _attendanceAlreadyMarked
                            ? 'Update Attendance'
                            : 'Submit Attendance',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
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
}
