import 'package:attendance_geetai/screen/dashboard.dart';
import 'package:attendance_geetai/screen/leaveHistroy.dart';
import 'package:attendance_geetai/screen2/attendance_History.dart';
import 'package:attendance_geetai/screen2/leaveApplication.dart';
import 'package:attendance_geetai/screen2/profile.dart';
import 'package:attendance_geetai/screen2/markattendance.dart';
import 'package:attendance_geetai/screen2/visitAttenadence.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BottomNavigationBarExample extends StatefulWidget {
  const BottomNavigationBarExample({super.key});

  @override
  State<BottomNavigationBarExample> createState() =>
      BottomNavigationBarExampleState();
}

class BottomNavigationBarExampleState
    extends State<BottomNavigationBarExample> with TickerProviderStateMixin {
 
  String _username = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
 int selectedIndex = 0; // 👈 made public
  final navigatorKeys = [ // 👈 made public
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void navigateToTab(int index, String route) {
    setState(() {
      selectedIndex = index;
      navigatorKeys[index].currentState?.pushNamedAndRemoveUntil(route, (route) => false);
    });
  
}


  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _loadUsername();


  
 _screens = [
  // Home Navigator
  Navigator(
    key: navigatorKeys[0],
    onGenerateRoute: (settings) {
      WidgetBuilder builder;
      switch (settings.name) {
        case '/a1':
          builder = (_) => MyHomePage();
          break;
        case '/a2':
          builder = (_) => Visitattendance();
          break;
        default:
          builder = (_) => DashboardScreen();
      }
      return MaterialPageRoute(builder: builder, settings: settings);
    },
  ),

  // History Navigator
  Navigator(
    key: navigatorKeys[1],
    onGenerateRoute: (settings) {
      WidgetBuilder builder;
      switch (settings.name) {
        case '/b2':
          builder = (_) => Visitattendance();
          break;
        default:
          builder = (_) => AttendanceHistoryPage();
      }
      return MaterialPageRoute(builder: builder, settings: settings);
    },
  ),

  // ✅ Leave Navigator
  Navigator(
    key: navigatorKeys[2],
    onGenerateRoute: (settings) {
      WidgetBuilder builder;
      switch (settings.name) {
        case '/l1':
          builder = (_) => LeaveScreen(); // Second screen
          break;
        case '/l2':
        default:
          builder = (_) => LeaveApplicationForm(); // Default screen
      }
      return MaterialPageRoute(builder: builder, settings: settings);
    },
  ),

  // Profile screen
  UserProfile(),
];



    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('userName') ?? 'Welcome';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      selectedIndex = index;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(
          index: selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Color(0xFF021526),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
          ],
          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Color.fromARGB(255, 145, 145, 145),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.exit_to_app),
              label: 'Leave',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

