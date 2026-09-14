import 'package:flutter/material.dart';

class PrincipalAnalytics extends StatefulWidget {
  const PrincipalAnalytics({super.key});

  @override
  State<PrincipalAnalytics> createState() => _PrincipalAnalyticsState();
}

class _PrincipalAnalyticsState extends State<PrincipalAnalytics> {
  String _selectedPeriod = 'Week';

  // Sample Analytics Data
  final List<Map<String, dynamic>> classAttendance = [
    {'class': 'XII-A', 'attendance': 92.8, 'color': Color(0xFF16A34A)},
    {'class': 'XII-B', 'attendance': 95.0, 'color': Color(0xFF16A34A)},
    {'class': 'XI-A', 'attendance': 92.1, 'color': Color(0xFF16A34A)},
    {'class': 'XI-B', 'attendance': 95.0, 'color': Color(0xFF16A34A)},
    {'class': 'X-A', 'attendance': 77.8, 'color': Color(0xFFDC2626)},
    {'class': 'X-B', 'attendance': 95.2, 'color': Color(0xFF16A34A)},
    {'class': 'IX-A', 'attendance': 95.0, 'color': Color(0xFF16A34A)},
  ];

  final List<Map<String, dynamic>> attendanceTrend = [
    {'day': 'Mon', 'value': 92},
    {'day': 'Tue', 'value': 94},
    {'day': 'Wed', 'value': 91},
    {'day': 'Thu', 'value': 95},
    {'day': 'Fri', 'value': 93},
    {'day': 'Sat', 'value': 88},
  ];

  final List<Map<String, dynamic>> subjectPerformance = [
    {'subject': 'Mathematics', 'score': 87, 'color': Color(0xFFDC2626)},
    {'subject': 'Physics', 'score': 82, 'color': Color(0xFF3498DB)},
    {'subject': 'Chemistry', 'score': 85, 'color': Color(0xFF9B59B6)},
    {'subject': 'English', 'score': 89, 'color': Color(0xFF16A34A)},
    {'subject': 'Computer', 'score': 91, 'color': Color(0xFFF59E0B)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) => setState(() => _selectedPeriod = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Day', child: Text('Day')),
              const PopupMenuItem(value: 'Week', child: Text('Week')),
              const PopupMenuItem(value: 'Month', child: Text('Month')),
              const PopupMenuItem(value: 'Year', child: Text('Year')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Text(_selectedPeriod,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ========== OVERVIEW CARDS ==========
            Row(
              children: [
                Expanded(
                  child: _overviewCard(
                    'Attendance',
                    '94.2%',
                    Icons.calendar_today,
                    const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _overviewCard(
                    'Avg Score',
                    '86.8%',
                    Icons.grade,
                    const Color(0xFF9B59B6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _overviewCard(
                    'Fee Collected',
                    '₹35L',
                    Icons.money,
                    const Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _overviewCard(
                    'Pending',
                    '₹15L',
                    Icons.pending,
                    const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // ========== ATTENDANCE TREND ==========
            const Text('Attendance Trend',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 4),
            Text('Last 6 days',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 150,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: attendanceTrend.map((t) {
                        final height = (t['value'] / 100) * 130;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${t['value']}%',
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFDC2626)),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 32,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Color(0xFFDC2626),
                                    Color(0xFFEF4444),
                                  ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  topRight: Radius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t['day'],
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ========== CLASS-WISE ATTENDANCE ==========
            const Text('Class-wise Attendance',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: classAttendance.map((c) {
                  final color = c['color'] as Color;
                  final attendance = c['attendance'] as double;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 55,
                          child: Text(
                            c['class'],
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: attendance / 100,
                                child: Container(
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 55,
                          child: Text(
                            '${attendance.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 25),

            // ========== SUBJECT PERFORMANCE ==========
            const Text('Subject Performance',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: subjectPerformance.map((s) {
                  final color = s['color'] as Color;
                  final score = s['score'] as int;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.book, color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s['subject'],
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$score%',
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 25),

            // ========== TOP PERFORMERS ==========
            const Text('Top Classes',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _performerRow('1', 'XII-B', '95.0%', const Color(0xFFF59E0B)),
                  _performerRow('2', 'X-B', '95.2%', const Color(0xFFC0C0C0)),
                  _performerRow('3', 'XI-B', '95.0%', const Color(0xFFCD7F32)),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // ========== ATTENTION REQUIRED ==========
            const Text('Needs Attention',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  _alertRow('⚠️', 'Class X-A attendance below 80%'),
                  _alertRow('📉', 'Physics average score dropped by 3%'),
                  _alertRow('💰', '5 students have overdue fees'),
                  _alertRow('✉️', 'Teacher leave pending for 3 days'),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _overviewCard(String title, String value, IconData icon, Color color) {
    return Container(
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _performerRow(
      String rank, String className, String score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(rank,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Class $className',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          Text(score,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _alertRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}
