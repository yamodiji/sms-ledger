import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

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

  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status == PermissionStatus.granted;
  }

  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final daysRange = prefs.getInt('transaction_days_range') ?? 30;
    
    final hasPermission = await requestSmsPermission();
    if (!hasPermission) {
      return [];
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
      // Error reading SMS messages - return empty list
      return [];
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
    final double? amount = _extractAmount(body);
    if (amount == null) {
      return null;
    }

    // Convert timestamp to DateTime
    final DateTime date = DateTime.fromMillisecondsSinceEpoch(
      int.tryParse(message.date.toString()) ?? DateTime.now().millisecondsSinceEpoch,
    );

    return Transaction(
      sender: sender,
      date: date,
      amount: amount,
      isCredit: isCredit,
      originalMessage: message.body ?? '',
    );
  }

  double? _extractAmount(String text) {
    // Common patterns for amount extraction
    final List<RegExp> patterns = [
      RegExp(r'rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'inr\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'amount\s*:?\s*rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'amount\s*:?\s*₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)', caseSensitive: false),
      RegExp(r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:rs|inr|₹)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        final amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }

    return null;
  }

  // Generate sample transactions for testing
  List<Transaction> getSampleTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        sender: 'HDFCBK',
        date: now.subtract(const Duration(days: 1)),
        amount: 500.00,
        isCredit: false,
        originalMessage: 'Your account has been debited with Rs.500.00',
      ),
      Transaction(
        sender: 'ICICIBK',
        date: now.subtract(const Duration(days: 2)),
        amount: 1200.50,
        isCredit: true,
        originalMessage: 'Your account has been credited with Rs.1200.50',
      ),
      Transaction(
        sender: 'SBIIN',
        date: now.subtract(const Duration(days: 3)),
        amount: 250.00,
        isCredit: false,
        originalMessage: 'Amount Rs.250.00 debited from your account',
      ),
      Transaction(
        sender: 'AXISBK',
        date: now.subtract(const Duration(days: 5)),
        amount: 2500.00,
        isCredit: true,
        originalMessage: 'Rs.2500.00 credited to your account',
      ),
    ];
  }
} 