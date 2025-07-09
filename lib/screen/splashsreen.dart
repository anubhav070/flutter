import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final GlobalKey _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds:3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox renderBox = _scaffoldKey.currentContext?.findRenderObject() as RenderBox;
      if (renderBox != null) {
        final size = renderBox.size;
        print('SplashScreen Size: $size');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF071952), // Dark blue
              Color(0xFF088395), // Teal
              Color(0xFF37B7C3), // Light teal
              Color(0xFFEBF4F4), // Very light blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: Duration(seconds: 2),
                curve: Curves.easeInOut,
                height: 200,
                width: 200,
                child: Image.asset('assets/images/logo.png'),
              ),
              SizedBox(height: 20),
              AnimatedOpacity(
                opacity: 1.0,
                duration: Duration(seconds: 2),
                child: Text(
                  'College',
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
