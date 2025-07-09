
import 'dart:async';
import 'dart:convert';
import 'dart:io'; // Needed for HttpHeaders
import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/login_screen.dart';
import 'package:attendance_geetai/screen/dashboard.dart';
import 'package:attendance_geetai/screen2/logoutScreen.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
// Placeholder for your LoginPage and HistoryPage


enum Status {
  present,
  late,
  halfDay,
  absent,
  Holiday,
  onSite,
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay currentTime = TimeOfDay.now();
  String currentLocation = "Location not available";
  bool _isLocationFetching = false;
  Status _status = Status.present;
  final Map<Status, int> statusToTypeId = {
    Status.present: 1,
    Status.late: 2,
    Status.absent: 3,
    Status.halfDay: 4,
    Status.Holiday: 5,
  };
  final Map<int, Status> typeIdToStatus = {
    1: Status.present,
    2: Status.late,
    3: Status.halfDay,
    4: Status.absent,
    7: Status.onSite,
  };
  TextEditingController _remarkController = TextEditingController();
  bool isInDisabled = false;
  bool isOutDisabled = true;
  bool isStatusDisabled = true;
  bool isRemarkDisabled = true;
  bool isSubmitDisabled = true;
  bool isAttendanceFullySubmitted = false;
  String? _staffId;
  String? _checkInTimeForDay;
  String? _checkInLocationForDay;
  final TextStyle _textStyle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
  );
  List<Status> _selectableInStatus = [
    Status.present,
    Status.late,
    Status.halfDay,
    Status.onSite,
  ];
  bool _checkInExistsInDb = false;

  @override
  void initState() {
    super.initState();
    _loadStaffId();
    _getCurrentLocation();
    _loadSavedState();

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          currentTime = TimeOfDay.now();
        });
      }
    });
  }

