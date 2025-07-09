import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/screen/dashboard.dart';
import 'package:attendance_geetai/screen2/attendance_History.dart' show AttendanceHistoryPage;

import 'package:attendance_geetai/screen2/logoutScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

// Model for Visit Attendance History
class VisitAttendanceHistoryModel {
  final String date;
  final String? inTime;
  final String? outTime;
  final String? location;
  final String? status;
  final String? remark;

  VisitAttendanceHistoryModel({
    required this.date,
    this.inTime,
    this.outTime,
    this.location,
    this.status,
    this.remark,
  });

  // Factory constructor to create an instance from JSON
  factory VisitAttendanceHistoryModel.fromJson(Map<String, dynamic> json) {
    return VisitAttendanceHistoryModel(
      date: json['date'] ?? '', // Ensure date is never null
      inTime: json['In_Time'],
      outTime: json['Out_Time'],
      location: json['location'],
      status: json['Status'], // Note: 'Status' with capital 'S' from DB
      remark: json['remark'],
    );
  }
}

// Visit Attendance History Page StatefulWidget
class VisitAttendanceHistory1Page extends StatefulWidget {
  @override
  _VisitAttendanceHistory1PageState createState() => _VisitAttendanceHistory1PageState();
}

// Visit Attendance History Page State
class _VisitAttendanceHistory1PageState extends State<VisitAttendanceHistory1Page> {
  // Stores all fetched visit attendance history
  List<VisitAttendanceHistoryModel> history = [];
  // Stores visit attendance history filtered by the selected date
  List<VisitAttendanceHistoryModel> filteredHistory = [];
  // Tracks loading state for UI
  bool isLoading = true;
  // Maps dates to their attendance status ('P' for Present, 'A' for Absent)
  Map<DateTime, String> attendanceMap = {};

  // Tracks the selected date in the calendar, defaults to today
  DateTime _selectedDay = DateTime.now();
  // Tracks the focused day in the calendar, defaults to today
  DateTime _focusedDay = DateTime.now();

  // Counters for present and absent days in the current month
  int _presentDaysInMonth = 0;
  int _absentDaysInMonth = 0;

  @override
  void initState() {
    super.initState();
    // Fetch visit attendance history when the widget initializes
    fetchVisitAttendanceHistory();
  }

  // Helper function to display "N/A" for null or empty values
  String _displayValue(String? value) {
    return value == null || value.trim().isEmpty ? "N/A" : value;
  }

  // Fetches visit attendance history from the API
  Future<void> fetchVisitAttendanceHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final staffIdToFetch = prefs.getString('id');

