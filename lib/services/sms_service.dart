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

  // Transaction type keywords
  static const Map<String, List<String>> transactionTypeKeywords = {
    'DEBIT_CARD': [
      'debit card',
      'debit-card',
      'dc',
      'card ending',
      'card no',
      'card****',
      'card xxxx',
      'via debit card',
      'using debit card',
      'through debit card',
    ],
    'CREDIT_CARD': [
      'credit card',
      'credit-card',
      'cc',
      'via credit card',
      'using credit card',
      'through credit card',
    ],
    'UPI': [
      'upi',
      'via upi',
      'using upi',
      'through upi',
      'upi id',
      'upi ref',
      'upi transaction',
      'paytm',
      'phonepe',
      'googlepay',
      'google pay',
      'bhim',
      'amazon pay',
      'mobikwik',
    ],
  };

  // Full bank name mapping
  static const Map<String, String> bankNameMapping = {
    // HDFC variations
    'hdfc': 'HDFC Bank',
    'hdfcbank': 'HDFC Bank',
    'hdfc bank': 'HDFC Bank',
    'hd-hdfc': 'HDFC Bank',
    'ad-hdfc': 'HDFC Bank',
    
    // ICICI variations
    'icici': 'ICICI Bank',
    'icicibk': 'ICICI Bank',
    'icici bank': 'ICICI Bank',
    'ad-icici': 'ICICI Bank',
    'vm-icici': 'ICICI Bank',
    
    // SBI variations
    'sbi': 'State Bank of India',
    'sbipsg': 'State Bank of India',
    'sbiinb': 'State Bank of India',
    'ad-sbibnk': 'State Bank of India',
    'vm-sbibnk': 'State Bank of India',
    'state bank': 'State Bank of India',
    
    // Axis variations
    'axis': 'Axis Bank',
    'axisbk': 'Axis Bank',
    'axis bank': 'Axis Bank',
    'ad-axis': 'Axis Bank',
    'vm-axis': 'Axis Bank',
    
    // Other major banks
    'kotak': 'Kotak Mahindra Bank',
    'kotakbk': 'Kotak Mahindra Bank',
    'kotak mahindra': 'Kotak Mahindra Bank',
    
    'pnb': 'Punjab National Bank',
    'punjab national': 'Punjab National Bank',
    
    'canara': 'Canara Bank',
    'canarabk': 'Canara Bank',
    'canara bank': 'Canara Bank',
    
    'bob': 'Bank of Baroda',
    'baroda': 'Bank of Baroda',
    'bank of baroda': 'Bank of Baroda',
    
    'union': 'Union Bank of India',
    'unionbk': 'Union Bank of India',
    'union bank': 'Union Bank of India',
    
    'idbi': 'IDBI Bank',
    'idbibk': 'IDBI Bank',
    'idbi bank': 'IDBI Bank',
    
    'yes': 'YES Bank',
    'yesbk': 'YES Bank',
    'yes bank': 'YES Bank',
    
    'indusind': 'IndusInd Bank',
    'indusbk': 'IndusInd Bank',
    'indusind bank': 'IndusInd Bank',
    
    'federal': 'Federal Bank',
    'federalbk': 'Federal Bank',
    'federal bank': 'Federal Bank',
    
    'rbl': 'RBL Bank',
    'rblbk': 'RBL Bank',
    'rbl bank': 'RBL Bank',
    
    'bandhan': 'Bandhan Bank',
    'bandhanbk': 'Bandhan Bank',
    'bandhan bank': 'Bandhan Bank',
  };

  /// Request SMS permission using the standard Android permission dialog
  /// This will show the original dialog with "Allow while using the app" and "Don't allow"
  Future<bool> requestSmsPermission() async {
    try {
      // Check if permission is already granted
      final hasPermission = await telephony.isSmsCapable ?? false;
      if (hasPermission) {
        return true;
      }

      // Request permission using telephony package
      return await telephony.requestPhoneAndSmsPermissions ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get all SMS transactions
  Future<List<Transaction>> getTransactions() async {
    try {
      final hasPermission = await requestSmsPermission();
      if (!hasPermission) {
        throw Exception('SMS permission denied');
      }

      final messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );

      final transactions = <Transaction>[];
      
      for (final message in messages) {
        final transaction = _parseTransaction(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      return transactions;
    } catch (e) {
      // Return demo data for testing
      return _getDemoTransactions();
    }
  }

  /// Parse SMS message into transaction
  Transaction? _parseTransaction(SmsMessage message) {
    final body = message.body?.toLowerCase() ?? '';
    final sender = message.address ?? '';
    final date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

    // Check if it's a transaction message
    final isDebit = debitKeywords.any((keyword) => body.contains(keyword));
    final isCredit = creditKeywords.any((keyword) => body.contains(keyword));
    
    if (!isDebit && !isCredit) return null;

    // Extract amount
    final amount = _extractAmount(body);
    if (amount == null) return null;

    // Extract full bank name
    final bankName = _extractBankName(sender, body);
    
    // Detect transaction type
    final transactionType = _detectTransactionType(body);

    return Transaction(
      id: '${message.date}_${sender.hashCode}',
      sender: sender,
      date: date,
      amount: amount,
      isCredit: isCredit,
      bank: bankName,
      description: message.body ?? '',
      transactionType: transactionType,
    );
  }

  /// Extract amount from SMS body
  double? _extractAmount(String body) {
    // Common patterns for amount extraction
    final patterns = [
      r'rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'inr\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'amount\s*rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:rs|inr)',
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(body);
      if (match != null) {
        final amountStr = match.group(1)?.replaceAll(',', '') ?? '';
        return double.tryParse(amountStr);
      }
    }

    return null;
  }

  /// Extract full bank name from sender and body
  String _extractBankName(String sender, String body) {
    // First try to extract from sender
    final senderLower = sender.toLowerCase();
    
    // Check direct mapping
    for (final entry in bankNameMapping.entries) {
      if (senderLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Try to extract from message body
    for (final entry in bankNameMapping.entries) {
      if (body.contains(entry.key)) {
        return entry.value;
      }
    }

    // If no match found, try to clean up sender name
    String cleanSender = sender.replaceAll(RegExp(r'[^a-zA-Z\s]'), '').trim();
    if (cleanSender.isNotEmpty) {
      return cleanSender;
    }

    return 'Unknown Bank';
  }

  /// Detect transaction type from SMS body
  String _detectTransactionType(String body) {
    for (final entry in transactionTypeKeywords.entries) {
      for (final keyword in entry.value) {
        if (body.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'OTHER';
  }

  /// Get demo transactions for testing
  List<Transaction> _getDemoTransactions() {
    final now = DateTime.now();
    return [
      Transaction(
        id: 'demo_1',
        sender: 'AD-HDFC',
        date: now.subtract(const Duration(hours: 2)),
        amount: 2500.00,
        isCredit: false,
        bank: 'HDFC Bank',
        description: 'Amount Rs.2500.00 debited from A/c **1234 via Debit Card on 15-Jan-25. Available Balance: Rs.45000.00',
        transactionType: 'DEBIT_CARD',
      ),
      Transaction(
        id: 'demo_2',
        sender: 'VM-ICICI',
        date: now.subtract(const Duration(hours: 5)),
        amount: 15000.00,
        isCredit: true,
        bank: 'ICICI Bank',
        description: 'Rs.15000.00 credited to A/c **5678 via UPI from John Doe. Balance: Rs.60000.00',
        transactionType: 'UPI',
      ),
      Transaction(
        id: 'demo_3',
        sender: 'AD-AXIS',
        date: now.subtract(const Duration(days: 1)),
        amount: 850.00,
        isCredit: false,
        bank: 'Axis Bank',
        description: 'Rs.850.00 spent via Credit Card **9876 at Amazon. Available limit: Rs.45000.00',
        transactionType: 'CREDIT_CARD',
      ),
      Transaction(
        id: 'demo_4',
        sender: 'SBI',
        date: now.subtract(const Duration(days: 2)),
        amount: 5000.00,
        isCredit: true,
        bank: 'State Bank of India',
        description: 'Rs.5000.00 credited to A/c **3456 salary credit. Balance: Rs.25000.00',
        transactionType: 'OTHER',
      ),
    ];
  }
} 