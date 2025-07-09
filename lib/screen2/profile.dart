import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendance_geetai/login_screen.dart';
import 'package:attendance_geetai/MyBottomNavigationBar.dart';

class UserProfile extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfile> {
  Map<String, dynamic>? profileData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

 Future<void> fetchProfile() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? id = prefs.getString('id'); // ✅ changed from employeeId to id

  if (id == null) {
    setState(() => isLoading = false);
    return;
  }

  var response = await http.post(
    Uri.parse('https://erp.vpsedu.org/appapi/attendance/profile.php'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'employee_id': id}), // ✅ still sending as 'employee_id' if backend expects that
  );

  print("📥 Profile API Response: ${response.body}");

  if (response.statusCode == 200) {
    var json = jsonDecode(response.body);
    if (json['status'] == true) {
      setState(() {
        profileData = json['data'];
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      print("❌ ${json["message"]}");
    }
  } else {
    setState(() => isLoading = false);
    print("❌ Failed to load profile");
  }
}

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('OK', style: TextStyle(color: Colors.black)),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.0)),
          child: AppBar(
            leading: IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BottomNavigationBarExample()),
              ),
            ),
            automaticallyImplyLeading: false,
            title: Text("Profile", style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Color(0xFF021526),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.white),
                onPressed: _showLogoutDialog,
              ),
            ],
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : profileData == null
              ? Center(child: Text("No profile data found."))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage('assets/images/logo.png'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
       Text(
  "${profileData!['name'] ?? ''} ${profileData!['surname'] ?? ''}".trim(),
  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
),


                      SizedBox(height: 20),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.badge),
                          title: Text(profileData!['employee_id']),
                          subtitle: Text('Employee ID'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.email),
                          title: Text(profileData!['email']),
                          subtitle: Text('Email'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.calendar_today),
                          title: Text(profileData!['dob']),
                          subtitle: Text('Date of Birth'),
                        ),
                      ),
                      Card(
                        child: ListTile(
                          leading: Icon(Icons.school),
                          title: Text(profileData!['qualification']),
                          subtitle: Text('Qualification'),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