Future<void> requestLocationPermissions() async {
  var status = await Permission.location.request();
  if (status.isGranted) {
    // Permission granted
  } else if (status.isDenied) {
    // Handle denial
  }
}
  Future<void> _loadStaffId() async {
    // ... (rest of your _loadStaffId method)
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
      });
      print("✅ Loaded Staff ID for Staff Attendance: $_staffId");

      _checkDailyAttendanceStatus();
    }
  }

  Future<void> _checkDailyAttendanceStatus() async {
    // ... (rest of your _checkDailyAttendanceStatus method)
    if (_staffId == null) return;

    String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String apiUrl = 'https://erp.vpsedu.org/appapi/attendance/attendanceget.php';
    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode({
          'action': 'get_daily_status',
          'date': todayDate,
        }),
        headers: {"Content-Type": "application/json"},
      );

      print("Daily Status API Response Status: ${response.statusCode}");
      print("Daily Status API Response Body: ${response.body}");

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          var attendanceData = responseData['data'];
          String? inTime = attendanceData['in_time'];
          String? outTime = attendanceData['out_time'];
          String? location = attendanceData['location'];
          String? remarks = attendanceData['remark'];
          int? statusTypeId =
              int.tryParse(attendanceData['staff_attendance_type_id'].toString());

          setState(() {
            _checkInTimeForDay = inTime;
            _checkInLocationForDay = location;
            _remarkController.text = remarks ?? '';

            if (statusTypeId != null && typeIdToStatus.containsKey(statusTypeId)) {
              _status = typeIdToStatus[statusTypeId]!;
            } else {
              _status = Status.present;
            }

            if (inTime != null && inTime.isNotEmpty) {
              isInDisabled = true;
              isOutDisabled = false;
              isStatusDisabled = false;
              isRemarkDisabled = false;
              isSubmitDisabled = true;
              _checkInExistsInDb = true; // Set to true if in_time is found in DB

              // Show a toast message if check-in is already in DB
              Fluttertoast.showToast(
                msg: "Check-in data already exists for today.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );

              if (outTime != null && outTime.isNotEmpty) {
                isOutDisabled = true;
                isSubmitDisabled = true;
                isStatusDisabled = true;
                isRemarkDisabled = true;
                isAttendanceFullySubmitted = true;
                Fluttertoast.showToast(
                  msg: "Today's attendance is already submitted.",
                  toastLength: Toast.LENGTH_LONG,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: Colors.blueAccent,
                  textColor: Colors.white,
                );
              }
            } else {
              isInDisabled = false;
              isOutDisabled = true;
              isStatusDisabled = true;
              isRemarkDisabled = true;
              isSubmitDisabled = true;
              isAttendanceFullySubmitted = false;
              _checkInExistsInDb = false; // Reset to false
            }
          });
        } else {
          setState(() {
            isInDisabled = false;
            isOutDisabled = true;
            isStatusDisabled = true;
            isRemarkDisabled = true;
            isSubmitDisabled = true;
            isAttendanceFullySubmitted = false;
            _checkInTimeForDay = null;
            _checkInLocationForDay = null;
            _remarkController.clear();
            _status = Status.present;
            _checkInExistsInDb = false; // Reset to false
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: "Failed to fetch daily attendance status.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          isInDisabled = false;
          isOutDisabled = true;
          isStatusDisabled = true;
          isRemarkDisabled = true;
          isSubmitDisabled = true;
          isAttendanceFullySubmitted = false;
          _checkInExistsInDb = false; // Reset to false on error
        });
      }
    } catch (e) {
      print("Error fetching daily attendance status: $e");
      Fluttertoast.showToast(
        msg: "Error connecting to fetch daily status.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        isInDisabled = false;
        isOutDisabled = true;
        isStatusDisabled = true;
        isRemarkDisabled = true;
        isSubmitDisabled = true;
        isAttendanceFullySubmitted = false;
        _checkInExistsInDb = false; // Reset to false on error
      });
    }
  }

  Future<void> _loadSavedState() async {
    // ... (rest of your _loadSavedState method)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    String? checkInTimeStr = prefs.getString('check_in_time_for_$todayKey');
    String? checkInLocationStr = prefs.getString('location_for_$todayKey');
    String? savedStatusStr = prefs.getString('status_type_id_for_$todayKey');
    String? savedRemarks = prefs.getString('remarks_for_$todayKey');
    bool? isFullySubmittedLocally = prefs.getBool('is_fully_submitted_for_$todayKey');

    setState(() {
      if (checkInTimeStr != null) {
        _checkInTimeForDay = checkInTimeStr;
        _checkInLocationForDay = checkInLocationStr;
        isInDisabled = true; // ✅ Disable Check-In
        isOutDisabled = false;
        isStatusDisabled = false;
        isRemarkDisabled = false;
        isSubmitDisabled = true;

        if (isFullySubmittedLocally == true) {
          isOutDisabled = true;
          isSubmitDisabled = true;
          isStatusDisabled = true;
          isRemarkDisabled = true;
          isAttendanceFullySubmitted = true;
        }

        // ✅ Show Toast or message
        Fluttertoast.showToast(
          msg: "Check-In already submitted for today.",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        isInDisabled = false;
        isOutDisabled = true;
        isStatusDisabled = true;
        isRemarkDisabled = true;
        isSubmitDisabled = true;
        isAttendanceFullySubmitted = false;
      }

      // Set saved status
      if (savedStatusStr != null) {
        int? savedStatusTypeId = int.tryParse(savedStatusStr);
        if (savedStatusTypeId != null && typeIdToStatus.containsKey(savedStatusTypeId)) {
          _status = typeIdToStatus[savedStatusTypeId]!;
        }
      }

      if (savedRemarks != null) {
        _remarkController.text = savedRemarks;
      }

      if (_checkInLocationForDay != null && _checkInLocationForDay!.isNotEmpty) {
        currentLocation = _checkInLocationForDay!;
      } else {
        if (!isInDisabled && !_isLocationFetching) {
          _getCurrentLocation();
        }
      }
    });
  }

  Future<void> _getCurrentLocation() async {
  setState(() {
    _isLocationFetching = true;
    currentLocation = "Fetching location...";
  });

  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      currentLocation = "Location services disabled.";
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      currentLocation = "Location permissions denied.";
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];

    setState(() {
      currentLocation = "${place.name}, ${place.locality}, ${place.country}";
    });
  } catch (e) {
    print("❌ Location error: $e");
    setState(() {
      currentLocation = "Unable to get location.";
    });
  } finally {
    setState(() {
      _isLocationFetching = false;
    });
  }
}

  void _handleStatusChange(Status? newStatus) {
    setState(() {
      if (newStatus != null) {
        _status = newStatus;
        String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString(
              'status_type_id_for_$todayKey', statusToTypeId[newStatus].toString());
        });
      }
    });
  }

  Future<void> _handleCheckIn() async {
    // ... (rest of your _handleCheckIn method)
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if (_staffId == null || _staffId!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Staff ID not available. Cannot Check-In. Please re-login.",
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
      return;
    }

    if (currentLocation.isEmpty ||
        currentLocation == "Fetching location..." ||
        currentLocation.contains("Location services disabled") ||
        currentLocation.contains("Location permissions denied") ||
        currentLocation.contains("Unable to get location")) {
      Fluttertoast.showToast(
        msg:
            "Location is not precise or unavailable. Checking in without a precise location. Please ensure location is enabled.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
    }

    _getCurrentLocation();

    DateTime now = DateTime.now();
    _checkInTimeForDay = DateFormat('HH:mm:ss').format(now);
    _checkInLocationForDay = currentLocation;

    int? selectedTypeId = statusToTypeId[_status];
    if (selectedTypeId == null) {
      Fluttertoast.showToast(
        msg: "Invalid attendance status selected.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    Map<String, dynamic> checkInData = {
      'action': 'in',
      'staff_id': _staffId,
      'date': DateFormat('yyyy-MM-dd').format(now),
      'in_time': _checkInTimeForDay,
      'location': _checkInLocationForDay, // Sent even if it's a placeholder
      'remark': _remarkController.text,
      'status': _status.toString().split('.').last,
      'staff_attendance_type_id': selectedTypeId,
      'biometric_attendence': 0,
      'is_active': 1,
    };

    String checkInApiUrl = 'https://erp.vpsedu.org/appapi/attendance/attendanceget.php';

    try {
      var response = await http.post(
        Uri.parse(checkInApiUrl),
        body: jsonEncode(checkInData),
        headers: {"Content-Type": "application/json"},
      );

      print("Check-In API Response Status: ${response.statusCode}");
      print("Check-In API Response Body: ${response.body}");

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["status"] == true) {
        Fluttertoast.showToast(
          msg: responseData["message"] ?? "Check-In successful!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        await prefs.setString('check_in_time_for_$todayKey', _checkInTimeForDay!);

        if (_checkInLocationForDay != null &&
            !(_checkInLocationForDay!.contains("Location services disabled") ||
                _checkInLocationForDay!.contains("Location permissions denied") ||
                _checkInLocationForDay!.contains("Unable to get location") ||
                _checkInLocationForDay! == "Fetching location...")) {
          await prefs.setString('location_for_$todayKey', _checkInLocationForDay!);
        } else {
          await prefs.remove('location_for_$todayKey'); // Clear invalid location
        }

        await prefs.setString('status_type_id_for_$todayKey', selectedTypeId.toString());
        await prefs.setString('remarks_for_$todayKey', _remarkController.text);
        await prefs.setBool('is_fully_submitted_for_$todayKey', false); // Mark as not fully submitted yet

        setState(() {
          isInDisabled = true;
          isOutDisabled = false;
          isStatusDisabled = false;
          isRemarkDisabled = false;
          isSubmitDisabled = true;
          isAttendanceFullySubmitted = false;
          _checkInExistsInDb = true; // Set this to true on successful check-in
        });
      } else {
        await prefs.remove('check_in_time_for_$todayKey');
        await prefs.remove('location_for_$todayKey');
        await prefs.remove('status_type_id_for_$todayKey');
        await prefs.remove('remarks_for_$todayKey');
        await prefs.remove('is_fully_submitted_for_$todayKey');
        _checkInTimeForDay = null;
        _checkInLocationForDay = null;

        Fluttertoast.showToast(
          msg: responseData["message"] ?? "Check-In failed. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          isInDisabled = false;
          isOutDisabled = true;
          isStatusDisabled = true;
          isRemarkDisabled = true;
          isSubmitDisabled = true;
          isAttendanceFullySubmitted = false;
          currentLocation = "Location not available"; // Reset location display
          _getCurrentLocation(); // Attempt to get location again
          _checkInExistsInDb = false; // Reset on failed check-in
        });
      }
    } catch (e) {
      print("Check-In API Exception: $e");
      await prefs.remove('check_in_time_for_$todayKey');
      await prefs.remove('location_for_$todayKey');
      await prefs.remove('status_type_id_for_$todayKey');
      await prefs.remove('remarks_for_$todayKey');
      await prefs.remove('is_fully_submitted_for_$todayKey');
      _checkInTimeForDay = null;
      _checkInLocationForDay = null;
      Fluttertoast.showToast(
        msg: "Failed to connect for Check-In. Check internet.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      setState(() {
        isInDisabled = false;
        isOutDisabled = true;
        isStatusDisabled = true;
        isRemarkDisabled = true;
        isSubmitDisabled = true;
        isAttendanceFullySubmitted = false;
        currentLocation = "Location not available"; // Reset location display
        _getCurrentLocation(); // Attempt to get location again
        _checkInExistsInDb = false; // Reset on error
      });
    }
  }

  void _handleCheckOut() async {
    // **MODIFICATION START**
    if (_remarkController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter remarks before checking out.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return; // Stop the checkout process if remarks are empty
    }
    // **MODIFICATION END**

    if (!isAttendanceFullySubmitted && !isOutDisabled) {
      await _getCurrentLocation(); // Attempt to get the latest location
      setState(() {
        isOutDisabled = true;
        isSubmitDisabled = false;
        isRemarkDisabled = false;
        isStatusDisabled = false; // Status can be changed before final submit
      });
      Fluttertoast.showToast(
        msg: "Check-Out process initiated. Please confirm remarks/status and Submit.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleSubmit() async {
    // ... (rest of your _handleSubmit method)
    String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (_remarkController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter remarks before submitting.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_staffId == null || _staffId!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Staff ID not available. Please re-login.",
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
      return;
    }

    String? storedCheckInTime = prefs.getString('check_in_time_for_$todayKey');
    String? storedCheckInLocation =
        prefs.getString('location_for_$todayKey'); // Can be null if not saved
    int? storedAttendanceTypeId =
        int.tryParse(prefs.getString('status_type_id_for_$todayKey') ?? '');

    if (storedCheckInTime == null) {
      Fluttertoast.showToast(
        msg: "No Check-In time recorded for today. Please Check-In first.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    DateTime now = DateTime.now();
    String outTime = DateFormat('HH:mm:ss').format(now);

    await _getCurrentLocation(); // Refresh current location one last time

    int? selectedTypeId = statusToTypeId[_status];
    if (selectedTypeId == null) {
      Fluttertoast.showToast(
        msg: "Invalid attendance status selected.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    Map<String, dynamic> submitData = {
      'action': 'out', // Explicitly 'out' action for PHP backend
      'staff_id': _staffId,
      'date': DateFormat('yyyy-MM-dd').format(now),
      'in_time': storedCheckInTime,
      'out_time': outTime,
      'location': storedCheckInLocation ?? 'N/A', // Use stored check-in location, or 'N/A' if null
      'out_location': currentLocation, // Use the latest captured location, even if imperfect
      'remark': _remarkController.text,
      'status': _status.toString().split('.').last,
      'staff_attendance_type_id': selectedTypeId,
      'biometric_attendence': 0,
      'is_active': 1,
    };

    String submitApiUrl = 'https://erp.vpsedu.org/appapi/attendance/attendanceget.php';

    try {
      var response = await http.post(
        Uri.parse(submitApiUrl),
        body: jsonEncode(submitData),
        headers: {"Content-Type": "application/json"},
      );

      print("Submit API Response Status: ${response.statusCode}");
      print("Submit API Response Body: ${response.body}");

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["status"] == true) {
        Fluttertoast.showToast(
          msg: responseData["message"] ?? "Attendance submitted successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Clear all daily saved data upon successful submission
        await prefs.remove('check_in_time_for_$todayKey');
        await prefs.remove('location_for_$todayKey');
        await prefs.remove('status_type_id_for_$todayKey');
        await prefs.remove('remarks_for_$todayKey');
        await prefs.setBool('is_fully_submitted_for_$todayKey', true); // Mark as fully submitted

        setState(() {
          isInDisabled = true;
          isOutDisabled = true; // Disable OUT button after submission
          isStatusDisabled = true; // Disable status dropdown after submission
          isRemarkDisabled = true; // Disable remarks after submission
          isSubmitDisabled = true; // Disable submit button after submission
          isAttendanceFullySubmitted = true; // Set flag
          _checkInTimeForDay = null; // Clear display
          _checkInLocationForDay = null; // Clear display
          _remarkController.clear();
          currentLocation = "Location not available"; // Reset location display
          _getCurrentLocation(); // Attempt to get location for next day/fresh state
          _checkInExistsInDb = false; // Reset after full submission
        });
      } else {
        Fluttertoast.showToast(
          msg: responseData["message"] ?? "Submission failed. Please try again.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print("Submit API Exception: $e");
      Fluttertoast.showToast(
        msg: "Failed to connect for Submission. Check internet.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (rest of your build method)
    return Scaffold(
     appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
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
            title: Text("Attendace", style: TextStyle(color: const Color.fromARGB(174, 255, 255, 255))),
            centerTitle: true,
            backgroundColor: Color(0xFF021526),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: () =>  LogoutConfirmation.show(context),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(
          children: [
            if (_checkInTimeForDay != null)
              Container(
                padding: EdgeInsets.all(12),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red.shade900),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "You have already checked in today. Check-in is saved in the database.",
                        style: TextStyle(
                          color: Colors.red.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow("📅 Date", DateFormat('yyyy-MM-dd').format(selectedDate)),
                    _buildInfoRow("⏰ Current Time", currentTime.format(context)),
                    Divider(),
                    _buildInfoRow(
                      "📍 Current Location",
                      _isLocationFetching ? "Fetching location..." : currentLocation,
                      color: (_isLocationFetching ||
                              currentLocation.contains("denied") ||
                              currentLocation.contains("disabled") ||
                              currentLocation == "Location not available")
                          ? Colors.orange
                          : Colors.green.shade700,
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: (isAttendanceFullySubmitted || isInDisabled)
                    ? null
                    : _handleCheckIn,
                icon: Icon(Icons.login),
                label: Text("Check-In"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 35, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),

            SizedBox(height: 25),

            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📝 Status", style: _textStyle.copyWith(fontSize: 16)),
                    SizedBox(height: 10),
                    DropdownButton<Status>(
                      value: _status,
                      onChanged: isStatusDisabled ? null : _handleStatusChange,
                      items: _selectableInStatus.map((Status status) {
                        return DropdownMenuItem<Status>(
                          value: status,
                          child: Text(
                            _getStatusString(status),
                            style: TextStyle(
                              color: isStatusDisabled ? Colors.grey : Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                      isExpanded: true,
                      style: _textStyle,
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: _remarkController,
                      decoration: InputDecoration(
                        labelText: "Remarks",
                        hintText: "Enter remarks for attendance",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabled: !isRemarkDisabled,
                      ),
                      enabled: !isRemarkDisabled,
                      onChanged: (text) async {
                        String todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
                        SharedPreferences prefs = await SharedPreferences.getInstance();
                        prefs.setString('remarks_for_$todayKey', text);
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 25),

            Center(
              child: ElevatedButton.icon(
                onPressed: isAttendanceFullySubmitted || isOutDisabled
                    ? null
                    : _handleCheckOut, // Calls the modified _handleCheckOut
                icon: Icon(Icons.logout),
                label: Text("Check-Out"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 35, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),

            SizedBox(height: 20),

            Center(
              child: ElevatedButton.icon(
                onPressed: isAttendanceFullySubmitted || isSubmitDisabled
                    ? null
                    : _handleSubmit,
                icon: Icon(Icons.send),
                label: Text("Submit Attendance"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade400,
                  padding: EdgeInsets.symmetric(horizontal: 35, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 4,
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ),

            SizedBox(height: 20),

            // ... (rest of your build method, assuming _buildInfoRow and _getStatusString are defined elsewhere)
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title + ": ",
            style: _textStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: _textStyle.copyWith(color: color ?? Colors.black),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusString(Status status) {
    switch (status) {
      case Status.present:
        return "Present";
      case Status.late:
        return "Late";
      case Status.halfDay:
        return "Half Day";
      case Status.absent:
        return "Absent";
      case Status.Holiday:
        return "Holiday";
      case Status.onSite:
        return "On Site";
      default:
        return "Unknown";
    }
  }
}
