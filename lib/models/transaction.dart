class Transaction {
  final String sender;
  final DateTime date;
  final double amount;
  final bool isCredit;
  final String originalMessage;

  Transaction({
    required this.sender,
    required this.date,
    required this.amount,
    required this.isCredit,
    required this.originalMessage,
  });

  String get formattedAmount {
    final prefix = isCredit ? '+₹' : '-₹';
    return '$prefix${amount.toStringAsFixed(2)}';
  }

  String get bankLogo {
    return getBankLogo(sender);
  }

  static String getBankLogo(String sender) {
    sender = sender.toLowerCase();
    if (sender.contains('hdfc')) return 'assets/bank_logos/hdfc.png';
    if (sender.contains('icici')) return 'assets/bank_logos/icici.png';
    if (sender.contains('sbi')) return 'assets/bank_logos/sbi.png';
    if (sender.contains('axis')) return 'assets/bank_logos/axis.png';
    if (sender.contains('kotak')) return 'assets/bank_logos/default.png';
    if (sender.contains('pnb')) return 'assets/bank_logos/default.png';
    if (sender.contains('bob')) return 'assets/bank_logos/default.png';
    if (sender.contains('canara')) return 'assets/bank_logos/default.png';
    // Add more banks as needed
    return 'assets/bank_logos/default.png';
  }
} 