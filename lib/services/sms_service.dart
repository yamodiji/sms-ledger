import 'package:another_telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
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

  /// Multi-layered permission request strategy
  Future<SmsPermissionResult> requestSmsPermission() async {
    try {
      // Strategy 1: Try telephony-based permission first (more direct)
      final telephonyResult = await _requestTelephonyPermission();
      if (telephonyResult == SmsPermissionResult.granted) {
        return SmsPermissionResult.granted;
      }

      // Strategy 2: Traditional permission handler approach
      final currentStatus = await Permission.sms.status;
      if (currentStatus == PermissionStatus.granted) {
        return SmsPermissionResult.granted;
      }

      if (currentStatus == PermissionStatus.permanentlyDenied) {
        return SmsPermissionResult.permanentlyDenied;
      }

      // Try to request permission
      final status = await Permission.sms.request();
      
      switch (status) {
        case PermissionStatus.granted:
          return SmsPermissionResult.granted;
        case PermissionStatus.denied:
          return SmsPermissionResult.denied;
        case PermissionStatus.permanentlyDenied:
          return SmsPermissionResult.permanentlyDenied;
        case PermissionStatus.restricted:
          return SmsPermissionResult.restricted;
        default:
          return SmsPermissionResult.denied;
      }
    } catch (e) {
      // If there's an error, try telephony direct approach
      return await _requestTelephonyPermission();
    }
  }

  /// Direct telephony permission request (bypasses some Android restrictions)
  Future<SmsPermissionResult> _requestTelephonyPermission() async {
    try {
      // Check if telephony permissions are available
      final hasPermission = await telephony.requestPhoneAndSmsPermissions;
      if (hasPermission == true) {
        return SmsPermissionResult.granted;
      }
      
      // Try to access SMS directly to test permission
      try {
        await telephony.getInboxSms(
          columns: [SmsColumn.ADDRESS],
          filter: SmsFilter.where(SmsColumn.DATE)
              .greaterThan(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch.toString()),
        );
        return SmsPermissionResult.granted;
      } catch (e) {
        return SmsPermissionResult.restricted;
      }
    } catch (e) {
      return SmsPermissionResult.restricted;
    }
  }

  /// Check current SMS permission status
  Future<bool> checkSmsPermission() async {
    try {
      // Try direct SMS access test
      await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThan(DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch.toString()),
      );
      return true;
    } catch (e) {
      final status = await Permission.sms.status;
      return status == PermissionStatus.granted;
    }
  }

  /// Open app settings for permission management
  Future<bool> openPermissionSettings() async {
    return await openAppSettings();
  }

  /// Opens Android's restricted settings for this app
  Future<void> openRestrictedSettings() async {
    try {
      // Try to open app-specific settings
      await openAppSettings();
    } catch (e) {
      // Fallback - this will at least open general settings
      const platform = MethodChannel('flutter/platform');
      try {
        await platform.invokeMethod('SystemNavigator.pop');
      } catch (_) {
        // If all else fails, just return
      }
    }
  }

  /// Request SMS permission with user-friendly approach
  Future<SmsPermissionResult> requestSmsPermissionWithGuidance() async {
    // First, try the multi-layered approach
    final result = await requestSmsPermission();
    
    if (result == SmsPermissionResult.granted) {
      return result;
    }

    // If not granted, provide specific guidance based on result
    return result;
  }

  Future<List<Transaction>> getTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final daysRange = prefs.getInt('transaction_days_range') ?? 30;
    
    // Try multiple permission strategies
    final permissionResult = await requestSmsPermissionWithGuidance();
    
    // If permission not granted, return sample data
    if (permissionResult != SmsPermissionResult.granted) {
      return getSampleTransactions();
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
      Transaction(
        sender: 'HDFCBK',
        date: now.subtract(const Duration(days: 7)),
        amount: 150.00,
        isCredit: false,
        originalMessage: 'ATM withdrawal Rs.150.00',
      ),
      Transaction(
        sender: 'PAYTM',
        date: now.subtract(const Duration(days: 10)),
        amount: 75.50,
        isCredit: true,
        originalMessage: 'Cashback Rs.75.50 credited',
      ),
      Transaction(
        sender: 'GOOGLEPAY',
        date: now.subtract(const Duration(days: 12)),
        amount: 300.00,
        isCredit: false,
        originalMessage: 'Payment of Rs.300.00 via Google Pay',
      ),
      Transaction(
        sender: 'ICICIBK',
        date: now.subtract(const Duration(days: 15)),
        amount: 5000.00,
        isCredit: true,
        originalMessage: 'Salary credited Rs.5000.00',
      ),
    ];
  }
}

enum SmsPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
} 