import 'dart:convert';
import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/login_screen.dart';
import 'package:attendance_geetai/screen2/logoutScreen.dart';
import 'package:attendance_geetai/screen2/markattendance.dart';
import 'package:attendance_geetai/screen2/visitAttenadence.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
// In lib/screen/dashboard.dart
import 'package:attendance_geetai/login_screen.dart'; // <-- One source for LoginPage
import 'package:attendance_geetai/MyBottomNavigationBar.dart'; // <-- One source for BottomNavigationBarExample
// ... other imports ...
import 'package:attendance_geetai/screen2/markattendance.dart'; // <-- This file also imports LoginPage and BottomNavigationBarExample if my previous code was directly pasted there
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _employeeId;
  String _todayAttendanceStatus = 'Loading...';
  Color _attendanceStatusColor = Colors.grey;
  final String _dashboardBgImagePath = 'assets/images/bg.png';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _employeeId = prefs.getString('id');
    });
    await _fetchTodayAttendanceStatus();
  }

  Future<void> _fetchTodayAttendanceStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? baseUrl = prefs.getString('baseUrl');
    String? staffId = prefs.getString('id');

    if (baseUrl == null || staffId == null) {
      setState(() {
        _todayAttendanceStatus = 'N/A';
        _attendanceStatusColor = Colors.grey;
      });
      return;
    }

    var url = Uri.parse("$baseUrl/attendanceget.php");
    try {
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "staff_id": int.parse(staffId),
          "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
          "action": "get_status",
        }),
      );

      print("📥 Today's Attendance API Response: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == true && data['attendance_type'] != null) {
          setState(() {
            _todayAttendanceStatus = data['attendance_type'];
            if (_todayAttendanceStatus.contains('Present')) {
              _attendanceStatusColor = Colors.green;
            } else if (_todayAttendanceStatus.contains('Half Day')) {
              _attendanceStatusColor = Colors.orange;
            } else if (_todayAttendanceStatus.contains('Absent')) {
              _attendanceStatusColor = Colors.red;
            } else {
              _attendanceStatusColor = Colors.blueGrey;
            }
          });
        } else {
          setState(() {
            _todayAttendanceStatus = data['message'] ?? 'Not Marked';
            _attendanceStatusColor = Colors.redAccent;
          });
        }
      } else {
        print("Today's Attendance API HTTP Error: ${response.statusCode}");
        setState(() {
          _todayAttendanceStatus = 'Error Fetching';
          _attendanceStatusColor = Colors.red;
        });
      }
    } catch (e) {
      print("Error fetching today's attendance: $e");
      setState(() {
        _todayAttendanceStatus = 'Error';
        _attendanceStatusColor = Colors.red;
      });
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Clear all saved data for a clean logout
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final String currentDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                
              },
            ),
            automaticallyImplyLeading: false,
            title: Text("Dashboard", style: TextStyle(color: const Color.fromARGB(174, 255, 255, 255))),
            centerTitle: true,
            backgroundColor: Color(0xFF021526),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
               onPressed: () =>  LogoutConfirmation.show(context)
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Background image with gradient
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(_dashboardBgImagePath),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     SizedBox(height: 50),
                    Text(
                      currentDate,
                      style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 245, 221, 221), fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                
                  
                  ],
                ),
              ),
            ),
          ),
SizedBox(height: 30),
          // Grid section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 236, 236, 236),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 500 ? 4 : 2,
                  mainAxisSpacing: 15.0,
                  crossAxisSpacing: 15.0,
                  childAspectRatio: 0.9,
                  children: [
                    DashboardCard(
                      icon: Icons.fingerprint,
                      label: 'Mark Attendance',
                      color: Colors.blueAccent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => MyHomePage()),
                        );
                      },
                    ),
                    DashboardCard(
                      icon: Icons.pin_drop,
                      label: 'Mark Visit',
                      color: Colors.teal,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Visitattendance()),
                        );
                      },
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
}

// Reusable Dashboard card widget
class DashboardCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? notificationCount;
  final VoidCallback? onTap;
  final Color color;

  DashboardCard({
    required this.icon,
    required this.label,
    this.notificationCount,
    this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Card(
        elevation: 5.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),
                if (notificationCount != null && notificationCount! > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$notificationCount',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 15),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
