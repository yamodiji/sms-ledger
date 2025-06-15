import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:another_telephony/telephony.dart';
import 'screens/ledger_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMS Ledger',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _permissionRequested = false;

  final List<Widget> _screens = [
    const LedgerScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _requestPermissionsEarly();
  }

  /// Early permission request strategy for better user experience
  Future<void> _requestPermissionsEarly() async {
    if (_permissionRequested) return;
    _permissionRequested = true;

    try {
      // Strategy 1: Try telephony-based permission first (more direct for Android 13+)
      final telephony = Telephony.instance;
      
      // Check if we can request telephony permissions directly
      try {
        final hasPermission = await telephony.requestPhoneAndSmsPermissions;
        if (hasPermission == true) {
          return; // Success with telephony approach
        }
      } catch (e) {
        // Continue to traditional approach
      }

      // Strategy 2: Traditional permission request
      final currentStatus = await Permission.sms.status;
      
      if (currentStatus == PermissionStatus.granted) {
        return; // Already granted
      }

      if (currentStatus == PermissionStatus.permanentlyDenied) {
        return; // Don't request if permanently denied
      }

      // Try to request permission silently
      await Permission.sms.request();
      
    } catch (e) {
      // Silently handle errors - the app will work with demo data
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
} 