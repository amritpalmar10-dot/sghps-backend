import 'package:flutter/material.dart';

class TeacherClassDetail extends StatefulWidget {
  final String className;
  final String section;
  final String subject;

  const TeacherClassDetail({
    super.key,
    this.className = 'XII',
    this.section = 'A',
    this.subject = 'Mathematics',
  });

  @override
  State<TeacherClassDetail> createState() => _TeacherClassDetailState();
}

class _TeacherClassDetailState extends State<TeacherClassDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> students = [
    {
      'name': 'Manavjot Singh',
      'roll': '01',
      'attendance': '94%',
      'status': 'Active'
    },
    {
      'name': 'Riya Sharma',
      'roll': '02',
      'attendance': '88%',
      'status': 'Active'
    },
    {'name': 'Arjun Verma', 'roll': '03', 'attendance': '72%', 'status': 'Low'},
    {
      'name': 'Priya Patel',
      'roll': '04',
      'attendance': '96%',
      'status': 'Active'
    },
    {
      'name': 'Rahul Kumar',
      'roll': '05',
      'attendance': '85%',
      'status': 'Active'
    },
    {
      'name': 'Sneha Gupta',
      'roll': '06',
      'attendance': '91%',
      'status': 'Active'
    },
    {
      'name': 'Vikram Singh',
      'roll': '07',
      'attendance': '68%',
      'status': 'Low'
    },
    {
      'name': 'Anjali Sharma',
      'roll': '08',
      'attendance': '93%',
      'status': 'Active'
    },
  ];

  final List<Map<String, dynamic>> homework = [
    {
      'title': 'Chapter 5: Calculus',
      'deadline': '2024-12-20',
      'submitted': 35,
      'total': 42,
    },
    {
      'title': 'Chapter 4: Integration',
      'deadline': '2024-12-15',
      'submitted': 40,
      'total': 42,
    },
    {
      'title': 'Chapter 3: Differentiation',
      'deadline': '2024-12-10',
      'submitted': 38,
      'total': 42,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('Class ${widget.className}-${widget.section}'),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Students', icon: Icon(Icons.people, size: 18)),
            Tab(text: 'Homework', icon: Icon(Icons.assignment, size: 18)),
            Tab(text: 'Info', icon: Icon(Icons.info, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudentsTab(),
          _buildHomeworkTab(),
          _buildInfoTab(),
        ],
      ),
    );
  }

  // ========== STUDENTS TAB ==========
  Widget _buildStudentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _miniStat('Students', '${students.length}', Icons.people,
                    Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                    'Avg Attendance', '87%', Icons.check_circle, Colors.green),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Students List
          ...students.map((s) {
            final isLow = s['status'] == 'Low';
            final color =
                isLow ? const Color(0xFFE74C3C) : const Color(0xFF16A34A);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: color.withValues(alpha: 0.1),
                    child: Text(
                      s['roll'],
                      style:
                          TextStyle(fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Roll: ${s['roll']}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(s['attendance'],
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(s['status'],
                            style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ========== HOMEWORK TAB ==========
  Widget _buildHomeworkTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...homework.map((hw) {
            final progress = hw['submitted'] / hw['total'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.assignment,
                            color: Color(0xFFFF6B6B)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hw['title'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('Deadline: ${hw['deadline']}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF16A34A)),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${hw['submitted']}/${hw['total']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ========== INFO TAB ==========
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Class Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3498DB), Color(0xFF5DADE2)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.class_, size: 60, color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  'Class ${widget.className}-${widget.section}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.subject,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _infoTile(Icons.people, 'Total Students', '${students.length}'),
          _infoTile(Icons.person, 'Class Teacher', 'Navdeep Singh'),
          _infoTile(Icons.book, 'Subject', widget.subject),
          _infoTile(Icons.room, 'Room', 'Room 101'),
          _infoTile(Icons.schedule, 'Timing', '9:00 AM - 10:00 AM'),
          _infoTile(Icons.calendar_today, 'Days', 'Mon, Tue, Wed, Thu, Fri'),

          const SizedBox(height: 20),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/teacher-mark-attendance'),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/teacher-homework'),
              icon: const Icon(Icons.assignment),
              label: const Text('Add Homework'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF6B6B),
                side: const BorderSide(color: Color(0xFFFF6B6B)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3498DB).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3498DB), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
