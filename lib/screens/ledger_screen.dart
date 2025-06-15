import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../widgets/transaction_item.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  final SmsService _smsService = SmsService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _showExpenses = true; // true for expenses, false for income
  SmsPermissionResult? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check permission status first
      _permissionStatus = await _smsService.requestSmsPermission();
      
      // Load transactions (will return sample data if no permission)
      final transactions = await _smsService.getTransactions();
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      // Show permission dialog if needed
      if (_permissionStatus != SmsPermissionResult.granted && mounted) {
        _showPermissionDialog();
      }
    } catch (e) {
      setState(() {
        _transactions = _smsService.getSampleTransactions();
        _isLoading = false;
      });
    }
  }

  void _showPermissionDialog() {
    String title;
    String message;
    List<Widget> actions;

    switch (_permissionStatus) {
      case SmsPermissionResult.restricted:
        title = 'SMS Permission Restricted';
        message = 'Android has restricted SMS access for security. To enable SMS reading:\n\n'
            '1. Tap "Open Settings" below\n'
            '2. Find "SMS Ledger" in the app list\n'
            '3. Tap "More" → "Allow restricted settings"\n'
            '4. Follow the on-screen instructions\n'
            '5. Grant SMS permission\n\n'
            'This app needs SMS access to read your bank transaction messages.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Demo Data'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _smsService.openRestrictedSettings();
            },
            child: const Text('Open Settings'),
          ),
        ];
        break;
      case SmsPermissionResult.permanentlyDenied:
        title = 'SMS Permission Required';
        message = 'SMS permission has been permanently denied. To enable SMS reading:\n\n'
            '1. Tap "Open Settings" below\n'
            '2. Find "Permissions" or "App permissions"\n'
            '3. Enable SMS permission\n\n'
            'This app needs SMS access to read your bank transaction messages.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Demo Data'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _smsService.openPermissionSettings();
            },
            child: const Text('Open Settings'),
          ),
        ];
        break;
      case SmsPermissionResult.denied:
        title = 'SMS Permission Needed';
        message = 'This app needs SMS permission to read your bank transaction messages. '
            'Would you like to grant permission now?';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Demo Data'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _loadTransactions();
            },
            child: const Text('Grant Permission'),
          ),
        ];
        break;
      default:
        return; // Don't show dialog for granted permission
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: actions,
        );
      },
    );
  }

  List<Transaction> get _filteredTransactions {
    return _transactions.where((transaction) {
      return _showExpenses ? !transaction.isCredit : transaction.isCredit;
    }).toList();
  }

  double get _totalAmount {
    return _filteredTransactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Ledger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
            tooltip: 'Refresh Transactions',
          ),
          if (_permissionStatus != SmsPermissionResult.granted)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _showPermissionDialog,
              tooltip: 'Permission Settings',
            ),
        ],
      ),
      body: Column(
        children: [
          // Permission status banner
          if (_permissionStatus != SmsPermissionResult.granted)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.orange.shade100,
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _permissionStatus == SmsPermissionResult.restricted
                          ? 'SMS access restricted - showing demo data'
                          : 'SMS permission needed - showing demo data',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: _showPermissionDialog,
                    child: const Text('Fix'),
                  ),
                ],
              ),
            ),
          
          // Toggle Switch
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Income',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _showExpenses ? FontWeight.normal : FontWeight.bold,
                    color: _showExpenses ? Colors.grey : Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _showExpenses,
                  onChanged: (value) {
                    setState(() {
                      _showExpenses = value;
                    });
                  },
                  activeColor: Colors.red,
                  inactiveThumbColor: Colors.green,
                ),
                const SizedBox(width: 16),
                Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                    color: _showExpenses ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Total Amount
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total ${_showExpenses ? 'Expenses' : 'Income'}:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₹${NumberFormat('#,##,###.00').format(_totalAmount)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _showExpenses ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Transaction List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showExpenses ? Icons.money_off : Icons.attach_money,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_showExpenses ? 'expenses' : 'income'} found',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Pull down to refresh',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadTransactions,
                        child: ListView.builder(
                          itemCount: _filteredTransactions.length,
                          itemBuilder: (context, index) {
                            return TransactionItem(
                              transaction: _filteredTransactions[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
} 