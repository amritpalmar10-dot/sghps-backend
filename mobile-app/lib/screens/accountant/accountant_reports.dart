import 'package:flutter/material.dart';

class AccountantReports extends StatefulWidget {
  const AccountantReports({super.key});

  @override
  State<AccountantReports> createState() => _AccountantReportsState();
}

class _AccountantReportsState extends State<AccountantReports> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  String _selectedPeriod = 'Month';

  final List<Map<String, dynamic>> reportTypes = [
    {
      'title': 'Fee Collection',
      'desc': 'Total collected report',
      'icon': Icons.attach_money,
      'color': Color(0xFF16A34A),
    },
    {
      'title': 'Pending Fees',
      'desc': 'Outstanding dues list',
      'icon': Icons.pending_actions,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Class-wise Fee',
      'desc': 'Fee by each class',
      'icon': Icons.class_,
      'color': Color(0xFF3498DB),
    },
    {
      'title': 'Defaulter List',
      'desc': 'Students with dues',
      'icon': Icons.warning,
      'color': Color(0xFFDC2626),
    },
    {
      'title': 'Payment History',
      'desc': 'All transactions',
      'icon': Icons.receipt_long,
      'color': Color(0xFF9B59B6),
    },
    {
      'title': 'Fee Structure',
      'desc': 'Class fee structure',
      'icon': Icons.description,
      'color': Color(0xFF16A085),
    },
    {
      'title': 'Teacher Leaves',
      'desc': 'Leave report',
      'icon': Icons.event_busy,
      'color': Color(0xFF7E22CE),
    },
    {
      'title': 'Audit Log',
      'desc': 'All changes log',
      'icon': Icons.history,
      'color': Color(0xFF7F8C8D),
    },
  ];

  final List<Map<String, dynamic>> recentReports = [
    {
      'title': 'Fee Collection - Dec 2024',
      'type': 'Collection',
      'date': '2024-12-15',
      'size': '320 KB',
      'color': Color(0xFF16A34A),
    },
    {
      'title': 'Pending Dues Report',
      'type': 'Pending',
      'date': '2024-12-14',
      'size': '245 KB',
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Class-wise Fee Summary',
      'type': 'Class',
      'date': '2024-12-10',
      'size': '180 KB',
      'color': Color(0xFF3498DB),
    },
  ];

  void _generateReport(String reportType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.description, color: primaryPurple, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Generate $reportType',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Period:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Day', 'Week', 'Month', 'Year'].map((p) {
                return ChoiceChip(
                  label: Text(p),
                  selected: _selectedPeriod == p,
                  selectedColor: primaryPurple,
                  labelStyle: TextStyle(
                    color: _selectedPeriod == p ? Colors.white : Colors.black,
                    fontSize: 12,
                  ),
                  onSelected: (v) => setState(() => _selectedPeriod = p),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Format:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSuccess('$reportType PDF generated!');
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFDC2626)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showSuccess('$reportType Excel generated!');
                    },
                    icon: const Icon(Icons.table_chart, size: 16),
                    label: const Text('Excel'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ $message'),
        backgroundColor: const Color(0xFF16A34A),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
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
              child: const Row(
                children: [
                  Text('📊', style: TextStyle(fontSize: 50)),
                  SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Reports Center',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('Generate Reports',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text('PDF & Excel Export',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ========== QUICK STATS ==========
            Row(
              children: [
                Expanded(
                  child: _quickStatCard(
                    'Today',
                    '₹35K',
                    Icons.today,
                    const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickStatCard(
                    'This Month',
                    '₹8.5L',
                    Icons.calendar_month,
                    const Color(0xFF3498DB),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _quickStatCard(
                    'Total',
                    '₹35L',
                    Icons.attach_money,
                    primaryPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // ========== PERIOD FILTER ==========
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade200, blurRadius: 10),
                ],
              ),
              child: Row(
                children: ['Today', 'Week', 'Month', 'Year'].map((period) {
                  final isSelected = _selectedPeriod == period;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = period),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color:
                              isSelected ? primaryPurple : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          period,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 25),

            // ========== REPORT TYPES ==========
            const Text('Report Types',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937))),
            const SizedBox(height: 12),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: reportTypes.map((r) {
                final color = r['color'] as Color;
                return GestureDetector(
                  onTap: () => _generateReport(r['title']),
                  child: Container(
                    padding: const EdgeInsets.all(14),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(r['icon'], color: color, size: 22),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              r['title'],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              r['desc'],
                              style: const TextStyle(
                                  fontSize: 10, color: Colors.grey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),

            // ========== RECENT REPORTS ==========
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Reports',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937))),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All',
                      style: TextStyle(color: primaryPurple)),
                ),
              ],
            ),

            ...recentReports.map((r) {
              final color = r['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
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
                      child: Icon(Icons.description, color: color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['title'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${r['date']} • ${r['size']}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showSuccess('Download started!'),
                      icon: Icon(Icons.download, color: color, size: 22),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon:
                          const Icon(Icons.share, color: Colors.grey, size: 20),
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

  Widget _quickStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
