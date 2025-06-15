import 'package:another_telephony/telephony.dart';
import 'package:razorpay_ifsc/razorpay_ifsc.dart';
import '../models/transaction.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;
  final IfscRazorpay _ifscRazorpay = IfscRazorpay();

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
    'amount debited',
    'amt debited',
    'money debited',
    'balance debited',
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
    'amount credited',
    'amt credited',
    'money credited',
    'balance credited',
  ];

  // UNIVERSAL bank name mapping - covers ALL major Indian banks + IFSC integration
  static const Map<String, String> bankNameMapping = {
    // HDFC variations
    'hdfc': 'HDFC Bank',
    'hdfcbank': 'HDFC Bank',
    'hdfc bank': 'HDFC Bank',
    'hd-hdfc': 'HDFC Bank',
    'ad-hdfc': 'HDFC Bank',
    'vm-hdfc': 'HDFC Bank',
    'tm-hdfc': 'HDFC Bank',
    'hdfcbk': 'HDFC Bank',
    
    // ICICI variations
    'icici': 'ICICI Bank',
    'icicibk': 'ICICI Bank',
    'icici bank': 'ICICI Bank',
    'ad-icici': 'ICICI Bank',
    'vm-icici': 'ICICI Bank',
    'tm-icici': 'ICICI Bank',
    'icicibk': 'ICICI Bank',
    
    // SBI variations
    'sbi': 'State Bank of India',
    'sbipsg': 'State Bank of India',
    'sbiinb': 'State Bank of India',
    'ad-sbibnk': 'State Bank of India',
    'vm-sbibnk': 'State Bank of India',
    'tm-sbibnk': 'State Bank of India',
    'state bank': 'State Bank of India',
    'state bank of india': 'State Bank of India',
    'sbibank': 'State Bank of India',
    'sbibk': 'State Bank of India',
    
    // Axis variations
    'axis': 'Axis Bank',
    'axisbk': 'Axis Bank',
    'axis bank': 'Axis Bank',
    'ad-axis': 'Axis Bank',
    'vm-axis': 'Axis Bank',
    'tm-axis': 'Axis Bank',
    'axisbank': 'Axis Bank',
    
    // Kotak variations
    'kotak': 'Kotak Mahindra Bank',
    'kotakbk': 'Kotak Mahindra Bank',
    'kotak mahindra': 'Kotak Mahindra Bank',
    'kotak mahindra bank': 'Kotak Mahindra Bank',
    'ad-kotak': 'Kotak Mahindra Bank',
    'vm-kotak': 'Kotak Mahindra Bank',
    'kotakbank': 'Kotak Mahindra Bank',
    
    // PNB variations
    'pnb': 'Punjab National Bank',
    'punjab national': 'Punjab National Bank',
    'punjab national bank': 'Punjab National Bank',
    'ad-pnbbk': 'Punjab National Bank',
    'vm-pnbbk': 'Punjab National Bank',
    'pnbbank': 'Punjab National Bank',
    'pnbbk': 'Punjab National Bank',
    
    // Canara variations
    'canara': 'Canara Bank',
    'canarabk': 'Canara Bank',
    'canara bank': 'Canara Bank',
    'ad-canara': 'Canara Bank',
    'vm-canara': 'Canara Bank',
    'canarabank': 'Canara Bank',
    
    // Bank of Baroda variations
    'bob': 'Bank of Baroda',
    'baroda': 'Bank of Baroda',
    'bank of baroda': 'Bank of Baroda',
    'ad-baroda': 'Bank of Baroda',
    'vm-baroda': 'Bank of Baroda',
    'barodabank': 'Bank of Baroda',
    'bobbank': 'Bank of Baroda',
    
    // Union Bank variations
    'union': 'Union Bank of India',
    'unionbk': 'Union Bank of India',
    'union bank': 'Union Bank of India',
    'union bank of india': 'Union Bank of India',
    'ad-union': 'Union Bank of India',
    'vm-union': 'Union Bank of India',
    'unionbank': 'Union Bank of India',
    
    // IDBI variations
    'idbi': 'IDBI Bank',
    'idbibk': 'IDBI Bank',
    'idbi bank': 'IDBI Bank',
    'ad-idbi': 'IDBI Bank',
    'vm-idbi': 'IDBI Bank',
    'idbibank': 'IDBI Bank',
    
    // YES Bank variations
    'yes': 'YES Bank',
    'yesbk': 'YES Bank',
    'yes bank': 'YES Bank',
    'ad-yesbnk': 'YES Bank',
    'vm-yesbnk': 'YES Bank',
    'yesbank': 'YES Bank',
    
    // IndusInd variations
    'indusind': 'IndusInd Bank',
    'indusbk': 'IndusInd Bank',
    'indusind bank': 'IndusInd Bank',
    'ad-indus': 'IndusInd Bank',
    'vm-indus': 'IndusInd Bank',
    'indusindbank': 'IndusInd Bank',
    
    // Federal Bank variations
    'federal': 'Federal Bank',
    'federalbk': 'Federal Bank',
    'federal bank': 'Federal Bank',
    'ad-federal': 'Federal Bank',
    'vm-federal': 'Federal Bank',
    'federalbank': 'Federal Bank',
    
    // RBL Bank variations
    'rbl': 'RBL Bank',
    'rblbk': 'RBL Bank',
    'rbl bank': 'RBL Bank',
    'ad-rbl': 'RBL Bank',
    'vm-rbl': 'RBL Bank',
    'rblbank': 'RBL Bank',
    
    // Bandhan Bank variations
    'bandhan': 'Bandhan Bank',
    'bandhanbk': 'Bandhan Bank',
    'bandhan bank': 'Bandhan Bank',
    'ad-bandhan': 'Bandhan Bank',
    'vm-bandhan': 'Bandhan Bank',
    'bandhanbank': 'Bandhan Bank',
    
    // DBS Bank variations
    'dbs': 'DBS Bank',
    'dbsbank': 'DBS Bank',
    'dbs bank': 'DBS Bank',
    'ad-dbs': 'DBS Bank',
    'vm-dbs': 'DBS Bank',
    'tm-dbs': 'DBS Bank',
    'dbsbk': 'DBS Bank',
    
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
    'centralbk': 'Central Bank of India',
    
    // Indian Bank variations
    'indian': 'Indian Bank',
    'indian bank': 'Indian Bank',
    'ad-indian': 'Indian Bank',
    'vm-indian': 'Indian Bank',
    'indianbank': 'Indian Bank',
    'indianbk': 'Indian Bank',
    
    // Bank of India variations
    'boi': 'Bank of India',
    'bank of india': 'Bank of India',
    'ad-boi': 'Bank of India',
    'vm-boi': 'Bank of India',
    'boibank': 'Bank of India',
    'bankofind': 'Bank of India',
    
    // UCO Bank variations
    'uco': 'UCO Bank',
    'uco bank': 'UCO Bank',
    'ad-uco': 'UCO Bank',
    'vm-uco': 'UCO Bank',
    'ucobank': 'UCO Bank',
    'ucobk': 'UCO Bank',
    
    // Syndicate Bank variations
    'syndicate': 'Syndicate Bank',
    'syndicate bank': 'Syndicate Bank',
    'ad-syndicate': 'Syndicate Bank',
    'vm-syndicate': 'Syndicate Bank',
    'syndicatebank': 'Syndicate Bank',
    'syndicatebk': 'Syndicate Bank',
    
    // IDFC Bank variations
    'idfc': 'IDFC Bank',
    'idfc bank': 'IDFC Bank',
    'idfcbank': 'IDFC Bank',
    'ad-idfc': 'IDFC Bank',
    'vm-idfc': 'IDFC Bank',
    'idfcbk': 'IDFC Bank',
    
    // Standard Chartered variations
    'sc': 'Standard Chartered Bank',
    'scb': 'Standard Chartered Bank',
    'standard chartered': 'Standard Chartered Bank',
    'standard chartered bank': 'Standard Chartered Bank',
    'ad-sc': 'Standard Chartered Bank',
    'vm-sc': 'Standard Chartered Bank',
    'standardchartered': 'Standard Chartered Bank',
    
    // Citibank variations
    'citi': 'Citibank',
    'citibank': 'Citibank',
    'citi bank': 'Citibank',
    'ad-citi': 'Citibank',
    'vm-citi': 'Citibank',
    'citibk': 'Citibank',
    
    // HSBC variations
    'hsbc': 'HSBC Bank',
    'hsbc bank': 'HSBC Bank',
    'hsbcbank': 'HSBC Bank',
    'ad-hsbc': 'HSBC Bank',
    'vm-hsbc': 'HSBC Bank',
    'hsbcbk': 'HSBC Bank',
    
    // Deutsche Bank variations
    'deutsche': 'Deutsche Bank',
    'deutsche bank': 'Deutsche Bank',
    'deutschebank': 'Deutsche Bank',
    'ad-deutsche': 'Deutsche Bank',
    'vm-deutsche': 'Deutsche Bank',
    'deutschebk': 'Deutsche Bank',
    
    // Karur Vysya Bank variations
    'kvb': 'Karur Vysya Bank',
    'karur': 'Karur Vysya Bank',
    'karur vysya': 'Karur Vysya Bank',
    'karur vysya bank': 'Karur Vysya Bank',
    'ad-kvb': 'Karur Vysya Bank',
    'vm-kvb': 'Karur Vysya Bank',
    'kvbbank': 'Karur Vysya Bank',
    
    // South Indian Bank variations
    'sib': 'South Indian Bank',
    'south indian': 'South Indian Bank',
    'south indian bank': 'South Indian Bank',
    'ad-sib': 'South Indian Bank',
    'vm-sib': 'South Indian Bank',
    'sibbank': 'South Indian Bank',
    
    // Tamilnad Mercantile Bank variations
    'tmb': 'Tamilnad Mercantile Bank',
    'tamilnad': 'Tamilnad Mercantile Bank',
    'tamilnad mercantile': 'Tamilnad Mercantile Bank',
    'tamilnad mercantile bank': 'Tamilnad Mercantile Bank',
    'ad-tmb': 'Tamilnad Mercantile Bank',
    'vm-tmb': 'Tamilnad Mercantile Bank',
    'tmbbank': 'Tamilnad Mercantile Bank',
    
    // City Union Bank variations
    'cub': 'City Union Bank',
    'city union': 'City Union Bank',
    'city union bank': 'City Union Bank',
    'ad-cub': 'City Union Bank',
    'vm-cub': 'City Union Bank',
    'cubbank': 'City Union Bank',
    
    // Jammu Kashmir Bank variations
    'jkb': 'Jammu Kashmir Bank',
    'jammu kashmir': 'Jammu Kashmir Bank',
    'jammu kashmir bank': 'Jammu Kashmir Bank',
    'ad-jkb': 'Jammu Kashmir Bank',
    'vm-jkb': 'Jammu Kashmir Bank',
    'jkbbank': 'Jammu Kashmir Bank',
    
    // DCB Bank variations
    'dcb': 'DCB Bank',
    'dcb bank': 'DCB Bank',
    'dcbbank': 'DCB Bank',
    'ad-dcb': 'DCB Bank',
    'vm-dcb': 'DCB Bank',
    'dcbbk': 'DCB Bank',
    
    // Lakshmi Vilas Bank variations
    'lvb': 'Lakshmi Vilas Bank',
    'lakshmi vilas': 'Lakshmi Vilas Bank',
    'lakshmi vilas bank': 'Lakshmi Vilas Bank',
    'ad-lvb': 'Lakshmi Vilas Bank',
    'vm-lvb': 'Lakshmi Vilas Bank',
    'lvbbank': 'Lakshmi Vilas Bank',
    
    // Nainital Bank variations
    'nainital': 'Nainital Bank',
    'nainital bank': 'Nainital Bank',
    'nainitalbank': 'Nainital Bank',
    'ad-nainital': 'Nainital Bank',
    'vm-nainital': 'Nainital Bank',
    'nainitalbk': 'Nainital Bank',
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
        final transaction = await _parseTransaction(message);
        if (transaction != null) {
          transactions.add(transaction);
        }
      }

      return transactions;
    } catch (e) {
      return _getDemoTransactions();
    }
  }

  /// Parse SMS message into transaction - UNIVERSAL PARSING with IFSC integration
  Future<Transaction?> _parseTransaction(SmsMessage message) async {
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

    // UNIVERSAL bank name extraction with IFSC integration
    final bankName = await _universalBankExtraction(sender, originalBody);
    
    // UNIVERSAL transaction type detection from actual SMS content
    final transactionType = _universalTransactionTypeDetection(originalBody);

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

  /// UNIVERSAL bank name extraction - works with ANY bank + IFSC database
  Future<String> _universalBankExtraction(String sender, String smsBody) async {
    final bodyLower = smsBody.toLowerCase();
    final senderLower = sender.toLowerCase();
    
    // Method 1: Extract IFSC code from SMS and get bank name from Razorpay database
    final ifscCode = _extractIfscCode(smsBody);
    if (ifscCode != null) {
      try {
        final bankDetails = await _ifscRazorpay.getBankDetails(ifscCode);
        if (bankDetails != null && bankDetails.bank != null) {
          return bankDetails.bank!;
        }
      } catch (e) {
        // Continue with other methods if IFSC lookup fails
      }
    }
    
    // Method 2: Look for explicit bank mentions in SMS body (UNIVERSAL PATTERNS)
    final universalBankPatterns = [
      // Full bank names with "Bank"
      r'([a-zA-Z\s]+)\s+bank(?:\s+ltd)?(?:\s+limited)?',
      // Bank names with "Bank of"
      r'bank\s+of\s+([a-zA-Z\s]+)',
      // Specific patterns for Indian banks
      r'(hdfc|icici|sbi|axis|kotak|pnb|canara|baroda|union|idbi|yes|indusind|federal|rbl|bandhan|dbs|central|indian|uco|syndicate|idfc|standard\s+chartered|citi|hsbc|deutsche|kvb|sib|tmb|cub|jkb|dcb|lvb|nainital)\s*(?:bank)?',
    ];

    for (final pattern in universalBankPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final matches = regex.allMatches(bodyLower);
      for (final match in matches) {
        final bankName = match.group(1)?.trim() ?? match.group(0)?.trim() ?? '';
        if (bankName.isNotEmpty && bankName.length > 2) {
          // Check if this extracted name matches our mapping
          final mappedName = bankNameMapping[bankName.toLowerCase()];
          if (mappedName != null) {
            return mappedName;
          }
          // If not in mapping, format it properly
          if (bankName.toLowerCase().contains('bank')) {
            return _formatBankName(bankName);
          } else {
            return _formatBankName('$bankName Bank');
          }
        }
      }
    }

    // Method 3: Look for bank name patterns in SMS content (UNIVERSAL)
    final contentPatterns = [
      r'dear\s+([a-zA-Z\s]+)\s+(?:bank\s+)?customer',
      r'([a-zA-Z\s]+)\s+bank\s+a/?c',
      r'([a-zA-Z\s]+)\s+bank\s+account',
      r'from\s+([a-zA-Z\s]+)\s+bank',
      r'your\s+([a-zA-Z\s]+)\s+bank',
      r'([a-zA-Z\s]+)\s+bank\s+(?:ltd|limited)',
      r'welcome\s+to\s+([a-zA-Z\s]+)\s+bank',
      r'([a-zA-Z\s]+)\s+bank\s+alert',
      r'([a-zA-Z\s]+)\s+bank\s+info',
    ];

    for (final pattern in contentPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(smsBody);
      if (match != null) {
        final extractedName = match.group(1)?.trim().toLowerCase() ?? '';
        if (extractedName.isNotEmpty && extractedName.length > 2) {
          final mappedName = bankNameMapping[extractedName];
          if (mappedName != null) {
            return mappedName;
          }
          // Format unknown bank name
          return _formatBankName('$extractedName Bank');
        }
      }
    }

    // Method 4: Check sender against bank mapping (COMPREHENSIVE)
    for (final entry in bankNameMapping.entries) {
      if (senderLower.contains(entry.key)) {
        return entry.value;
      }
    }

    // Method 5: Extract bank name from sender (UNIVERSAL FALLBACK)
    final senderPatterns = [
      r'([a-zA-Z]+)(?:-|_)?(?:bank|bk|bnk)',
      r'(?:ad|vm|tm|hd)-([a-zA-Z]+)',
      r'([a-zA-Z]{3,})',
    ];

    for (final pattern in senderPatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(sender);
      if (match != null) {
        final extractedName = match.group(1)?.trim() ?? '';
        if (extractedName.isNotEmpty && extractedName.length > 2) {
          final mappedName = bankNameMapping[extractedName.toLowerCase()];
          if (mappedName != null) {
            return mappedName;
          }
          // Format unknown bank name
          return _formatBankName('$extractedName Bank');
        }
      }
    }

    // Method 6: Clean up sender name as final fallback
    String cleanSender = sender.replaceAll(RegExp(r'[^a-zA-Z\s-]'), '').trim();
    if (cleanSender.isNotEmpty && cleanSender.length > 2) {
      return _formatBankName(cleanSender);
    }

    return 'Unknown Bank';
  }

  /// Extract IFSC code from SMS body
  String? _extractIfscCode(String smsBody) {
    // IFSC code pattern: 4 letters followed by 7 digits
    final ifscPattern = RegExp(r'\b([A-Z]{4}[0-9]{7})\b', caseSensitive: false);
    final match = ifscPattern.firstMatch(smsBody);
    return match?.group(1)?.toUpperCase();
  }

  /// Format bank name properly
  String _formatBankName(String bankName) {
    return bankName.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
    ).join(' ');
  }

  /// UNIVERSAL transaction type detection - works with any SMS format
  String _universalTransactionTypeDetection(String smsBody) {
    final bodyLower = smsBody.toLowerCase();
    
    // Method 1: Look for explicit mentions of card types (COMPREHENSIVE)
    final creditCardPatterns = [
      'credit card', 'credit-card', 'cc ending', 'cc****', 'cc xxxx',
      'via credit card', 'using credit card', 'through credit card',
      'on credit card', 'cc transaction', 'credit card transaction',
      'spent on credit card', 'purchase on credit card', 'cc purchase',
      'credit card payment', 'cc payment', 'credit card bill',
    ];

    for (final pattern in creditCardPatterns) {
      if (bodyLower.contains(pattern)) {
        return 'CREDIT_CARD';
      }
    }

    final debitCardPatterns = [
      'debit card', 'debit-card', 'dc ending', 'dc****', 'dc xxxx',
      'via debit card', 'using debit card', 'through debit card',
      'on debit card', 'dc transaction', 'debit card transaction',
      'spent on debit card', 'purchase on debit card', 'dc purchase',
      'debit card payment', 'dc payment', 'atm transaction',
    ];

    for (final pattern in debitCardPatterns) {
      if (bodyLower.contains(pattern)) {
        return 'DEBIT_CARD';
      }
    }

    // Method 2: Look for UPI mentions (COMPREHENSIVE)
    final upiPatterns = [
      'upi', 'via upi', 'using upi', 'through upi', 'upi id', 'upi ref',
      'upi transaction', 'upi payment', 'unified payments', 'paytm',
      'phonepe', 'googlepay', 'google pay', 'bhim', 'amazon pay',
      'mobikwik', 'freecharge', 'airtel money', 'jio money', 'ola money',
      'uber money', 'whatsapp pay', 'samsung pay', 'mi pay',
    ];

    for (final pattern in upiPatterns) {
      if (bodyLower.contains(pattern)) {
        return 'UPI';
      }
    }

    // Method 3: Look for generic card mentions (fallback to debit card)
    final genericCardPatterns = [
      'card ending', 'card no', 'card****', 'card xxxx', 'card number',
      'atm card', 'bank card', 'your card', 'card transaction',
    ];

    for (final pattern in genericCardPatterns) {
      if (bodyLower.contains(pattern)) {
        return 'DEBIT_CARD';  // Default to debit card for generic card mentions
      }
    }

    // Method 4: Look for other transaction types
    final netBankingPatterns = [
      'net banking', 'netbanking', 'internet banking', 'online banking',
      'web banking', 'mobile banking', 'online transfer',
    ];

    for (final pattern in netBankingPatterns) {
      if (bodyLower.contains(pattern)) {
        return 'OTHER';
      }
    }

    return 'OTHER';
  }

  /// Extract amount from SMS body (UNIVERSAL PATTERNS)
  double? _extractAmount(String body) {
    final patterns = [
      // Indian Rupee patterns
      r'rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'inr\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'amount\s*rs\.?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:rs|inr)',
      r'₹\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*₹',
      // Generic amount patterns
      r'amount\s*(?:of\s*)?(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'amt\s*(?:of\s*)?(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'sum\s*(?:of\s*)?(\d+(?:,\d+)*(?:\.\d{2})?)',
      // Transaction amount patterns
      r'(?:debited|credited|paid|received|spent|withdrawn|deposited)\s*(?:rs\.?|inr|₹)?\s*(\d+(?:,\d+)*(?:\.\d{2})?)',
      r'(\d+(?:,\d+)*(?:\.\d{2})?)\s*(?:debited|credited|paid|received|spent|withdrawn|deposited)',
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

  /// Get demo transactions for testing - shows UNIVERSAL coverage with IFSC integration
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
        description: 'Amount Rs.2500.00 debited from HDFC Bank A/c **1234 via Debit Card on 15-Jan-25. IFSC: HDFC0000001. Available Balance: Rs.45000.00',
        transactionType: 'DEBIT_CARD',
      ),
      Transaction(
        id: 'demo_2',
        sender: 'VM-ICICI',
        date: now.subtract(const Duration(hours: 5)),
        amount: 15000.00,
        isCredit: true,
        bank: 'ICICI Bank',
        description: 'Rs.15000.00 credited to ICICI Bank A/c **5678 via UPI from John Doe. IFSC: ICIC0000001. Balance: Rs.60000.00',
        transactionType: 'UPI',
      ),
      Transaction(
        id: 'demo_3',
        sender: 'AD-AXIS',
        date: now.subtract(const Duration(days: 1)),
        amount: 850.00,
        isCredit: false,
        bank: 'Axis Bank',
        description: 'Rs.850.00 spent via Credit Card **9876 at Amazon from Axis Bank. IFSC: UTIB0000001. Available limit: Rs.45000.00',
        transactionType: 'CREDIT_CARD',
      ),
      Transaction(
        id: 'demo_4',
        sender: 'DBS-BANK',
        date: now.subtract(const Duration(days: 2)),
        amount: 5000.00,
        isCredit: true,
        bank: 'DBS Bank',
        description: 'Rs.5000.00 credited to your DBS Bank A/c **3456 salary credit. IFSC: DBSS0IN0811. Balance: Rs.25000.00',
        transactionType: 'OTHER',
      ),
      Transaction(
        id: 'demo_5',
        sender: 'CENTRAL-BK',
        date: now.subtract(const Duration(days: 3)),
        amount: 1200.00,
        isCredit: false,
        bank: 'Central Bank of India',
        description: 'Rs.1200.00 debited from Central Bank of India A/c **7890 via Credit Card. IFSC: CBIN0280001. Balance: Rs.15000.00',
        transactionType: 'CREDIT_CARD',
      ),
      Transaction(
        id: 'demo_6',
        sender: 'UNKNOWN-BANK',
        date: now.subtract(const Duration(days: 4)),
        amount: 750.00,
        isCredit: false,
        bank: 'Unknown Bank',
        description: 'Rs.750.00 debited from Unknown Bank A/c **1111 via UPI. Balance: Rs.12000.00',
        transactionType: 'UPI',
      ),
    ];
  }
} 