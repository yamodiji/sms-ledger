class Transaction {
  final String id;
  final String sender;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String bank;
  final String description;

  Transaction({
    required this.id,
    required this.sender,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.bank,
    required this.description,
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

  static String getBankLogo(String bankName) {
    final bank = bankName.toLowerCase();
    if (bank.contains('hdfc')) return 'assets/bank_logos/hdfc.png';
    if (bank.contains('icici')) return 'assets/bank_logos/icici.png';
    if (bank.contains('sbi')) return 'assets/bank_logos/sbi.png';
    if (bank.contains('axis')) return 'assets/bank_logos/axis.png';
    if (bank.contains('kotak')) return 'assets/bank_logos/default.png';
    if (bank.contains('pnb')) return 'assets/bank_logos/default.png';
    if (bank.contains('bob')) return 'assets/bank_logos/default.png';
    if (bank.contains('canara')) return 'assets/bank_logos/default.png';
    // Add more banks as needed
    return 'assets/bank_logos/default.png';
  }
} 