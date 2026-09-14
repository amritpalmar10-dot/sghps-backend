import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PrincipalAddEvent extends StatefulWidget {
  final int? eventId;

  const PrincipalAddEvent({super.key, this.eventId});

  @override
  State<PrincipalAddEvent> createState() => _PrincipalAddEventState();
}

class _PrincipalAddEventState extends State<PrincipalAddEvent> {
  static const Color primaryRed = Color(0xFFDC2626);

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedType = 'event';
  String _selectedPriority = 'normal';
  bool _isLoading = false;
  bool _isEditing = false;

  final List<DropdownMenuItem<String>> _typeItems = [
    const DropdownMenuItem<String>(
      value: 'event',
      child: Row(
        children: [
          Icon(Icons.celebration, size: 18),
          SizedBox(width: 8),
          Text('Event'),
        ],
      ),
    ),
    const DropdownMenuItem<String>(
      value: 'holiday',
      child: Row(
        children: [
          Icon(Icons.beach_access, size: 18),
          SizedBox(width: 8),
          Text('Holiday'),
        ],
      ),
    ),
    const DropdownMenuItem<String>(
      value: 'exam',
      child: Row(
        children: [
          Icon(Icons.assignment, size: 18),
          SizedBox(width: 8),
          Text('Exam'),
        ],
      ),
    ),
    const DropdownMenuItem<String>(
      value: 'ptm',
      child: Row(
        children: [
          Icon(Icons.people, size: 18),
          SizedBox(width: 8),
          Text('PTM'),
        ],
      ),
    ),
    const DropdownMenuItem<String>(
      value: 'activity',
      child: Row(
        children: [
          Icon(Icons.emoji_events, size: 18),
          SizedBox(width: 8),
          Text('Activity'),
        ],
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.eventId != null) {
      _isEditing = true;
      _loadEvent();
    }
  }

  Future<void> _loadEvent() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://sghps-backend.onrender.com/api/events'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['events'] as List;
        final event = events.firstWhere(
          (e) => e['id'] == widget.eventId,
          orElse: () => null,
        );

        if (event != null) {
          setState(() {
            _titleController.text = event['title'] ?? '';
            _descriptionController.text = event['description'] ?? '';
            _dateController.text = event['event_date'] ?? '';
            _timeController.text = event['event_time'] ?? '';
            _locationController.text = event['location'] ?? '';
            _selectedType = event['type'] ?? 'event';
            _selectedPriority = event['priority'] ?? 'normal';
          });
        }
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryRed),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      _dateController.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: primaryRed),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      _timeController.text = '$hour:$minute';
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final body = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'event_date': _dateController.text.trim(),
        'event_time': _timeController.text.trim(),
        'location': _locationController.text.trim(),
        'type': _selectedType,
        'priority': _selectedPriority,
      };

      http.Response response;
      if (_isEditing) {
        response = await http.put(
          Uri.parse(
              'https://sghps-backend.onrender.com/api/events/${widget.eventId}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );
      } else {
        response = await http.post(
          Uri.parse('https://sghps-backend.onrender.com/api/events/create'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );
      }

      final data = json.decode(response.body);

      setState(() => _isLoading = false);

      if (data['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(_isEditing ? '✅ Event updated!' : '✅ Event created!'),
              backgroundColor: const Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${data['message'] ?? 'Error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Connection error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Create Event'),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryRed, Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Text(_isEditing ? '✏️' : '📅',
                        style: const TextStyle(fontSize: 50)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit Event' : 'New Event',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            _isEditing
                                ? 'Update details'
                                : 'Announce to everyone',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Title
              _inputField(
                controller: _titleController,
                label: 'Title',
                icon: Icons.title,
                hint: 'e.g., Annual Sports Day',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title required' : null,
              ),

              // Description
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Event details...',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.description, color: primaryRed),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryRed, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),

              // Date
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    hintText: 'Tap to select',
                    prefixIcon:
                        const Icon(Icons.calendar_today, color: primaryRed),
                    suffixIcon:
                        const Icon(Icons.arrow_drop_down, color: primaryRed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryRed, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Date required' : null,
                ),
              ),

              // Time
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _selectTime,
                  decoration: InputDecoration(
                    labelText: 'Time (Optional)',
                    hintText: 'Tap to select',
                    prefixIcon:
                        const Icon(Icons.access_time, color: primaryRed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryRed, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),

              // Location
              _inputField(
                controller: _locationController,
                label: 'Location (Optional)',
                icon: Icons.location_on,
                hint: 'e.g., School Ground',
              ),

              // Type
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    labelText: 'Event Type',
                    prefixIcon: const Icon(Icons.category, color: primaryRed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryRed, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: _typeItems,
                  onChanged: (v) => setState(() => _selectedType = v!),
                ),
              ),

              // Priority
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: DropdownButtonFormField<String>(
                  value: _selectedPriority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    prefixIcon:
                        const Icon(Icons.priority_high, color: primaryRed),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryRed, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(
                        value: 'important', child: Text('Important')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                  ],
                  onChanged: (v) => setState(() => _selectedPriority = v!),
                ),
              ),

              const SizedBox(height: 10),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveEvent,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isEditing ? Icons.update : Icons.check),
                  label: Text(
                    _isLoading
                        ? 'Saving...'
                        : _isEditing
                            ? 'Update Event'
                            : 'Create Event',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryRed),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryRed, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
