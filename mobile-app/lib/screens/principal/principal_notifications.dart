import 'package:flutter/material.dart';

class PrincipalNotifications extends StatefulWidget {
  const PrincipalNotifications({super.key});

  @override
  State<PrincipalNotifications> createState() => _PrincipalNotificationsState();
}

class _PrincipalNotificationsState extends State<PrincipalNotifications> {
  String _filterType = 'All';

  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Teacher Leave Request',
      'message': 'Navdeep Singh applied for leave (Dec 20-22)',
      'type': 'leave',
      'category': 'Approval',
      'date': '2 hours ago',
      'icon': Icons.event_busy,
      'color': Color(0xFFDC2626),
      'unread': true,
      'priority': 'urgent',
    },
    {
      'title': 'Low Attendance Alert',
      'message': 'Class X-A attendance below 80%',
      'type': 'alert',
      'category': 'Alert',
      'date': '5 hours ago',
      'icon': Icons.warning,
      'color': Color(0xFFF59E0B),
      'unread': true,
      'priority': 'urgent',
    },
    {
      'title': 'Fee Collection Update',
      'message': 'Fee collection target 75% achieved',
      'type': 'fee',
      'category': 'Fee',
      'date': '1 day ago',
      'icon': Icons.money,
      'color': Color(0xFF16A085),
      'unread': true,
      'priority': 'normal',
    },
    {
      'title': 'New Certificate Request',
      'message': 'Arjun Verma requested bonafide certificate',
      'type': 'certificate',
      'category': 'Approval',
      'date': '1 day ago',
      'icon': Icons.workspace_premium,
      'color': Color(0xFF9B59B6),
      'unread': false,
      'priority': 'normal',
    },
    {
      'title': 'Staff Meeting Reminder',
      'message': 'Staff meeting scheduled tomorrow at 10 AM',
      'type': 'admin',
      'category': 'Admin',
      'date': '2 days ago',
      'icon': Icons.meeting_room,
      'color': Color(0xFF3498DB),
      'unread': false,
      'priority': 'normal',
    },
    {
      'title': 'Monthly Report Ready',
      'message': 'November attendance report generated',
      'type': 'report',
      'category': 'Report',
      'date': '3 days ago',
      'icon': Icons.description,
      'color': Color(0xFF16A34A),
      'unread': false,
      'priority': 'normal',
    },
  ];

  List<Map<String, dynamic>> get filteredNotifications {
    if (_filterType == 'All') return notifications;
    if (_filterType == 'Unread') {
      return notifications.where((n) => n['unread'] == true).toList();
    }
    return notifications.where((n) => n['category'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => n['unread'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in notifications) {
                  n['unread'] = false;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ All marked as read'),
                  backgroundColor: Color(0xFF16A34A),
                ),
              );
            },
            child: const Text('Mark All Read',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== HEADER ==========
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.4),
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
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${notifications.length}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ========== FILTER CHIPS ==========
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', const Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  _filterChip('Unread', const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _filterChip('Approval', const Color(0xFF9B59B6)),
                  const SizedBox(width: 8),
                  _filterChip('Alert', const Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  _filterChip('Fee', const Color(0xFF16A085)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ========== NOTIFICATIONS LIST ==========
            if (filteredNotifications.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.notifications_off,
                          size: 60, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No notifications',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ...filteredNotifications.map((n) {
                final color = n['color'] as Color;
                final isUnread = n['unread'] as bool;
                final isUrgent = n['priority'] == 'urgent';

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
                                if (isUrgent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      'URGENT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isUnread && !isUrgent)
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    n['category'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  n['date'],
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 11),
                                ),
                              ],
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

  Widget _filterChip(String label, Color color) {
    final isSelected = _filterType == label;
    return GestureDetector(
      onTap: () => setState(() => _filterType = label),
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
}