    if (staffIdToFetch == null || staffIdToFetch.isEmpty) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ No staff ID found for visit history. Please re-login.")),
        );
      }
      return;
    }

    final url = Uri.parse("https://erp.vpsedu.org/appapi/attendance/fetch_visit_attendance.php");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': staffIdToFetch}),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == true && data['data'] != null) {
        final List fetched = data['data'];
        List<VisitAttendanceHistoryModel> tempList = [];
        Map<DateTime, String> tempAttendanceMap = {};

        // Populate tempList from fetched data
        for (var item in fetched) {
          VisitAttendanceHistoryModel model = VisitAttendanceHistoryModel.fromJson(item);
          tempList.add(model);
        }

        // --- NEW LOGIC START ---
        // Determine the earliest and latest dates from the fetched data
        // If no data, default to a reasonable range around today.
        DateTime firstDate = DateTime.now().subtract(const Duration(days: 365)); // Default to past year
        DateTime lastDate = DateTime.now().add(const Duration(days: 30)); // Default to next month

        if (tempList.isNotEmpty) {
          tempList.sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
          firstDate = DateTime.parse(tempList.first.date);
          lastDate = DateTime.parse(tempList.last.date);
        }

        // Generate all dates within the relevant range and mark them 'A' (Absent) by default.
        // Normalize all dates to UTC midnight for consistent comparison.
        DateTime currentDate = DateTime.utc(firstDate.year, firstDate.month, firstDate.day);
        DateTime endDate = DateTime.utc(lastDate.year, lastDate.month, lastDate.day);

        while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
          tempAttendanceMap[currentDate] = "A"; // Assume absent by default
          currentDate = currentDate.add(const Duration(days: 1));
        }

        // Now, iterate through fetched data and mark 'P' (Present) where applicable.
        for (var model in tempList) {
          DateTime date = DateTime.parse(model.date);
          DateTime normalizedDate = DateTime.utc(date.year, date.month, date.day);

          if (model.inTime != null && model.inTime!.isNotEmpty && model.inTime != "00:00:00") {
            tempAttendanceMap[normalizedDate] = "P";
          }
          // If inTime is "00:00:00" or empty, it remains "A" from the default setting.
        }
        // --- NEW LOGIC END ---

        setState(() {
          history = tempList; // Store all fetched history (only records from API)
          attendanceMap = tempAttendanceMap; // Store attendance status for calendar (includes absent days)
          isLoading = false;
          // Filter history for the initially selected day (today)
          _filterHistoryByDate(_selectedDay);
          // Calculate present/absent days for the initially focused month
          _calculateMonthlyAttendance(_focusedDay);
        });
      } else {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ No visit attendance data available.")),
          );
          // If no data, still calculate monthly attendance for the current month
          _calculateMonthlyAttendance(_focusedDay);
        }
      }
    } catch (e) {
      print("❗ Exception while calling Visit History API: $e");
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to fetch visit history: $e")),
        );
      }
    }
  }

  // Filters the complete history list based on the given date
  void _filterHistoryByDate(DateTime date) {
    setState(() {
      filteredHistory = history
          .where((item) {
            final itemDate = DateTime.parse(item.date);
            // Compare only year, month, and day for date matching
            return itemDate.year == date.year &&
                itemDate.month == date.month &&
                itemDate.day == date.day;
          })
          .toList();
    });
  }

  // Calculates present and absent days for the given month
  void _calculateMonthlyAttendance(DateTime monthDate) {
    int present = 0;
    int absent = 0;

    // Get the first day of the focused month
    DateTime firstDayOfMonth = DateTime.utc(monthDate.year, monthDate.month, 1);
    // Get the last day of the focused month
    DateTime lastDayOfMonth = DateTime.utc(monthDate.year, monthDate.month + 1, 0);

    // Iterate through all days in the month and check their status from attendanceMap
    DateTime tempDate = firstDayOfMonth;
    while (tempDate.isBefore(lastDayOfMonth) || tempDate.isAtSameMomentAs(lastDayOfMonth)) {
      DateTime normalizedTempDate = DateTime.utc(tempDate.year, tempDate.month, tempDate.day);
      String? status = attendanceMap[normalizedTempDate];

      if (status == "P") {
        present++;
      } else if (status == "A") {
        absent++;
      }
      tempDate = tempDate.add(const Duration(days: 1));
    }

    setState(() {
      _presentDaysInMonth = present;
      _absentDaysInMonth = absent;
    });
  }

  // Function to show the calendar as a bottom sheet
  void _showCalendarBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the bottom sheet to take full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Text(
                  'Select a Date',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Card(
                  margin: EdgeInsets.zero, // Remove outer margin as it's now in a sheet
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2023, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                        _filterHistoryByDate(selectedDay);
                      });
                      Navigator.pop(context); // Close the bottom sheet after selection
                    },
                    onPageChanged: (focusedDay) {
                      setState(() {
                        _focusedDay = focusedDay;
                        _calculateMonthlyAttendance(focusedDay);
                      });
                    },
                    calendarBuilders: CalendarBuilders(
                      defaultBuilder: (context, date, _) {
                        DateTime normalizedDate = DateTime.utc(date.year, date.month, date.day);
                        String? status = attendanceMap[normalizedDate];

                        if (status == "P") {
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                'P',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        } else if (status == "A") {
                          return Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                'A',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                        return null;
                      },
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).primaryColor),
                      rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).primaryColor),
                    ),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      weekendTextStyle: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Monthly Attendance Summary inside the bottom sheet
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.green.shade200, width: 1.5),
                        ),
                        color: Colors.green.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Present Days',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: Text(
                                  '$_presentDaysInMonth',
                                  key: ValueKey<int>(_presentDaysInMonth),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: Colors.red.shade200, width: 1.5),
                        ),
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Absent Days',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                              ),
                              const SizedBox(height: 8),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (Widget child, Animation<double> animation) {
                                  return FadeTransition(opacity: animation, child: child);
                                },
                                child: Text(
                                  '$_absentDaysInMonth',
                                  key: ValueKey<int>(_absentDaysInMonth),
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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
        leading: IconButton(
           icon: Icon(Icons.home, color: Colors.white),
  onPressed: () {
    final navBarState = context.findAncestorStateOfType<BottomNavigationBarExampleState>();
    navBarState?.setState(() {
      navBarState.selectedIndex = 0; // Go to Home Tab
      navBarState.navigatorKeys[0].currentState?.pushNamedAndRemoveUntil('/', (route) => false);
    });
             },
),       automaticallyImplyLeading: false,
        title: const Text(
          "Visit Attendance",
          style: TextStyle(color: Color.fromARGB(174, 255, 255, 255)),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF021526),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white), // New Calendar Icon
            tooltip: "Show Calendar",
            onPressed: _showCalendarBottomSheet, // Call the new function
          ),
          IconButton(
            icon: const Icon(Icons.mark_as_unread, color: Colors.white), // General Attendance Icon
            tooltip: "Attendance History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AttendanceHistoryPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => LogoutConfirmation.show(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // No TableCalendar directly here anymore

                // Display filtered attendance history or a message
                Expanded(
                  child: filteredHistory.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_note, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 10),
                              Text(
                                'No visit attendance recorded for\n${_displayValue(_selectedDay.toLocal().toString().split(' ')[0])}.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredHistory.length,
                          itemBuilder: (context, index) {
                            final item = filteredHistory[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '📅 Date: ${_displayValue(item.date)}',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                                    ),
                                    const Divider(height: 20, thickness: 1),
                                    _buildInfoRow(
                                      icon: Icons.access_time,
                                      label: "In/Out Time:",
                                      value: "In: ${_displayValue(item.inTime)} | Out: ${_displayValue(item.outTime)}",
                                      context: context,
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.location_on,
                                      label: "Location:",
                                      value: _displayValue(item.location),
                                      context: context,
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.check_circle,
                                      label: "Status:",
                                      value: _displayValue(item.status),
                                      valueColor: item.status == 'Present' ? Colors.green : Colors.orange,
                                      context: context,
                                    ),
                                    _buildInfoRow(
                                      icon: Icons.notes,
                                      label: "Remark:",
                                      value: _displayValue(item.remark),
                                      context: context,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // Helper widget to build consistent info rows with icons and styling
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required BuildContext context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey.shade600),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: valueColor ?? Colors.blueGrey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}