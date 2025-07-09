// import 'dart:io';
// import 'package:attendance_geetai/MyBottomNavigationBar.dart';
// import 'package:attendance_geetai/login_screen.dart';
// import 'package:attendance_geetai/screen/leaveApplication.dart';
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// import 'dart:convert';
// // Import the LeaveDetailPage

// class LeaveScreen extends StatefulWidget {
//   @override
//   _LeaveScreenState createState() => _LeaveScreenState();
// }

// class _LeaveScreenState extends State<LeaveScreen> {
//   late Future<List<dynamic>> _leaveHistory;
//   int totalApprovedDays = 0;
//   int totalAppliedDays = 0;

//   @override
//   void initState() {
//     super.initState();
//     _leaveHistory = fetchLeaveHistory();
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           backgroundColor: Colors.black87,
//           title: Text('Logout', style: TextStyle(color: Colors.white)),
//           content: Text('Are you sure you want to logout?',
//               style: TextStyle(color: Colors.white70)),
//           actions: <Widget>[
//             TextButton(
//               child: Text('Cancel', style: TextStyle(color: Colors.grey)),
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//             ),
//             TextButton(
//               child: Text('OK', style: TextStyle(color: Colors.red)),
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 await prefs.remove('username');
//                 await prefs.remove('isLoggedIn');
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

//   Future<String?> _getUsername() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString('username');
//   }

//   Future<int?> _fetchStaffId(String? username) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? baseUrl = prefs.getString('baseUrl');

//     String apiUrl = '$baseUrl/fetch_id.php';
//     try {
//       final request = http.Request('POST', Uri.parse(apiUrl))
//         ..headers[HttpHeaders.contentTypeHeader] = 'application/json'
//         ..body = jsonEncode({
//           'username': username,
//         });

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         return responseData;
//       } else {
//         Fluttertoast.showToast(
//           msg: "Failed to fetch staff ID.",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.BOTTOM,
//           timeInSecForIosWeb: 1,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           fontSize: 16.0,
//         );
//         return null;
//       }
//     } catch (e) {
//       Fluttertoast.showToast(
//         msg:
//             "Failed to connect to the server. Please check your internet connection.",
//         toastLength: Toast.LENGTH_SHORT,
//         gravity: ToastGravity.BOTTOM,
//         timeInSecForIosWeb: 1,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         fontSize: 16.0,
//       );
//       return null;
//     }
//   }

 

//   Future<List<dynamic>> fetchLeaveHistory() async {
//     String? username = await _getUsername();
//     int? staffId = await _fetchStaffId(username);

//    SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? baseUrl = prefs.getString('baseUrl');
      
//     final response = await http.get(

//         Uri.parse('$baseUrl/get_leave_history.php'));

//     if (response.statusCode == 200) {
//       List<dynamic> leaveHistory = json.decode(response.body);

//       // Filter leave history to include only the records matching the staffId
//       List<dynamic> matchingLeaveHistory = leaveHistory.where((leave) {
//         int leaveStaffId = int.parse(leave['staff_id'].toString());
//         return leaveStaffId == staffId;
//       }).toList();

//       // Sort leave history by date in descending order (most recent first)
//       matchingLeaveHistory.sort((a, b) {
//         DateTime dateA = DateTime.parse(a['date']);
//         DateTime dateB = DateTime.parse(b['date']);
//         return dateB.compareTo(dateA); // Sort in descending order
//       });

//       // Calculate total applied days for the matching leave history
//       int totalApplied = matchingLeaveHistory.fold(0, (sum, leave) {
//         int appliedDays =
//             int.tryParse(leave['total_leave_days']?.toString() ?? '0') ?? 0;
//         return sum + appliedDays;
//       });

//       // Calculate total approved days for the matching leave history
//       int totalApproved = matchingLeaveHistory.fold(0, (sum, leave) {
//         int approvedDays =
//             int.tryParse(leave['approved_days']?.toString() ?? '0') ?? 0;
//         return sum + approvedDays;
//       });

