import 'dart:convert';
import 'dart:io'; // Import for HttpHeaders
import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/login_screen.dart';
import 'package:attendance_geetai/screen/dashboard.dart';
// Assuming VisitHistoryPage is here
import 'package:attendance_geetai/screen2/visitehistroy.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum Status {
  Samajkalyan_Office,
  Other_Government_Office,
  Student_Home_Visit,
  absent,
  Collector_Office,
}

class Visitattendance extends StatefulWidget {
  @override
  _VisitattendanceState createState() => _VisitattendanceState();
}

class _VisitattendanceState extends State<Visitattendance> {
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now(); // Still kept, but its usage in API might be redundant
  String currentLocation = "";
  Status _status = Status.absent; // Initial status set to absent
  TextEditingController _remarkController = TextEditingController();

  bool isInDisabled = false;
  bool isOutDisabled = true;
  bool isStatusDisabled = true;
  bool isRemarkDisabled = true;
  bool isSubmitDisabled = true;

  String? _staffId; // Variable to store the staff ID from SharedPreferences

  final TextStyle _textStyle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
  );

  @override
  void initState() {
    super.initState();
    _loadStaffId(); // Load staff ID at initialization
    _getCurrentLocation();
    _loadSavedState();
  }

  // --- NEW FUNCTION TO LOAD STAFF ID ---
  Future<void> _loadStaffId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('id'); // Get the 'id' saved during login

    if (id == null || id.isEmpty) {
      // If ID is not found, it means the user is not logged in or session expired
      Fluttertoast.showToast(
        msg: "Session expired. Please login again.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM, // Corrected here
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
      print("✅ Loaded Staff ID for Visit: $_staffId"); // For debugging
    }
  }

  Future<void> _loadSavedState() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      // Load saved check-in time
      String? checkInTimeStr = prefs.getString('check_in_time1');
      if (checkInTimeStr != null) {
        isInDisabled = true;
        isOutDisabled = false;
        isStatusDisabled = false;
        isRemarkDisabled = false;
        // isSubmitDisabled is controlled by _handleCheckOut, keep it as true initially
      }

      // Load saved status
      String? savedStatus = prefs.getString('status');
      if (savedStatus != null) {
        _status = Status.values.firstWhere(
          (e) => e.toString() == savedStatus,
          orElse: () => Status.absent,
        );
      }

      // Load saved remarks
      String? savedRemarks = prefs.getString('remarks');
      if (savedRemarks != null) {
        _remarkController.text = savedRemarks;
      }

      // Load saved location
      String? savedLocation = prefs.getString('current_location');
      if (savedLocation != null) {
        currentLocation = savedLocation;
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentLocation = "Location services are disabled.";
      });
      Fluttertoast.showToast(msg: "Location services are disabled. Please enable them.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          currentLocation = "Location permissions are denied.";
        });
        Fluttertoast.showToast(msg: "Location permissions are denied.");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentLocation = "Location permissions are permanently denied.";
      });
      Fluttertoast.showToast(msg: "Location permissions are permanently denied.");
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _getAddressFromLatLng(position);
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks[0];

      setState(() {
        currentLocation = "${place.name}, ${place.locality}, ${place.country}";
      });
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('current_location', currentLocation);
      });
    } catch (e) {
      setState(() {
        currentLocation = "Unable to get location.";
      });
      Fluttertoast.showToast(msg: "Unable to get current address.");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  void _handleStatusChange(Status? newStatus) {
    setState(() {
      if (newStatus != null) {
        _status = newStatus;
        // Save status to SharedPreferences
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString('status', newStatus.toString());
        });
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_remarkController.text.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please enter remarks before submitting.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // Corrected here
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    if (_staffId == null || _staffId!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Staff ID not available. Please re-login.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM, // Corrected here
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      // Navigate to login page
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
      return;
    }

    String statusText;
    switch (_status) {
      case Status.Samajkalyan_Office:
        statusText = 'Samajkalyan_Office';
        break;
      case Status.Other_Government_Office:
        statusText = 'Other_Government_Office';
        break;
      case Status.Student_Home_Visit:
        statusText = 'Student_Home_Visit';
        break;
      case Status.absent:
        statusText = 'Absent';
        break;
      case Status.Collector_Office:
        statusText = 'Collector_Office';
        break;
      default:
        statusText = 'Unknown';
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? checkInTimeStr = prefs.getString('check_in_time1');
    DateTime? checkInTime = checkInTimeStr != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').parse(checkInTimeStr)
        : null;

    if (checkInTime == null) {
      Fluttertoast.showToast(
        msg: "Check-in time not found. Please check in first.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // Corrected here
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    final now = DateTime.now();
    // No need for checkOutTimeStr if we are sending the DateTime object to format directly
    // final checkOutTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);

    Map<String, dynamic> data = {
      'staff_id': _staffId,
      'date': DateFormat('yyyy-MM-dd').format(selectedDate),
      'location': currentLocation,
      'status': statusText,
      'remark': _remarkController.text,
      'in_time': DateFormat('HH:mm:ss').format(checkInTime),
      'out_time': DateFormat('HH:mm:ss').format(now),
      'flutter_selected_time': selectedTime.format(context), // If you still want to send it
    };

    String apiUrl = 'https://erp.vpsedu.org/appapi/attendance/visiteattendance.php';

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: jsonEncode(data),
        headers: {"Content-Type": "application/json"},
      );

      print("Visit Submit API Response: ${response.statusCode}");
      print("Visit Submit API Body: ${response.body}");

      var responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData["status"] == true) {
        Fluttertoast.showToast(
          msg: responseData["message"] ?? "Visit details submitted successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Corrected here
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Clear shared preferences and reset state AFTER successful submission
        prefs.remove('check_in_time1');
        prefs.remove('status');
        prefs.remove('remarks');
        prefs.remove('current_location');

        setState(() {
          isInDisabled = false;
          isOutDisabled = true;
          isStatusDisabled = true;
          isRemarkDisabled = true;
          isSubmitDisabled = true;
          _status = Status.absent;
          _remarkController.clear();
          currentLocation = "";
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VisitAttendanceHistory1Page(),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: responseData["message"] ?? "Failed to submit visit. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM, // Corrected here
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      print("Visit Submit Exception: $e");
      Fluttertoast.showToast(
        msg: "Failed to connect to the server. Please check your internet connection.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // Corrected here
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> _handleCheckIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Ensure staffId is loaded before checking in
    if (_staffId == null || _staffId!.isEmpty) {
      Fluttertoast.showToast(
        msg: "Staff ID not available. Cannot Check-In. Please re-login.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM, // Corrected here
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
    currentLocation == "Location services are disabled." ||
    currentLocation == "Location permissions are denied." ||
    currentLocation == "Location permissions are permanently denied." ||
    currentLocation == "Unable to get location.") {
  Fluttertoast.showToast(
    msg: "Location not found. Continuing without location.",
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.orange,
    textColor: Colors.white,
  );
  currentLocation = "Not Available"; // default fallback
}


    DateTime now = DateTime.now();
    String checkInTimeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
    await prefs.setString('check_in_time1', checkInTimeStr);
    await prefs.setString('current_location', currentLocation); // Save current location on check-in

    setState(() {
      isInDisabled = true;
      isOutDisabled = false;
      isStatusDisabled = false;
      isRemarkDisabled = false;
      isSubmitDisabled = true; // Submit button should be enabled only after checkout
    });

    Fluttertoast.showToast(
      msg: "Check-In successful at ${DateFormat('HH:mm').format(now)}.",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM, // Corrected here
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _handleCheckOut() async {
    if (!isOutDisabled) {
      setState(() {
        isOutDisabled = true;
        isSubmitDisabled = false;
      });
      Fluttertoast.showToast(
        msg: "Check-Out captured. Please submit the form.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM, // Corrected here
        backgroundColor: Colors.blue,
        textColor: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20.0),
          ),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DashboardScreen()),
                );
              },
            ),
            automaticallyImplyLeading: false,
            title:
                Text("Mark the Visit", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Color(0xFF021526),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: () => _showLogoutDialog(),
              ),
            ],
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
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Date: ${DateFormat('yyyy-MM-dd').format(selectedDate)}",
                      style: _textStyle,
                    ),
                    Text(
                      "Time: ${selectedTime.format(context)}",
                      style: _textStyle,
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isInDisabled
                              ? Color.fromARGB(255, 216, 25, 7) // Disabled color
                              : Color(0xFF03346E), // Enabled color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Rounded corners
                          ),
                          shadowColor:
                              Colors.black.withOpacity(0.4), // Shadow color
                          elevation: 8, // Elevation for shadow effect
                          padding:
                              EdgeInsets.all(10), // Padding inside the button
                        ),
                        onPressed: isInDisabled ? null : _handleCheckIn,
                        child: Text(
                          'In',
                          style: _textStyle.copyWith(
                            color: isInDisabled
                                ? Colors.grey
                                : Colors.white, // Text color
                            fontSize: 18.0, // Font size
                            fontWeight: FontWeight.bold, // Bold text
                            letterSpacing: 1.5, // Letter spacing
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 30.0),
                // Display Current Location
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Location: $currentLocation",
                        style: _textStyle,
                        overflow: TextOverflow.ellipsis, // Handle long text
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.0), // Added spacing
                Text("Visit To:", style: _textStyle),
                SizedBox(height: 20.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4.0),
                        child: GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 1, // Number of items per row
                          childAspectRatio: 10.0, // Adjust this to fit content nicely
                          children: <Widget>[
                            RadioListTile<Status>(
                              title:
                                  Text('Samajkalyan Office', style: _textStyle),
                              value: Status.Samajkalyan_Office,
                              groupValue: _status,
                              onChanged:
                                  isStatusDisabled ? null : _handleStatusChange,
                            ),
                            RadioListTile<Status>(
                              title:
                                  Text('Collector Office', style: _textStyle),
                              value: Status.Collector_Office,
                              groupValue: _status,
                              onChanged:
                                  isStatusDisabled ? null : _handleStatusChange,
                            ),
                            RadioListTile<Status>(
                              title: Text('Other Government Office',
                                  style: _textStyle),
                              value: Status.Other_Government_Office,
                              groupValue: _status,
                              onChanged:
                                  isStatusDisabled ? null : _handleStatusChange,
                            ),
                            RadioListTile<Status>(
                              title:
                                  Text('Student Home Visit', style: _textStyle),
                              value: Status.Student_Home_Visit,
                              groupValue: _status,
                              onChanged:
                                  isStatusDisabled ? null : _handleStatusChange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30.0),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Remarks:',
                        style: _textStyle,
                      ),
                      SizedBox(height: 8.0),
                      TextField(
                        controller: _remarkController,
                        enabled: !isRemarkDisabled, // Enable/disable remarks based on state
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter any remarks here',
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30.0),

                Center(
                  child: SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOutDisabled
                            ? Color.fromARGB(255, 216, 25, 7) // Disabled color
                            : Color(0xFF03346E), // Enabled color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Rounded corners
                        ),
                        shadowColor:
                            Colors.black.withOpacity(0.4), // Shadow color
                        elevation: 8, // Elevation for shadow effect
                        padding:
                            EdgeInsets.all(10), // Padding inside the button
                      ),
                      onPressed: isOutDisabled ? null : _handleCheckOut, // Calls _handleCheckOut
                      child: Text(
                        'Out',
                        style: _textStyle.copyWith(
                          color: isOutDisabled
                              ? Colors.grey
                              : Colors.white, // Text color
                          fontSize: 18.0, // Font size
                          fontWeight: FontWeight.bold, // Bold text
                          letterSpacing: 1.5, // Letter spacing
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20.0), // Added spacing for submit button

                Center(
                  child: SizedBox(
                    width: 250,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSubmitDisabled
                            ? Color.fromARGB(255, 216, 25, 7) // Disabled color
                            : Colors.green.shade700, // Enabled color
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // Rounded corners
                        ),
                        shadowColor:
                            Colors.black.withOpacity(0.4), // Shadow color
                        elevation: 8, // Elevation for shadow effect
                        padding:
                            EdgeInsets.all(10), // Padding inside the button
                      ),
                      onPressed: isSubmitDisabled ? null : _handleSubmit, // Calls _handleSubmit
                      child: Text(
                        'Submit',
                        style: _textStyle.copyWith(
                          color: isSubmitDisabled
                              ? Colors.grey
                              : Colors.white, // Text color
                          fontSize: 18.0, // Font size
                          fontWeight: FontWeight.bold, // Bold text
                          letterSpacing: 1.5, // Letter spacing
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 50.0),
                Align(
                  alignment: FractionalOffset(
                      0.9, 0.9), // Adjust the alignment values as needed
                  child: FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  Visitattendance
()),
                      );
                    },
                    backgroundColor: Color(0xFF03346E),
                    child: Icon(Icons.history, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}