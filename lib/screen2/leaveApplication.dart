
// import 'package:attendance_geetai/screen/leaveFORM.DART' show LeaveHistory;
// import 'package:attendance_geetai/screen/leaveHistroy.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:shared_preferences/shared_preferences.dart';

// void main() => runApp(LeaveApplicationApp());

// class LeaveApplicationApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Teacher Leave Application',
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: const Color(0xFFE0F2F7),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFFB3E5FC),
//           foregroundColor: Colors.black87,
//           centerTitle: true,
//           elevation: 0,
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.teal,
//             foregroundColor: Colors.white,
//             textStyle: const TextStyle(fontWeight: FontWeight.bold),
//             minimumSize: const Size.fromHeight(50),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         ),
//       ),
//       debugShowCheckedModeBanner: false,
//       home: LeaveApplicationForm(),
//     );
//   }
// }

// class LeaveApplicationForm extends StatefulWidget {
//   @override
//   State<LeaveApplicationForm> createState() => _LeaveApplicationFormState();
// }

// class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
//   DateTime? startDate;
//   DateTime? endDate;
//   String? selectedLeaveType = 'Sick Leave';
//   final reasonController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   final List<String> leaveTypes = [
//     'Sick Leave',
//     'Casual Leave',
//     'Maternity Leave',
//     'Paternity Leave',
//     'Emergency Leave',
//   ];

//   @override
//   void dispose() {
//     reasonController.dispose();
//     super.dispose();
//   }

//   Future<void> _pickDate(bool isStart) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(2020),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStart) {
//           startDate = picked;
//           if (endDate != null && startDate!.isAfter(endDate!)) endDate = null;
//         } else {
//           if (startDate != null && picked.isBefore(startDate!)) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               const SnackBar(content: Text('End date cannot be before start date')),
//             );
//           } else {
//             endDate = picked;
//           }
//         }
//       });
//     }
//   }

//   Future<void> _submitLeave() async {
//     if (!_formKey.currentState!.validate() || startDate == null || endDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Please complete the form.')),
//       );
//       return;
//     }

//     final prefs = await SharedPreferences.getInstance();
//     final staffId = prefs.getString('id') ?? '1';

//     final url = Uri.parse('http://localhost/apply_leave.php');

//     try {
//       final response = await http.post(
//         url,
//         headers: {'Content-Type': 'application/json'},
//         body: jsonEncode({
//           'staff_id': staffId,
//           'start_date': _formatDate(startDate!),
//           'end_date': _formatDate(endDate!),
//           'leave_type': selectedLeaveType,
//           'reason': reasonController.text.trim(),
//         }),
//       );

//       final data = jsonDecode(response.body);

//       if (response.statusCode == 200 && data['status'] == true) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('✅ Leave application submitted successfully!')),
//         );
//         setState(() {
//           startDate = null;
//           endDate = null;
//           selectedLeaveType = 'Sick Leave';
//           reasonController.clear();
//         });
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('❌ Error: ${data['message'] ?? 'Unknown error'}')),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('❗ Exception: $e')),
//       );
//     }
//   }

//   String _formatDate(DateTime date) {
//     return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Leave Application')),
//       body: Center(
//         child: Card(
//           margin: const EdgeInsets.all(16),
//           elevation: 6,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Form(
//               key: _formKey,
//               child: ListView(
//                 shrinkWrap: true,
//                 children: [
//                   _buildDateField('Start Date', startDate, () => _pickDate(true)),
//                   const SizedBox(height: 16),
//                   _buildDateField('End Date', endDate, () => _pickDate(false)),
//                   const SizedBox(height: 16),
//                   _buildLeaveTypeDropdown(),
//                   const SizedBox(height: 16),
//                   _buildReasonField(),
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: _submitLeave,
//                     child: const Text('SUBMIT'),
//                   ),
//                   const SizedBox(height: 12),
//                   OutlinedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (_) => LeaveScreen()),
//                       );
//                     },
//                     child: const Text('VIEW LEAVE HISTORY'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
//     return TextFormField(
//       readOnly: true,
//       onTap: onTap,
//       controller: TextEditingController(
//         text: date != null ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}" : '',
//       ),
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: 'Select $label',
//         suffixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
//       ),
//       validator: (_) => date == null ? 'Please select $label' : null,
//     );
//   }

//   Widget _buildLeaveTypeDropdown() {
//     return DropdownButtonFormField<String>(
//       value: selectedLeaveType,
//       items: leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
//       decoration: const InputDecoration(labelText: 'Leave Type'),
//       onChanged: (value) => setState(() => selectedLeaveType = value),
//       validator: (value) => value == null ? 'Select leave type' : null,
//     );
//   }

//   Widget _buildReasonField() {
//     return TextFormField(
//       controller: reasonController,
//       maxLines: 3,
//       decoration: const InputDecoration(
//         labelText: 'Reason',
//         hintText: 'Enter reason for leave',
//       ),
//       validator: (value) =>
//           (value == null || value.trim().isEmpty) ? 'Please enter a reason' : null,
//     );
//   }
// }
import 'package:attendance_geetai/screen/dashboard.dart';
import 'package:attendance_geetai/screen/leaveHistroy.dart';
import 'package:attendance_geetai/screen2/logoutScreen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
// Import the new leave history screen

// void main() {
//   runApp(const LeaveApplicationApp());
// }

