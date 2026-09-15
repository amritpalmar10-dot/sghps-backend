import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentResults extends StatefulWidget {
  const StudentResults({super.key});

  @override
  State<StudentResults> createState() => _StudentResultsState();
}

class _StudentResultsState extends State<StudentResults> {
  List<dynamic> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    try {
      final response = await http.get(
        Uri.parse('https://sghps-backend.onrender.com/api/students/results'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _results = data['results'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    double total = 0;
    for (var r in _results) {
      total += (r['marks'] / r['total']) * 100;
    }
    final average = _results.isNotEmpty ? (total / _results.length).round() : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Results'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF9333EA), Color(0xFFA855F7)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Overall Percentage',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text('$average%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Mid Term Results',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  if (_results.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text('No results published yet',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._results.map((r) {
                      final percentage =
                          ((r['marks'] / r['total']) * 100).round();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey.shade200, blurRadius: 5)
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['subject'] ?? '',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 5),
                                  Text(r['exam_name'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.grey, fontSize: 12)),
                                  const SizedBox(height: 10),
                                  LinearProgressIndicator(
                                    value: r['marks'] / r['total'],
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation(
                                        _getGradeColor(r['grade'])),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Column(
                              children: [
                                Text('${r['marks']}/${r['total']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18)),
                                Text('$percentage%',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
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
