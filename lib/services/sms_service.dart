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
    'used',
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
    'added',
  ];

  // Comprehensive bank name mapping - extract from SMS content
  static const Map<String, String> bankNameMapping = {
    // HDFC variations
    'hdfc': 'HDFC Bank',
    'hdfcbank': 'HDFC Bank',
    'hdfc bank': 'HDFC Bank',
    'hd-hdfc': 'HDFC Bank',
    'ad-hdfc': 'HDFC Bank',
    'vm-hdfc': 'HDFC Bank',
    'tm-hdfc': 'HDFC Bank',
    
    // ICICI variations
    'icici': 'ICICI Bank',
    'icicibk': 'ICICI Bank',
    'icici bank': 'ICICI Bank',
    'ad-icici': 'ICICI Bank',
    'vm-icici': 'ICICI Bank',
    'tm-icici': 'ICICI Bank',
    
    // SBI variations
    'sbi': 'State Bank of India',
    'sbipsg': 'State Bank of India',
    'sbiinb': 'State Bank of India',
    'ad-sbibnk': 'State Bank of India',
    'vm-sbibnk': 'State Bank of India',
    'tm-sbibnk': 'State Bank of India',
    'state bank': 'State Bank of India',
    'state bank of india': 'State Bank of India',
    
    // Axis variations
    'axis': 'Axis Bank',
    'axisbk': 'Axis Bank',
    'axis bank': 'Axis Bank',
    'ad-axis': 'Axis Bank',
    'vm-axis': 'Axis Bank',
    'tm-axis': 'Axis Bank',
    
    // Kotak variations
    'kotak': 'Kotak Mahindra Bank',
    'kotakbk': 'Kotak Mahindra Bank',
    'kotak mahindra': 'Kotak Mahindra Bank',
    'kotak mahindra bank': 'Kotak Mahindra Bank',
    'ad-kotak': 'Kotak Mahindra Bank',
    'vm-kotak': 'Kotak Mahindra Bank',
    
    // PNB variations
    'pnb': 'Punjab National Bank',
    'punjab national': 'Punjab National Bank',
    'punjab national bank': 'Punjab National Bank',
    'ad-pnbbk': 'Punjab National Bank',
    'vm-pnbbk': 'Punjab National Bank',
    
    // Canara variations
    'canara': 'Canara Bank',
    'canarabk': 'Canara Bank',
    'canara bank': 'Canara Bank',
    'ad-canara': 'Canara Bank',
    'vm-canara': 'Canara Bank',
    
    // Bank of Baroda variations
    'bob': 'Bank of Baroda',
    'baroda': 'Bank of Baroda',
    'bank of baroda': 'Bank of Baroda',
    'ad-baroda': 'Bank of Baroda',
    'vm-baroda': 'Bank of Baroda',
    
    // Union Bank variations
    'union': 'Union Bank of India',
    'unionbk': 'Union Bank of India',
    'union bank': 'Union Bank of India',
    'union bank of india': 'Union Bank of India',
    'ad-union': 'Union Bank of India',
    'vm-union': 'Union Bank of India',
    
    // IDBI variations
    'idbi': 'IDBI Bank',
    'idbibk': 'IDBI Bank',
    'idbi bank': 'IDBI Bank',
    'ad-idbi': 'IDBI Bank',
    'vm-idbi': 'IDBI Bank',
    
    // YES Bank variations
    'yes': 'YES Bank',
    'yesbk': 'YES Bank',
    'yes bank': 'YES Bank',
    'ad-yesbnk': 'YES Bank',
    'vm-yesbnk': 'YES Bank',
    
    // IndusInd variations
    'indusind': 'IndusInd Bank',
    'indusbk': 'IndusInd Bank',
    'indusind bank': 'IndusInd Bank',
    'ad-indus': 'IndusInd Bank',
    'vm-indus': 'IndusInd Bank',
    
    // Federal Bank variations
    'federal': 'Federal Bank',
    'federalbk': 'Federal Bank',
    'federal bank': 'Federal Bank',
    'ad-federal': 'Federal Bank',
    'vm-federal': 'Federal Bank',
    
    // RBL Bank variations
    'rbl': 'RBL Bank',
    'rblbk': 'RBL Bank',
    'rbl bank': 'RBL Bank',
    'ad-rbl': 'RBL Bank',
    'vm-rbl': 'RBL Bank',
    
    // Bandhan Bank variations
    'bandhan': 'Bandhan Bank',
    'bandhanbk': 'Bandhan Bank',
    'bandhan bank': 'Bandhan Bank',
    'ad-bandhan': 'Bandhan Bank',
    'vm-bandhan': 'Bandhan Bank',
    
    // DBS Bank variations
    'dbs': 'DBS Bank',
    'dbsbank': 'DBS Bank',
    'dbs bank': 'DBS Bank',
    'ad-dbs': 'DBS Bank',
    'vm-dbs': 'DBS Bank',
    'tm-dbs': 'DBS Bank',
    
    // Central Bank of India variations
    'central': 'Central Bank of India',
    'centralbank': 'Central Bank of India',
    'central bank': 'Central Bank of India',
    'central bank of india': 'Central Bank of India',
    'ad-central': 'Central Bank of India',
    'vm-central': 'Central Bank of India',
    'tm-central': 'Central Bank of India',
    'cbi': 'Central Bank of India',
    'ad-cbi': 'Central Bank of India',
    'vm-cbi': 'Central Bank of India',
    
    // Additional banks
    'indian': 'Indian Bank',
    'indian bank': 'Indian Bank',
    'ad-indian': 'Indian Bank',
    'vm-indian': 'Indian Bank',
    
    'boi': 'Bank of India',
    'bank of india': 'Bank of India',
    'ad-boi': 'Bank of India',
    'vm-boi': 'Bank of India',
    
    'uco': 'UCO Bank',
    'uco bank': 'UCO Bank',
    'ad-uco': 'UCO Bank',
    'vm-uco': 'UCO Bank',
    
    'syndicate': 'Syndicate Bank',
    'syndicate bank': 'Syndicate Bank',
    'ad-syndicate': 'Syndicate Bank',
    'vm-syndicate': 'Syndicate Bank',
  };

  /// Request SMS permission
  Future<bool> requestSmsPermission() async {
    try {
      final hasPermission = await telephony.isSmsCapable ?? false;
      if (hasPermission) {
        return true;
      }
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
      return _getDemoTransactions();
    }
  }

  /// Parse SMS message into transaction - INTELLIGENT PARSING
  Transaction? _parseTransaction(SmsMessage message) {
    final originalBody = message.body ?? '';
    final bodyLower = originalBody.toLowerCase();
    final sender = message.address ?? '';
    final date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

    // Check if it's a transaction message
    final isDebit = debitKeywords.any((keyword) => bodyLower.contains(keyword));
    final isCredit = creditKeywords.any((keyword) => bodyLower.contains(keyword));
    
    if (!isDebit && !isCredit) return null;

    // Extract amount
    final amount = _extractAmount(bodyLower);
    if (amount == null) return null;

    // INTELLIGENT bank name extraction from SMS content
    final bankName = _intelligentBankExtraction(sender, originalBody);
    
    // INTELLIGENT transaction type detection from actual SMS content
    final transactionType = _intelligentTransactionTypeDetection(originalBody);

    return Transaction(
      id: '${message.date}_${sender.hashCode}',
      sender: sender,
      date: date,
      amount: amount,
      isCredit: isCredit,
      bank: bankName,
      description: originalBody,
      transactionType: transactionType,
    );
  }

  /// INTELLIGENT bank name extraction - reads actual SMS content
  String _intelligentBankExtraction(String sender, String smsBody) {
    final bodyLower = smsBody.toLowerCase();
    final senderLower = sender.toLowerCase();
    
    // Method 1: Look for explicit bank mentions in SMS body
    // Pattern: "HDFC Bank", "State Bank of India", "DBS Bank", etc.
    final bankMentionPatterns = [
      r'(hdfc\s+bank)',
      r'(icici\s+bank)',
      r'(state\s+bank\s+of\s+india)',
      r'(axis\s+bank)',
      r'(kotak\s+mahindra\s+bank)',
      r'(punjab\s+national\s+bank)',
      r'(canara\s+bank)',
      r'(bank\s+of\s+baroda)',
      r'(union\s+bank\s+of\s+india)',
      r'(idbi\s+bank)',
      r'(yes\s+bank)',
      r'(indusind\s+bank)',
      r'(federal\s+bank)',
      r'(rbl\s+bank)',
      r'(bandhan\s+bank)',
      r'(dbs\s+bank)',
      r'(central\s+bank\s+of\s+india)',
      r'(indian\s+bank)',
      r'(bank\s+of\s+india)',
      r'(uco\s+bank)',
      r'(syndicate\s+bank)',
    ];

    for (final pattern in bankMentionPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(bodyLower);
      if (match != null) {
        final bankName = match.group(1)?.trim() ?? '';
        final mappedName = bankNameMapping[bankName];
        if (mappedName != null) {
          return mappedName;
        }
      }
    }

    // Method 2: Look for bank name patterns in SMS content
    final contentPatterns = [
      r'dear\s+([a-zA-Z\s]+)\s+bank\s+customer',
      r'([a-zA-Z\s]+)\s+bank\s+a/c',
      r'([a-zA-Z\s]+)\s+bank\s+account',
      r'from\s+([a-zA-Z\s]+)\s+bank',
      r'your\s+([a-zA-Z\s]+)\s+bank',
      r'([a-zA-Z\s]+)\s+bank\s+ltd',
    ];

    for (final pattern in contentPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(smsBody);
      if (match != null) {
        final extractedName = match.group(1)?.trim().toLowerCase() ?? '';
        if (extractedName.isNotEmpty) {
          final mappedName = bankNameMapping[extractedName];
          if (mappedName != null) {
            return mappedName;
          }
        }
      }
    }

    // Method 3: Check sender against bank mapping
    for (final entry in bankNameMapping.entries) {
      if (senderLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Method 4: Clean up sender name as fallback
    String cleanSender = sender.replaceAll(RegExp(r'[^a-zA-Z\s-]'), '').trim();
    if (cleanSender.isNotEmpty && cleanSender.length > 2) {
      return cleanSender.split(' ').map((word) => 
        word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
      ).join(' ');
    }

    return 'Unknown Bank';
  }

  /// INTELLIGENT transaction type detection - reads actual SMS wording
  String _intelligentTransactionTypeDetection(String smsBody) {
    final bodyLower = smsBody.toLowerCase();
    
    // Method 1: Look for explicit mentions of card types
    if (bodyLower.contains('credit card') || 
        bodyLower.contains('credit-card') ||
        bodyLower.contains('cc ending') ||
        bodyLower.contains('cc****') ||
        bodyLower.contains('via credit card') ||
        bodyLower.contains('using credit card') ||
        bodyLower.contains('through credit card') ||
        bodyLower.contains('on credit card') ||
        bodyLower.contains('cc transaction') ||
        bodyLower.contains('credit card transaction')) {
      return 'CREDIT_CARD';
    }

    if (bodyLower.contains('debit card') || 
        bodyLower.contains('debit-card') ||
        bodyLower.contains('dc ending') ||
        bodyLower.contains('dc****') ||
        bodyLower.contains('via debit card') ||
        bodyLower.contains('using debit card') ||
        bodyLower.contains('through debit card') ||
        bodyLower.contains('on debit card') ||
        bodyLower.contains('dc transaction') ||
        bodyLower.contains('debit card transaction')) {
      return 'DEBIT_CARD';
    }

    // Method 2: Look for UPI mentions
    if (bodyLower.contains('upi') ||
        bodyLower.contains('via upi') ||
        bodyLower.contains('using upi') ||
        bodyLower.contains('through upi') ||
        bodyLower.contains('upi id') ||
        bodyLower.contains('upi ref') ||
        bodyLower.contains('upi transaction') ||
        bodyLower.contains('paytm') ||
        bodyLower.contains('phonepe') ||
        bodyLower.contains('googlepay') ||
        bodyLower.contains('google pay') ||
        bodyLower.contains('bhim') ||
        bodyLower.contains('amazon pay') ||
        bodyLower.contains('mobikwik')) {
      return 'UPI';
    }

    // Method 3: Look for generic card mentions (fallback to debit card)
    if (bodyLower.contains('card ending') ||
        bodyLower.contains('card no') ||
        bodyLower.contains('card****') ||
        bodyLower.contains('card xxxx')) {
      return 'DEBIT_CARD';  // Default to debit card for generic card mentions
    }

    return 'OTHER';
  }

  /// Extract amount from SMS body
  double? _extractAmount(String body) {
    final patterns = [
      r'rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'inr\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'amount\s*rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:rs|inr)',
      r'₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*₹',
    ];

    for (final pattern in patterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(body);
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
        description: 'Amount Rs.2500.00 debited from HDFC Bank A/c **1234 via Debit Card on 15-Jan-25. Available Balance: Rs.45000.00',
        transactionType: 'DEBIT_CARD',
      ),
      Transaction(
        id: 'demo_2',
        sender: 'VM-ICICI',
        date: now.subtract(const Duration(hours: 5)),
        amount: 15000.00,
        isCredit: true,
        bank: 'ICICI Bank',
        description: 'Rs.15000.00 credited to ICICI Bank A/c **5678 via UPI from John Doe. Balance: Rs.60000.00',
        transactionType: 'UPI',
      ),
      Transaction(
        id: 'demo_3',
        sender: 'AD-AXIS',
        date: now.subtract(const Duration(days: 1)),
        amount: 850.00,
        isCredit: false,
        bank: 'Axis Bank',
        description: 'Rs.850.00 spent via Credit Card **9876 at Amazon from Axis Bank. Available limit: Rs.45000.00',
        transactionType: 'CREDIT_CARD',
      ),
      Transaction(
        id: 'demo_4',
        sender: 'DBS-BANK',
        date: now.subtract(const Duration(days: 2)),
        amount: 5000.00,
        isCredit: true,
        bank: 'DBS Bank',
        description: 'Rs.5000.00 credited to your DBS Bank A/c **3456 salary credit. Balance: Rs.25000.00',
        transactionType: 'OTHER',
      ),
      Transaction(
        id: 'demo_5',
        sender: 'CENTRAL-BK',
        date: now.subtract(const Duration(days: 3)),
        amount: 1200.00,
        isCredit: false,
        bank: 'Central Bank of India',
        description: 'Rs.1200.00 debited from Central Bank of India A/c **7890 via Credit Card. Balance: Rs.15000.00',
        transactionType: 'CREDIT_CARD',
      ),
          ];
    }
  } 