import 'package:attendance_geetai/login_screen.dart';
import 'package:flutter/material.dart';

class Option extends StatefulWidget {
  @override
  _OptionState createState() => _OptionState();
}

class _OptionState extends State<Option> {
  String? _selectedInstitute;
  final List<String> _institutes = [
    'Institute A',
    'Institute B',
  ];

  void _navigateToPage(String institute) {
    // You can apply different navigation if needed
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050A30),
      body: Stack(
        children: [
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(100),
                ),
              ),
              child: _buildDropdownView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 50),
          const Text(
            "Please Select the Institute",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Image.asset(
            'assets/images/DropDownScreenImage.png',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 50),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              "Select the Appropriate Institute for Proceeding Further",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: DropdownButtonFormField<String>(
              value: _selectedInstitute,
              hint: const Text(
                'Select an institute',
                style: TextStyle(color: Colors.black, fontSize: 16),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF5F3F3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
              dropdownColor: const Color(0xFF050A30),
              iconEnabledColor: Colors.black,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              items: _institutes.map((String institute) {
                return DropdownMenuItem<String>(
                  value: institute,
                  child: Text(
                    institute,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedInstitute = value;
                });
                if (_selectedInstitute != null) {
                  _navigateToPage(_selectedInstitute!);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
