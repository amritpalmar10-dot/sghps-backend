import 'package:flutter/material.dart';

class TeacherStudentView extends StatelessWidget {
  const TeacherStudentView({super.key});

  @override
  Widget build(BuildContext context) {
    final students = [
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
      {
        'name': 'Arjun Verma',
        'roll': '03',
        'attendance': '72%',
        'status': 'Low'
      },
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

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Students'),
        backgroundColor: const Color(0xFF9B59B6),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF9B59B6), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B59B6).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('👥', style: TextStyle(fontSize: 50)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Students',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${students.length} Students',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                      child: Text(s['roll'].toString(),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: color)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s['name']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text('Roll: ${s['roll']}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(s['attendance']!,
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
                          child: Text(s['status']!,
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
      ),
    );
  }
}
