import 'package:another_telephony/telephony.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;
  static const platform = MethodChannel('sms_ledger/permissions');

  // Keywords for identifying transaction messages
  static const List<String> debitKeywords = [
    'debited',
    'withdrawn',
    'spent',
    'paid',
    'debit',
    'purchase',
    'transaction',
    'charged',
  ];

  static const List<String> creditKeywords = [
    'credited',
    'received',
    'deposited',
    'credit',
    'refund',
    'cashback',
    'salary',
    'transfer',
  ];

  /// Request SMS permission using proper Android system
  Future<bool> requestSmsPermission() async {
    try {
      // First try the telephony package approach
      final bool? telephonyResult = await telephony.requestPhoneAndSmsPermissions;
      if (telephonyResult == true) {
        return true;
      }

      // If that fails, try platform channel approach
      try {
        final bool result = await platform.invokeMethod('requestSmsPermission');
        return result;
      } catch (e) {
        // Fallback to telephony result
        return telephonyResult == true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Check if SMS permission is already granted
  Future<bool> checkSmsPermission() async {
    try {
      // Try platform channel first
      try {
        final bool result = await platform.invokeMethod('checkSmsPermission');
        return result;
      } catch (e) {
        // Fallback to telephony test
        await telephony.getInboxSms(
          columns: [SmsColumn.ADDRESS],
          filter: SmsFilter.where(SmsColumn.DATE)
              .greaterThan(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch.toString()),
        );
        return true;
      }
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for manual permission grant
  Future<void> openAppSettings() async {
    try {
      await platform.invokeMethod('openAppSettings');
    } catch (e) {
      // Silently fail if platform channel not available
    }
  }

  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final daysRange = prefs.getInt('transaction_days_range') ?? 30;
    
    // Check if we have permission
    final hasPermission = await checkSmsPermission();
    
    // If no permission, try to request it
    if (!hasPermission) {
      final granted = await requestSmsPermission();
      if (!granted) {
        // Return sample data if permission denied
        return getSampleTransactions();
      }
    }

    final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysRange));
    
    try {
      final List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThan(cutoffDate.millisecondsSinceEpoch.toString()),
      );

      final List<Transaction> transactions = [];

      for (final message in messages) {
        final transaction = _parseTransaction(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      // Sort by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      // Error reading SMS messages - return sample data for demo
      return getSampleTransactions();
    }
  }

  Transaction? _parseTransaction(SmsMessage message) {
    final String body = message.body?.toLowerCase() ?? '';
    final String sender = message.address ?? 'Unknown';
    
    // Check if message contains transaction keywords
    final bool isDebit = debitKeywords.any((keyword) => body.contains(keyword));
    final bool isCredit = creditKeywords.any((keyword) => body.contains(keyword));
    
    if (!isDebit && !isCredit) {
      return null; // Not a transaction message
    }

    // Extract amount using regex
    final RegExp amountRegex = RegExp(r'(?:rs\.?|inr|₹)\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false);
    final Match? match = amountRegex.firstMatch(body);
    
    if (match == null) {
      return null; // No amount found
    }

    final String amountStr = match.group(1)!.replaceAll(',', '');
    final double amount = double.tryParse(amountStr) ?? 0.0;
    
    if (amount == 0.0) {
      return null; // Invalid amount
    }

    // Determine bank from sender
    final String bank = _getBankFromSender(sender);
    
    return Transaction(
      id: message.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      isCredit: isCredit,
      sender: sender,
      bank: bank,
      date: DateTime.fromMillisecondsSinceEpoch(message.date ?? DateTime.now().millisecondsSinceEpoch),
      description: message.body ?? '',
    );
  }

  String _getBankFromSender(String sender) {
    final String lowerSender = sender.toLowerCase();
    
    if (lowerSender.contains('hdfc')) return 'HDFC';
    if (lowerSender.contains('icici')) return 'ICICI';
    if (lowerSender.contains('sbi')) return 'SBI';
    if (lowerSender.contains('axis')) return 'Axis';
    if (lowerSender.contains('kotak')) return 'Kotak';
    if (lowerSender.contains('pnb')) return 'PNB';
    if (lowerSender.contains('bob')) return 'BOB';
    if (lowerSender.contains('canara')) return 'Canara';
    if (lowerSender.contains('union')) return 'Union';
    if (lowerSender.contains('indian')) return 'Indian';
    
    return 'Other';
  }

  List<Transaction> getSampleTransactions() {
    return [
      Transaction(
        id: '1',
        amount: 2500.00,
        isCredit: false,
        sender: 'HDFC-BANK',
        bank: 'HDFC',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        description: 'Amount debited from your account for UPI transaction',
      ),
      Transaction(
        id: '2',
        amount: 5000.00,
        isCredit: true,
        sender: 'ICICI-BANK',
        bank: 'ICICI',
        date: DateTime.now().subtract(const Duration(days: 1)),
        description: 'Amount credited to your account - salary transfer',
      ),
      Transaction(
        id: '3',
        amount: 150.00,
        isCredit: false,
        sender: 'SBI-BANK',
        bank: 'SBI',
        date: DateTime.now().subtract(const Duration(days: 2)),
        description: 'ATM withdrawal transaction completed',
      ),
      Transaction(
        id: '4',
        amount: 1200.00,
        isCredit: true,
        sender: 'AXIS-BANK',
        bank: 'Axis',
        date: DateTime.now().subtract(const Duration(days: 3)),
        description: 'Cashback credited for online purchase',
      ),
      Transaction(
        id: '5',
        amount: 800.00,
        isCredit: false,
        sender: 'HDFC-BANK',
        bank: 'HDFC',
        date: DateTime.now().subtract(const Duration(days: 4)),
        description: 'Bill payment transaction successful',
      ),
    ];
  }
} 