//       setState(() {
//         totalAppliedDays = totalApplied;
//         totalApprovedDays = totalApproved;
//       });

//       // Return the filtered and sorted matching leave history
//       return matchingLeaveHistory;
//     } else {
//       throw Exception('Failed to load leave history');
//     }
//   }

//   String _statusToText(String? status) {
//     switch (status) {
//       case 'Pending':
//         return 'Pending';
//       case 'Approved':
//         return 'Approved';
//       case 'Rejected':
//         return 'Rejected';
//       default:
//         return 'Unknown';
//     }
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Pending':
//         return Colors.orange;
//       case 'Approved':
//         return Colors.green;
//       case 'Rejected':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: PreferredSize(
//         preferredSize: Size.fromHeight(kToolbarHeight),
//         child: ClipRRect(
//           borderRadius: BorderRadius.vertical(
//             bottom: Radius.circular(20.0),
//           ),
//           child: AppBar(
//             leading: IconButton(
//               icon: Icon(Icons.home, color: Colors.white),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                       builder: (context) => BottomNavigationBarExample()),
//                 );
//               },
//             ),
//             automaticallyImplyLeading: false,
//             title: Text("Leave", style: TextStyle(color: Colors.white)),
//             centerTitle: true,
//             backgroundColor: Color(0xFF021526),
//             actions: [
//               IconButton(
//                 icon: Icon(Icons.logout, color: Colors.white),
//                 onPressed: () => _showLogoutDialog(context),
//               ),
//             ],
//           ),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Leave History',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               SizedBox(height: 16),
//               FutureBuilder<List<dynamic>>(
//                 future: _leaveHistory,
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return Center(child: CircularProgressIndicator());
//                   } else if (snapshot.hasError) {
//                     return Center(child: Text('Error: ${snapshot.error}'));
//                   } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return Center(child: Text('No leave history available.'));
//                   } else {
//                     return Column(
//                       children: snapshot.data!.map((leave) {
//                         int status1 =
//                             int.tryParse(leave['status'].toString()) ?? -1;

//                         String status = _getstatus(status1);

//                         return _buildLeaveRequestItem(
//                           leave['leave_from'] ?? '',
//                           leave['leave_to'] ?? '',
//                           leave['leave_days'] ?? 'N/A',
//                           leave['date'] ?? '0',
//                           leave['admin_remark'] ?? 'N/A',
//                           leave['employee_remark'] ?? 'N/A',
//                           status,
//                         );
//                       }).toList(),
//                     );
//                   }
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(builder: (context) => LeaveApplicationForm()),
//           );
//         },
//         child: Icon(Icons.add, color: Colors.white), // Set icon color here
//         backgroundColor: Color(0xFF021526),
//       ),
//     );
//   }

