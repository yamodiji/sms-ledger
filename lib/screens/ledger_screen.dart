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
      _permissionStatus = await _smsService.requestSmsPermissionWithGuidance();
      
      // Load transactions (will return sample data if no permission)
      final transactions = await _smsService.getTransactions();
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });

      // Show permission dialog if needed
      if (_permissionStatus != SmsPermissionResult.granted && mounted) {
        _showSimplePermissionDialog();
      }
    } catch (e) {
      setState(() {
        _transactions = _smsService.getSampleTransactions();
        _isLoading = false;
      });
    }
  }

  void _showSimplePermissionDialog() {
    String title;
    String message;
    List<Widget> actions;

    switch (_permissionStatus) {
      case SmsPermissionResult.restricted:
        title = '📱 Enable SMS Access';
        message = 'To show your real bank transactions, please:\n\n'
            '1️⃣ Tap "Settings" below\n'
            '2️⃣ Find "SMS Ledger" app\n'
            '3️⃣ Tap the menu (⋮) and select "Allow restricted settings"\n'
            '4️⃣ Turn ON SMS permission\n\n'
            '✅ Your SMS data stays private on your phone\n'
            '✅ We only read bank transaction messages';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Demo Mode'),
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
        title = '📱 SMS Permission Needed';
        message = 'To read your bank transaction messages:\n\n'
            '1️⃣ Tap "Settings" below\n'
            '2️⃣ Find "Permissions"\n'
            '3️⃣ Turn ON SMS permission\n\n'
            '✅ Safe: Only reads bank messages\n'
            '✅ Private: Data stays on your phone';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Demo Mode'),
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
        title = '📱 Allow SMS Access?';
        message = 'SMS Ledger needs to read your bank transaction messages to track your expenses and income.\n\n'
            '✅ Only reads bank messages (HDFC, ICICI, SBI, etc.)\n'
            '✅ Your personal messages are never accessed\n'
            '✅ All data stays on your phone\n\n'
            'Would you like to allow SMS access?';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Use Demo Mode'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _loadTransactions();
            },
            child: const Text('Allow SMS'),
          ),
        ];
        break;
      default:
        return; // Don't show dialog for granted permission
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 18)),
          content: Text(message, style: const TextStyle(fontSize: 14)),
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
              icon: const Icon(Icons.help_outline),
              onPressed: _showSimplePermissionDialog,
              tooltip: 'Help with SMS Access',
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
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _permissionStatus == SmsPermissionResult.restricted
                          ? '📱 Enable SMS access to see your real transactions'
                          : '📱 SMS access needed for real transaction data',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: _showSimplePermissionDialog,
                    child: const Text('Help', style: TextStyle(fontSize: 12)),
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

          // Demo data notice
          if (_permissionStatus != SmsPermissionResult.granted)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility, color: Colors.amber.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Showing demo transactions. Enable SMS access to see your real bank transactions.',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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