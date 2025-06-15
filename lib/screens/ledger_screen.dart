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
  bool _showExpenses = true;
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];
  bool _isLoading = true;
  final SmsService _smsService = SmsService();

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
      List<Transaction> transactions = await _smsService.getTransactions();
      
      if (transactions.isEmpty) {
        transactions = _smsService.getSampleTransactions();
      }

      setState(() {
        _allTransactions = transactions;
        _filterTransactions();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _allTransactions = _smsService.getSampleTransactions();
        _filterTransactions();
        _isLoading = false;
      });
    }
  }

  void _filterTransactions() {
    setState(() {
      if (_showExpenses) {
        _filteredTransactions = _allTransactions
            .where((transaction) => !transaction.isCredit)
            .toList();
      } else {
        _filteredTransactions = _allTransactions
            .where((transaction) => transaction.isCredit)
            .toList();
      }
    });
  }

  void _toggleTransactionType(bool showExpenses) {
    setState(() {
      _showExpenses = showExpenses;
      _filterTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Income',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: !_showExpenses ? FontWeight.bold : FontWeight.normal,
                    color: !_showExpenses ? Colors.green : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Switch(
                  value: _showExpenses,
                  onChanged: _toggleTransactionType,
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
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _showExpenses ? Colors.red[50] : Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showExpenses ? Colors.red[200]! : Colors.green[200]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showExpenses ? 'Total Expenses' : 'Total Income',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getTotalAmount(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _showExpenses ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
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
                              _showExpenses 
                                  ? 'No expenses found'
                                  : 'No income found',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
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

  String _getTotalAmount() {
    double total = 0;
    for (final transaction in _filteredTransactions) {
      total += transaction.amount;
    }
    
    final prefix = _showExpenses ? '-₹' : '+₹';
    return '$prefix${total.toStringAsFixed(2)}';
  }
} 