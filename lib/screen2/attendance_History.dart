import 'package:attendance_geetai/MyBottomNavigationBar.dart';

import 'package:attendance_geetai/screen/dashboard.dart';
import 'package:attendance_geetai/screen2/logoutScreen.dart';
import 'package:attendance_geetai/screen2/visitehistroy.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:table_calendar/table_calendar.dart';

// Assuming LoginPage is defined elsewhere, if not, provide a minimal one
class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Please implement your LoginPage here.')),
    );
  }
}

// --- ENUM FOR ATTENDANCE STATUS FOR HISTORY DISPLAY ---
enum AttendanceStatus {
  present, // ID: 1
  late, // ID: 2
  absent, // ID: 3
  halfDay, // ID: 4
  holiday, // ID: 5
  Unknown, // For any unhandled status or ID
}

// --- DATA MODEL FOR ATTENDANCE RECORD ---
class AttendanceRecord {
  final DateTime date;
  final String? inTime;
  final String? outTime;
  final String? location;
  final AttendanceStatus status;
  final String? remark;

  AttendanceRecord({
    required this.date,
    this.inTime,
    this.outTime,
    this.location,
    required this.status,
    this.remark,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    DateTime recordDate;
    try {
      recordDate = DateFormat('yyyy-MM-dd').parse(json['date']);
    } catch (e) {
      recordDate = DateTime.now();
    }

    AttendanceStatus parsedStatus;
    final String? attendanceTypeId = json['staff_attendance_type_id']?.toString();

    if (attendanceTypeId != null) {
      switch (attendanceTypeId) {
        case '1':
          parsedStatus = AttendanceStatus.present;
          break;
        case '2':
          parsedStatus = AttendanceStatus.late;
          break;
        case '3':
          parsedStatus = AttendanceStatus.absent;
          break;
        case '4':
          parsedStatus = AttendanceStatus.halfDay;
          break;
        case '5':
          parsedStatus = AttendanceStatus.holiday;
          break;
        default:
          parsedStatus = AttendanceStatus.Unknown;
      }
    } else {
      parsedStatus = AttendanceStatus.Unknown;
    }

    return AttendanceRecord(
      date: recordDate,
      inTime: json['In_Time'],
      outTime: json['Out_Time'],
      location: json['location'],
      status: parsedStatus,
      remark: json['remark'],
    );
  }
}

// --- ATTENDANCE HISTORY PAGE ---
class AttendanceHistoryPage extends StatefulWidget {
  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> with SingleTickerProviderStateMixin {
  late Future<List<AttendanceRecord>> _historyFuture;
  List<AttendanceRecord> _allHistory = [];
  List<AttendanceRecord> _filteredHistory = [];
  Map<DateTime, AttendanceRecord> _attendanceMap = {};

  CalendarFormat _calendarFormat = CalendarFormat.month; // Always show full month
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String? _staffId;

  // Monthly counters for attendance types
  int _presentDaysInMonth = 0;
  int _lateDaysInMonth = 0;
  int _absentDaysInMonth = 0;
  int _halfDaysInMonth = 0;
  int _holidayDaysInMonth = 0;

  // Animation for daily attendance cards
  late AnimationController _cardAnimationController;
  late Animation<Offset> _cardSlideAnimation;
  late Animation<double> _cardFadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadStaffIdAndFetchHistory();

    _cardAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.5), // Start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeOut,
    ));

    _cardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _cardAnimationController,
      curve: Curves.easeIn,
    ));
  }

  @override
  void dispose() {
    _cardAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffIdAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id');

    if (id == null || id.isEmpty) {
      Fluttertoast.showToast(
        msg: "Session expired. Please login again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } else {
      setState(() {
        _staffId = id;
        _historyFuture = fetchAttendanceHistory(id);
      });
      _allHistory = await _historyFuture;
      _populateAttendanceMap(_allHistory);
      _selectedDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
      _filterHistoryByDate(_selectedDay);
      _calculateMonthlyAttendance(_focusedDay);
    }
  }

  Future<List<AttendanceRecord>> fetchAttendanceHistory(String staffId) async {
    final String apiUrl = 'https://erp.vpsedu.org/appapi/attendance/feach_attendanc.php?staff_id=$staffId';
    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          List<dynamic> attendanceData = responseData['data'];
          List<AttendanceRecord> fetchedRecords =
              attendanceData.map((json) => AttendanceRecord.fromJson(json)).toList();

          Map<DateTime, AttendanceRecord> fetchedMap = {
            for (var record in fetchedRecords)
              DateTime(record.date.year, record.date.month, record.date.day): record
          };

          List<AttendanceRecord> completeHistory = [];
          DateTime today = DateTime.now();
          DateTime ninetyDaysAgo = today.subtract(const Duration(days: 90));

          for (int i = 0; i <= today.difference(ninetyDaysAgo).inDays; i++) {
            DateTime currentDay = DateTime(ninetyDaysAgo.year, ninetyDaysAgo.month, ninetyDaysAgo.day).add(Duration(days: i));
            currentDay = DateTime(currentDay.year, currentDay.month, currentDay.day); // Normalize to just date

            if (fetchedMap.containsKey(currentDay)) {
              completeHistory.add(fetchedMap[currentDay]!);
            } else if (currentDay.isBefore(today.add(const Duration(days: 1)))) {
              completeHistory.add(
                AttendanceRecord(
                  date: currentDay,
                  status: AttendanceStatus.absent,
                  remark: "No attendance recorded",
                ),
              );
            }
          }
          completeHistory.sort((a, b) => a.date.compareTo(b.date));
          return completeHistory;
        } else {
          Fluttertoast.showToast(msg: responseData['message'] ?? "No attendance data found.");
          return [];
        }
      } else {
        Fluttertoast.showToast(msg: "Failed to load attendance history: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Error fetching attendance history: $e");
      print("Error fetching attendance history: $e"); // For debugging
      return [];
    }
  }

  void _populateAttendanceMap(List<AttendanceRecord> records) {
    _attendanceMap.clear();
    for (var record in records) {
      _attendanceMap[DateTime(record.date.year, record.date.month, record.date.day)] = record;
    }
  }

  void _filterHistoryByDate(DateTime day) {
    setState(() {
      _selectedDay = DateTime(day.year, day.month, day.day);
      _filteredHistory = [_attendanceMap[_selectedDay]].whereType<AttendanceRecord>().toList();

      if (_filteredHistory.isEmpty && _selectedDay.isBefore(DateTime.now().add(const Duration(days: 1)))) {
        _filteredHistory.add(AttendanceRecord(
          date: _selectedDay,
          status: AttendanceStatus.absent,
          remark: "No attendance recorded",
        ));
      }
    });
    _cardAnimationController.forward(from: 0.0);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _filterHistoryByDate(_selectedDay);
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    setState(() {
      _focusedDay = focusedDay;
    });
    _calculateMonthlyAttendance(_focusedDay);
  }

  void _calculateMonthlyAttendance(DateTime month) {
    _presentDaysInMonth = 0;
    _lateDaysInMonth = 0;
    _absentDaysInMonth = 0;
    _halfDaysInMonth = 0;
    _holidayDaysInMonth = 0;

    for (var record in _allHistory) {
      if (record.date.year == month.year && record.date.month == month.month) {
        switch (record.status) {
          case AttendanceStatus.present:
            _presentDaysInMonth++;
            break;
          case AttendanceStatus.late:
            _lateDaysInMonth++;
            break;
          case AttendanceStatus.absent:
            _absentDaysInMonth++;
            break;
          case AttendanceStatus.halfDay:
            _halfDaysInMonth++;
            break;
          case AttendanceStatus.holiday:
            _holidayDaysInMonth++;
            break;
          case AttendanceStatus.Unknown:
            break;
        }
      }
    }
    setState(() {});
  }

  bool _hasRecordedAttendance(AttendanceStatus status) {
    return status != AttendanceStatus.absent && status != AttendanceStatus.Unknown;
  }

  IconData _getStatusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle;
      case AttendanceStatus.late:
        return Icons.access_time;
      case AttendanceStatus.absent:
        return Icons.cancel;
      case AttendanceStatus.halfDay:
        return Icons.watch_later;
      case AttendanceStatus.holiday:
        return Icons.celebration;
      case AttendanceStatus.Unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
      case AttendanceStatus.halfDay:
        return Colors.purple;
      case AttendanceStatus.holiday:
        return Colors.blue;
      case AttendanceStatus.Unknown:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF021526),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(25.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
  leading: IconButton(
    icon: Icon(Icons.home, color: Colors.white),
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    },
  ),
  automaticallyImplyLeading: false,
  title: Text(
    "Attendance Histroy",
    style: TextStyle(color: Color.fromARGB(174, 255, 255, 255)),
  ),
  centerTitle: true,
  backgroundColor: Color(0xFF021526),
  actions: [
    IconButton(
      icon: Icon(Icons.map_outlined, color: Colors.white), // Visit Attendance Icon
      tooltip: "Visit Attendance",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VisitAttendanceHistory1Page()),
        );
      },
    ),
    IconButton(
      icon: Icon(Icons.logout, color: Colors.white),
      onPressed: () => LogoutConfirmation.show(context),
    ),
  ],
),

        ),
      ),
      body: FutureBuilder<List<AttendanceRecord>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No attendance history found.'));
          } else {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20), // General bottom padding for scroll view
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Today's Attendance Status
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: AnimatedBuilder(
                        animation: _cardAnimationController,
                        builder: (context, child) {
                          final todayRecord = _attendanceMap[DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)];
                          final status = todayRecord?.status ?? AttendanceStatus.Unknown;
                          final cardColor = _hasRecordedAttendance(status) ? Colors.green.shade50 : Colors.red.shade50;
                          final statusTextColor = _hasRecordedAttendance(status) ? Colors.green.shade800 : Colors.red.shade800;

                          return ScaleTransition(
                            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(
                              parent: _cardAnimationController,
                              curve: Curves.easeOutCubic,
                            )),
                            child: FadeTransition(
                              opacity: _cardFadeAnimation,
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                color: cardColor,
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Today's Attendance Status",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF021526),
                                            ),
                                          ),
                                          Icon(
                                            _getStatusIcon(status),
                                            color: _getStatusColor(status),
                                            size: 36,
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24, thickness: 1.2),
                                      if (todayRecord != null)
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Status: ${status.toString().split('.').last.replaceAll('_', ' ')}",
                                              style: TextStyle(
                                                fontSize: 19,
                                                fontWeight: FontWeight.w700,
                                                color: statusTextColor,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            if (todayRecord.inTime != null && todayRecord.inTime!.isNotEmpty)
                                              _buildDetailRow(Icons.login, "In Time:", todayRecord.inTime!),
                                            if (todayRecord.outTime != null && todayRecord.outTime!.isNotEmpty)
                                              _buildDetailRow(Icons.logout, "Out Time:", todayRecord.outTime!),
                                            if (todayRecord.location != null && todayRecord.location!.isNotEmpty)
                                              _buildDetailRow(Icons.location_on, "Location:", todayRecord.location!),
                                            if (todayRecord.remark != null && todayRecord.remark!.isNotEmpty)
                                              _buildDetailRow(Icons.info_outline, "Remark:", todayRecord.remark!),
                                          ],
                                        )
                                      else
                                        Text(
                                          "No attendance recorded for today.",
                                          style: TextStyle(fontSize: 17, color: Colors.red[800]),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Calendar
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 8,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TableCalendar(
                          firstDay: DateTime.now().subtract(const Duration(days: 90)),
                          lastDay: DateTime.now().add(const Duration(days: 30)),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                          onDaySelected: _onDaySelected,
                          onPageChanged: _onPageChanged,
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: Color(0xFF021526)),
                            leftChevronIcon: const Icon(Icons.chevron_left, color: Color(0xFF021526), size: 30),
                            rightChevronIcon: const Icon(Icons.chevron_right, color: Color(0xFF021526), size: 30),
                          ),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.8),
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            weekendTextStyle: TextStyle(color: Colors.red[700]),
                            outsideDaysVisible: false,
                            defaultTextStyle: const TextStyle(color: Color(0xFF021526)),
                            isTodayHighlighted: true,
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder: (context, day, focusedDay) {
                              final record = _attendanceMap[DateTime(day.year, day.month, day.day)];
                              if (record != null) {
                                Color color;

                                if (record.status == AttendanceStatus.absent) {
                                  color = Colors.red.shade400;
                                } else if (_hasRecordedAttendance(record.status)) {
                                  color = Colors.green.shade400;
                                } else {
                                  return null;
                                }

                                return Container(
                                  margin: const EdgeInsets.all(4.0),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: color.withOpacity(0.4),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  ),
                                  child: Text(
                                    '${day.day}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),

                    // Monthly Summary
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Text(
                        "Monthly Attendance Summary (${DateFormat('MMMM yyyy').format(_focusedDay)}):",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF021526)),
                      ),
                    ),
                  Wrap(
  spacing: 16.0, // horizontal space between cards
  runSpacing: 16.0, // vertical space between rows
  children: [
    _buildSummaryCard("Present", _presentDaysInMonth, const Color.fromARGB(255, 27, 105, 30), Icons.check_circle_outline),
    _buildSummaryCard("Late", _lateDaysInMonth, Colors.orange, Icons.access_time_outlined),
    _buildSummaryCard("Absent", _absentDaysInMonth, Colors.red, Icons.highlight_off),
    _buildSummaryCard("Half Day", _halfDaysInMonth, Colors.purple, Icons.adjust),
    _buildSummaryCard("Holiday", _holidayDaysInMonth, Colors.blue, Icons.beach_access),
  ].map((card) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width / 2) - 24, // for 2 items per row with padding
      child: card,
    );
  }).toList(),
),


                    // Attendance on Selected Date
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        "Attendance on ${DateFormat('yyyy-MM-dd').format(_selectedDay)}:",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF021526)),
                      ),
                    ),
                    _filteredHistory.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text("No attendance records for this date.", style: TextStyle(fontSize: 17, color: Colors.grey[700])),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _filteredHistory.length,
                            itemBuilder: (context, index) {
                              final record = _filteredHistory[index];
                              return SlideTransition(
                                position: _cardSlideAnimation,
                                child: FadeTransition(
                                  opacity: _cardFadeAnimation,
                                  child: Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(_getStatusIcon(record.status), color: _getStatusColor(record.status), size: 28),
                                              const SizedBox(width: 12),
                                              Text(
                                                record.status.toString().split('.').last.replaceAll('_', ' '),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                  color: _getStatusColor(record.status),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(height: 20, thickness: 1),
                                          if (record.inTime != null && record.inTime!.isNotEmpty) _buildDetailRow(Icons.login, "In Time:", record.inTime!),
                                          if (record.outTime != null && record.outTime!.isNotEmpty) _buildDetailRow(Icons.logout, "Out Time:", record.outTime!),
                                          if (record.location != null && record.location!.isNotEmpty) _buildDetailRow(Icons.location_on, "Location:", record.location!),
                                          if (record.remark != null && record.remark!.isNotEmpty) _buildDetailRow(Icons.info_outline, "Remark:", record.remark!),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    // Adding a final SizedBox for extra scroll space, preventing overflow on the last elements
                    const SizedBox(height: 55), // Matches the overflow amount, or slightly more
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: "$label ",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17, color: Color(0xFF021526)),
                  ),
                  TextSpan(
                    text: value,
                    style: const TextStyle(fontSize: 17, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, Color color, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color.withOpacity(0.15),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center, // Center content vertically within the card
          children: [
            Row(
              children: [
                Icon(icon, size: 36, color: color),
                const SizedBox(width: 12),
                Expanded( // Use Expanded to ensure text wraps if long, though 'title' is short
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF021526),
                    ),
                    overflow: TextOverflow.ellipsis, // Prevent overflow if title is unexpectedly long
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color.darken(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

extension ColorExtension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}