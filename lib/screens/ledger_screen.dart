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
        _errorMessage = 'Error loading transactions: $e';
        _isLoading = false;
      });
    }
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
          ),
        ],
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
                    fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                    color: _showExpenses ? Colors.red : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          
          // Total Amount Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: _showExpenses ? Colors.red.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showExpenses ? Colors.red.shade200 : Colors.green.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ${_showExpenses ? 'Expenses' : 'Income'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _showExpenses ? Colors.red.shade700 : Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Transactions List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red.shade600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTransactions,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredTransactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showExpenses ? Icons.money_off : Icons.attach_money,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No ${_showExpenses ? 'expenses' : 'income'} found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Transactions will appear here when SMS messages are detected',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: _filteredTransactions.length,
                            itemBuilder: (context, index) {
                              return TransactionItem(
                                transaction: _filteredTransactions[index],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
} 