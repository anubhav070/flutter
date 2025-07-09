// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
// import 'package:teacher_attendenc/MyBottomNavigationBar.dart';

// class LoginPage extends StatefulWidget {
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   TextEditingController _usernameController = TextEditingController();
//   TextEditingController _passwordController = TextEditingController();
//   bool _isPasswordVisible = false;
//   bool _rememberMe = false;

//   @override
//   void initState() {
//     super.initState();
//     _loadUsername();
//   }

//   Future<void> _loadUsername() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? savedUsername = prefs.getString('username');
//     if (savedUsername != null) {
//       _usernameController.text = savedUsername;
//     }
//   }

//   Future<void> _saveUsername(String username) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     await prefs.setString('username', username);
//   }

//   Future<void> login() async {
//     if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
//       Fluttertoast.showToast(
//         msg: 'Please enter both username and password',
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         toastLength: Toast.LENGTH_SHORT,
//       );
//       return;
//     }

//     try {
//       // Show loading indicator
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (context) => Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//        SharedPreferences prefs = await SharedPreferences.getInstance();
//       String? baseUrl = prefs.getString('baseUrl');

// var response = await http.post(
//   Uri.parse('http://10.0.2.2/atttendace/login.php'),
//   body: {
//     "username": _usernameController.text,
//     "pin": _passwordController.text, // match PHP $_POST['pin']
//   },
// );



//       Navigator.of(context).pop(); // Close the loading indicator

//       print('Response status: ${response.statusCode}');
//       print('Response body: ${response.body}');

//       var data = json.decode(response.body);
//       if (data == "Success") {
//         SharedPreferences prefs = await SharedPreferences.getInstance();
//         await prefs.setString('username', _usernameController.text);
//         if (_rememberMe) {
//           await _saveUsername(_usernameController.text);
//         }
//         await prefs.setBool('isLoggedIn', true); // Save login state

//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => BottomNavigationBarExample()),
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: 'Invalid Username or Password',
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//           toastLength: Toast.LENGTH_SHORT,
//         );
//       }
//     } catch (e, stackTrace) {
//       print('Login failed: $e');
//       print('Stack trace: $stackTrace');

//       Navigator.of(context).pop(); // Close the loading indicator

//       Fluttertoast.showToast(
//         msg: 'An error occurred. Please try again later.',
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//         toastLength: Toast.LENGTH_SHORT,
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         color: Color(0xFF050A30), // Set the background color
//         child: Stack(
//           children: [
//             Positioned(
//               top: 80, // Adjust this value to create a gap at the top
//               left: 0,
//               right: 0,
//               bottom: 0,
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Color(0xFFD9D9D9), // The color of the title bar
//                   borderRadius: BorderRadius.vertical(
//                     top: Radius.circular(100), // Semi-circular shape at the top
//                   ),
//                 ),
//               ),
//             ),
//             Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 Text(
//                   "Let's Get You Started",
//                   style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 25,
//                       fontWeight: FontWeight.bold),
//                 ),
//                 SizedBox(height: 13.0),
//                 Text(
//                   "Tell us something about yourself",
//                   style: TextStyle(
//                       color: Colors.black,
//                       fontSize: 14,
//                       fontWeight: FontWeight.normal),
//                 ),
//                 SizedBox(height: 60.0),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 30.0),
//                   child: TextFormField(
//                     controller: _usernameController,
//                     decoration: InputDecoration(
//                       hintText: 'Username',
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: EdgeInsets.symmetric(
//                           vertical: 10.0, horizontal: 15.0),
//                       suffixIcon: Icon(Icons.person),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                         borderSide: BorderSide(color: Colors.white),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                         borderSide: BorderSide(color: Colors.blue),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 15.0),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 30.0),
//                   child: TextFormField(
//                     controller: _passwordController,
//                     obscureText: !_isPasswordVisible,
//                     decoration: InputDecoration(
//                       hintText: 'Password',
//                       filled: true,
//                       fillColor: Colors.white,
//                       contentPadding: EdgeInsets.symmetric(
//                           vertical: 10.0, horizontal: 15.0),
//                       suffixIcon: IconButton(
//                         icon: Icon(
//                           _isPasswordVisible
//                               ? Icons.visibility
//                               : Icons.visibility_off,
//                         ),
//                         onPressed: () {
//                           setState(() {
//                             _isPasswordVisible = !_isPasswordVisible;
//                           });
//                         },
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                         borderSide: BorderSide(color: Colors.white),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8.0),
//                         borderSide: BorderSide(color: Colors.blue),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 15.0),
//                 Padding(
//                   padding: EdgeInsets.symmetric(horizontal: 30.0),
//                   child: Row(
//                     children: <Widget>[
//                       Spacer(),
//                       TextButton(
//                         onPressed: () {
//                           // Show a dialog with the message
//                           showDialog(
//                             context: context,
//                             builder: (BuildContext context) {
//                               return AlertDialog(
//                                 backgroundColor: Colors.white,
//                                 title: Text(
//                                   'Forgot Password',
//                                   style: TextStyle(
//                                     color: Color(0xFF03346E),
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 content: Text(
//                                   'For more details, please contact the admin.',
//                                   style: TextStyle(
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 actions: <Widget>[
//                                   TextButton(
//                                     child: Text(
//                                       'OK',
//                                       style: TextStyle(
//                                         color: Color(0xFF03346E),
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     onPressed: () {
//                                       Navigator.of(context)
//                                           .pop(); // Close the dialog
//                                     },
//                                   ),
//                                 ],
//                               );
//                             },
//                           );
//                         },
//                         child: Text(
//                           'Forgot Password?',
//                           style: TextStyle(
//                             color: Color(0xFF03346E),
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       )

//                       // You can add widgets here if needed
//                     ],
//                   ),
//                 ),
//                 SizedBox(height: 50.0),
//                 ElevatedButton(
//                   onPressed: login,
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//                     child: Text(
//                       'Login',
//                       style: TextStyle(
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFF03346E),
//                     padding: EdgeInsets.symmetric(horizontal: 40, vertical: 10),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(40),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/model_service.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> login(BuildContext context) async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    try {
      var response = await http.post(
        Uri.parse("https://erp.vpsedu.org/appapi/attendance/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      print("🔍 Status Code: ${response.statusCode}");
      print("🔍 Raw Response: ${response.body}");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        var json = jsonDecode(response.body);
        LoginResponse loginResponse = LoginResponse.fromJson(json);

        if (loginResponse.status && loginResponse.data != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
         await prefs.setBool('isLoggedIn', true);
await prefs.setString('userName', loginResponse.data!.name);
await prefs.setString('role', loginResponse.data!.role);
await prefs.setString('id', loginResponse.data!.id); // ✅ Only saving ID


          print("✅ Saved staffId: ${loginResponse.data!.staffid}");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomNavigationBarExample()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ ${loginResponse.message}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("❌ Login exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Login failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60),
                Text("Welcome Back 👋", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text("Login to continue", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => login(context),
                    child: Text("Login", style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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