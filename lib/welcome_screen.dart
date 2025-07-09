
import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/screen/Options.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';// Import your dashboard page here

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      // Navigate to the dashboard if the user is logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavigationBarExample()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF050A30), // Set the background color
      body: Stack(
        children: [
          Positioned(
            top: 80, // Adjust this value to create a gap at the top
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFD9D9D9), // The color of the title bar
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(100), // Semi-circular shape at the top
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 50), // Adjust the height to make room for the title bar text
              Text(
                "Let's get you started",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              Image.asset(
                'assets/images/logo.png',
                width: 200, // Adjust size as needed
                height: 200,
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  "Streamline teacher attendance effortlessly with our intuitive app. Enhance efficiency and track teacher presence seamlessly.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 100),
              SizedBox(
                width: 200,
                height: 50, // Set the desired width
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF03346E),
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Option()),
                    );
                  },
                  child: Text(
                    'Take Me In',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 0, // Adjust this value to align with the gap above the container
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
            ),
          ),
          SizedBox(height: 400),
        ],
      ),
    );
  }
}
