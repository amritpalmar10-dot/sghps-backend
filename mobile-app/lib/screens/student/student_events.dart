import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentEvents extends StatefulWidget {
  const StudentEvents({super.key});

  @override
  State<StudentEvents> createState() => _StudentEventsState();
}

class _StudentEventsState extends State<StudentEvents> {
  static const Color primaryPurple = Color(0xFF9B59B6);
  static const Color secondaryPurple = Color(0xFFA855F7);

  List<dynamic> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/events'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _events = data['events'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  // ✅ FIXED: Safe date comparison
  bool _isUpcoming(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;

    try {
      final eventDate = DateTime.parse(dateStr);
      final today = DateTime.now();

      // Compare using DateTime (not string)
      return eventDate.isAfter(today.subtract(const Duration(days: 1)));
    } catch (e) {
      return false;
    }
  }

  Color _typeColor(String? type) {
    switch (type) {
      case 'holiday':
        return const Color(0xFF16A34A);
      case 'exam':
        return const Color(0xFFDC2626);
      case 'ptm':
        return const Color(0xFF3498DB);
      case 'activity':
        return const Color(0xFF9B59B6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'holiday':
        return Icons.beach_access;
      case 'exam':
        return Icons.assignment;
      case 'ptm':
        return Icons.people;
      case 'activity':
        return Icons.emoji_events;
      default:
        return Icons.celebration;
    }
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
        return const Color(0xFFDC2626);
      case 'important':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3498DB);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateStr);
      final today = DateTime.now();
      final tomorrow = today.add(const Duration(days: 1));

      if (date.year == today.year &&
          date.month == today.month &&
          date.day == today.day) {
        return 'Today';
      } else if (date.year == tomorrow.year &&
          date.month == tomorrow.month &&
          date.day == tomorrow.day) {
        return 'Tomorrow';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ];
        return '${date.day} ${months[date.month - 1]} ${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Safe comparison using method
    final upcoming =
        _events.where((e) => _isUpcoming(e['event_date'] as String?)).toList();

    final past =
        _events.where((e) => !_isUpcoming(e['event_date'] as String?)).toList();

    // Sort upcoming by date (ascending)
    upcoming.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['event_date'] ?? '');
        final dateB = DateTime.parse(b['event_date'] ?? '');
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });

    // Sort past by date (descending - most recent first)
    past.sort((a, b) {
      try {
        final dateA = DateTime.parse(a['event_date'] ?? '');
        final dateB = DateTime.parse(b['event_date'] ?? '');
        return dateB.compareTo(dateA);
      } catch (e) {
        return 0;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('School Events'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryPurple, secondaryPurple],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: primaryPurple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 50)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('School Events',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 13)),
                              Text(
                                '${upcoming.length} Upcoming',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_events.length} total events',
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

                  // Empty State
                  if (_events.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(60),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.event_busy, size: 70, color: Colors.grey),
                          SizedBox(height: 15),
                          Text('No events yet',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey)),
                          SizedBox(height: 5),
                          Text('Check back later',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),

                  // Upcoming Events
                  if (upcoming.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.upcoming,
                            color: primaryPurple, size: 20),
                        const SizedBox(width: 8),
                        const Text('Upcoming Events',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937))),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${upcoming.length}',
                            style: const TextStyle(
                                color: primaryPurple,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...upcoming.map((e) => _buildEventCard(e, false)),
                    const SizedBox(height: 20),
                  ],

                  // Past Events
                  if (past.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.history, color: Colors.grey, size: 20),
                        SizedBox(width: 8),
                        Text('Past Events',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...past.map((e) => _buildEventCard(e, true)),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildEventCard(dynamic e, bool isPast) {
    final color = _typeColor(e['type'] as String?);
    final icon = _typeIcon(e['type'] as String?);
    final priorityColor = _priorityColor(e['priority'] as String?);
    final formattedDate = _formatDate(e['event_date'] as String?);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPast ? Colors.grey.shade200 : color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border:
            isPast ? null : Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isPast ? 0.05 : 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, color: isPast ? Colors.grey : color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e['title'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isPast ? Colors.grey.shade700 : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'By ${e['created_by_name'] ?? 'Unknown'}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              if (e['priority'] == 'urgent' ||
                  e['priority'] == 'important') ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    (e['priority'] ?? '').toString().toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (e['description'] != null &&
              e['description'].toString().isNotEmpty) ...[
            Text(
              e['description'],
              style: TextStyle(
                  fontSize: 13,
                  color: isPast ? Colors.grey.shade500 : Colors.grey),
            ),
            const SizedBox(height: 10),
          ],
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPast ? Colors.grey.shade50 : color.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: isPast ? Colors.grey : color),
                    const SizedBox(width: 6),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isPast ? Colors.grey : color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      e['event_date'] ?? '',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (e['event_time'] != null &&
                    e['event_time'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        e['event_time'],
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
                if (e['location'] != null &&
                    e['location'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text(
                        e['location'],
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
