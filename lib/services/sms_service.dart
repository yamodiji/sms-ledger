import 'package:another_telephony/telephony.dart';
import '../models/transaction.dart';

class SmsService {
  final Telephony telephony = Telephony.instance;

  // Keywords for identifying REAL transaction messages (not promotional)
  static const List<String> debitKeywords = [
    'debited',
    'withdrawn',
    'spent',
    'paid',
    'purchase',
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

  // Transaction confirmation phrases that indicate REAL transactions
  static const List<String> transactionConfirmationPhrases = [
    'if this transaction was not done by you',
    'if this transaction wasnt done by you',
    'if you have not done this transaction',
    'if you did not make this transaction',
    'transaction not done by you',
    'available balance',
    'balance is',
    'remaining balance',
    'account balance',
    'current balance',
    'total balance',
    'txn id',
    'transaction id',
    'ref no',
    'reference number',
    'utr no',
    'utr number',
  ];

  // SPAM keywords that indicate promotional messages (NOT transactions)
  static const List<String> spamKeywords = [
    'credit limit',
    'eligible for',
    'you are eligible',
    'congratulations',
    'offer',
    'apply now',
    'click here',
    'call us',
    'visit branch',
    'upgrade',
    'pre-approved',
    'limited time',
    'hurry',
    'act now',
    'terms and conditions',
    'interest rate',
    'processing fee',
    'annual fee',
    'reward points',
    'cashback offer',
    'exclusive offer',
    'special offer',
    'promotional',
    'marketing',
    'advertisement',
    'download app',
    'install app',
    'update app',
    'verify mobile',
    'register mobile',
    'activate card',
    'block card',
    'unblock card',
    'pin generation',
    'otp',
    'one time password',
    'temporary block',
    'statement',
    'cheque book',
    'passbook',
    'kyc',
    'know your customer',
    'document upload',
    'visit nearest branch',
    'customer care',
    'helpline',
    'toll free',
    'website',
    'portal',
    'login',
    'username',
    'password',
    'security',
    'fraud alert',
    'do not share',
    'never share',
    'phishing',
    'fake',
    'suspicious',
  ];

  // UNIVERSAL bank name mapping - covers ALL major Indian banks
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

  /// Parse SMS message into transaction - SIMPLE CLEAR APPROACH
  /// 1. Find transaction type (Credit Card/Debit Card/UPI/RTGS/IMPS/NEFT)
  /// 2. Find transaction action (debited/credited/spent/received)  
  /// 3. Check for account/card patterns (a/c, xxxx, card ending)
  Transaction? _parseTransaction(SmsMessage message) {
    final originalBody = message.body ?? '';
    final bodyLower = originalBody.toLowerCase();
    final sender = message.address ?? '';
    final date = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

    // STEP 1: Check for SPAM keywords first (reject promotional messages)
    final isSpam = spamKeywords.any((keyword) => bodyLower.contains(keyword));
    if (isSpam) return null;

    // STEP 2: FIRST - Identify transaction type based on clear patterns
    final transactionType = _simpleTransactionTypeDetection(bodyLower);
    if (transactionType == 'UNKNOWN') return null; // No clear transaction type found

    // STEP 3: SECOND - Check for transaction actions
    final transactionActions = ['debited', 'credited', 'spent', 'received', 'paid', 'withdrawn'];
    final hasTransactionAction = transactionActions.any((action) => bodyLower.contains(action));
    if (!hasTransactionAction) return null; // Must have clear action

    // STEP 4: THIRD - Check for account/card patterns (xxxx, a/c, account)
    final accountPatterns = ['a/c', 'account', 'xxxx', '****', 'ending'];
    final hasAccountPattern = accountPatterns.any((pattern) => bodyLower.contains(pattern));
    if (!hasAccountPattern) return null; // Must have account/card reference

    // STEP 5: FOURTH - Extract amount (must have valid amount)
    final amount = _extractAmount(bodyLower);
    if (amount == null) return null;

    // STEP 6: FIFTH - Determine if it's credit or debit based on simple action words
    bool isCredit = false;
    
    // Simple approach: Look for clear action words
    final creditActions = ['credited', 'received', 'deposited', 'refund', 'cashback'];
    final debitActions = ['debited', 'spent', 'paid', 'withdrawn'];
    
    final hasCreditAction = creditActions.any((action) => bodyLower.contains(action));
    final hasDebitAction = debitActions.any((action) => bodyLower.contains(action));
    
    if (hasCreditAction && !hasDebitAction) {
      isCredit = true; // Money coming in
    } else if (hasDebitAction && !hasCreditAction) {
      isCredit = false; // Money going out
    } else {
      return null; // Ambiguous or conflicting actions
    }

    // STEP 7: SIXTH - Extract bank name (simple approach)
    final bankName = _universalBankExtraction(sender, originalBody);

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



  /// UNIVERSAL bank name extraction - works with ANY bank
  String _universalBankExtraction(String sender, String smsBody) {
    final bodyLower = smsBody.toLowerCase();
    final senderLower = sender.toLowerCase();
    
    // Method 1: Priority-based bank extraction that matches sender
    List<String> foundBanks = [];
    
    // Find ALL bank mentions in SMS body
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
            foundBanks.add(mappedName);
          } else {
            // If not in mapping, format it properly
            if (bankName.toLowerCase().contains('bank')) {
              foundBanks.add(_formatBankName(bankName));
            } else {
              foundBanks.add(_formatBankName('$bankName Bank'));
            }
          }
        }
      }
    }
    
    // If multiple banks found, prioritize based on sender match
    if (foundBanks.length > 1) {
      // Check which bank name characters match the sender
      for (final bankName in foundBanks) {
        if (_doesBankMatchSender(bankName, sender)) {
          return bankName;
        }
      }
      
      // If no direct match, prefer banks mentioned at the end of SMS
      // (usually the actual sending bank)
      return foundBanks.last;
    } else if (foundBanks.isNotEmpty) {
      return foundBanks.first;
    }

    // Method 2: Look for bank signatures at the end of SMS (highest priority)
    final endSignaturePatterns = [
      r'-\s*([a-zA-Z\s]+(?:bank|ltd|limited))\s*$',  // "- Canara Bank" at end
      r'regards[,\s]*([a-zA-Z\s]+bank)\s*$',          // "Regards, HDFC Bank" at end  
      r'from[,\s]*([a-zA-Z\s]+bank)\s*$',             // "From, SBI Bank" at end
      r'thank\s+you[,\s]*([a-zA-Z\s]+bank)\s*$',      // "Thank you, Axis Bank" at end
    ];

    for (final pattern in endSignaturePatterns) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(smsBody);
      if (match != null) {
        final extractedName = match.group(1)?.trim().toLowerCase() ?? '';
        if (extractedName.isNotEmpty && extractedName.length > 2) {
          final mappedName = bankNameMapping[extractedName];
          if (mappedName != null && _doesBankMatchSender(mappedName, sender)) {
            return mappedName;
          } else if (mappedName != null) {
            foundBanks.add(mappedName);
          } else {
            foundBanks.add(_formatBankName(extractedName));
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
            foundBanks.add(mappedName);
          } else {
            foundBanks.add(_formatBankName('$extractedName Bank'));
          }
        }
      }
    }
    
    // If we found banks, prioritize by sender match
    if (foundBanks.isNotEmpty) {
      // First check for sender matches
      for (final bankName in foundBanks) {
        if (_doesBankMatchSender(bankName, sender)) {
          return bankName;
        }
      }
      // Return the last found bank (likely the signature bank)
      return foundBanks.last;
    }

    // Method 4: Check sender against bank mapping (COMPREHENSIVE)
    for (final entry in bankNameMapping.entries) {
      if (senderLower.contains(entry.key)) {
        foundBanks.add(entry.value);
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
            foundBanks.add(mappedName);
          } else {
            foundBanks.add(_formatBankName('$extractedName Bank'));
          }
        }
      }
    }
    
    // Final prioritization of found banks
    if (foundBanks.isNotEmpty) {
      // Remove duplicates while preserving order
      final uniqueBanks = <String>[];
      for (final bank in foundBanks) {
        if (!uniqueBanks.contains(bank)) {
          uniqueBanks.add(bank);
        }
      }
      
      // First check for sender matches
      for (final bankName in uniqueBanks) {
        if (_doesBankMatchSender(bankName, sender)) {
          return bankName;
        }
      }
      
      // Return the last found bank (likely the signature bank)
      return uniqueBanks.last;
    }

    // Method 6: Clean up sender name as final fallback
    String cleanSender = sender.replaceAll(RegExp(r'[^a-zA-Z\s-]'), '').trim();
    if (cleanSender.isNotEmpty && cleanSender.length > 2) {
      return _formatBankName(cleanSender);
    }

    return 'Unknown Bank';
  }



  /// Check if bank name matches sender characters
  bool _doesBankMatchSender(String bankName, String sender) {
    final bankLower = bankName.toLowerCase();
    final senderLower = sender.toLowerCase();
    
    // Extract key bank identifiers and check if they appear in sender
    final bankIdentifiers = <String>[];
    
    if (bankLower.contains('hdfc')) bankIdentifiers.add('hdfc');
    if (bankLower.contains('icici')) bankIdentifiers.add('icici');
    if (bankLower.contains('sbi') || bankLower.contains('state bank')) bankIdentifiers.add('sbi');
    if (bankLower.contains('axis')) bankIdentifiers.add('axis');
    if (bankLower.contains('kotak')) bankIdentifiers.add('kotak');
    if (bankLower.contains('federal')) bankIdentifiers.addAll(['fed', 'federal']);
    if (bankLower.contains('yes')) bankIdentifiers.add('yes');
    if (bankLower.contains('punjab') || bankLower.contains('pnb')) bankIdentifiers.add('pnb');
    if (bankLower.contains('canara')) bankIdentifiers.add('canara');
    if (bankLower.contains('baroda') || bankLower.contains('bob')) bankIdentifiers.addAll(['bob', 'baroda']);
    if (bankLower.contains('union')) bankIdentifiers.add('union');
    if (bankLower.contains('idbi')) bankIdentifiers.add('idbi');
    if (bankLower.contains('indusind')) bankIdentifiers.addAll(['indus', 'indusind']);
    if (bankLower.contains('rbl')) bankIdentifiers.add('rbl');
    if (bankLower.contains('bandhan')) bankIdentifiers.add('bandhan');
    if (bankLower.contains('dbs')) bankIdentifiers.add('dbs');
    if (bankLower.contains('central')) bankIdentifiers.add('central');
    if (bankLower.contains('indian')) bankIdentifiers.add('indian');
    
    // Check if any bank identifier appears in the sender
    for (final identifier in bankIdentifiers) {
      if (senderLower.contains(identifier)) {
        return true;
      }
    }
    
    return false;
  }

  /// Format bank name properly
  String _formatBankName(String bankName) {
    return bankName.split(' ').map((word) => 
      word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
    ).join(' ');
  }

  /// SIMPLE transaction type detection - clear pattern matching
  String _simpleTransactionTypeDetection(String bodyLower) {
    // STEP 1: Check for CREDIT CARD patterns
    if (bodyLower.contains('credit card')) {
      return 'CREDIT_CARD';
    }
    
    // STEP 2: Check for DEBIT CARD patterns  
    if (bodyLower.contains('debit card')) {
      return 'DEBIT_CARD';
    }
    
    // STEP 3: Check for UPI patterns
    if (bodyLower.contains('upi') || bodyLower.contains('via upi') || 
        bodyLower.contains('@') || bodyLower.contains('vpa')) {
      return 'UPI';
    }
    
    // STEP 4: Check for bank transfer patterns
    if (bodyLower.contains('rtgs')) {
      return 'RTGS';
    }
    if (bodyLower.contains('imps')) {
      return 'IMPS';
    }
    if (bodyLower.contains('neft')) {
      return 'NEFT';
    }
    
    // STEP 5: Generic card (when just "card" is mentioned)
    if (bodyLower.contains('card ending') || bodyLower.contains('card xxxx') || 
        bodyLower.contains('card ****')) {
      return 'DEBIT_CARD'; // Default to debit for generic card
    }
    
    // STEP 6: Other bank transactions
    if (bodyLower.contains('account') || bodyLower.contains('a/c') || 
        bodyLower.contains('bank')) {
      return 'OTHER';
    }
    
    return 'UNKNOWN';
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

  /// Get demo transactions for testing - shows ANTI-SPAM filtering
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
        description: 'Amount Rs.2500.00 debited from HDFC Bank A/c **1234 via Debit Card on 15-Jan-25. Available Balance: Rs.45000.00. If this transaction was not done by you, contact us.',
        transactionType: 'DEBIT_CARD',
      ),
      Transaction(
        id: 'demo_2',
        sender: 'VM-ICICI',
        date: now.subtract(const Duration(hours: 5)),
        amount: 15000.00,
        isCredit: true,
        bank: 'ICICI Bank',
        description: 'Rs.15000.00 credited to ICICI Bank A/c **5678 via UPI from John Doe. Available Balance: Rs.60000.00. Txn ID: 987654321',
        transactionType: 'UPI',
      ),
      Transaction(
        id: 'demo_3',
        sender: 'AD-AXIS',
        date: now.subtract(const Duration(days: 1)),
        amount: 850.00,
        isCredit: false,
        bank: 'Axis Bank',
        description: 'Rs.850.00 spent via credit card ending **9876 at Amazon from Axis Bank A/c. Available Balance: Rs.45000.00. If this transaction wasnt done by you, contact us.',
        transactionType: 'CREDIT_CARD',
      ),
      Transaction(
        id: 'demo_7',
        sender: 'VM-FEDBNK',
        date: now.subtract(const Duration(days: 1, hours: 2)),
        amount: 2000.00,
        isCredit: true,
        bank: 'Federal Bank',
        description: 'Rs.2000.00 credited to Federal Bank A/c **4567 via UPI from friend. Available Balance: Rs.30000.00. Txn ID: FED123456',
        transactionType: 'UPI',
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
      Transaction(
        id: 'demo_8',
        sender: 'AD-HDFC',
        date: now.subtract(const Duration(days: 5)),
        amount: 150.00,
        isCredit: true,
        bank: 'HDFC Bank',
        description: 'Rs.150.00 cashback credited to credit card ending **1234 for purchase at Flipkart. If this transaction wasnt done by you, contact us.',
        transactionType: 'CREDIT_CARD',
      ),
      Transaction(
        id: 'demo_9',
        sender: 'VM-ICICI',
        date: now.subtract(const Duration(days: 6)),
        amount: 500.00,
        isCredit: false,
        bank: 'ICICI Bank',
        description: 'Rs.500.00 debited from ICICI Bank A/c **5678 via UPI to merchant. Available Balance: Rs.25000.00. Txn ID: UPI987654',
        transactionType: 'UPI',
      ),
      Transaction(
        id: 'demo_10',
        sender: 'AD-SBI',
        date: now.subtract(const Duration(days: 7)),
        amount: 1200.00,
        isCredit: true,
        bank: 'State Bank of India',
        description: 'Rs.1200.00 received via VPA to SBI Bank A/c **9012 from friend@oksbi. Available Balance: Rs.18000.00. Ref: VPA123456',
        transactionType: 'UPI',
      ),
      Transaction(
        id: 'demo_11',
        sender: 'CANARA-BK',
        date: now.subtract(const Duration(days: 8)),
        amount: 3475.00,
        isCredit: true,
        bank: 'Canara Bank',
        description: 'An amount of INR 3,475.00 has been credited to XXXX0224 on 16/06/2025 towards NEFT by Sender PHONEPE PRIVATE LIMI FOR PHONE, IFSC YESB0000001, Sender A/c XXXX0025, YES BANK LTD, Worli, Mumbai, UTR YESPH51670217794, Total Avail. Bal INR 9241.42- Canara Bank',
        transactionType: 'NEFT',
      ),
      Transaction(
        id: 'demo_12',
        sender: 'AD-HDFCBK',
        date: now.subtract(const Duration(days: 9)),
        amount: 1250.00,
        isCredit: false,
        bank: 'HDFC Bank',
        description: 'INR 1250.00 spent on HDFC Bank Credit Card ending xxxx9876 on 17-Jan-25 at AMAZON. Available Credit Limit: INR 45000.00',
        transactionType: 'CREDIT_CARD',
      ),
    ];
  }
} 