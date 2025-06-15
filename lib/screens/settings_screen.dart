import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedDays = prefs.getInt('transaction_days_range') ?? 30;
    });
  }

  Future<void> _saveSettings(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('transaction_days_range', days);
    setState(() {
      _selectedDays = days;
    });
  }

  void _showRangeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction History Range',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Last 30 Days'),
                trailing: _selectedDays == 30 
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _saveSettings(30);
                  Navigator.pop(context);
                  _showSuccessMessage('Range updated to Last 30 Days');
                },
              ),
              ListTile(
                title: const Text('Last 3 Months'),
                trailing: _selectedDays == 90 
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _saveSettings(90);
                  Navigator.pop(context);
                  _showSuccessMessage('Range updated to Last 3 Months');
                },
              ),
              ListTile(
                title: const Text('Last 6 Months'),
                trailing: _selectedDays == 180 
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  _saveSettings(180);
                  Navigator.pop(context);
                  _showSuccessMessage('Range updated to Last 6 Months');
                },
              ),
              ListTile(
                title: const Text('Custom Days'),
                trailing: ![30, 90, 180].contains(_selectedDays)
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () {
                  Navigator.pop(context);
                  _showCustomRangePicker();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCustomRangePicker() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Custom Range'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter number of days:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Days',
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 60',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final days = int.tryParse(controller.text);
                if (days != null && days > 0 && days <= 365) {
                  _saveSettings(days);
                  Navigator.pop(context);
                  _showSuccessMessage('Range updated to $days days');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid number between 1 and 365'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _getRangeText() {
    switch (_selectedDays) {
      case 30:
        return 'Last 30 Days';
      case 90:
        return 'Last 3 Months';
      case 180:
        return 'Last 6 Months';
      default:
        return '$_selectedDays Days';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Transaction History Range Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure how far back to scan for SMS transactions',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Transaction History Range'),
                    subtitle: Text(_getRangeText()),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showRangeSelector,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // App Information Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'App Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    title: Text('Version'),
                    subtitle: Text('1.0.0'),
                    leading: Icon(Icons.info_outline),
                  ),
                  ListTile(
                    title: const Text('About'),
                    subtitle: const Text('SMS Ledger - Track your transactions'),
                    leading: const Icon(Icons.description),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: 'SMS Ledger',
                        applicationVersion: '1.0.0',
                        applicationIcon: const Icon(Icons.account_balance_wallet),
                        children: const [
                          Text('A Flutter app for parsing and tracking SMS transactions from banks.'),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Permissions Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Permissions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const ListTile(
                    title: Text('SMS Permission'),
                    subtitle: Text('Required to read transaction messages'),
                    leading: Icon(Icons.sms),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'This app needs SMS permission to read transaction messages from your bank. '
                      'No personal messages are accessed, only transaction-related SMS.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 