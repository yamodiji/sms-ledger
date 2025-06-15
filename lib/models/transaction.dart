class Transaction {
  final String id;
  final String sender;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String bank;
  final String description;
  final String transactionType;

  Transaction({
    required this.id,
    required this.sender,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.bank,
    required this.description,
    required this.transactionType,
  });

  // Backward compatibility getter
  String get originalMessage => description;

  String get formattedAmount {
    final prefix = isCredit ? '+₹' : '-₹';
    return '$prefix${amount.toStringAsFixed(2)}';
  }

  String get bankLogo {
    return getBankLogo(bank);
  }

  String get transactionTypeDisplay {
    switch (transactionType) {
      case 'DEBIT_CARD':
        return 'Debit Card';
      case 'CREDIT_CARD':
        return 'Credit Card';
      case 'UPI':
        return 'UPI';
      case 'OTHER':
        return 'Bank Transfer';
      default:
        return 'Other';
    }
  }

  static String getBankLogo(String bankName) {
    final bank = bankName.toLowerCase();
    if (bank.contains('hdfc')) {
      return '🏦'; // HDFC logo placeholder
    } else if (bank.contains('icici')) {
      return '🏛️'; // ICICI logo placeholder
    } else if (bank.contains('sbi') || bank.contains('state bank')) {
      return '🏪'; // SBI logo placeholder
    } else if (bank.contains('axis')) {
      return '🏢'; // Axis logo placeholder
    } else if (bank.contains('kotak')) {
      return '🏦'; // Kotak logo placeholder
    } else if (bank.contains('yes')) {
      return '🏛️'; // YES Bank logo placeholder
    } else if (bank.contains('pnb') || bank.contains('punjab')) {
      return '🏪'; // PNB logo placeholder
    } else if (bank.contains('canara')) {
      return '🏢'; // Canara logo placeholder
    } else if (bank.contains('baroda') || bank.contains('bob')) {
      return '🏦'; // BOB logo placeholder
    } else if (bank.contains('union')) {
      return '🏛️'; // Union Bank logo placeholder
    } else if (bank.contains('idbi')) {
      return '🏪'; // IDBI logo placeholder
    } else if (bank.contains('indusind')) {
      return '🏢'; // IndusInd logo placeholder
    } else if (bank.contains('federal')) {
      return '🏦'; // Federal logo placeholder
    } else if (bank.contains('rbl')) {
      return '🏛️'; // RBL logo placeholder
    } else if (bank.contains('bandhan')) {
      return '🏪'; // Bandhan logo placeholder
    }
    return '🏦'; // Default bank logo
  }
} 