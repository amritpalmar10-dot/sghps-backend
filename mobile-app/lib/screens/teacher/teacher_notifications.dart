import 'package:flutter/material.dart';

class TeacherNotifications extends StatefulWidget {
  const TeacherNotifications({super.key});

  @override
  State<TeacherNotifications> createState() => _TeacherNotificationsState();
}

class _TeacherNotificationsState extends State<TeacherNotifications> {
  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Leave Request',
      'message': 'Manavjot Singh applied for leave',
      'type': 'leave',
      'date': '2 hours ago',
      'icon': Icons.event_busy,
      'color': Color(0xFFF59E0B),
      'unread': true,
    },
    {
      'title': 'New Submission',
      'message': 'Riya Sharma submitted Mathematics homework',
      'type': 'submission',
      'date': '5 hours ago',
      'icon': Icons.assignment_turned_in,
      'color': Color(0xFF16A34A),
      'unread': true,
    },
    {
      'title': 'PTM Reminder',
      'message': 'Parent Teacher Meeting on Dec 28',
      'type': 'event',
      'date': '1 day ago',
      'icon': Icons.people,
      'color': Color(0xFF3498DB),
      'unread': false,
    },
    {
      'title': 'Attendance Alert',
      'message': 'Low attendance in Class XI-B',
      'type': 'alert',
      'date': '1 day ago',
      'icon': Icons.warning,
      'color': Color(0xFFE74C3C),
      'unread': false,
    },
    {
      'title': 'Meeting Reminder',
      'message': 'Staff meeting tomorrow at 10 AM',
      'type': 'admin',
      'date': '2 days ago',
      'icon': Icons.meeting_room,
      'color': Color(0xFF9B59B6),
      'unread': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n['unread'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF16A34A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('🔔', style: TextStyle(fontSize: 50)),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Notifications',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text(
                          '$unreadCount Unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Notifications List
            const Text('Recent',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            ...notifications.map((n) {
              final color = n['color'] as Color;
              final isUnread = n['unread'] as bool;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnread ? Colors.white : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: isUnread
                      ? Border.all(
                          color: color.withValues(alpha: 0.3), width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: isUnread
                          ? color.withValues(alpha: 0.15)
                          : Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(n['icon'], color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n['title'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: isUnread
                                        ? const Color(0xFF1F2937)
                                        : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n['message'],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n['date'],
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 11),
                          ),
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
}
