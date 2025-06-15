import 'package:flutter/material.dart';
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
  bool _showExpenses = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final transactions = await _smsService.getTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Transaction> get filteredTransactions {
    return _transactions.where((transaction) {
      return _showExpenses ? !transaction.isCredit : transaction.isCredit;
    }).toList();
  }

  void _showPermissionHelp() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('SMS Permission Required'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'To read SMS transactions, this app needs SMS permission.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Text('For sideloaded apps (installed from APK), follow these steps:'),
                SizedBox(height: 12),
                Text('1. Go to Settings → Apps'),
                Text('2. Find "SMS Ledger" app'),
                Text('3. Tap the 3-dot menu (⋮) → "Allow restricted settings"'),
                Text('4. Go to Permissions → SMS → Allow'),
                SizedBox(height: 16),
                Text(
                  'Note: Apps from Play Store don\'t have this restriction.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _requestPermission();
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _requestPermission() async {
    final hasPermission = await _smsService.requestSmsPermission();
    if (hasPermission) {
      _loadTransactions();
    } else {
      _showPermissionHelp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Ledger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Toggle Switch
          Container(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Income',
                  style: TextStyle(
                    color: !_showExpenses ? Colors.green : Colors.grey,
                    fontWeight: !_showExpenses ? FontWeight.bold : FontWeight.normal,
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
                    color: _showExpenses ? Colors.red : Colors.grey,
                    fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.sms_failed,
                              size: 64,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'SMS Permission Required',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                'This app needs SMS permission to read transaction messages from your bank.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _requestPermission,
                              icon: const Icon(Icons.security),
                              label: const Text('Grant Permission'),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _showPermissionHelp,
                              child: const Text('Need Help?'),
                            ),
                          ],
                        ),
                      )
                    : filteredTransactions.isEmpty
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
                                  _showExpenses ? 'No expenses found' : 'No income found',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Transaction messages will appear here',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            child: ListView.builder(
                              itemCount: filteredTransactions.length,
                              itemBuilder: (context, index) {
                                return TransactionItem(
                                  transaction: filteredTransactions[index],
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