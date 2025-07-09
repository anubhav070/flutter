import 'dart:io';

import 'package:attendance_geetai/MyBottomNavigationBar.dart';
import 'package:attendance_geetai/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// Assuming MyBottomNavigationBar and LoginPage are defined elsewhere
// For demonstration purposes, I'll add minimal versions if not provided.
class MyBottomNavigationBarExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Your home screen content.')),
    );
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Your login page content.')),
    );
  }
}

class UserProfile extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfile>
    with SingleTickerProviderStateMixin {
  String _username = '';
  Map<String, dynamic>? _profileData;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad),
    );
    _loadUsernameAndFetchProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUsernameAndFetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
    });
    await _fetchUserProfile();
    if (_profileData != null) {
      _animationController.forward();
    }
  }

  Future<void> _saveUserId(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', id);
  }

  Future<void> _fetchUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? baseUrl = prefs.getString('baseUrl');
    var url = Uri.parse("$baseUrl/Profile2.php");
    var response = await http.post(url, body: {
      "Username": _username,
    });

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['error'] != null) {
        print('Error: ${data['error']}');
      } else {
        setState(() {
          _profileData = data;
        });
        await _saveUserId(data['employee_id']);
      }
    } else {
      print('Failed to load profile: ${response.statusCode}');
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('username');
                await prefs.remove('employee_id');
                await prefs.remove('isLoggedIn');
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF021526),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor; // Using theme's primary color

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200.0), // Increased height for a hero effect
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF021526),
                Color(0xFF1A3B5D), // A slightly lighter shade for gradient
              ],
            ),
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(40.0), // More pronounced curve
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 15,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  "My Profile",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                if (_profileData != null)
                  Text(
                    _profileData!['name'] ?? 'Guest User',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                const SizedBox(height: 10), // Padding above the content
              ],
            ),
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => MyBottomNavigationBarExample()),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 28),
                onPressed: () => _showLogoutDialog(),
              ),
            ],
            toolbarHeight: 200, // Explicitly set toolbar height
          ),
        ),
      ),
      body: _profileData == null
          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF021526))))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(25.0, 200.0 + 30.0, 25.0, 30.0), // Adjust padding for app bar and avatar
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Profile Image
                      Align(
                        alignment: Alignment.topCenter,
                        child: Transform.translate(
                          offset: const Offset(0, -90), // Move avatar up into the app bar area
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                color: Theme.of(context).primaryColor,
                                width: 5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  spreadRadius: 5,
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              image: DecorationImage(
                                image: _profileData!['ImagePath'] != null &&
                                        _profileData!['ImagePath'].isNotEmpty
                                    ? NetworkImage(_profileData!['ImagePath'])
                                    : const AssetImage('assets/images/logo_login.jpg') as ImageProvider,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10), // Space below the translated avatar

                      Text(
                        _profileData!['designation'] ?? 'Designation Not Available',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 35),

                      _buildProfileInfoCard(
                        context,
                        Icons.email_outlined,
                        'Email Address',
                        _profileData!['email'] ?? 'N/A',
                      ),
                      _buildProfileInfoCard(
                        context,
                        Icons.phone_outlined,
                        'Contact Number',
                        _profileData!['contact_no'] ?? 'N/A',
                      ),
                      _buildProfileInfoCard(
                        context,
                        Icons.home_outlined,
                        'Local Address',
                        _profileData!['local_address'] ?? 'N/A',
                      ),
                      _buildProfileInfoCard(
                        context,
                        Icons.location_on_outlined,
                        'Permanent Address',
                        _profileData!['permanent_address'] ?? 'N/A',
                      ),
                      _buildProfileInfoCard(
                        context,
                        Icons.security,
                        'Account Status',
                        _profileData!['is_active'] == 1 ? 'Active' : 'Inactive',
                        valueColor: _profileData!['is_active'] == 1 ? Colors.green[700] : Colors.red[700],
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // Improved helper widget for profile info cards
  Widget _buildProfileInfoCard(
      BuildContext context, IconData icon, String label, String value,
      {Color? valueColor}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      elevation: 8, // Increased elevation for a floating effect
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // More rounded corners
      color: Colors.white, // Pure white card background
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 25.0), // Generous padding
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start, // Align icon and text at top
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor), // Larger, themed icon
            const SizedBox(width: 25),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8), // More space between label and value
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: valueColor ?? const Color(0xFF021526), // Use custom color or default
                    ),
                    overflow: TextOverflow.ellipsis, // Handle long text
                    maxLines: 2, // Allow up to 2 lines for value
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}