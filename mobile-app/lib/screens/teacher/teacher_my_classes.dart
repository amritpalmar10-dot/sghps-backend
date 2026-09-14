import 'package:flutter/material.dart';

class TeacherMyClasses extends StatefulWidget {
  const TeacherMyClasses({super.key});

  @override
  State<TeacherMyClasses> createState() => _TeacherMyClassesState();
}

class _TeacherMyClassesState extends State<TeacherMyClasses> {
  final List<Map<String, dynamic>> _classes = [
    {
      'class': 'XII',
      'section': 'A',
      'subject': 'Mathematics',
      'students': 42,
      'color': Color(0xFFFF6B6B),
    },
    {
      'class': 'XII',
      'section': 'B',
      'subject': 'Mathematics',
      'students': 40,
      'color': Color(0xFF3498DB),
    },
    {
      'class': 'XI',
      'section': 'A',
      'subject': 'Mathematics',
      'students': 38,
      'color': Color(0xFF9B59B6),
    },
    {
      'class': 'XI',
      'section': 'B',
      'subject': 'Mathematics',
      'students': 40,
      'color': Color(0xFF16A34A),
    },
    {
      'class': 'X',
      'section': 'A',
      'subject': 'Mathematics',
      'students': 45,
      'color': Color(0xFFF39C12),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('My Classes'),
        backgroundColor: const Color(0xFF3498DB),
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
                  colors: [Color(0xFF3498DB), Color(0xFF5DADE2)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3498DB).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🎓', style: TextStyle(fontSize: 50)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Assigned Classes',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('${_classes.length} Classes',
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
            ..._classes.map((c) {
              final color = c['color'] as Color;
              return GestureDetector(
                onTap: () {},
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
                            c['class'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Class ${c['class']} - ${c['section']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(c['subject'],
                                style: TextStyle(
                                    color: color,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
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
      ),
    );
  }
}
