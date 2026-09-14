import 'package:flutter/material.dart';

class StudentAcademicCalendar extends StatefulWidget {
  const StudentAcademicCalendar({super.key});

  @override
  State<StudentAcademicCalendar> createState() =>
      _StudentAcademicCalendarState();
}

class _StudentAcademicCalendarState extends State<StudentAcademicCalendar> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> calendarData = [
    {
      'date': '2024-12-20',
      'title': 'Annual Sports Day',
      'type': 'Event',
      'icon': Icons.sports_soccer,
      'color': Color(0xFF9B59B6),
    },
    {
      'date': '2024-12-25',
      'title': 'Winter Break Starts',
      'type': 'Holiday',
      'icon': Icons.beach_access,
      'color': Color(0xFF16A34A),
    },
    {
      'date': '2024-12-28',
      'title': 'Parent Teacher Meeting',
      'type': 'PTM',
      'icon': Icons.people,
      'color': Color(0xFF3498DB),
    },
    {
      'date': '2025-01-05',
      'title': 'School Reopens',
      'type': 'Event',
      'icon': Icons.school,
      'color': Color(0xFF9B59B6),
    },
    {
      'date': '2025-01-15',
      'title': 'Mid-Term Exams Start',
      'type': 'Exam',
      'icon': Icons.assignment,
      'color': Color(0xFFE74C3C),
    },
    {
      'date': '2025-01-26',
      'title': 'Republic Day',
      'type': 'Holiday',
      'icon': Icons.flag,
      'color': Color(0xFF16A34A),
    },
    {
      'date': '2025-02-14',
      'title': 'Annual Day Function',
      'type': 'Event',
      'icon': Icons.celebration,
      'color': Color(0xFF9B59B6),
    },
  ];

  List<Map<String, dynamic>> get filteredData {
    if (_selectedFilter == 'All') return calendarData;
    return calendarData.where((e) => e['type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Academic Calendar'),
        backgroundColor: const Color(0xFF3498DB),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', const Color(0xFF3498DB)),
                  const SizedBox(width: 8),
                  _filterChip('Holiday', const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  _filterChip('Exam', const Color(0xFFE74C3C)),
                  const SizedBox(width: 8),
                  _filterChip('Event', const Color(0xFF9B59B6)),
                  const SizedBox(width: 8),
                  _filterChip('PTM', const Color(0xFF3498DB)),
                ],
              ),
            ),
          ),

          // Calendar List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredData.length,
              itemBuilder: (context, index) {
                final item = filteredData[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (item['color'] as Color).withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Date Box
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color:
                              (item['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item['date'].toString().split('-')[2],
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: item['color'] as Color,
                              ),
                            ),
                            Text(
                              _getMonthName(item['date'].toString()),
                              style: TextStyle(
                                fontSize: 11,
                                color: item['color'] as Color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (item['color'] as Color)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item['type'].toString().toUpperCase(),
                                style: TextStyle(
                                  color: item['color'] as Color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(item['icon'], color: item['color'] as Color),
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

  Widget _filterChip(String label, Color color) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  String _getMonthName(String date) {
    final month = int.parse(date.split('-')[1]);
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC'
    ];
    return months[month - 1];
  }
}
