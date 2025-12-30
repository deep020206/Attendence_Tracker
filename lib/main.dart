import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0xFF6366F1),
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AttendanceApp());
}

/// Main Application Widget with Modern Design
class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Deep Purple
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF9FAFB), // Off-white
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6366F1),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6366F1),
              width: 2,
            ),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 14,
          ),
          hintStyle: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6366F1),
            side: const BorderSide(
              color: Color(0xFF6366F1),
              width: 2,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const AttendanceScreen(),
    );
  }
}

/// Main Attendance Screen with multiple states
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Step tracking
  int _currentStep = 0;
  bool _isLoading = false;

  // Form data for initial setup
  String? _selectedDepartment;
  String? _selectedDivision;
  int? _selectedSemester;
  int? _lectureNumber;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _facultyName = '';
  String _rollNumberFormat = ''; // e.g., "23it" for roll numbers like 23it001

  // Roll number ranges
  List<RollRange> _rollRanges = [];

  // Generated attendance data
  List<int> _allRollNumbers = [];
  Map<int, bool> _attendanceStatus = {}; // true = present, false = absent
  bool _markAllPresent = true;

  // Constants
  final List<String> _departments = ['IT', 'CE', 'ME', 'EE', 'ECE'];
  final List<String> _divisions = ['Div 1', 'Div 2', 'Div 3', 'Div 4'];

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  /// Load previously saved department and division from SharedPreferences
  Future<void> _loadSavedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDepartment = prefs.getString('last_department');
      _selectedDivision = prefs.getString('last_division');
    });
  }

  /// Save department and division to SharedPreferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedDepartment != null) {
      await prefs.setString('last_department', _selectedDepartment!);
    }
    if (_selectedDivision != null) {
      await prefs.setString('last_division', _selectedDivision!);
    }
  }

  /// Validate if all mandatory fields are filled
  bool _isStep0Valid() {
    return _selectedDepartment != null &&
        _selectedDivision != null &&
        _selectedSemester != null;
  }

  /// Validate if at least one roll range is added
  bool _isStep1Valid() {
    return _rollRanges.isNotEmpty;
  }

  /// Generate all roll numbers from ranges
  void _generateAttendanceList() {
    _allRollNumbers = [];
    _attendanceStatus = {};

    // Sort ranges and generate roll numbers
    for (var range in _rollRanges) {
      for (int i = range.start; i <= range.end; i++) {
        _allRollNumbers.add(i);
        _attendanceStatus[i] = true; // Default: Present
      }
    }

    // Sort the roll numbers
    _allRollNumbers.sort();

    setState(() {
      _currentStep = 2;
    });
  }

  /// Toggle attendance status for a roll number
  void _toggleAttendance(int rollNumber) {
    setState(() {
      _attendanceStatus[rollNumber] =
          !(_attendanceStatus[rollNumber] ?? true);
    });
  }

  /// Mark all as present
  void _markAllAsPresent() {
    setState(() {
      for (int roll in _allRollNumbers) {
        _attendanceStatus[roll] = true;
      }
      _markAllPresent = true;
    });
  }

  /// Mark all as absent
  void _markAllAsAbsent() {
    setState(() {
      for (int roll in _allRollNumbers) {
        _attendanceStatus[roll] = false;
      }
      _markAllPresent = false;
    });
  }

  /// Generate formatted summary
  String _generateSummary() {
    List<int> presentRolls = [];
    List<int> absentRolls = [];

    for (int roll in _allRollNumbers) {
      if (_attendanceStatus[roll] ?? true) {
        presentRolls.add(roll);
      } else {
        absentRolls.add(roll);
      }
    }

    String dateStr =
        '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}';
    String timeStr =
        '${_selectedTime.hour}:${_selectedTime.minute.toString().padLeft(2, '0')} ${_selectedTime.period.toString().split('.').last.toUpperCase()}';

    // Generate format examples
    String formatExample = '';
    if (_rollNumberFormat.isNotEmpty) {
      formatExample = '\nRoll Number Format: ${_rollNumberFormat}\n';
    }

    String summary = '''Department: $_selectedDepartment
Division: $_selectedDivision
Semester: $_selectedSemester${_lectureNumber != null ? '\nLecture No: $_lectureNumber' : ''}
Date: $dateStr
Time: $timeStr
Faculty Name: ${_facultyName.isEmpty ? 'N/A' : _facultyName}$formatExample
Present:
${presentRolls.isEmpty ? 'None' : presentRolls.join(', ')}

Absent:
${absentRolls.isEmpty ? 'None' : absentRolls.join(', ')}''';

    return summary;
  }

  void _copySummary() {
    Clipboard.setData(ClipboardData(text: _generateSummary()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Attendance copied successfully'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.school,
                  size: 60,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Attendance Manager',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Created By',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Deep Ashokbhai Marodiya',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'ID: 23IT060',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '"Your feedback and suggestions are always welcome. Together, we can make this better!"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance Manager',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'about') {
                _showAboutDialog(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 12),
                    Text('About'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _buildStepContent(),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _buildProgressIndicator(),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        color: Color(0xFF6366F1),
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Processing...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build progress dots (1/4, 2/4, etc.)
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index <= _currentStep
                  ? const Color(0xFF6366F1)
                  : const Color(0xFFE5E7EB),
            ),
          );
        }),
      ),
    );
  }

  /// Build content based on current step
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return _buildStep0();
    }
  }

  /// Step 0: Class Information
  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Title
          const Text(
            'Class Information',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter class details for attendance',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 32),

          // Form Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Department
                  DropdownButtonFormField<String>(
                    value: _selectedDepartment,
                    decoration: InputDecoration(
                      labelText: 'Department',
                      prefixIcon: const Icon(Icons.school),
                    ),
                    items: _departments
                        .map((dept) => DropdownMenuItem(
                              value: dept,
                              child: Text(dept),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedDepartment = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Division
                  DropdownButtonFormField<String>(
                    value: _selectedDivision,
                    decoration: InputDecoration(
                      labelText: 'Division',
                      prefixIcon: const Icon(Icons.group),
                    ),
                    items: _divisions
                        .map((div) => DropdownMenuItem(
                              value: div,
                              child: Text(div),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedDivision = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Semester
                  DropdownButtonFormField<int>(
                    value: _selectedSemester,
                    decoration: InputDecoration(
                      labelText: 'Semester',
                      prefixIcon: const Icon(Icons.calendar_view_month),
                    ),
                    items: List.generate(8, (index) => index + 1)
                        .map((sem) => DropdownMenuItem(
                              value: sem,
                              child: Text('Semester $sem'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() => _selectedSemester = value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Lecture Number
                  TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Lecture Number (Optional)',
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    onChanged: (value) {
                      setState(() => _lectureNumber = int.tryParse(value));
                    },
                  ),
                  const SizedBox(height: 20),

                  // Date Picker Button
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() => _selectedDate = pickedDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedDate.day}-${_selectedDate.month}-${_selectedDate.year}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Time Picker Button
                  InkWell(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (pickedTime != null) {
                        setState(() => _selectedTime = pickedTime);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Time',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Faculty Name
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Faculty Name (Optional)',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    onChanged: (value) =>
                        setState(() => _facultyName = value),
                  ),
                  const SizedBox(height: 20),

                  // Roll Format
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Roll Format (Optional)',
                      prefixIcon: const Icon(Icons.numbers),
                      hintText: 'e.g., 23itxxx, 24itxxx or D23itxxx',
                    ),
                    onChanged: (value) =>
                        setState(() => _rollNumberFormat = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Next Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isStep0Valid() && !_isLoading
                  ? () async {
                      setState(() => _isLoading = true);
                      await Future.delayed(const Duration(milliseconds: 300));
                      _savePreferences();
                      setState(() {
                        _currentStep = 1;
                        _isLoading = false;
                      });
                    }
                  : null,
              child: const Text(
                'Continue to Ranges',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Roll Number Ranges
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Title
          const Text(
            'Roll Number Ranges',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add one or more ranges. e.g., 1-60, 142-156',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Added Ranges
          if (_rollRanges.isNotEmpty) ...[
            const Text(
              'Added Ranges',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _rollRanges.length,
              itemBuilder: (context, index) {
                final range = _rollRanges[index];
                return Dismissible(
                  key: ValueKey(index),
                  onDismissed: (direction) {
                    setState(() => _rollRanges.removeAt(index));
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.numbers,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${range.start} to ${range.end}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  Text(
                                    '${range.end - range.start + 1} students',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFF43F5E),
                            ),
                            onPressed: () {
                              setState(() => _rollRanges.removeAt(index));
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],

          // Add Range Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: RollRangeInput(
                onAddRange: (start, end) {
                  if (start > 0 && end > 0 && start <= end) {
                    setState(() {
                      _rollRanges.add(RollRange(start: start, end: end));
                      _rollRanges
                          .sort((a, b) => a.start.compareTo(b.start));
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Invalid range'),
                        backgroundColor: const Color(0xFFF43F5E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.all(16),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Navigation Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => setState(() => _currentStep = 0),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isStep1Valid() && !_isLoading
                      ? () async {
                          setState(() => _isLoading = true);
                          await Future.delayed(const Duration(milliseconds: 400));
                          _generateAttendanceList();
                          setState(() => _isLoading = false);
                        }
                      : null,
                  child: const Text('Generate List'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Step 2: Attendance Marking
  Widget _buildStep2() {
    List<int> presentRolls =
        _allRollNumbers.where((r) => _attendanceStatus[r] ?? true).toList();
    List<int> absentRolls =
        _allRollNumbers.where((r) => !(_attendanceStatus[r] ?? true)).toList();

    return Stack(
      children: [
        Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Mark Attendance',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Swipe to remove or tap to change status',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Stats Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn(
                            label: 'Present',
                            count: presentRolls.length,
                            color: const Color(0xFF10B981),
                            icon: Icons.check_circle,
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey[300],
                          ),
                          _buildStatColumn(
                            label: 'Absent',
                            count: absentRolls.length,
                            color: const Color(0xFFF43F5E),
                            icon: Icons.cancel,
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: Colors.grey[300],
                          ),
                          _buildStatColumn(
                            label: 'Total',
                            count: _allRollNumbers.length,
                            color: const Color(0xFF6366F1),
                            icon: Icons.people,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Student List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                itemCount: _allRollNumbers.length,
                itemBuilder: (context, index) {
                  final rollNumber = _allRollNumbers[index];
                  final isPresent = _attendanceStatus[rollNumber] ?? true;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border(
                          left: BorderSide(
                            color: isPresent
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF43F5E),
                            width: 4,
                          ),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: isPresent
                              ? const Color(0xFF10B981).withOpacity(0.2)
                              : const Color(0xFFF43F5E).withOpacity(0.2),
                          child: Text(
                            rollNumber.toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPresent
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF43F5E),
                            ),
                          ),
                        ),
                        title: Text(
                          'Roll No: $rollNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        subtitle: Text(
                          isPresent ? 'Present' : 'Absent',
                          style: TextStyle(
                            color: isPresent
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF43F5E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        trailing: Switch(
                          value: isPresent,
                          onChanged: (_) => _toggleAttendance(rollNumber),
                          activeColor: const Color(0xFF10B981),
                          inactiveThumbColor: const Color(0xFFF43F5E),
                        ),
                        onTap: () => _toggleAttendance(rollNumber),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        // Bottom Navigation Buttons
        Positioned(
          bottom: 16,
          left: 24,
          right: 24,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => setState(() => _currentStep = 1),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          await Future.delayed(const Duration(milliseconds: 300));
                          setState(() {
                            _currentStep = 3;
                            _isLoading = false;
                          });
                        },
                  child: const Text('Summary'),
                ),
              ),
            ],
          ),
        ),
        // FAB for Mark All
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            onPressed: _showMarkAllBottomSheet,
            backgroundColor: const Color(0xFF6366F1),
            child: const Icon(Icons.more_vert),
          ),
        ),
      ],
    );
  }

  /// Show Mark All bottom sheet
  void _showMarkAllBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  _markAllAsPresent();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('Mark All Present'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () {
                  _markAllAsAbsent();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.cancel),
                label: const Text('Mark All Absent'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(
                    color: Color(0xFFF43F5E),
                    width: 2,
                  ),
                  foregroundColor: const Color(0xFFF43F5E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Step 3: Summary
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          // Title
          const Text(
            'Summary & Review',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review and copy your attendance record',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),

          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(
                  _generateSummary(),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.8,
                    fontFamily: 'monospace',
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Action Buttons
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _copySummary,
              icon: const Icon(Icons.content_copy),
              label: const Text(
                'Copy to Clipboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 300));
                setState(() {
                  _currentStep = 2;
                  _isLoading = false;
                });
              },
              child: const Text(
                'Back to Attendance',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 56,
            child: TextButton(
              onPressed: _isLoading ? null : () async {
                setState(() => _isLoading = true);
                await Future.delayed(const Duration(milliseconds: 300));
                setState(() {
                  _currentStep = 0;
                  _selectedDepartment = null;
                  _selectedDivision = null;
                  _lectureNumber = null;
                  _selectedDate = DateTime.now();
                  _selectedTime = TimeOfDay.now();
                  _facultyName = '';
                  _rollNumberFormat = '';
                  _rollRanges = [];
                  _allRollNumbers = [];
                  _attendanceStatus = {};
                  _isLoading = false;
                });
              },
              child: const Text(
                'Start New Attendance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF59E0B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build stat column for stats card
  Widget _buildStatColumn({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

/// Roll Number Range Data Model
class RollRange {
  final int start;
  final int end;

  RollRange({required this.start, required this.end});
}

/// Widget for adding roll number ranges
class RollRangeInput extends StatefulWidget {
  final Function(int, int) onAddRange;

  const RollRangeInput({
    super.key,
    required this.onAddRange,
  });

  @override
  State<RollRangeInput> createState() => _RollRangeInputState();
}

class _RollRangeInputState extends State<RollRangeInput> {
  late TextEditingController _startController;
  late TextEditingController _endController;

  @override
  void initState() {
    super.initState();
    _startController = TextEditingController();
    _endController = TextEditingController();
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _startController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Start',
                  prefixIcon: const Icon(Icons.low_priority),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Text(
                'to',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),
            Expanded(
              child: TextField(
                controller: _endController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'End',
                  prefixIcon: const Icon(Icons.arrow_upward),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              final start = int.tryParse(_startController.text) ?? 0;
              final end = int.tryParse(_endController.text) ?? 0;
              widget.onAddRange(start, end);
              _startController.clear();
              _endController.clear();
            },
            icon: const Icon(Icons.add_circle),
            label: const Text(
              'Add Range',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
