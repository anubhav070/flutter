import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AttendanceRecord {
  final String date;
  final String createdAt;
  final String staffId;
  final String staffAttendanceTypeId;
  final String location;
  final String? inTime;
  final String? outTime;
  final String? status;
  final String? remark;

  AttendanceRecord({
    required this.date,
    required this.createdAt,
    required this.staffId,
    required this.staffAttendanceTypeId,
    required this.location,
    this.inTime,
    this.outTime,
    this.status,
    this.remark,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      date: json['date'] ?? 'No Date',
      createdAt: json['created_at'] ?? 'No Created At',
      staffId: json['staff_id'] ?? 'No Staff ID',
      staffAttendanceTypeId: json['staff_attendance_type_id'] ?? 'No Type ID',
      location: json['location'] ?? 'No Location',
      inTime: json['In_Time'],
      outTime: json['Out_Time'],
      status: (json['status'] ?? 'Absent').isEmpty ? 'Absent' : json['status'],
      remark: json['remark'],
    );
  }
}


class AttendanceHistoryPage extends StatefulWidget {
  final DateTime selectedDate;

  AttendanceHistoryPage({required this.selectedDate});

  @override
  _AttendanceHistoryPageState createState() => _AttendanceHistoryPageState();
}

class _AttendanceHistoryPageState extends State<AttendanceHistoryPage> {
  List<dynamic> _attendanceHistory = []; // Initialize as empty list

  final TextStyle _textStyle = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w400,
  );

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory(); // Fetch attendance history when the page is initialized
  }

  Future<dynamic?> _fetchUserId() async {
    try {
      // Fetch the username from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('username');

      if (username == null) {
        Fluttertoast.showToast(
          msg: "Username not found. Please log in again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return null;
      }
       SharedPreferences pref = await SharedPreferences.getInstance();
      String? baseUrl = pref.getString('baseUrl');

      // URL of your PHP script that fetches user ID based on the username
      String apiUrl = '$baseUrl/fetch_id.php';

      final request = http.Request('POST', Uri.parse(apiUrl))
        ..headers[HttpHeaders.contentTypeHeader] = 'application/json'
        ..body = jsonEncode({
          'username': username,
        });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        Fluttertoast.showToast(
          msg: "Failed to connect to the server. Please check your internet connection.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
        return null;
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "An error occurred: $e",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return null;
    }
  }

  Future<void> _fetchAttendanceHistory() async {
    final userId = await _fetchUserId();

    if (userId == null) {
      print('Failed to fetch user ID');
      return;
    }
     SharedPreferences prefs = await SharedPreferences.getInstance();
      String? baseUrl = prefs.getString('baseUrl');
    final url = '$baseUrl/get_attendance.php';

    final client = http.Client();
    final request = http.Request('POST', Uri.parse(url))
      ..headers[HttpHeaders.contentTypeHeader] = 'application/json'
      ..body = jsonEncode({
        'selectedDate':
            '${widget.selectedDate.toLocal().toIso8601String().split('T')[0]}',
        'userId': userId, // Ensure userId is included correctly
      });

    try {
      final response = await client.send(request);
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        setState(() {
          _attendanceHistory = jsonDecode(responseBody);
        });
      } else {
        throw Exception('Failed to load attendance history');
      }
    } catch (e) {
      print('Error fetching attendance history: $e');
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20.0),
          ),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.home),
              onPressed: () {
                Navigator.pop(context); // Navigate back to previous screen
              },
            ),
            automaticallyImplyLeading: false,
            title: Text("Attendance Information"),
            centerTitle: true,
            backgroundColor: Color.fromARGB(255, 65, 172, 194),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _buildAttendanceHistory(),
              ],
            ),
          ),
        ),
      ),
    );
  }
Widget _buildAttendanceHistory() {
  if (_attendanceHistory.isEmpty) {
    return Text('No attendance records found for the selected date.');
  }

  return Container(
    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    padding: EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10.0),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.5),
          spreadRadius: 2,
          blurRadius: 5,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _attendanceHistory.map((record) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  record['date'] ?? 'No date',
                  style: _textStyle,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  record['status'] ?? 'No status',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w400,
                    color: record['status'] == 'Present'
                        ? Colors.green
                        : record['status'] == 'On Site'
                            ? Colors.red
                            : Colors.orange,
                  ),
                ),
              ),
              Text(
                record['in time'] ?? 'No check-in time',
                style: _textStyle,
              ),
              Text(
                record['remark'] ?? 'No remarks',
                style: _textStyle,
              ),
              Text(
                record['out time'] ?? 'No check-out time',
                style: _textStyle,
              ),
              Divider(),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
}