// class LeaveApplicationApp extends StatelessWidget {
//   const LeaveApplicationApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Teacher Leave Application',
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: const Color(0xFFE0F2F7), // Light blue background
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFFB3E5FC), // Light blue app bar
//           foregroundColor: Colors.black87,
//           centerTitle: true,
//           elevation: 0,
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.teal.shade300),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.teal.shade200),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: const BorderSide(color: Colors.teal, width: 2.0),
//           ),
//           labelStyle: TextStyle(color: Colors.teal.shade700),
//           hintStyle: TextStyle(color: Colors.grey.shade500),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.teal, // Teal button
//             foregroundColor: Colors.white,
//             textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//             minimumSize: const Size.fromHeight(50),
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//         ),
//        outlinedButtonTheme: OutlinedButtonThemeData(
//   style: OutlinedButton.styleFrom(
//     foregroundColor: Colors.teal, // Text color for the button
//     side: const BorderSide(color: Colors.teal, width: 2), // Border color & width
//     textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//     minimumSize: const Size.fromHeight(50), // Button height
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//   ),
// ),

      //   cardTheme: CardTheme(
      //     elevation: 6,
      //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //     margin: const EdgeInsets.all(16),
      //   ),
      // // ),
      // debugShowCheckedModeBanner: false,
      // home: LeaveApplicationForm(),
//     // );
//   }
// }

class LeaveApplicationForm extends StatefulWidget {
  const LeaveApplicationForm({super.key});

  @override
  State<LeaveApplicationForm> createState() => _LeaveApplicationFormState();
}

class _LeaveApplicationFormState extends State<LeaveApplicationForm> {
  DateTime? startDate;
  DateTime? endDate;
  String? selectedLeaveType = 'Sick Leave'; // Default value
  final TextEditingController reasonController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final List<String> leaveTypes = const [
    'Sick Leave',
    'Casual Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Emergency Leave',
  ];

  @override
  void dispose() {
    reasonController.dispose();
    super.dispose();
  }

  // Function to handle date picking
  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: isStart ? 'Select Start Date' : 'Select End Date',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.teal, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
          // If start date is set after end date, clear end date
          if (endDate != null && startDate!.isAfter(endDate!)) {
            endDate = null;
          }
        } else {
          // Ensure end date is not before start date
          if (startDate != null && picked.isBefore(startDate!)) {
            _showSnackBar('End date cannot be before start date.');
          } else {
            endDate = picked;
          }
        }
      });
    }
  }

  // Function to submit leave application
  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill out all required fields correctly.');
      return;
    }

    if (startDate == null || endDate == null) {
      _showSnackBar('Please select both start and end dates.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    // Use the actual staff ID obtained after successful login.
    // For demonstration, defaulting to '1'.
    final staffId = prefs.getString('id') ?? '1';

    // IMPORTANT: Replace with your actual API endpoint for apply_leave.php
    const String apiUrl = 'https://erp.vpsedu.org/appapi/attendance/apply_leave.php'; // Adjust for your server (e.g., your_ip/apply_leave.php)

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'staff_id': staffId,
          'start_date': _formatDate(startDate!),
          'end_date': _formatDate(endDate!),
          'leave_type': selectedLeaveType,
          'reason': reasonController.text.trim(),
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['status'] == true) {
        _showSnackBar('✅ Leave application submitted successfully!');
        // Clear form fields on success
        setState(() {
          startDate = null;
          endDate = null;
          selectedLeaveType = 'Sick Leave';
          reasonController.clear();
          _formKey.currentState?.reset(); // Reset form validation state
        });
      } else {
        _showSnackBar('❌ Failed to submit leave: ${responseData['message'] ?? 'Unknown error'}.');
      }
    } catch (e) {
      _showSnackBar('❗ An error occurred: $e. Check server connection.');
      debugPrint('Error submitting leave application: $e');
    }
  }

  // Helper to format date as YYYY-MM-DD for API
  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // Helper for showing snack bars
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DashboardScreen()),
                );
              },
            ),
            automaticallyImplyLeading: false,
            title:
                Text("Leave Application", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Color(0xFF021526),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
               onPressed: () =>  LogoutConfirmation.show(context)
              ),
            ],
          ),
    )),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: ListView(
                shrinkWrap: true, // Prevents content overflow
                children: [
                  _buildDateField('Start Date', startDate, () => _pickDate(true)),
                  const SizedBox(height: 16),
                  _buildDateField('End Date', endDate, () => _pickDate(false)),
                  const SizedBox(height: 16),
                  _buildLeaveTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildReasonField(),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submitLeave,
                    child: const Text('SUBMIT'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  LeaveScreen ()),
                      );
                    },
                    child: const Text('VIEW LEAVE HISTORY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable widget for date input fields
  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return TextFormField(
      readOnly: true,
      onTap: onTap,
      controller: TextEditingController(
        text: date != null ? "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}" : '',
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: 'Select $label',
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.teal),
      ),
      validator: (value) => date == null ? 'Please select a $label' : null,
    );
  }

  // Reusable widget for leave type dropdown
  Widget _buildLeaveTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedLeaveType,
      items: leaveTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
      decoration: const InputDecoration(labelText: 'Leave Type'),
      onChanged: (value) => setState(() => selectedLeaveType = value),
      validator: (value) => value == null ? 'Please select a leave type' : null,
    );
  }

  // Reusable widget for reason text field
  Widget _buildReasonField() {
    return TextFormField(
      controller: reasonController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Reason',
        hintText: 'Enter reason for leave',
        alignLabelWithHint: true,
      ),
      validator: (value) =>
          (value == null || value.trim().isEmpty) ? 'Please enter a reason' : null,
    );
  }
}