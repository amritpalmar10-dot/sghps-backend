import 'package:flutter/material.dart';

class StudentTimetable extends StatefulWidget {
  const StudentTimetable({super.key});

  @override
  State<StudentTimetable> createState() => _StudentTimetableState();
}

class _StudentTimetableState extends State<StudentTimetable> {
  final List<Map<String, String>> timetable = [
    {
      'day': 'Monday',
      'period': '1',
      'subject': 'Mathematics',
      'teacher': 'Navdeep Singh',
      'room': '101',
      'time': '9:00 AM'
    },
    {
      'day': 'Monday',
      'period': '2',
      'subject': 'Physics',
      'teacher': 'Dr. Sharma',
      'room': '102',
      'time': '10:00 AM'
    },
    {
      'day': 'Monday',
      'period': '3',
      'subject': 'Chemistry',
      'teacher': 'Ms. Gupta',
      'room': '103',
      'time': '11:00 AM'
    },
    {
      'day': 'Tuesday',
      'period': '1',
      'subject': 'English',
      'teacher': 'Mr. Kumar',
      'room': '104',
      'time': '9:00 AM'
    },
    {
      'day': 'Tuesday',
      'period': '2',
      'subject': 'Mathematics',
      'teacher': 'Navdeep Singh',
      'room': '101',
      'time': '10:00 AM'
    },
    {
      'day': 'Wednesday',
      'period': '1',
      'subject': 'Physics',
      'teacher': 'Dr. Sharma',
      'room': '102',
      'time': '9:00 AM'
    },
    {
      'day': 'Thursday',
      'period': '1',
      'subject': 'Chemistry',
      'teacher': 'Ms. Gupta',
      'room': '103',
      'time': '9:00 AM'
    },
    {
      'day': 'Friday',
      'period': '1',
      'subject': 'English',
      'teacher': 'Mr. Kumar',
      'room': '104',
      'time': '9:00 AM'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final dayClasses = timetable.where((c) => c['day'] == day).toList();

          return Container(
            margin: const EdgeInsets.only(bottom: 15),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 5)
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(day,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue)),
                const SizedBox(height: 10),
                if (dayClasses.isEmpty)
                  const Text('No classes', style: TextStyle(color: Colors.grey))
                else
                  ...dayClasses.map((c) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(c['period']!,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c['subject']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(
                                    '${c['teacher']} • ${c['time']} • Room ${c['room']}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
