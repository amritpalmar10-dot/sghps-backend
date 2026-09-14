import 'package:flutter/material.dart';

class StudentExamSchedule extends StatefulWidget {
  const StudentExamSchedule({super.key});

  @override
  State<StudentExamSchedule> createState() => _StudentExamScheduleState();
}

class _StudentExamScheduleState extends State<StudentExamSchedule> {
  final List<Map<String, dynamic>> exams = [
    {
      'subject': 'Mathematics',
      'date': '2025-01-15',
      'time': '9:00 AM - 12:00 PM',
      'room': 'Hall A',
      'syllabus': 'Chapters 1-8',
      'icon': Icons.calculate,
      'color': Color(0xFFFF6B6B),
    },
    {
      'subject': 'Physics',
      'date': '2025-01-17',
      'time': '9:00 AM - 12:00 PM',
      'room': 'Hall B',
      'syllabus': 'Chapters 1-6',
      'icon': Icons.science,
      'color': Color(0xFF3498DB),
    },
    {
      'subject': 'Chemistry',
      'date': '2025-01-19',
      'time': '9:00 AM - 12:00 PM',
      'room': 'Hall A',
      'syllabus': 'Chapters 1-7',
      'icon': Icons.science_outlined,
      'color': Color(0xFF9B59B6),
    },
    {
      'subject': 'English',
      'date': '2025-01-21',
      'time': '9:00 AM - 12:00 PM',
      'room': 'Hall C',
      'syllabus': 'Prose, Poetry, Grammar',
      'icon': Icons.book,
      'color': Color(0xFF16A34A),
    },
    {
      'subject': 'Computer Science',
      'date': '2025-01-23',
      'time': '9:00 AM - 12:00 PM',
      'room': 'Lab 1',
      'syllabus': 'Chapters 1-5',
      'icon': Icons.computer,
      'color': Color(0xFFF39C12),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Exam Schedule'),
        backgroundColor: const Color(0xFFE74C3C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFE74C3C), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('📝', style: TextStyle(fontSize: 50)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mid-Term Exams',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 4),
                        const Text('Starting from Jan 15',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('${exams.length} Subjects',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('Exam Timetable',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            ...exams.map((exam) {
              final color = exam['color'] as Color;
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(exam['icon'], color: color, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam['subject'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 17),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 12, color: color),
                                  const SizedBox(width: 4),
                                  Text(
                                    exam['date'],
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          _examDetail(
                              Icons.access_time, 'Time', exam['time'], color),
                          const SizedBox(height: 6),
                          _examDetail(
                              Icons.location_on, 'Room', exam['room'], color),
                          const SizedBox(height: 6),
                          _examDetail(Icons.menu_book, 'Syllabus',
                              exam['syllabus'], color),
                        ],
                      ),
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

  Widget _examDetail(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
