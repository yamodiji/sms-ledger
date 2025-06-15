import 'package:another_telephony/telephony.dart';
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

  /// Request SMS permission using the standard Android permission dialog
  /// This will show the original dialog with "Allow while using the app" and "Don't allow"
  Future<bool> requestSmsPermission() async {
    try {
      // Check if permission is already granted
      bool? permissionsGranted = await telephony.requestPhoneAndSmsPermissions;
      
      if (permissionsGranted == true) {
        return true;
      }
      
      // If not granted, the system will show the standard permission dialog
      // with "Allow while using the app" and "Don't allow" options
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if SMS permission is granted
  Future<bool> hasPermission() async {
    try {
      return await telephony.requestPhoneAndSmsPermissions ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get SMS transactions from the device
  Future<List<Transaction>> getTransactions({int days = 30}) async {
    try {
      // Check permission first
      bool hasPermission = await this.hasPermission();
      if (!hasPermission) {
        // Return demo data if no permission
        return _getDemoTransactions();
      }

      // Get SMS messages from the specified number of days
      final DateTime fromDate = DateTime.now().subtract(Duration(days: days));
      
      List<SmsMessage> messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThan(fromDate.millisecondsSinceEpoch.toString()),
      );

      List<Transaction> transactions = [];
      
      for (SmsMessage message in messages) {
        Transaction? transaction = _parseTransaction(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      // Sort by date (newest first)
      transactions.sort((a, b) => b.date.compareTo(a.date));
      
      return transactions;
    } catch (e) {
      // Return demo data on error
      return _getDemoTransactions();
    }
  }

  /// Parse SMS message into transaction
  Transaction? _parseTransaction(SmsMessage message) {
    try {
      String body = message.body ?? '';
      String sender = message.address ?? 'Unknown';
      DateTime date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

      // Check if it's a transaction message
      bool isDebit = debitKeywords.any((keyword) => 
          body.toLowerCase().contains(keyword.toLowerCase()));
      bool isCredit = creditKeywords.any((keyword) => 
          body.toLowerCase().contains(keyword.toLowerCase()));

      if (!isDebit && !isCredit) {
        return null; // Not a transaction message
      }

      // Extract amount using regex
      double? amount = _extractAmount(body);
      if (amount == null) {
        return null; // No amount found
      }

      // Determine bank from sender
      String bank = _extractBank(sender);

      return Transaction(
        id: message.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        sender: sender,
        date: date,
        amount: amount,
        isCredit: isCredit,
        bank: bank,
        description: body,
      );
    } catch (e) {
      return null;
    }
  }

  /// Extract amount from SMS text
  double? _extractAmount(String text) {
    // Common patterns for amounts in Indian SMS
    List<RegExp> patterns = [
      RegExp(r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{2})?)\s*(?:rs\.?|inr|₹)', caseSensitive: false),
      RegExp(r'amount\s*(?:of\s*)?(?:rs\.?|inr|₹)?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
    ];

    for (RegExp pattern in patterns) {
      Match? match = pattern.firstMatch(text);
      if (match != null) {
        String amountStr = match.group(1)!.replaceAll(',', '');
        double? amount = double.tryParse(amountStr);
        if (amount != null && amount > 0) {
          return amount;
        }
      }
    }
    return null;
  }

  /// Extract bank name from sender
  String _extractBank(String sender) {
    String senderLower = sender.toLowerCase();
    
    if (senderLower.contains('hdfc')) return 'HDFC Bank';
    if (senderLower.contains('icici')) return 'ICICI Bank';
    if (senderLower.contains('sbi')) return 'State Bank of India';
    if (senderLower.contains('axis')) return 'Axis Bank';
    if (senderLower.contains('kotak')) return 'Kotak Bank';
    if (senderLower.contains('paytm')) return 'Paytm';
    if (senderLower.contains('phonepe')) return 'PhonePe';
    if (senderLower.contains('gpay') || senderLower.contains('googlepay')) return 'Google Pay';
    
    return 'Other Bank';
  }

  /// Get demo transactions for testing
  List<Transaction> _getDemoTransactions() {
    return [
      Transaction(
        id: '1',
        sender: 'HDFC-BANK',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        amount: 500.00,
        isCredit: false,
        bank: 'HDFC Bank',
        description: 'Amount debited: Rs.500.00 from A/c XX1234 on 15-Jan-25. Available balance: Rs.15,000.00',
      ),
      Transaction(
        id: '2',
        sender: 'ICICI-BANK',
        date: DateTime.now().subtract(const Duration(days: 1)),
        amount: 2500.00,
        isCredit: true,
        bank: 'ICICI Bank',
        description: 'Amount credited: Rs.2,500.00 to A/c XX5678 on 14-Jan-25. Available balance: Rs.17,500.00',
      ),
      Transaction(
        id: '3',
        sender: 'SBI',
        date: DateTime.now().subtract(const Duration(days: 2)),
        amount: 150.00,
        isCredit: false,
        bank: 'State Bank of India',
        description: 'Amount debited: Rs.150.00 from A/c XX9012 on 13-Jan-25. Available balance: Rs.15,000.00',
      ),
      Transaction(
        id: '4',
        sender: 'AXIS-BANK',
        date: DateTime.now().subtract(const Duration(days: 3)),
        amount: 1000.00,
        isCredit: true,
        bank: 'Axis Bank',
        description: 'Amount credited: Rs.1,000.00 to A/c XX3456 on 12-Jan-25. Available balance: Rs.15,150.00',
      ),
    ];
  }
} 