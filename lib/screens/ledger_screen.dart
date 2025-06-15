import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../widgets/transaction_item.dart';
import '../widgets/permission_dialog.dart';

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
  bool _hasShownPermissionDialog = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if we should ask for permission
      final shouldAsk = await _smsService.shouldAskPermissionAgain();
      final hasPermission = await _smsService.checkSmsPermission();
      
      if (!hasPermission && shouldAsk && !_hasShownPermissionDialog) {
        _hasShownPermissionDialog = true;
        // Show native-style permission dialog immediately
        _showNativePermissionDialog();
      }
      
      await _loadTransactions();
    } catch (e) {
      await _loadTransactions();
    }
  }

  Future<void> _loadTransactions() async {
    try {
      // Load transactions (will return sample data if no permission)
      final transactions = await _smsService.getTransactions();
      final hasPermission = await _smsService.checkSmsPermission();
      
      setState(() {
        _transactions = transactions;
        _isLoading = false;
        _permissionStatus = hasPermission 
            ? SmsPermissionResult.granted 
            : SmsPermissionResult.denied;
      });
    } catch (e) {
      setState(() {
        _transactions = _smsService.getSampleTransactions();
        _isLoading = false;
        _permissionStatus = SmsPermissionResult.denied;
      });
    }
  }

  void _showNativePermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PermissionDialog(
          onDontAllow: () async {
            Navigator.of(context).pop();
            await _smsService.savePermissionChoice('dont_allow');
            await _loadTransactions();
          },
          onAllowOnlyThisTime: () async {
            Navigator.of(context).pop();
            await _smsService.savePermissionChoice('only_this_time');
            await _requestPermissionAndLoad();
          },
          onAllowWhileUsingApp: () async {
            Navigator.of(context).pop();
            await _smsService.savePermissionChoice('while_using_app');
            await _requestPermissionAndLoad();
          },
        );
      },
    );
  }

  Future<void> _requestPermissionAndLoad() async {
    try {
      final result = await _smsService.requestSmsPermissionDirect();
      
      if (result == SmsPermissionResult.restricted) {
        // Show restricted settings dialog
        _showRestrictedSettingsDialog();
      } else {
        await _loadTransactions();
      }
    } catch (e) {
      await _loadTransactions();
    }
  }

  void _showRestrictedSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return RestrictedSettingsDialog(
          onOpenSettings: () async {
            Navigator.of(context).pop();
            await _smsService.openPermissionSettings();
          },
          onUseDemoMode: () {
            Navigator.of(context).pop();
          },
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
            onPressed: _checkPermissionAndLoad,
            tooltip: 'Refresh Transactions',
          ),
          if (_permissionStatus != SmsPermissionResult.granted)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                _hasShownPermissionDialog = false;
                _showNativePermissionDialog();
              },
              tooltip: 'SMS Permissions',
            ),
        ],
      ),
      body: Column(
        children: [
          // Permission status banner (only if no permission)
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
                      'Tap the settings icon to enable SMS access for real transactions',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _hasShownPermissionDialog = false;
                      _showNativePermissionDialog();
                    },
                    child: const Text('Enable', style: TextStyle(fontSize: 12)),
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

          // Demo data notice (only if no permission)
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
                        onRefresh: _checkPermissionAndLoad,
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