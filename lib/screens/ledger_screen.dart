import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../services/sms_service.dart';
import '../widgets/transaction_item.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> with TickerProviderStateMixin {
  final SmsService _smsService = SmsService();
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  bool _showExpenses = true;
  String _errorMessage = '';
  String _selectedFilter = 'ALL';
  DateTime? _selectedDate;
  
  late TabController _filterTabController;

  final List<String> _filterTabs = ['ALL', 'DEBIT CARD', 'CREDIT CARD', 'UPI'];

  @override
  void initState() {
    super.initState();
    _filterTabController = TabController(length: _filterTabs.length, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _filterTabController.dispose();
    super.dispose();
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
    List<Transaction> filtered = _transactions;

    // Filter by income/expense
    filtered = filtered.where((transaction) {
      return _showExpenses ? !transaction.isCredit : transaction.isCredit;
    }).toList();

    // Filter by transaction type
    if (_selectedFilter != 'ALL') {
      String filterType = _selectedFilter.replaceAll(' ', '_');
      filtered = filtered.where((transaction) {
        return transaction.transactionType == filterType;
      }).toList();
    }

    // Filter by date if selected
    if (_selectedDate != null) {
      filtered = filtered.where((transaction) {
        return transaction.date.year == _selectedDate!.year &&
               transaction.date.month == _selectedDate!.month &&
               transaction.date.day == _selectedDate!.day;
      }).toList();
    }

    return filtered;
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  void _showFilterMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Transaction Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: _filterTabs.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      Navigator.pop(context);
                    },
                    selectedColor: Colors.blue.withValues(alpha: 0.2),
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              const Text(
                'Date Filter',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate != null 
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Select Date'),
                    ),
                  ),
                  if (_selectedDate != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _clearDateFilter,
                      icon: const Icon(Icons.clear),
                      tooltip: 'Clear date filter',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Ledger'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _showFilterMenu,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter transactions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Calendar and Income/Expense Toggle
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                // Calendar Row
                Row(
                  children: [
                    IconButton(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today, color: Colors.blue),
                      tooltip: 'Select date',
                    ),
                    Expanded(
                      child: Text(
                        _selectedDate != null 
                          ? 'Transactions for ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'All transactions',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_selectedDate != null)
                      IconButton(
                        onPressed: _clearDateFilter,
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        tooltip: 'Clear date filter',
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Income/Expense Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Income',
                      style: TextStyle(
                        color: !_showExpenses ? Colors.green[600] : Colors.grey,
                        fontWeight: !_showExpenses ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
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
                      activeColor: Colors.red[600],
                      inactiveThumbColor: Colors.green[600],
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Expenses',
                      style: TextStyle(
                        color: _showExpenses ? Colors.red[600] : Colors.grey,
                        fontWeight: _showExpenses ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Filter Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _filterTabController,
              isScrollable: true,
              labelColor: Colors.blue[600],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.blue[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              onTap: (index) {
                setState(() {
                  _selectedFilter = _filterTabs[index];
                });
              },
              tabs: _filterTabs.map((filter) => Tab(text: filter)).toList(),
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
                                  _selectedFilter != 'ALL' 
                                    ? 'No $_selectedFilter transactions found'
                                    : _showExpenses ? 'No expenses found' : 'No income found',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedDate != null 
                                    ? 'Try selecting a different date'
                                    : 'Transaction messages will appear here',
                                  style: const TextStyle(color: Colors.grey),
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