//   Widget _buildLeaveRequestItem(
//     String startDate,
//     String endDate,
//     String leaveType,
//     String appliedDays,
//     String approvedBy,
//     String reason,
//     String status,
//   ) {
//     return InkWell(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => LeaveDetailPage(
//               startDate: startDate,
//               endDate: endDate,
//               leaveType: leaveType,
//               appliedDays: appliedDays,
//               approvedBy: approvedBy,
//               reason: reason,
//               status: _statusToText(status),
//             ),
//           ),
//         );
//       },
//       child: Container(
//         margin: EdgeInsets.only(bottom: 16),
//         padding: EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8.0),
//           color: Colors.white,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.2),
//               spreadRadius: 2,
//               blurRadius: 5,
//               offset: Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               '$startDate - $endDate',
//               style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 8),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Applied Days',
//                         style: TextStyle(fontSize: 12),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         leaveType,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Applied Date',
//                         style: TextStyle(fontSize: 12),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         appliedDays,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Admin Remark',
//                         style: TextStyle(fontSize: 12),
//                       ),
//                       SizedBox(height: 4),
//                       Text(
//                         approvedBy,
//                         style: TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 8),
//             Row(
//               children: [
//                 _buildStatusIcon(_statusToText(status)),
//                 SizedBox(width: 8),
//                 Text(
//                   _statusToText(status),
//                   style: TextStyle(
//                     color: _statusColor(status),
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusIcon(String status) {
//     IconData icon;
//     Color color;

//     switch (status) {
//       case 'Pending' || '0':
//         icon = Icons.hourglass_empty;
//         color = Colors.orange;
//         break;
//       case 'Approved' || '1':
//         icon = Icons.check_circle;
//         color = Colors.green;
//         break;
//       case 'Rejected' || '2':
//         icon = Icons.cancel;
//         color = Colors.red;
//         break;
//       default:
//         icon = Icons.info;
//         color = Colors.grey;
//     }

//     return Icon(
//       icon,
//       color: color,
//       size: 20,
//     );
//   }

//   String _getstatus(int status1) {
//     switch (status1) {
//       case 0:
//         return 'Pending';
//       case 1:
//         return 'Approved';
//       case 2:
//         return 'Rejected';
//       default:
//         return 'Unknown';
//     }
//   }
// }

// class LeaveDetailPage extends StatelessWidget {
//   final String startDate;
//   final String endDate;
//   final String leaveType;
//   final String appliedDays;
//   final String approvedBy;
//   final String reason;
//   final String status;

//   LeaveDetailPage({
//     required this.startDate,
//     required this.endDate,
//     required this.leaveType,
//     required this.appliedDays,
//     required this.approvedBy,
//     required this.reason,
//     required this.status,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           'Leave Details',
//           style: TextStyle(color: Colors.white), // Title text color
//         ),
//         backgroundColor: Color(0xFF021526), // AppBar background color
//         iconTheme: IconThemeData(
//           color: Colors.white, // Back arrow color
//         ),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Center(
//               child: Text(
//                 'Leave Details',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.normal,
//                   color: Color(0xFF021526),
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             _buildDetailCard(Icons.date_range, 'Start Date', startDate),
//             _buildDetailCard(Icons.date_range, 'End Date', endDate),
//             _buildDetailCard(Icons.category, 'Leave Type', leaveType),
//             _buildDetailCard(Icons.timer, 'Applied Days', appliedDays),
//             _buildDetailCard(Icons.person, 'Approved By', approvedBy),
//             _buildDetailCard(Icons.description, 'Reason', reason),
//             _buildStatusCard(Icons.info, 'Status', status),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailCard(IconData icon, String title, String detail) {
//     return Card(
//       elevation: 4.0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15.0),
//       ),
//       margin: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Icon(icon, color: Color(0xFF021526)),
//             SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 '$title: $detail',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusCard(IconData icon, String title, String detail) {
//     return Card(
//       elevation: 4.0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15.0),
//       ),
//       margin: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             Icon(icon, color: Color(0xFF021526)),
//             SizedBox(width: 16),
//             Expanded(
//               child: Text(
//                 '$title: $detail',
//                 style: TextStyle(
//                   fontSize: 16,
//                   color: _statusColor(detail), // Pass status to get color
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _statusColor(String status) {
//     switch (status) {
//       case 'Pending' || '0':
//         return Colors.orange;
//       case 'Approved' || '1':
//         return Colors.green;
//       case 'Rejected' || '2':
//         return Colors.red;
//       default:
//         return Colors.grey;
//     }
//   }
// }
import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/screen/dashboard.dart';
import 'package:attendance_geetai/screen2/leaveApplication.dart';

import 'package:attendance_geetai/screen2/logoutScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveScreen extends StatefulWidget {
  const LeaveScreen({super.key});

  @override
  State<LeaveScreen> createState() => _LeaveHistoryScreenState();
}

class _LeaveHistoryScreenState extends State<LeaveScreen> {
  late Future<List<dynamic>> _leaveHistory;
  String? _staffId;

  @override
  void initState() {
    super.initState();
    _loadStaffIdAndFetchHistory();
  }

  // Loads staff ID from SharedPreferences and then fetches history
  Future<void> _loadStaffIdAndFetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _staffId = prefs.getString('id') ?? '1'; // Default to '1' if not found
    });
    _leaveHistory = _fetchLeaveHistory();
  }

  // Fetches leave history from the API
  Future<List<dynamic>> _fetchLeaveHistory() async {
    if (_staffId == null) {
      throw Exception('Staff ID is not available.');
    }

    // IMPORTANT: Replace with your actual API endpoint for leave_history.php
    const String apiUrl = 'https://erp.vpsedu.org/appapi/attendance/leave_history.php'; // Adjust for your server

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'staff_id': _staffId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          return responseData['data'];
        } else {
          debugPrint('API Response Error: ${responseData['message'] ?? 'No data found'}');
          return []; // Return empty list if no data or status is false
        }
      } else {
        throw Exception('Failed to load leave history. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching leave history: $e');
      throw Exception('Failed to connect to the server or parse data: $e');
    }
  }

  // Maps status integer to readable text
  String _statusToText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  // Determines color based on status
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
String leaveTypeName(String id) {
  switch (id) {
    case '1':
      return 'Sick Leave';
    case '2':
      return 'Casual Leave';
    case '3':
      return 'Maternity Leave';
    case '4':
      return 'Paternity Leave';
    case '5':
      return 'Emergency Leave';
    default:
      return 'Unknown Type';
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
          child:AppBar(
            leading: IconButton(
  icon: Icon(Icons.home, color: Colors.white),
  onPressed: () {
    final navBarState = context.findAncestorStateOfType<BottomNavigationBarExampleState>();
    navBarState?.setState(() {
      navBarState.selectedIndex = 0; // Go to Home Tab
      navBarState.navigatorKeys[0].currentState?.pushNamedAndRemoveUntil('/', (route) => false);
    });
  },
),

            automaticallyImplyLeading: false,
            title:
                Text("Leave History", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Color(0xFF021526),
            actions: [
               IconButton(
      icon: Icon(Icons.assignment, color: Colors.white), // Visit Attendance Icon
      tooltip: "Leave FORM",
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LeaveApplicationForm()),
        );
      },
    ),
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
               onPressed: () =>  LogoutConfirmation.show(context)
              ),
            ],
          ),
    )),
     
      body: FutureBuilder<List<dynamic>>(
        future: _leaveHistory,
        builder: (context, snapshot) {
          if (_staffId == null) {
            return const Center(
                child: Text('Staff ID not found. Please log in again.'));
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Error: ${snapshot.error}. Ensure your PHP server is running and accessible.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    'No leave history available for Staff ID: $_staffId.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _leaveHistory = _fetchLeaveHistory(); // Refresh data
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(10.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final leave = snapshot.data![index];
                // Assuming 'status' from your DB is the primary status to display
                final currentStatus = leave['status'] as String? ?? 'Unknown';

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${leave['leave_from']} - ${leave['leave_to']}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(currentStatus).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _statusToText(currentStatus),
                                style: TextStyle(
                                  color: _statusColor(currentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        Text(
                          'Type: ${leaveTypeName(leave['leave_type_id'].toString())}',
 // Renamed from leave_type_name in PHP
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Days: ${leave['leave_days']}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Reason: ${leave['employee_remark']}', // Assuming employee_remark is the user's reason
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                        ),
                        if (leave['admin_remark'] != null && leave['admin_remark'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: Text(
                              'Admin Remark: ${leave['admin_remark']}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.blueGrey),
                            ),
                          ),
                        const SizedBox(height: 10),
                        
                        Text(
                             'Principal Status: ${_statusToText(leave['principal_status'] as String? ?? 'Unknown')}, '
                             'Accountant Status: ${_statusToText(leave['accountant_status'] as String? ?? 'Unknown')}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: const Color.fromARGB(255, 233, 42, 42)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}