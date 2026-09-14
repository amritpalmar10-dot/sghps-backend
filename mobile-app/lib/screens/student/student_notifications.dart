import 'package:flutter/material.dart';

class StudentNotifications extends StatefulWidget {
  const StudentNotifications({super.key});

  @override
  State<StudentNotifications> createState() => _StudentNotificationsState();
}

class _StudentNotificationsState extends State<StudentNotifications> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'New Homework',
      'message': 'Mathematics homework assigned',
      'type': 'homework',
      'priority': 'normal',
      'date': '2024-12-10',
      'icon': Icons.assignment,
      'color': Colors.orange,
    },
    {
      'title': 'Fee Reminder',
      'message': 'Fee payment due in 15 days',
      'type': 'fees',
      'priority': 'important',
      'date': '2024-12-08',
      'icon': Icons.payment,
      'color': Colors.blue,
    },
    {
      'title': 'Exam Schedule',
      'message': 'Mid-term exams start from Dec 20',
      'type': 'exam',
      'priority': 'urgent',
      'date': '2024-12-05',
      'icon': Icons.event,
      'color': Colors.red,
    },
    {
      'title': 'School Event',
      'message': 'Annual Sports Day on Dec 25',
      'type': 'event',
      'priority': 'normal',
      'date': '2024-12-01',
      'icon': Icons.celebration,
      'color': Colors.purple,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final n = notifications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 5)
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (n['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(n['icon'], color: n['color']),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n['title'],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          if (n['priority'] == 'urgent')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('URGENT',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(n['message'],
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(n['date'],
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
