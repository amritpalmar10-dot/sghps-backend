import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccountantTeachers extends StatefulWidget {
  const AccountantTeachers({super.key});

  @override
  State<AccountantTeachers> createState() => _AccountantTeachersState();
}

class _AccountantTeachersState extends State<AccountantTeachers> {
  static const Color primaryPurple = Color(0xFF9333EA);
  static const Color secondaryPurple = Color(0xFFA855F7);

  List<dynamic> _teachers = [];
  List<dynamic> _filteredTeachers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filterType = 'All';

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTeachers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://organised-petition-telecharger-saints.trycloudflare.com/api/accountant/teachers'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _teachers = data['teachers'] ?? [];
          _filteredTeachers = _teachers;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _searchTeachers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTeachers = _teachers;
      } else {
        _filteredTeachers = _teachers.where((t) {
          final name = (t['name'] ?? '').toString().toLowerCase();
          final code = (t['staff_code'] ?? '').toString().toLowerCase();
          final subject = (t['subject'] ?? '').toString().toLowerCase();
          final q = query.toLowerCase();
          return name.contains(q) || code.contains(q) || subject.contains(q);
        }).toList();
      }
      _applyFilterType(_filterType, false);
    });
  }

  void _applyFilterType(String type, [bool update = true]) {
    if (update) setState(() => _filterType = type);

    List<dynamic> base = _searchController.text.isEmpty
        ? _teachers
        : _teachers.where((t) {
            final q = _searchController.text.toLowerCase();
            return (t['name'] ?? '').toString().toLowerCase().contains(q) ||
                (t['staff_code'] ?? '').toString().toLowerCase().contains(q) ||
                (t['subject'] ?? '').toString().toLowerCase().contains(q);
          }).toList();

    if (type == 'Incharge') {
      base = base.where((t) => t['is_class_incharge'] == 1).toList();
    } else if (type == 'Regular') {
      base = base.where((t) => t['is_class_incharge'] != 1).toList();
    }

    setState(() => _filteredTeachers = base);
  }

  @override
  Widget build(BuildContext context) {
    final inchargeCount =
        _teachers.where((t) => t['is_class_incharge'] == 1).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('All Teachers'),
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ========== HEADER ==========
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [primaryPurple, secondaryPurple],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('👨‍🏫', style: TextStyle(fontSize: 40)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Teaching Staff',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text(
                              '${_teachers.length} Teachers',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$inchargeCount Class Incharges',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== SEARCH BAR ==========
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _searchTeachers,
                        decoration: InputDecoration(
                          hintText: 'Search by name, code or subject...',
                          prefixIcon:
                              const Icon(Icons.search, color: primaryPurple),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchTeachers('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: primaryPurple, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('All', primaryPurple),
                            const SizedBox(width: 8),
                            _filterChip('Incharge', const Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            _filterChip('Regular', const Color(0xFF3498DB)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ========== LIST ==========
                Expanded(
                  child: _filteredTeachers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 60, color: Colors.grey.shade300),
                              const SizedBox(height: 10),
                              const Text('No teachers found',
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredTeachers.length,
                          itemBuilder: (context, index) {
                            final t = _filteredTeachers[index];
                            final isIncharge = t['is_class_incharge'] == 1;
                            final color = isIncharge
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF3498DB);

                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/accountant-teacher-detail',
                                  arguments: {'id': t['id']},
                                );
                              },
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
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Avatar
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                color,
                                                color.withValues(alpha: 0.7)
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              (t['name'] ?? 'T')
                                                  .toString()
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      t['name'] ?? '',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  if (isIncharge)
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: color.withValues(
                                                            alpha: 0.1),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.star,
                                                              color: color,
                                                              size: 12),
                                                          const SizedBox(
                                                              width: 3),
                                                          Text(
                                                            'Incharge',
                                                            style: TextStyle(
                                                              color: color,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${t['subject'] ?? ''} • ${t['designation'] ?? 'Teacher'}',
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Code: ${t['staff_code'] ?? ''}',
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 14, color: Colors.grey),
                                      ],
                                    ),
                                    if (isIncharge &&
                                        t['incharge_class'] != null &&
                                        t['incharge_class']
                                            .toString()
                                            .isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.08),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: color.withValues(alpha: 0.2),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.class_,
                                                color: color, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Class Incharge: ${t['incharge_class']}-${t['incharge_section']}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/accountant-add-teacher');
          _fetchTeachers();
        },
        backgroundColor: primaryPurple,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Teacher'),
      ),
    );
  }

  Widget _filterChip(String label, Color color) {
    final isSelected = _filterType == label;
    return GestureDetector(
      onTap: () => _applyFilterType(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
