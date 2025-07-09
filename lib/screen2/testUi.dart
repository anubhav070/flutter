import 'package:flutter/material.dart';

class TeacherLoginScreen extends StatelessWidget {
  const TeacherLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF673AB7), // Purple background
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Top Illustration
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white,
                child: Image.asset(
                  'assets/images/teacher.png', // Replace with your image
                  height: 100,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Teacher Attendance',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 30),

              // Login Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Password Field
                    TextFormField(
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Handle login
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF512DA8),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'LOG IN',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Forgot Password
                    TextButton(
                      onPressed: () {
                        // TODO: Forgot password logic
                      },
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// import 'dart:convert';
// import 'package:attendance_geetai/MyBottomNavigationBar.dart';
// import 'package:attendance_geetai/login_screen.dart';
// import 'package:attendance_geetai/screen2/markattendance.dart';
// import 'package:attendance_geetai/screen2/visitAttenadence.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart'; // Add this import for date formatting

// class DashboardScreen extends StatefulWidget {
//   @override
//   _DashboardScreenState createState() => _DashboardScreenState();
// }

// class _DashboardScreenState extends State<DashboardScreen> {
//   String _username = ''; // This might still be useful for initial load or as a fallback
//   Map<String, dynamic>? _profileData; // This will now hold data similar to UserProfile
//   final String _defaultAvatarPath = 'assets/images/user_avatar.png';

//   String _todayAttendanceStatus = 'Loading...';
//   Color _attendanceStatusColor = Colors.grey;

//   @override
//   void initState() {
//     super.initState();
//     _loadInitialData();
//   }

//   Future<void> _loadInitialData() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _username = prefs.getString('username') ?? '';
//     });
//     // Fetch profile and attendance status concurrently
//     await Future.wait([
//       _fetchUserProfile(),
//       _fetchTodayAttendanceStatus(),
//     ]);
//   }

//   // UPDATED: Using the profile.php endpoint and 'id' from shared preferences
//   Future<void> _fetchUserProfile() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? id = prefs.getString('id'); // Get 'id' from shared preferences
//     String? baseUrl = prefs.getString('baseUrl'); // Base URL for other APIs

//     if (id == null) {
//       print("Employee ID not found in SharedPreferences for profile.");
//       // Optionally set a placeholder name if ID is missing
//       setState(() {
//         _profileData = {'name': 'Guest', 'surname': '', 'profile_image_path': null};
//       });
//       return;
//     }

//     // Using the exact URL from your UserProfile.dart
//     var url = Uri.parse('https://erp.vpsedu.org/appapi/attendance/profile.php');
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({'employee_id': id}), // Send 'employee_id' as required by profile.php
//       );

//       print("📥 Dashboard Profile API Response: ${response.body}");

//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         if (data['status'] == true && data['data'] != null) {
//           setState(() {
//             _profileData = data['data'];
//             // Ensure profile_image_path is handled if it's different from ImagePath
//             // We'll use 'profile_image_path' from the new profile API
//           });
//         } else {
//           print("Dashboard Profile API Error: ${data['message'] ?? 'Unknown error'}");
//           // Fallback to username if profile data cannot be fetched
//           setState(() {
//             _profileData = {'name': _username, 'surname': '', 'profile_image_path': null};
//           });
//         }
//       } else {
//         print("Dashboard Profile API HTTP Error: ${response.statusCode}");
//         setState(() {
//           _profileData = {'name': _username, 'surname': '', 'profile_image_path': null};
//         });
//       }
//     } catch (e) {
//       print("Error fetching user profile for dashboard: $e");
//       setState(() {
//         _profileData = {'name': _username, 'surname': '', 'profile_image_path': null};
//       });
//     }
//   }

//   Future<void> _fetchTodayAttendanceStatus() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? baseUrl = prefs.getString('baseUrl');
//     String? staffId = prefs.getString('id'); // ✅ Use 'id' (which is employee_id)

//     if (baseUrl == null || staffId == null) {
//       setState(() {
//         _todayAttendanceStatus = 'N/A';
//         _attendanceStatusColor = Colors.grey;
//       });
//       return;
//     }

//     // Assuming you have an attendanceget.php or similar that can return today's status
//     // If you implemented the getTodayAttendance.php, use that here:
//     var url = Uri.parse("$baseUrl/attendanceget.php"); // Or "$baseUrl/getTodayAttendance.php"
//     try {
//       var response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode({
//           "staff_id": int.parse(staffId), // Ensure it's an integer
//           "date": DateFormat('yyyy-MM-dd').format(DateTime.now()),
//           "action": "get_status", // This action type needs to be handled on your PHP side
//         }),
//       );

//       if (response.statusCode == 200) {
//         var data = json.decode(response.body);
//         // Adjust this logic based on the actual response structure of your attendanceget.php
//         if (data['status'] == true && data['attendance_type'] != null) {
//           setState(() {
//             _todayAttendanceStatus = data['attendance_type'];
//             if (_todayAttendanceStatus.contains('Present')) {
//               _attendanceStatusColor = Colors.green;
//             } else if (_todayAttendanceStatus.contains('Half Day')) {
//               _attendanceStatusColor = Colors.orange;
//             } else if (_todayAttendanceStatus.contains('Absent')) {
//               _attendanceStatusColor = Colors.red;
//             } else {
//               _attendanceStatusColor = Colors.blueGrey;
//             }
//           });
//         } else {
//           setState(() {
//             _todayAttendanceStatus = data['message'] ?? 'Not Marked';
//             _attendanceStatusColor = Colors.redAccent;
//           });
//         }
//       } else {
//         print("Today's Attendance API HTTP Error: ${response.statusCode}");
//         setState(() {
//           _todayAttendanceStatus = 'Error Fetching';
//           _attendanceStatusColor = Colors.red;
//         });
//       }
//     } catch (e) {
//       print("Error fetching today's attendance: $e");
//       setState(() {
//         _todayAttendanceStatus = 'Error';
//         _attendanceStatusColor = Colors.red;
//       });
//     }
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: const Color.fromARGB(167, 255, 255, 255),
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
//           title: Text(
//             'Logout',
//             style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
//           ),
//           content: Text(
//             'Are you sure you want to logout?',
//             style: TextStyle(color: Colors.black87),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.redAccent,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//               child: Text('Logout', style: TextStyle(color: Colors.white)),
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 await prefs.remove('username');
//                 await prefs.remove('id'); // ✅ Remove 'id' consistent with UserProfile
//                 await prefs.remove('isLoggedIn');
//                 await prefs.remove('baseUrl'); // Also good to clear baseUrl on logout
//                 Navigator.pushAndRemoveUntil(
//                   context,
//                   MaterialPageRoute(builder: (context) => LoginPage()),
//                   (Route<dynamic> route) => false,
//                 );
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final String currentDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

//     // Use profileData from the new fetch logic
//     String displayUserName = "${_profileData?['name'] ?? 'Loading'} ${_profileData?['surname'] ?? ''}".trim();
//     String? profileImagePath = _profileData?['profile_image_path']; // Get path from new API structure
//     ImageProvider avatarImage;

//     // Use a placeholder if profileImagePath is null or empty, otherwise use NetworkImage
//     if (profileImagePath != null && profileImagePath.isNotEmpty) {
//       avatarImage = NetworkImage(profileImagePath);
//     } else {
//       avatarImage = AssetImage(_defaultAvatarPath);
//     }

//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.home, color: Colors.white),
//           onPressed: () {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(builder: (context) => BottomNavigationBarExample()),
//             );
//           },
//         ),
//         title: Text("Dashboard", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout, color: Colors.white),
//             onPressed: () => _showLogoutDialog(context),
//           ),
//         ],
//       ),
//       body: Stack(
//         children: [
//           // Background gradient
//           Container(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   Color(0xFF021526),
//                   Color(0xFF072E52),
//                   Color(0xFF0F4D82),
//                 ],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           Column(
//             children: <Widget>[
//               // Top section (user info and attendance status)
//               Padding(
//                 padding: const EdgeInsets.only(top: kToolbarHeight + 20, left: 20, right: 20, bottom: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     CircleAvatar(
//                       radius: 40, // Slightly reduced radius for less prominence
//                       backgroundColor: const Color.fromARGB(195, 255, 255, 255),
//                       backgroundImage: avatarImage,
//                       onBackgroundImageError: (exception, stackTrace) {
//                         setState(() {
//                           _profileData?['profile_image_path'] = null; // Forces AssetImage next time
//                           avatarImage = AssetImage(_defaultAvatarPath);
//                         });
//                       },
//                     ),
//                     SizedBox(height: 10),
//                     Text(
//                       'Hello,',
//                       style: TextStyle(fontSize: 16, color: Colors.white70),
//                       textAlign: TextAlign.center,
//                     ),
//                     Text(
//                       displayUserName,
//                       style: TextStyle(
//                         fontSize: 24, // Slightly reduced font size
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: 5),
//                     Text(
//                       currentDate,
//                       style: TextStyle(fontSize: 14, color: Colors.white60), // Slightly reduced font size
//                       textAlign: TextAlign.center,
//                     ),
//                     SizedBox(height: 15),
//                     Card(
//                       margin: EdgeInsets.symmetric(horizontal: 10),
//                       color: const Color.fromARGB(255, 255, 255, 255), // Solid white for prominence
//                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                       elevation: 5, // Added elevation
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0), // Increased padding
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               "Today's Attendance:",
//                               style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.w600), // Bolder text
//                             ),
//                             Text(
//                               _todayAttendanceStatus,
//                               style: TextStyle(
//                                 fontSize: 20, // Larger status text
//                                 fontWeight: FontWeight.bold,
//                                 color: _attendanceStatusColor,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Main content area with grid
//               Expanded(
//                 child: Container(
//                   decoration: BoxDecoration(
//                     color: Colors.orange.shade100, // Changed this to a light orange for the main grid background
//                     borderRadius: BorderRadius.only(
//                       topLeft: Radius.circular(30),
//                       topRight: Radius.circular(30),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 10,
//                         offset: Offset(0, -5),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.all(20.0),
//                     child: GridView.count(
//                       crossAxisCount: MediaQuery.of(context).size.width > 500 ? 4 : 2,
//                       mainAxisSpacing: 15.0,
//                       crossAxisSpacing: 15.0,
//                       childAspectRatio: 0.9,
//                       children: [
//                         DashboardCard(
//                           icon: Icons.fingerprint,
//                           label: 'Mark Attendance',
//                           color: Colors.blueAccent,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => MyHomePage()),
//                             );
//                           },
//                         ),
//                         DashboardCard(
//                           icon: Icons.pin_drop,
//                           label: 'Mark Visit',
//                           color: Colors.teal,
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(builder: (context) => Visitattendance()),
//                             );
//                           },
//                         ),
//                         // Add more DashboardCard widgets here for other functionalities
//                         DashboardCard(
//                           icon: Icons.calendar_today,
//                           label: 'My Attendance',
//                           color: Colors.purple,
//                           onTap: () {
//                             // Navigate to My Attendance screen
//                           },
//                         ),
//                          DashboardCard(
//                           icon: Icons.person,
//                           label: 'My Profile',
//                           color: Colors.brown,
//                           onTap: () {
//                             // Navigate to My Profile screen
//                           },
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Reusable widget for Dashboard buttons/cards
// class DashboardCard extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final int? notificationCount;
//   final VoidCallback? onTap;
//   final Color color;

//   DashboardCard({
//     required this.icon,
//     required this.label,
//     this.notificationCount,
//     this.onTap,
//     required this.color,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap ?? () {},
//       child: Card(
//         elevation: 5.0,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15.0),
//         ),
//         color: Colors.white, // Keep individual card backgrounds white for contrast
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Stack(
//               clipBehavior: Clip.none,
//               children: [
//                 Container(
//                   padding: EdgeInsets.all(15),
//                   decoration: BoxDecoration(
//                     color: color.withOpacity(0.15),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Icon(
//                     icon,
//                     size: 40,
//                     color: color,
//                   ),
//                 ),
//                 if (notificationCount != null && notificationCount! > 0)
//                   Positioned(
//                     top: -5,
//                     right: -5,
//                     child: CircleAvatar(
//                       radius: 12,
//                       backgroundColor: Colors.red,
//                       child: Text(
//                         '$notificationCount',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             SizedBox(height: 15),
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.black87,
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }