import 'package:flutter/material.dart';

class AccountantNotifications extends StatefulWidget {
  const AccountantNotifications({super.key});

  @override
  State<AccountantNotifications> createState() =>
      _AccountantNotificationsState();
}

class _AccountantNotificationsState extends State<AccountantNotifications> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  String _filterType = 'All';

  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Payment Received',
      'message': '₹15,000 received from Manavjot Singh',
      'type': 'payment',
      'category': 'Payment',
      'date': '2 hours ago',
      'icon': Icons.attach_money,
      'color': Color(0xFF16A34A),
      'unread': true,
      'priority': 'normal',
    },
    {
      'title': 'Fee Overdue Alert',
      'message': '15 students have overdue fees',
      'type': 'alert',
      'category': 'Alert',
      'date': '5 hours ago',
      'icon': Icons.warning,
      'color': Color(0xFFDC2626),
      'unread': true,
      'priority': 'urgent',
    },
    {
      'title': 'New Student Added',
      'message': 'Riya Sharma added to Class XII-A',
      'type': 'student',
      'category': 'Student',
      'date': '1 day ago',
      'icon': Icons.person_add,
      'color': Color(0xFF3498DB),
      'unread': true,
      'priority': 'normal',
    },
    {
      'title': 'Monthly Report Ready',
      'message': 'November fee collection report generated',
      'type': 'report',
      'category': 'Report',
      'date': '2 days ago',
      'icon': Icons.description,
      'color': Color(0xFF9B59B6),
      'unread': false,
      'priority': 'normal',
    },
    {
      'title': 'Teacher Leave Approved',
      'message': 'Principal approved Navdeep Singh\'s leave',
      'type': 'leave',
      'category': 'Leave',
      'date': '3 days ago',
      'icon': Icons.event_available,
      'color': Color(0xFFF59E0B),
      'unread': false,
      'priority': 'normal',
    },
    {
      'title': 'Fee Structure Updated',
      'message': 'Class X fee structure updated for 2025-26',
      'type': 'admin',
      'category': 'Admin',
      'date': '4 days ago',
      'icon': Icons.settings,
      'color': Color(0xFF7E22CE),
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
        backgroundColor: primaryPurple,
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
                  colors: [primaryPurple, secondaryPurple],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: primaryPurple.withValues(alpha: 0.4),
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
                  _filterChip('All', primaryPurple),
                  const SizedBox(width: 8),
                  _filterChip('Unread', const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _filterChip('Payment', const Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  _filterChip('Alert', const Color(0xFFDC2626)),
                  const SizedBox(width: 8),
                  _filterChip('Student', const Color(0xFF3498DB)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ========== NOTIFICATIONS LIST ==========
            if (filteredNotifications.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('No notifications',
                        style: TextStyle(color: Colors.grey)),
                  ],
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
            const SizedBox(height: 20),
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
