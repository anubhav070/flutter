

import 'package:attendance_geetai/screen2/testUi.dart';
import 'package:attendance_geetai/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the base URL in Shared Preferences
  const String baseUrl = 'https://erp.vpsedu.org/coa/attendance/';
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString('baseUrl', baseUrl);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: WelcomeScreen(),
    );
  }
}
