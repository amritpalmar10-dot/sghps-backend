import 'package:flutter/material.dart';

class PrincipalTeacherProfile extends StatefulWidget {
  final int teacherId;

  const PrincipalTeacherProfile({
    super.key,
    this.teacherId = 1,
  });

  @override
  State<PrincipalTeacherProfile> createState() =>
      _PrincipalTeacherProfileState();
}

class _PrincipalTeacherProfileState extends State<PrincipalTeacherProfile>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample teacher data
  final Map<String, dynamic> teacher = {
    'name': 'Navdeep Singh',
    'staff_code': 'TCH-001',
    'subject': 'Mathematics',
    'designation': 'Senior Teacher',
    'email': 'navdeep@test.com',
    'phone': '9876543211',
    'joined': '15 June 2020',
    'is_class_incharge': true,
    'incharge_class': 'XII',
    'incharge_section': 'A',
    'total_classes': 5,
    'total_students': 120,
    'attendance_marking': 95,
    'homework_assigned': 45,
    'avg_class_score': 87,
  };

  final List<Map<String, dynamic>> assignedClasses = [
    {
      'class': 'XII-A',
      'subject': 'Mathematics',
      'students': 42,
      'is_incharge': true,
      'color': Color(0xFFF59E0B),
    },
    {
      'class': 'XII-B',
      'subject': 'Mathematics',
      'students': 40,
      'is_incharge': false,
      'color': Color(0xFF3498DB),
    },
    {
      'class': 'XI-A',
      'subject': 'Mathematics',
      'students': 38,
      'is_incharge': false,
      'color': Color(0xFF9B59B6),
    },
    {
      'class': 'XI-B',
      'subject': 'Mathematics',
      'students': 40,
      'is_incharge': false,
      'color': Color(0xFF16A34A),
    },
    {
      'class': 'X-A',
      'subject': 'Mathematics',
      'students': 45,
      'is_incharge': false,
      'color': Color(0xFFDC2626),
    },
  ];

  final List<Map<String, dynamic>> leaveHistory = [
    {
      'start': '2024-11-10',
      'end': '2024-11-12',
      'reason': 'Family event',
      'status': 'approved',
    },
    {
      'start': '2024-10-05',
      'end': '2024-10-06',
      'reason': 'Medical',
      'status': 'approved',
    },
    {
      'start': '2024-09-15',
      'end': '2024-09-16',
      'reason': 'Personal',
      'status': 'rejected',
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

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: const Color(0xFFDC2626),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Teacher Profile'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Info', icon: Icon(Icons.info, size: 18)),
            Tab(text: 'Classes', icon: Icon(Icons.class_, size: 18)),
            Tab(text: 'Leaves', icon: Icon(Icons.event_busy, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInfoTab(),
          _buildClassesTab(),
          _buildLeavesTab(),
        ],
      ),
    );
  }

  // ========== INFO TAB ==========
  Widget _buildInfoTab() {
    final isIncharge = teacher['is_class_incharge'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Avatar
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 15),

          // Name
          Text(
            teacher['name'],
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),

          // Designation
          Text(
            '${teacher['designation']} - ${teacher['subject']}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 8),

          // Class Incharge Badge
          if (isIncharge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Class Incharge - ${teacher['incharge_class']}-${teacher['incharge_section']}',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 25),

          // Performance Stats
          Row(
            children: [
              Expanded(
                child: _perfCard(
                  'Attendance',
                  '${teacher['attendance_marking']}%',
                  Icons.check_circle,
                  const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _perfCard(
                  'Homework',
                  '${teacher['homework_assigned']}',
                  Icons.assignment,
                  const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _perfCard(
                  'Avg Score',
                  '${teacher['avg_class_score']}%',
                  Icons.grade,
                  const Color(0xFF9B59B6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),

          // Info Tiles
          _infoTile(Icons.badge, 'Staff Code', teacher['staff_code']),
          _infoTile(Icons.email, 'Email', teacher['email']),
          _infoTile(Icons.phone, 'Phone', teacher['phone']),
          _infoTile(Icons.book, 'Subject', teacher['subject']),
          _infoTile(Icons.class_, 'Total Classes',
              '${teacher['total_classes']} classes'),
          _infoTile(Icons.people, 'Total Students',
              '${teacher['total_students']} students'),
          _infoTile(Icons.calendar_today, 'Joined', teacher['joined']),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showComingSoon('Contact Teacher'),
              icon: const Icon(Icons.message),
              label: const Text('Contact Teacher'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFDC2626)),
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

  // ========== CLASSES TAB ==========
  Widget _buildClassesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Row(
            children: [
              Expanded(
                child: _miniStat('Total Classes', '${assignedClasses.length}',
                    Icons.class_, const Color(0xFFDC2626)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat('Total Students', '120', Icons.people,
                    const Color(0xFF3498DB)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Assigned Classes',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),

          ...assignedClasses.map((c) {
            final color = c['color'] as Color;
            final isIncharge = c['is_incharge'] as bool;

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/principal-class-detail',
                  arguments: {
                    'class': c['class'].toString().split('-')[0],
                    'section': c['class'].toString().split('-')[1],
                  },
                );
              },
              child: Container(
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
                child: Row(
                  children: [
                    Container(
                      width: 55,
                      height: 55,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          c['class'].toString().replaceAll('-', '\n'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Class ${c['class']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (isIncharge) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.star,
                                    color: Color(0xFFF59E0B), size: 16),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            c['subject'],
                            style: TextStyle(
                                color: color,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${c['students']} students',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, size: 16, color: color),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ========== LEAVES TAB ==========
  Widget _buildLeavesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats
          Row(
            children: [
              Expanded(
                child: _miniStat(
                  'Approved',
                  '${leaveHistory.where((l) => l['status'] == 'approved').length}',
                  Icons.check_circle,
                  const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  'Rejected',
                  '${leaveHistory.where((l) => l['status'] == 'rejected').length}',
                  Icons.cancel,
                  const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniStat(
                  'Total',
                  '${leaveHistory.length}',
                  Icons.event_busy,
                  const Color(0xFF3498DB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          const Text('Leave History',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 12),

          ...leaveHistory.map((l) {
            final isApproved = l['status'] == 'approved';
            final color =
                isApproved ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isApproved ? Icons.check_circle : Icons.cancel,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${l['start']} to ${l['end']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(l['reason'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l['status'].toString().toUpperCase(),
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _perfCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
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
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFFDC2626), size: 20),
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

  Widget _miniStat(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
